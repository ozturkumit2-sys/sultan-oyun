#!/usr/bin/env python3
"""Arapça / Çince / Japonca yedek yazı tiplerini üretir (statik ağırlık + alt küme).
Kaynaklar (Google Fonts, OFL): BalooBhaijaan2[wght].ttf, NotoSansSC[wght].ttf, MPLUSRounded1c-Bold.ttf
Kullanım: python3 tools_src/fonts.py <kaynak_klasörü> <proje_kökü>
Alt küme: oyundaki tüm çeviri metinleri + names.json + dil adları + sık kullanılan karakter tabloları
(GB2312 1. seviye / JIS X 0208 1. seviye kanji, kana) — oyuncunun şef adı yazabilmesi için."""
import json
import os
import sys

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

SRC = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/fontsrc"
ROOT = sys.argv[2] if len(sys.argv) > 2 else "."
NATIVE = "Türkçe English Español Deutsch العربية हिन्दी 简体中文 日本語"
ASCII = "".join(chr(c) for c in range(0x20, 0x7F))
CJK_PUNCT = "".join(chr(c) for c in range(0x3000, 0x3040)) + "".join(chr(c) for c in range(0xFF01, 0xFF66))
CJK_PUNCT += "・ー…‥—–―‘’“”·×÷★☆♪♥〜～"


def texts(lang):
    out = set(NATIVE + ASCII)
    tr = json.load(open(os.path.join(ROOT, "data", "i18n", lang + ".json"), encoding="utf-8"))
    for v in tr.values():
        out.update(v)
    names = json.load(open(os.path.join(ROOT, "data", "names.json"), encoding="utf-8"))

    def walk(x):
        if isinstance(x, str):
            out.update(x)
        elif isinstance(x, dict):
            for v in x.values():
                walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)
    walk(names["lang"].get(lang, {}))
    return out


def gb2312_level1():
    s = set()
    for hi in range(0xB0, 0xD8):
        for lo in range(0xA1, 0xFF):
            try:
                s.add(bytes([hi, lo]).decode("gb2312"))
            except UnicodeDecodeError:
                pass
    return s


def jis_level1():
    s = set()
    for hi in range(0xB0, 0xD0):
        for lo in range(0xA1, 0xFF):
            try:
                s.add(bytes([hi, lo]).decode("euc_jp"))
            except UnicodeDecodeError:
                pass
    s.update(chr(c) for c in range(0x3041, 0x3097))   # hiragana
    s.update(chr(c) for c in range(0x30A1, 0x30FB))   # katakana
    return s


def build(src, dst, chars, wght=None):
    f = TTFont(os.path.join(SRC, src))
    if wght is not None and "fvar" in f:
        f = instancer.instantiateVariableFont(f, {"wght": wght}, updateFontNames=False)
    opts = subset.Options()
    opts.layout_features = ["*"]
    opts.name_IDs = ["*"]
    opts.name_languages = ["*"]
    opts.notdef_outline = True
    opts.hinting = False
    opts.drop_tables += ["DSIG"]
    sub = subset.Subsetter(opts)
    cm = f.getBestCmap()
    uni = sorted({ord(c) for c in chars if ord(c) in cm})
    sub.populate(unicodes=uni)
    sub.subset(f)
    out = os.path.join(ROOT, "assets", "fonts", dst)
    f.save(out)
    print(dst, len(uni), "karakter,", os.path.getsize(out) // 1024, "KB")


def main():
    ar = texts("ar")
    ar.update(chr(c) for c in range(0x0600, 0x0700))          # Arapça bloğu (şef adı için)
    ar.update(chr(c) for c in range(0xFE70, 0xFF00))          # sunum biçimleri
    build("baloobhaijaan2_BalooBhaijaan2[wght].ttf", "BalooBhaijaan2.ttf", ar, 650)
    zh = texts("zh") | gb2312_level1() | set(CJK_PUNCT)
    build("notosanssc_NotoSansSC[wght].ttf", "NotoSansSC.ttf", zh, 650)
    ja = texts("ja") | jis_level1() | set(CJK_PUNCT)
    build("mplusrounded1c_MPLUSRounded1c-Bold.ttf", "MPLUSRounded1c.ttf", ja)


if __name__ == "__main__":
    main()
