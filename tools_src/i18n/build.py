#!/usr/bin/env python3
"""Çeviri parçalarını (tools_src/i18n/chunks/*.json) birleştirip doğrular -> data/i18n/<dil>.json

Her parça: {"<md5[:8] kimlik>": [en, es, de, ar, hi, zh, ja]}
Doğrulama: biçim belirteçleri (%s, %d, %.1f, %%) aynı sırada ve aynı sayıda olmalı (GDScript sırayı
değiştiremez); {dish} gibi yer tutucular korunmalı.
Kullanım: python3 tools_src/i18n/build.py <proje_kökü> [--strict]"""
import hashlib, json, os, re, sys
ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
STRICT = "--strict" in sys.argv
LANGS = ["en", "es", "de", "ar", "hi", "zh", "ja"]
FMT = re.compile(r"%%|%[-+ 0#]*\d*(?:\.\d+)?[sdif]")
BRACE = re.compile(r"\{[a-z_]+\}")


def hid(s):
    return hashlib.md5(s.encode("utf-8")).hexdigest()[:8]


def specs(s):
    return [m for m in FMT.findall(s) if m != "%%"]


def pct(s):
    return s.count("%%")


keys = json.load(open(os.path.join(ROOT, "tools_src/i18n/keys.json"), encoding="utf-8"))
by_id = {hid(k): k for k in keys}
cdir = os.path.join(ROOT, "tools_src/i18n/chunks")
tr = {}
errors = []
for f in sorted(os.listdir(cdir)):
    if not f.endswith(".json"):
        continue
    try:
        d = json.load(open(os.path.join(cdir, f), encoding="utf-8"))
    except json.JSONDecodeError as e:
        print("JSON HATASI", f, e)
        sys.exit(1)
    for h, vals in d.items():
        if h not in by_id:
            errors.append(f"{f}: bilinmeyen kimlik {h}")
            continue
        if len(vals) != len(LANGS):
            errors.append(f"{f}: {h} dil sayısı {len(vals)}")
            continue
        src = by_id[h]
        for lang, v in zip(LANGS, vals):
            if specs(src) or pct(src):
                if specs(v) != specs(src) or pct(v) != pct(src):
                    errors.append(f"{f}: {h} [{lang}] biçim uyuşmuyor: {specs(src)} != {specs(v)} | {v}")
            if sorted(BRACE.findall(v)) != sorted(BRACE.findall(src)):
                errors.append(f"{f}: {h} [{lang}] yer tutucu uyuşmuyor | {v}")
            if v.strip() == "":
                errors.append(f"{f}: {h} [{lang}] boş")
        tr[h] = vals
missing = [k for h, k in by_id.items() if h not in tr]
os.makedirs(os.path.join(ROOT, "data/i18n"), exist_ok=True)
for i, lang in enumerate(LANGS):
    out = {}
    for h, vals in tr.items():
        out[by_id[h]] = vals[i]
    json.dump(out, open(os.path.join(ROOT, "data/i18n", lang + ".json"), "w", encoding="utf-8"), ensure_ascii=False, indent=0, sort_keys=True)
for e in errors:
    print("HATA", e)
print(f"çevrilen {len(tr)} / {len(by_id)} · eksik {len(missing)} · hata {len(errors)}")
if STRICT and (missing or errors):
    for m in missing[:40]:
        print("EKSİK", hid(m), m)
    sys.exit(1)
