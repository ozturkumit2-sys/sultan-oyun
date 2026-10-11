#!/usr/bin/env python3
"""Çevrilecek tüm Türkçe kaynak metinleri toplar -> tools_src/i18n/keys.json
Kaynaklar: kod içindeki Loc.t("...") / Loc.f("...") çağrıları, "# i18n" etiketli sabit blokları ve
data/*.json içindeki görünür metinler (IngredientDatabase._collect ile aynı kurallar).
Kullanım: python3 tools_src/i18n/extract.py <proje_kökü>"""
import json, os, re, sys
ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
STR = re.compile(r'"((?:[^"\\]|\\.)*)"')
LOC = re.compile(r'Loc\.[tf]\(\s*"((?:[^"\\]|\\.)*)"')
NO_TR = {"id", "tags", "inputs", "method", "color", "color2", "c1", "c2", "base", "decor", "likes", "dislikes", "icon",
         "type", "living", "unlocks", "match", "opponent", "themes", "mystery", "preferred", "methods", "likes_tags",
         "noun", "adj", "weights", "target", "stats", "bonus", "tags_add", "visual", "category", "skin_tones",
         "hair_colors", "kind", "slot", "judge", "mutation", "weight_shift", "rule", "hat", "shape", "style", "pose",
         "preset", "reaction", "anim", "sfx", "key", "stat", "tag", "dish"}
DATA = ["ingredients", "recipes", "themes", "judges", "judge_lines", "opponents", "leagues", "content"]


def unesc(s):
    return s.encode("utf-8").decode("unicode_escape").encode("latin-1").decode("utf-8") if "\\" in s else s


def idlike(s):
    return re.fullmatch(r"[a-z0-9_:\-]+", s) is not None


def translatable(s):
    return s.strip() != "" and not s.startswith(("#", "res://")) and not idlike(s)


keys = {}   # metin -> kaynak listesi
CODE_IDS = set()


def add(s, src, code=False):
    # kodda yalnızca harf olan küçük kelimeler ("taze", "tuhaf") metin olabilir
    if not translatable(s) and not (code and re.fullmatch(r"[a-zçğıöşü]+", s) and s not in CODE_IDS):
        return
    keys.setdefault(s, [])
    if src not in keys[s] and len(keys[s]) < 3:
        keys[s].append(src)


def walk(v, src, strict=True):
    if isinstance(v, dict):
        for k, x in v.items():
            if strict and k in NO_TR:
                continue
            if isinstance(x, str):
                add(x, src)
            elif isinstance(x, (dict, list)):
                walk(x, src, strict)
    elif isinstance(v, list):
        for x in v:
            if isinstance(x, str):
                add(x, src)
            elif isinstance(x, (dict, list)):
                walk(x, src, strict)


def load(name):
    return json.load(open(os.path.join(ROOT, "data", name + ".json"), encoding="utf-8"))


# IngredientDatabase.load_all içindeki köklerle aynı
ing = load("ingredients")
walk(ing.get("categories", {}), "data/ingredients")
walk(ing.get("ingredients", []), "data/ingredients")
rec = load("recipes")
walk(rec.get("recipes", []), "data/recipes")
walk(rec.get("methods", {}), "data/recipes")
walk(load("themes").get("themes", []), "data/themes")
jd = load("judges")
walk(jd.get("judges", []), "data/judges")
walk(jd.get("reactions", []), "data/judges")
walk(load("judge_lines"), "data/judge_lines", strict=False)
walk(load("opponents").get("opponents", []), "data/opponents")
lg = load("leagues")
walk(lg.get("rules", {}), "data/leagues")
walk(lg.get("leagues", []), "data/leagues")
ct = load("content")
walk(ct, "data/content")
walk(ct.get("decor", []), "data/content")

for dp, dn, fn in os.walk(os.path.join(ROOT, "scripts")):
    for f in sorted(fn):
        if not f.endswith(".gd"):
            continue
        p = os.path.join(dp, f)
        rel = os.path.relpath(p, ROOT)
        lines = open(p, encoding="utf-8").read().split("\n")
        i = 0
        while i < len(lines):
            line = lines[i]
            if line.lstrip().startswith("#"):
                i += 1
                continue
            for m in LOC.finditer(line):
                add(unesc(m.group(1)), rel, True)
            if re.match(r"\s*const \w+", line) and "# i18n" in line:
                depth = 0
                j = i
                while True:
                    l2 = lines[j]
                    for m in STR.finditer(l2.split("# i18n")[0]):
                        s = unesc(m.group(1))
                        # sözlük anahtarlarını atla
                        after = l2[m.end():m.end() + 2]
                        if after.startswith(":"):
                            continue
                        # anahtarı NO_TR'de olan değerler (ör. "icon": "hex") metin değildir
                        km = re.search(r'"(\w+)"\s*:\s*$', l2[:m.start()])
                        if km and km.group(1) in NO_TR:
                            continue
                        add(s, rel, True)
                    depth += l2.count("{") + l2.count("[") - l2.count("}") - l2.count("]")
                    if depth <= 0 or j == len(lines) - 1:
                        break
                    j += 1
                i = j
            i += 1

out = os.path.join(ROOT, "tools_src", "i18n", "keys.json")
json.dump(keys, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=0)
by = {}
for k, v in keys.items():
    g = v[0].split("/")[0] if v[0].startswith("data") else "code"
    by[g] = by.get(g, 0) + 1
print(len(keys), "metin", by, "karakter:", sum(len(k) for k in keys))
