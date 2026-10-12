#!/usr/bin/env python3
"""Validates the authored data and writes the JSON files the game loads."""
import json, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
from characters import CHARACTERS, FACTS
from events import E
from dialogue_en import D
from lang_en import S

errors = []
ids = {e["id"] for e in E}
dup = [e["id"] for e in E if sum(1 for x in E if x["id"] == e["id"]) > 1]
if dup: errors.append("duplicate event ids: %s" % sorted(set(dup)))

def walk_effects(effs, eid):
    for f in effs:
        k = f.get("e")
        if k == "say":
            lines = f["line"] if isinstance(f["line"], list) else [f["line"]]
            for l in lines:
                if l not in D: errors.append("%s: missing dialogue key %s" % (eid, l))
        elif k == "log":
            if f["text"] not in S: errors.append("%s: missing log key %s" % (eid, f["text"]))
        elif k == "mem":
            if f.get("text") and f["text"] not in S: errors.append("%s: missing mem key %s" % (eid, f["text"]))
        elif k == "chain":
            if f["event"] not in ids: errors.append("%s: chain to unknown event %s" % (eid, f["event"]))
        elif k == "intent":
            if f.get("event") and f["event"] not in ids: errors.append("%s: intent to unknown event %s" % (eid, f["event"]))
        elif k == "call" and f["fn"] == "summon":
            if f.get("event") and f["event"] not in ids: errors.append("%s: summon unknown event %s" % (eid, f["event"]))
        elif k == "stat":
            if f["key"] not in ("cliques",) and "stat." + f["key"] not in S: errors.append("%s: missing stat label %s" % (eid, f["key"]))
        for sub in ("effects",):
            if sub in f: walk_effects(f[sub], eid)
        if k == "pick":
            for opt in f["of"]: walk_effects(opt, eid)

for e in E:
    walk_effects(e.get("effects", []), e["id"])
    for o in e.get("outcomes", []):
        walk_effects(o.get("effects", []), e["id"] + "/" + o["id"])

# keys referenced from GDScript
code_events = ["item_returned", "coffee_gift", "ceren_briefing", "deniz_pitch", "gossip_share", "email_all_scene", "email_redirect_scene", "boss_scold", "job_hunt_talk", "help_request"]
for ce in code_events:
    if ce not in ids: errors.append("code references missing event " + ce)
for t in ["secret", "gossip_digest", "rant", "love", "complaint_boss", "complaint_team", "scheme"]:
    for m in ["email_all", "email_redirect"]:
        if "log.%s.%s" % (m, t) not in S: errors.append("missing log.%s.%s" % (m, t))
for a in ["break_coffee", "fix_coffee", "break_printer", "move_meeting", "set_temp", "lights_off", "lights_on", "edit_promo", "email_all", "email_redirect", "shuffle_files", "fake_notif", "move_item"]:
    for k in ["log.player." + a, "act." + a, "act." + a + ".d"]:
        if k not in S: errors.append("missing " + k)
for f in FACTS:
    if "fact." + f not in S: errors.append("missing fact text " + f)
for c in CHARACTERS:
    for g in c["goals"]:
        if "goal." + g["id"] not in S: errors.append("missing goal " + g["id"])
    for t in c["tasks"]:
        if "task." + t["id"] not in S: errors.append("missing task " + t["id"])

# placeholders sanity: every {x} in dialogue must be a known role/var name
known = {"actor","target","to","me","obj","item","suspect","owner","gossip","topic","helper","credited","victim","winner","loser","subject",
         "defender","requester","listener","spotter","joker","crush","honest","fact","intended","time","old_time","new_time","temp","loc","g1","g2","a","b","other","name","day","n","v","state","doing","age"}
for src, dd in (("dialogue", {k: sum(v.values(), []) for k, v in D.items()}), ("lang", {k: (v if isinstance(v, list) else [v]) for k, v in S.items()})):
    for k, lines in dd.items():
        for l in lines:
            for ph in re.findall(r"\{(\w+)\}", l):
                if ph not in known: errors.append("%s %s: unknown placeholder {%s}" % (src, k, ph))

if errors:
    print("\n".join(errors))
    print("%d errors" % len(errors))
    sys.exit(1)

os.makedirs(os.path.join(ROOT, "data", "lang"), exist_ok=True)
def dump(name, obj):
    with open(os.path.join(ROOT, "data", name), "w", encoding="utf-8") as fh:
        json.dump(obj, fh, ensure_ascii=False, indent=1)
dump("characters.json", CHARACTERS)
dump("facts.json", FACTS)
dump("events.json", E)
dump("dialogue_en.json", D)
dump("lang/en.json", S)
lines = sum(len(x) for v in D.values() for x in v.values())
print("OK: %d characters, %d facts, %d events, %d dialogue keys (%d lines), %d strings" % (len(CHARACTERS), len(FACTS), len(E), len(D), lines, len(S)))
