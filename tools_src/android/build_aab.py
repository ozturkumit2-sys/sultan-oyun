#!/usr/bin/env python3
"""FUSE CHEF — Godot release APK'sından Google Play için imzalı Android App Bundle (.aab) üretir.

Neden: Godot'nun yerleşik AAB yolu Gradle derlemesi ister (Google Maven bağımlılıkları). Bu betik
aynı sonucu Google'ın resmi araçlarıyla (aapt2 + bundletool) Gradle'sız üretir:
  1. Godot'nun dışa aktardığı release APK'sı alınır (imzasız olabilir).
  2. Godot 4.5 dışa aktarımındaki iki kusur giderilir:
     - resources.arsc'nin işaret ettiği ama silinmiş res/mipmap-anydpi-v26/themed_icon.xml geri eklenir,
     - androidx.startup sağlayıcısına verilen yanlış "authorities" değeri düzeltilir.
  3. aapt2 ile kaynaklar proto biçimine çevrilir; manifestte targetSdkVersion yükseltilir (varsayılan 36).
  4. bundletool build-bundle ile AAB oluşturulur (yerel kitaplıklar 16 KB sayfa hizalı, sıkıştırmasız).
  5. AAB, yükleme anahtarıyla (upload key) jarsigner ile imzalanır ve doğrulanır.

Kullanım:
  FUSECHEF_KS_PASS=... python3 tools_src/android/build_aab.py \\
      --apk build/release/FuseChef-v1.0.0.apk --out build/release/FuseChef-v1.0.0-release.aab \\
      --bundletool /yol/bundletool-all-1.18.2.jar --keystore /yol/fusechef-upload.jks --alias fusechef-upload
Parola yalnızca FUSECHEF_KS_PASS ortam değişkeninden okunur; komut satırına ya da depoya yazılmaz.
Gerekenler: JDK (jarsigner), aapt2 (Ubuntu: apt install aapt), python3-protobuf, bundletool jar.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from aapt_proto import XmlNode, attr, walk  # noqa: E402

SIG_SUFFIXES = (".SF", ".RSA", ".DSA", ".EC")


def run(cmd, env=None):
    print("$", " ".join(cmd))
    r = subprocess.run(cmd, env=env, capture_output=True, text=True)
    out = (r.stdout + r.stderr).strip()
    if out:
        lines = [l for l in out.splitlines() if "JAVA_TOOL_OPTIONS" not in l]
        if len(lines) > 40:
            lines = lines[:5] + ["... (%d satır)" % (len(lines) - 10)] + lines[-5:]
        print("\n".join(lines))
    if r.returncode != 0:
        sys.exit("HATA: komut başarısız (%d)" % r.returncode)
    return out


def is_signature(name):
    if not name.startswith("META-INF/"):
        return False
    base = name.split("/")[-1].upper()
    return base == "MANIFEST.MF" or base.endswith(SIG_SUFFIXES)


def fix_apk(src, dst):
    """İmzayı atar, eksik themed_icon.xml'i geri ekler. Sıkıştırılmadan saklanan asset yollarını döndürür."""
    zin = zipfile.ZipFile(src)
    names = set(zin.namelist())
    stored_assets = []
    icon_xml = None
    with zipfile.ZipFile(dst, "w") as zout:
        for info in zin.infolist():
            data = zin.read(info)
            if info.filename == "res/mipmap-anydpi-v26/icon.xml":
                icon_xml = data
            if is_signature(info.filename):
                continue
            if info.filename.startswith("assets/") and info.compress_type == zipfile.ZIP_STORED:
                stored_assets.append(info.filename)
            zout.writestr(info, data, compress_type=info.compress_type)
        if "res/mipmap-anydpi-v26/themed_icon.xml" not in names and icon_xml is not None:
            zi = zipfile.ZipInfo("res/mipmap-anydpi-v26/themed_icon.xml", date_time=(2026, 1, 1, 0, 0, 0))
            zi.compress_type = zipfile.ZIP_DEFLATED
            zout.writestr(zi, icon_xml)
            print("düzeltme: res/mipmap-anydpi-v26/themed_icon.xml geri eklendi")
    return stored_assets


def patch_manifest(data, target_sdk):
    node = XmlNode()
    node.ParseFromString(data)
    pkg = ""
    for el, path in walk(node):
        if el.name == "manifest":
            for a in el.attribute:
                if a.name == "package":
                    pkg = a.value
        if el.name == "uses-sdk":
            a = attr(el, "targetSdkVersion")
            old = a.compiled_item.prim.int_decimal_value
            a.compiled_item.prim.int_decimal_value = target_sdk
            if a.value:
                a.value = str(target_sdk)
            print("düzeltme: targetSdkVersion %d -> %d" % (old, target_sdk))
        if el.name == "provider":
            name = attr(el, "name")
            auth = attr(el, "authorities")
            if name is not None and auth is not None and name.value == "androidx.startup.InitializationProvider":
                want = pkg + ".androidx-startup"
                if auth.value != want:
                    print("düzeltme: androidx.startup authorities %s -> %s" % (auth.value, want))
                    auth.value = want
                    if auth.compiled_item.HasField("str"):
                        auth.compiled_item.str.value = want
    # aynı yetki adı iki sağlayıcıda olmamalı
    seen = {}
    for el, path in walk(node):
        if el.name == "provider":
            a = attr(el, "authorities")
            if a is not None:
                assert a.value not in seen, "yinelenen provider authority: " + a.value
                seen[a.value] = True
    return node.SerializeToString()


def build_module(proto_apk, module_zip, target_sdk):
    zin = zipfile.ZipFile(proto_apk)
    with zipfile.ZipFile(module_zip, "w", zipfile.ZIP_DEFLATED) as zout:
        for info in zin.infolist():
            n = info.filename
            if n.endswith("/") or is_signature(n):
                continue
            data = zin.read(info)
            if n == "AndroidManifest.xml":
                zout.writestr("manifest/AndroidManifest.xml", patch_manifest(data, target_sdk))
            elif n.startswith("classes") and n.endswith(".dex") and "/" not in n:
                zout.writestr("dex/" + n, data)
            elif n == "resources.pb" or n.startswith(("res/", "assets/", "lib/")):
                zout.writestr(n, data)
            else:
                zout.writestr("root/" + n, data)


def bundle_config(stored_assets):
    globs = set()
    for p in stored_assets:
        base = p.split("/")[-1]
        if "." in base:
            globs.add("assets/**." + base.rsplit(".", 1)[1])
        else:
            globs.add(p)
    return {
        "optimizations": {
            "splitsConfig": {"splitDimension": [
                {"value": "ABI"},
                {"value": "SCREEN_DENSITY"},
                {"value": "LANGUAGE", "negate": True},
            ]},
            "uncompressNativeLibraries": {"enabled": True, "alignment": "PAGE_ALIGNMENT_16K"},
        },
        "compression": {"uncompressedGlob": sorted(globs)},
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apk", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--bundletool", required=True)
    ap.add_argument("--keystore", required=True)
    ap.add_argument("--alias", required=True)
    ap.add_argument("--target-sdk", type=int, default=36)
    a = ap.parse_args()
    if not os.environ.get("FUSECHEF_KS_PASS"):
        sys.exit("HATA: FUSECHEF_KS_PASS ortam değişkeni (keystore parolası) tanımlı değil")
    for tool in ("aapt2", "jarsigner", "java"):
        if shutil.which(tool) is None:
            sys.exit("HATA: %s bulunamadı" % tool)

    work = tempfile.mkdtemp(prefix="fusechef_aab_")
    fixed = os.path.join(work, "fixed.apk")
    proto = os.path.join(work, "proto.apk")
    module = os.path.join(work, "base.zip")
    cfg = os.path.join(work, "BundleConfig.json")
    unsigned = os.path.join(work, "unsigned.aab")

    stored = fix_apk(a.apk, fixed)
    run(["aapt2", "convert", "--output-format", "proto", "-o", proto, fixed])
    build_module(proto, module, a.target_sdk)
    json.dump(bundle_config(stored), open(cfg, "w"), indent=1)
    run(["java", "-jar", a.bundletool, "build-bundle", "--modules=" + module, "--config=" + cfg, "--output=" + unsigned])

    out_tmp = a.out + ".tmp"
    shutil.copyfile(unsigned, out_tmp)
    run(["jarsigner", "-sigalg", "SHA256withRSA", "-digestalg", "SHA-256", "-keystore", a.keystore,
         "-storepass:env", "FUSECHEF_KS_PASS", "-keypass:env", "FUSECHEF_KS_PASS", out_tmp, a.alias])
    os.replace(out_tmp, a.out)
    # Android imza sertifikaları kendinden imzalıdır; -strict bunu hata sayacağı için kullanılmaz.
    v = run(["jarsigner", "-verify", "-verbose", "-certs", a.out])
    if "jar verified." not in v or "CN=" not in v:
        sys.exit("HATA: AAB imzası doğrulanamadı")
    run(["java", "-jar", a.bundletool, "validate", "--bundle=" + a.out])
    shutil.rmtree(work, ignore_errors=True)
    print("TAMAM:", a.out, os.path.getsize(a.out), "bayt")


if __name__ == "__main__":
    main()
