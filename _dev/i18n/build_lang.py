#!/usr/bin/env python3
"""Builds data/lang/<code>.json and data/dialogue_<code>.json from translation files.

Translation files: _dev/i18n/<code>/*.txt, one unit per line: "id|text" ("\\n" = new line).
Checks every line against its English original: the same people/values must be
named, grammar tags must exist for the language, nothing may be left unknown.
Usage: build_lang.py [codes...]   (default: every folder that exists)
"""
import json, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
LANGS = ["tr", "de", "es", "fr", "zh", "hi"]
CASES = {"tr": {"in", "i", "e", "de", "den", "le", "dir"}, "de": {"s"}}
PH = re.compile(r"\{(\w+)(?::(\w+))?(?:\?([^|{}]*)\|([^{}]*))?\}")
BAD_BRACES = re.compile(r"\{[^}]*$|^[^{]*\}")

units = json.load(open(os.path.join(HERE, "units.json"), encoding="utf-8"))
by_id = {u["id"]: u for u in units}


def names(s):
    return [m.group(1) for m in PH.finditer(s)]


def load(code):
    out = {}
    d = os.path.join(HERE, code)
    if not os.path.isdir(d):
        return out, []
    errs = []
    for fn in sorted(os.listdir(d)):
        if not fn.endswith(".txt"):
            continue
        for ln, line in enumerate(open(os.path.join(d, fn), encoding="utf-8"), 1):
            line = line.rstrip("\n").rstrip("\r")
            if not line.strip():
                continue
            m = re.match(r"^(\d+)\|(.*)$", line)
            if not m:
                errs.append("%s/%s:%d: not 'id|text'" % (code, fn, ln))
                continue
            i = int(m.group(1))
            if i not in by_id:
                errs.append("%s/%s:%d: unknown id %d" % (code, fn, ln, i))
                continue
            if i in out and out[i] != m.group(2).replace("\\n", "\n"):
                errs.append("%s/%s:%d: id %d translated twice" % (code, fn, ln, i))
            out[i] = m.group(2).replace("\\n", "\n")
    return out, errs


def check(code, tr):
    errs, warns = [], []
    for i, t in tr.items():
        u = by_id[i]
        en = u["en"]
        allowed = set(names(en))
        if u["key"].startswith("D|"):
            allowed |= {"me", "to"}
        tag = "%s #%d (%s)" % (code, i, u["key"])
        if t.strip() == "":
            errs.append(tag + ": empty")
            continue
        for m in PH.finditer(t):
            n, case = m.group(1), m.group(2)
            if n not in allowed:
                errs.append("%s: unknown placeholder {%s}" % (tag, m.group(0)[1:-1]))
            if case and case not in CASES.get(code, set()):
                errs.append("%s: grammar tag ':%s' not available in %s" % (tag, case, code))
        rest = PH.sub("", t)
        if "{" in rest or "}" in rest:
            errs.append(tag + ": stray brace in " + repr(t))
        for n in set(names(en)):
            if n not in [m.group(1) for m in PH.finditer(t) if m.group(3) is None]:
                warns.append("%s: does not show {%s}" % (tag, n))
    return errs, warns


def build(code):
    tr, errs = load(code)
    e2, warns = check(code, tr)
    errs += e2
    S, D = {}, {}
    s_lists, d_keys = {}, {}
    for u in units:
        parts = u["key"].split("|")
        val = tr.get(u["id"])
        if parts[0] == "S":
            if len(parts) == 3:
                s_lists.setdefault(parts[1], []).append((int(parts[2]), val, u["en"]))
            elif val is not None:
                S[parts[1]] = val
        else:
            d_keys.setdefault(parts[1], []).append((parts[2], int(parts[3]), val))
    for k, items in s_lists.items():
        if all(v is not None for _, v, _ in items):
            S[k] = [v for _, v, _ in sorted(items)]
    for k, items in d_keys.items():
        if all(v is not None for _, _, v in items):
            entry = {}
            for sp, idx, v in sorted(items, key=lambda x: (x[0], x[1])):
                entry.setdefault(sp, []).append(v)
            D[k] = entry
    total = len(units)
    done = sum(1 for u in units if u["id"] in tr)
    return S, D, errs, warns, done, total


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    codes = args or [c for c in LANGS if os.path.isdir(os.path.join(HERE, c))]
    bad = False
    for code in codes:
        S, D, errs, warns, done, total = build(code)
        for e in errs:
            print("ERROR " + e)
        if "-v" in sys.argv or os.environ.get("I18N_WARN"):
            for w in warns:
                print("warn  " + w)
        print("%s: %d/%d units (%.1f%%), %d strings, %d dialogue keys, %d errors, %d warnings" % (
            code, done, total, 100.0 * done / total, len(S), len(D), len(errs), len(warns)))
        if errs:
            bad = True
            continue
        with open(os.path.join(ROOT, "data", "lang", code + ".json"), "w", encoding="utf-8") as fh:
            json.dump(S, fh, ensure_ascii=False, indent=1)
        with open(os.path.join(ROOT, "data", "dialogue_%s.json" % code), "w", encoding="utf-8") as fh:
            json.dump(D, fh, ensure_ascii=False, indent=1)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
