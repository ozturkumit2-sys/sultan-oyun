#!/usr/bin/env python3
"""Lists every English text unit (UI/log strings and speech lines) with a stable number.

units.json keeps the numbering: units already numbered keep their id, new ones are
appended, so translation files (lines "id|text") stay valid when the game grows.
Writes chunks/en_NNN.txt ("id|key|text") for translating in manageable pieces.
"""
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

S = json.load(open(os.path.join(ROOT, "data", "lang", "en.json"), encoding="utf-8"))
D = json.load(open(os.path.join(ROOT, "data", "dialogue_en.json"), encoding="utf-8"))

ORDER = ["ui", "title", "paper", "journal", "cat", "tab", "spot", "state", "opt", "why", "rel", "mood", "emo", "stat", "bond",
         "plan", "doing", "loc", "what", "topic", "item", "obj", "office", "goal", "task", "fact", "rumor", "char", "wall", "board",
         "act", "iv", "arc", "log", "mem"]


def s_units():
    keys = sorted(S, key=lambda k: (ORDER.index(k.split(".")[0]) if k.split(".")[0] in ORDER else len(ORDER), k))
    for k in keys:
        v = S[k]
        if isinstance(v, list):
            for i, x in enumerate(v):
                yield "S|%s|%d" % (k, i), x
        else:
            yield "S|%s" % k, v


def d_units():
    for k in D:
        for sp, lines in D[k].items():
            for i, x in enumerate(lines):
                yield "D|%s|%s|%d" % (k, sp, i), x


def main():
    path = os.path.join(HERE, "units.json")
    old = json.load(open(path, encoding="utf-8")) if os.path.exists(path) else []
    by_key = {u["key"]: u for u in old}
    nxt = max([u["id"] for u in old] + [0]) + 1
    units = []
    for key, text in list(s_units()) + list(d_units()):
        if key in by_key:
            u = by_key[key]
            u["en"] = text
        else:
            u = {"id": nxt, "key": key, "en": text}
            nxt += 1
        units.append(u)
    units.sort(key=lambda u: u["id"])
    json.dump(units, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=0)
    # chunks of roughly N English words, never splitting a key's lines
    size = int(sys.argv[1]) if len(sys.argv) > 1 else 1400
    cdir = os.path.join(HERE, "chunks")
    os.makedirs(cdir, exist_ok=True)
    for f in os.listdir(cdir):
        os.remove(os.path.join(cdir, f))
    chunk, words, n = [], 0, 0
    def flush():
        nonlocal chunk, words, n
        if not chunk:
            return
        with open(os.path.join(cdir, "en_%03d.txt" % n), "w", encoding="utf-8") as fh:
            for u in chunk:
                fh.write("%d|%s|%s\n" % (u["id"], u["key"][2:], u["en"].replace("\n", "\\n")))
        n += 1
        chunk, words = [], 0
    last_group = None
    for u in units:
        group = u["key"].rsplit("|", 2)[0] if u["key"].startswith("D|") else u["key"]
        if words >= size and group != last_group:
            flush()
        chunk.append(u)
        words += len(u["en"].split())
        last_group = group
    flush()
    print("%d units, %d chunks, %d words" % (len(units), n, sum(len(u["en"].split()) for u in units)))


if __name__ == "__main__":
    main()
