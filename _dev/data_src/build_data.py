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
import events_life  # noqa: F401  (registers living-office events)
import lang_story_en  # noqa: F401  (strings for the story layer)
import arcs as arcs_mod
from rumors import RUMORS
A = arcs_mod.A

# ---------------------------------------------------------------- pacing tiers for the original events
TIERS = {
    "small": ["gossip_share", "flirt", "jealousy", "coffee_gift", "ece_spill", "tease_crush", "secret_friends_spotted", "workload_vent",
              "thermo_complaint", "dark_bonding", "meeting_late", "board_noticed", "spill"],
    "medium": ["accusation", "credit_steal", "credit_fight", "grudge_flare", "reconciliation", "thermo_argument", "email_confront", "boss_scold",
               "crush_exposed", "couple_forms", "job_hunt_talk", "defense", "unexpected_solidarity", "meeting_opportunity", "ceren_tells_victim",
               "promo_grudge", "nepotism_reveal", "boss_learns_job_hunt", "review_shock", "manager_outburst", "big_fight", "zeynep_knows"],
}
# less daily repetition of the original encounter events
TWEAKS = {
    "jealousy": {"cooldown_days": 2},
    "secret_friends_spotted": {"max_day": 1, "cooldown_days": 2},
    "gossip_share": {"max_day": 1, "cooldown": 180},
    "unexpected_solidarity": {"max_day": 1},
    "flirt": {"max_day": 1, "cooldown": 240},
    "ece_spill": {"cooldown_days": 2},
    "secret_friends_spotted": {"max_day": 1, "cooldown_days": 2, "scope": "global"},
    "jealous_friend": {"max_day": 1},
}
by_id = {e["id"]: e for e in E}
for tier, ids in TIERS.items():
    for i in ids:
        if i in by_id and "tier" not in by_id[i]:
            by_id[i]["tier"] = tier
for i, kv in TWEAKS.items():
    by_id[i].update(kv)

errors = []
ids = {e["id"] for e in E}
dup = [e["id"] for e in E if sum(1 for x in E if x["id"] == e["id"]) > 1]
if dup: errors.append("duplicate event ids: %s" % sorted(set(dup)))
arc_ids = {a["id"] for a in A}

EFFECTS = {"say", "emote", "expr", "rel", "mood", "stress", "mem", "learn", "reveal", "log", "stat", "hold", "intent", "cancel", "chain", "witness",
           "each", "rumor", "favor", "obj", "item_home", "meet", "goal", "flag", "npcflag", "sfx", "fx", "ghost", "work", "act", "call", "set", "pick",
           "debunk", "forget", "distort", "bond", "plan", "morale", "arc_start", "arc_next", "arc_end", "meetup", "away", "trigger"}
CONDS = {"trait", "rel", "affinity", "mood", "stress", "knows", "fact_exists", "is", "same", "present", "available", "near", "time", "chance", "goal",
         "mem", "memval", "day", "office", "flag", "dayflag", "npcflag", "activity", "stat", "var", "zone", "meeting", "work_left", "discomfort",
         "ghost", "rolefilled", "promoted", "any", "all", "sure", "picks", "truth", "bond", "plan", "morale", "arc", "in_story", "fired", "result", "can_arc"}
known_ph = {"actor","target","to","me","obj","item","suspect","owner","gossip","topic","helper","credited","victim","winner","loser","subject",
            "defender","requester","listener","spotter","joker","crush","honest","fact","intended","time","old_time","new_time","temp","loc","g1","g2",
            "a","b","other","name","day","n","v","state","doing","age","rumor"}
arc_next_refs = {}   # event id -> [stage names it may jump to]

def walk_conds(conds, eid):
    for c in conds:
        k = c.get("c")
        if k not in CONDS: errors.append("%s: unknown condition %s" % (eid, k))
        if k in ("any", "all"): walk_conds(c["of"], eid)
        if k == "can_arc" and c["arc"] not in arc_ids: errors.append("%s: can_arc unknown arc %s" % (eid, c["arc"]))

def walk_effects(effs, eid):
    for f in effs:
        k = f.get("e")
        if k not in EFFECTS: errors.append("%s: unknown effect %s" % (eid, k))
        if "when" in f: walk_conds(f["when"], eid)
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
        elif k == "meetup":
            if f["event"] not in ids: errors.append("%s: meetup unknown event %s" % (eid, f["event"]))
        elif k == "call" and f["fn"] == "summon":
            if f.get("event") and f["event"] not in ids: errors.append("%s: summon unknown event %s" % (eid, f["event"]))
        elif k == "stat":
            if f["key"] not in ("cliques",) and "stat." + f["key"] not in S: errors.append("%s: missing stat label %s" % (eid, f["key"]))
        elif k == "rumor":
            if f["kind"] not in RUMORS: errors.append("%s: unknown rumour kind %s" % (eid, f["kind"]))
            if f.get("key"): known_ph.add(f["key"])
        elif k == "arc_start":
            if f["arc"] not in arc_ids: errors.append("%s: arc_start unknown arc %s" % (eid, f["arc"]))
        elif k == "arc_next":
            arc_next_refs.setdefault(eid.split("/")[0], []).append(f["stage"])
            if f.get("delay"): errors.append("%s: arc_next must not be delayed" % eid)
        elif k == "arc_end":
            if f.get("delay"): errors.append("%s: arc_end must not be delayed" % eid)
        elif k == "set":
            known_ph.add(f["key"])
        if k in ("chain", "intent", "meetup", "trigger") and isinstance(f.get("roles"), dict):
            for rk in f["roles"]:
                known_ph.add(rk)
        elif k == "distort":
            known_ph.add(f.get("key", "gossip"))
        for sub in ("effects",):
            if sub in f: walk_effects(f[sub], eid)
        if k == "pick":
            for opt in f["of"]: walk_effects(opt, eid)

for e in E:
    for r in e.get("roles", []):
        known_ph.add(r["name"])
        walk_conds(r.get("where", []), e["id"])
    for v in e.get("vars", []):
        known_ph.add(v["name"])
    if "tier" in e and e["tier"] not in ("", "small", "medium", "big"):
        errors.append("%s: bad tier %s" % (e["id"], e["tier"]))
    walk_conds(e.get("conditions", []), e["id"])
    walk_effects(e.get("effects", []), e["id"])
    for o in e.get("outcomes", []):
        walk_conds(o.get("when", []), e["id"])
        walk_effects(o.get("effects", []), e["id"] + "/" + o["id"])
    for f in e.get("effects", []) + sum((o.get("effects", []) for o in e.get("outcomes", [])), []):
        if f.get("e") == "arc_start":
            for ck in f["cast"]:
                known_ph.add(ck)

# ---------------------------------------------------------------- story arcs
MODES = {"now", "visit", "desk", "place", "meet", "gather"}
owner_of = {}
for a in A:
    st = a["stages"]
    if a["first"] not in st: errors.append("arc %s: first stage %s missing" % (a["id"], a["first"]))
    if len(st) < 3: errors.append("arc %s: needs at least 3 stages" % a["id"])
    for sid, s_ in st.items():
        if s_["event"] not in ids: errors.append("arc %s/%s: unknown event %s" % (a["id"], sid, s_["event"]))
        if s_["mode"] not in MODES: errors.append("arc %s/%s: bad mode %s" % (a["id"], sid, s_["mode"]))
        if s_["mode"] in ("visit", "desk", "meet") and not s_.get("target"): errors.append("arc %s/%s: mode %s needs a target" % (a["id"], sid, s_["mode"]))
        if s_["mode"] == "place" and not s_.get("place"): errors.append("arc %s/%s: place mode needs a place" % (a["id"], sid))
        if s_["mode"] in ("meet", "gather") and not s_.get("area"): errors.append("arc %s/%s: needs an area" % (a["id"], sid))
        f = s_.get("fail", "")
        if not (f.startswith("end:") or f == "retry" or f in st): errors.append("arc %s/%s: fail -> unknown %s" % (a["id"], sid, f))
        if s_["event"] in owner_of and owner_of[s_["event"]] != a["id"]:
            errors.append("event %s used by two arcs" % s_["event"])
        owner_of[s_["event"]] = a["id"]
        for nxt in arc_next_refs.get(s_["event"], []):
            if nxt not in st: errors.append("arc %s/%s: event %s jumps to unknown stage %s" % (a["id"], sid, s_["event"], nxt))
    # every stage must be reachable from the first one
    seen, todo = set(), [a["first"]]
    while todo:
        cur = todo.pop()
        if cur in seen or cur not in st: continue
        seen.add(cur)
        todo += arc_next_refs.get(st[cur]["event"], [])
        f = st[cur].get("fail", "")
        if f in st: todo.append(f)
    for sid in st:
        if sid not in seen: errors.append("arc %s: stage %s is unreachable" % (a["id"], sid))
    longest = {}
    def depth(sid, stack=()):
        if sid in stack: return 0
        nx = arc_next_refs.get(st[sid]["event"], [])
        return 1 + max([depth(n, stack + (sid,)) for n in nx if n in st] + [0])
    a["_max_depth"] = depth(a["first"])
    if a["_max_depth"] < 3: errors.append("arc %s: longest path only %d stages" % (a["id"], a["_max_depth"]))
    for stid, s_ in st.items():
        for key in ("actor", "target"):
            ref = s_.get(key, "")
            if ref and not ref.startswith("@") and not ref.startswith("$"):
                known_ph.add(ref)

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
for k in RUMORS:
    if "rumor." + k not in S: errors.append("missing rumor text " + k)
    tw = RUMORS[k].get("twist")
    if tw and tw not in RUMORS: errors.append("rumour %s twists into unknown %s" % (k, tw))
for a in A:
    if "arc." + a["id"] not in S: errors.append("missing arc title arc.%s" % a["id"])
    if "arc.%s.teaser" % a["id"] not in S: errors.append("missing arc teaser arc.%s.teaser" % a["id"])
for c in CHARACTERS:
    for g in c["goals"]:
        if "goal." + g["id"] not in S: errors.append("missing goal " + g["id"])
    for t in c["tasks"]:
        if "task." + t["id"] not in S: errors.append("missing task " + t["id"])

# placeholders sanity: every {x} in dialogue must be a known role/var name
for src, dd in (("dialogue", {k: sum(v.values(), []) for k, v in D.items()}), ("lang", {k: (v if isinstance(v, list) else [v]) for k, v in S.items()})):
    for k, lines in dd.items():
        for l in lines:
            for ph in re.findall(r"\{(\w+)\}", l):
                if ph not in known_ph: errors.append("%s %s: unknown placeholder {%s}" % (src, k, ph))

if errors:
    print("\n".join(errors))
    print("%d errors" % len(errors))
    sys.exit(1)

for a in A:
    a.pop("_max_depth", None)
os.makedirs(os.path.join(ROOT, "data", "lang"), exist_ok=True)
def dump(name, obj):
    with open(os.path.join(ROOT, "data", name), "w", encoding="utf-8") as fh:
        json.dump(obj, fh, ensure_ascii=False, indent=1)
dump("characters.json", CHARACTERS)
dump("facts.json", FACTS)
dump("events.json", E)
dump("arcs.json", A)
dump("rumors.json", RUMORS)
dump("dialogue_en.json", D)
dump("lang/en.json", S)
lines = sum(len(x) for v in D.values() for x in v.values())
init = [e for e in E if e.get("trigger") == "initiative"]
print("OK: %d characters, %d facts, %d events (%d initiative), %d arcs (%d stages), %d rumour kinds, %d dialogue keys (%d lines), %d strings" % (
    len(CHARACTERS), len(FACTS), len(E), len(init), len(A), sum(len(a["stages"]) for a in A), len(RUMORS), len(D), lines, len(S)))
