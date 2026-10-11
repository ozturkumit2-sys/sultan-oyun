#!/usr/bin/env python3
"""keys.json -> gruplu, karma (hash) kimlikli liste. Çeviri dosyaları bu kimlikleri kullanır."""
import hashlib, json, os, sys
ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
group = sys.argv[2] if len(sys.argv) > 2 else None
keys = json.load(open(os.path.join(ROOT, "tools_src/i18n/keys.json"), encoding="utf-8"))
def hid(s):
    return hashlib.md5(s.encode("utf-8")).hexdigest()[:8]
def grp(src):
    return src[0].split("/")[1] if src[0].startswith("data/") else "code"
done = set()
cdir = os.path.join(ROOT, "tools_src/i18n/chunks")
if os.path.isdir(cdir):
    for f in os.listdir(cdir):
        if f.endswith(".json"):
            done |= set(json.load(open(os.path.join(cdir, f), encoding="utf-8")).keys())
rows = [(hid(k), k, grp(v)) for k, v in keys.items()]
if group == "--stats":
    from collections import Counter
    c = Counter(g for h, k, g in rows if h not in done)
    print("eksik:", dict(c), "toplam eksik:", sum(c.values()), "/", len(rows))
    sys.exit()
for h, k, g in rows:
    if (group is None or g == group) and h not in done:
        print(h, "|", json.dumps(k, ensure_ascii=False))
