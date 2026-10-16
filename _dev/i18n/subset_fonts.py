#!/usr/bin/env python3
"""Cuts the Chinese fonts down to the characters the game actually uses.

Full fonts (~27 MB) live in _dev/fonts_full (downloaded if missing, not in git);
the subsets go to assets/fonts/zh_body.ttf (LXGW WenKai) and zh_display.ttf
(ZCOOL KuaiLe). Both are renamed, as the SIL OFL asks of modified fonts.
Run after every change to the Chinese text.
"""
import json, os, subprocess, sys, urllib.request
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
FULL = os.path.join(ROOT, "_dev", "fonts_full")
SRC = {
    "LXGWWenKai-Regular.ttf": "https://github.com/lxgw/LxgwWenKai/releases/latest/download/LXGWWenKai-Regular.ttf",
    "zcoolkuaile_ZCOOLKuaiLe-Regular.ttf": "https://raw.githubusercontent.com/google/fonts/main/ofl/zcoolkuaile/ZCOOLKuaiLe-Regular.ttf",
}


def chars():
    txt = "中文"
    for p in (os.path.join(ROOT, "data", "lang", "zh.json"), os.path.join(ROOT, "data", "dialogue_zh.json")):
        if os.path.exists(p):
            txt += open(p, encoding="utf-8").read()
    # everything wide (CJK, full-width punctuation) plus the usual Chinese punctuation
    out = set(c for c in txt if ord(c) >= 0x2E80)
    out |= set("，。！？；：、（）《》「」『』“”‘’…—～·")
    return "".join(sorted(out))


def subset(src, dst, family, text):
    from fontTools import subset as fts
    from fontTools.ttLib import TTFont
    opts = fts.Options()
    opts.layout_features = ["*"]
    opts.name_IDs = ["*"]
    opts.notdef_outline = True
    opts.hinting = False
    f = TTFont(src)
    sub = fts.Subsetter(opts)
    sub.populate(text=text)
    sub.subset(f)
    for rec in f["name"].names:
        if rec.nameID in (1, 3, 4, 6, 16, 17):
            val = {1: family, 3: family + "-Subset", 4: family, 6: family.replace(" ", ""), 16: family, 17: "Regular"}[rec.nameID]
            rec.string = val
    f.save(dst)
    return os.path.getsize(dst)


def main():
    os.makedirs(FULL, exist_ok=True)
    for fn, url in SRC.items():
        p = os.path.join(FULL, fn)
        if not os.path.exists(p):
            print("downloading", fn)
            urllib.request.urlretrieve(url, p)
    text = chars()
    a = subset(os.path.join(FULL, "LXGWWenKai-Regular.ttf"), os.path.join(ROOT, "assets", "fonts", "zh_body.ttf"), "OP Kai Body", text)
    b = subset(os.path.join(FULL, "zcoolkuaile_ZCOOLKuaiLe-Regular.ttf"), os.path.join(ROOT, "assets", "fonts", "zh_display.ttf"), "OP Kuaile Display", text)
    print("%d characters -> zh_body %d KB, zh_display %d KB" % (len(text), a // 1024, b // 1024))


if __name__ == "__main__":
    main()
