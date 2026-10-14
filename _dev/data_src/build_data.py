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
import iv_all
import arcs_more1  # noqa: F401  (more story arcs)
import arcs_more2  # noqa: F401  (stories set off by hidden combinations)
import arcs_more3  # noqa: F401  (stories the office starts on its own)
import npc_actions  # noqa: F401  (more things people do on their own)
import lang_ui_more  # noqa: F401  (UI strings for v1.2)
IV = iv_all.IV
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
# ---------------------------------------------------------------- what kind of NPC action each initiative is
DOMAINS = ("socializing", "rivalry", "work_career", "friendship", "romance", "arguments", "gossip", "helping", "secret_plans", "comedy")
OLD_DOMAINS = {
    "kitchen_gossip": "gossip", "rumor_check": "gossip", "misheard_call": "comedy", "suck_up": "work_career", "raise_request": "work_career",
    "micromanage": "work_career", "work_dump": "rivalry", "new_rule": "work_career", "bet_pool": "socializing", "brag_visit": "rivalry",
    "desk_sabotage": "rivalry", "hide_prank": "comedy", "lunch_invite": "socializing", "bring_snack": "helping", "inside_joke": "friendship",
    "congratulate": "friendship", "confide": "friendship", "note_drop": "romance", "coffee_date": "romance", "heartbreak": "romance",
    "sarcasm_misfire": "arguments", "wrong_name": "comedy", "quit_vent": "work_career", "update_cv": "secret_plans", "recruiter_call": "secret_plans",
    "lost_report": "helping", "reply_all": "comedy", "room_double_booked": "arguments", "alliance_pact": "secret_plans", "alliance_intel": "secret_plans",
    "chair_sink": "comedy", "fridge_raid": "comedy", "kick_me_note": "comedy", "glass_bonk": "comedy", "keyboard_spill": "comedy", "cake_day": "socializing",
    "share_credit": "helping", "deal_closed": "work_career", "audit": "work_career", "secret_slip": "gossip", "logs_discovery": "secret_plans",
    "revenge_rumor": "gossip", "peace_offering": "friendship", "start_stolen_idea": "rivalry", "start_romance": "romance", "start_headhunted": "work_career",
    "start_resignation": "work_career", "start_missing_contract": "arguments", "start_deleted_folder": "helping", "start_layoff_panic": "gossip",
    "start_secret_alliance": "secret_plans", "start_birthday": "socializing", "start_blame_game": "arguments", "start_mentor": "helping",
    "start_promo_push": "work_career", "start_revenge": "rivalry", "start_boss_clash": "arguments", "start_niece": "secret_plans",
}
by_id = {e["id"]: e for e in E}
# history some NPC actions need before they make sense (used by tests/npc_action_test: "suitable conditions")
INIT_TEST = {
    "heartbreak": [{"e": "bond", "a": "@mert", "b": "@ceren", "kind": "romance", "v": True}],
    "alliance_intel": [{"e": "bond", "a": "@deniz", "b": "@zeynep", "kind": "alliance", "v": True}],
    "start_breakup": [{"e": "bond", "a": "@mert", "b": "@ceren", "kind": "romance", "v": True}, {"e": "stress", "who": "@mert", "d": 25}],
    "start_ghost_hunt": [{"e": "flag", "key": "ghost_belief", "v": 2, "day": False}],
    "start_lunch_mystery": [{"e": "npcflag", "who": "@burak", "key": "lunch_victim", "v": True}],
}
for k, v in INIT_TEST.items():
    by_id[k]["test"] = {"setup": v}
for k, v in OLD_DOMAINS.items():
    if k in by_id and "domain" not in by_id[k]:
        by_id[k]["domain"] = v
for tier, ids in TIERS.items():
    for i in ids:
        if i in by_id and "tier" not in by_id[i]:
            by_id[i]["tier"] = tier
for i, kv in TWEAKS.items():
    by_id[i].update(kv)

errors = []
warnings = []
STRICT = "--strict" in sys.argv
ids = {e["id"] for e in E}
dup = [e["id"] for e in E if sum(1 for x in E if x["id"] == e["id"]) > 1]
if dup: errors.append("duplicate event ids: %s" % sorted(set(dup)))
arc_ids = {a["id"] for a in A}

EFFECTS = {"say", "emote", "expr", "rel", "mood", "stress", "mem", "learn", "reveal", "log", "stat", "hold", "intent", "cancel", "chain", "witness",
           "each", "rumor", "favor", "obj", "item_home", "meet", "goal", "flag", "npcflag", "sfx", "fx", "ghost", "work", "act", "call", "set", "pick",
           "debunk", "forget", "distort", "bond", "plan", "morale", "arc_start", "arc_next", "arc_end", "meetup", "away", "trigger",
           "trap", "untrap", "oset", "pin", "unpin", "meeting", "npcval", "item_to", "hunt", "spotfx"}
CONDS = {"trait", "rel", "affinity", "mood", "stress", "knows", "fact_exists", "is", "same", "present", "available", "near", "time", "chance", "goal",
         "mem", "memval", "day", "office", "flag", "dayflag", "npcflag", "activity", "stat", "var", "zone", "meeting", "work_left", "discomfort",
         "ghost", "rolefilled", "promoted", "any", "all", "sure", "picks", "truth", "bond", "plan", "morale", "arc", "in_story", "fired", "result", "can_arc",
         "ostate", "iv", "trap", "in_meeting", "pins", "attends"}
known_ph = {"actor","target","to","me","obj","item","suspect","owner","gossip","topic","helper","credited","victim","winner","loser","subject",
            "defender","requester","listener","spotter","joker","crush","honest","fact","intended","time","old_time","new_time","temp","loc","g1","g2",
            "a","b","other","name","day","n","v","state","doing","age","rumor","what","owner2","friend","snoop","fixpath","choice","sender","doc","origin","pairkind",
            "total","pct","ends","arcs","text"}
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
    if e.get("trigger") == "initiative" and e.get("domain") not in DOMAINS:
        errors.append("%s: initiative without a valid domain (%s)" % (e["id"], e.get("domain")))
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
    for ck in a.get("test", {}):
        known_ph.add(ck)   # the cast an arc is started with
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

# names introduced by interventions (their pickers and roles filled at apply time)
def _iv_names(effs):
    for f in effs:
        if f.get("e") == "call" and f.get("fn") == "pick_role":
            known_ph.add(f["role"])
        if f.get("e") == "set":
            known_ph.add(f["key"])
for d in IV:
    for v in d.get("vars", []):
        known_ph.add(v["name"])
    _iv_names(d.get("state", []) + d.get("react", []))

# placeholders sanity: every {x} in dialogue must be a known role/var name
for src, dd in (("dialogue", {k: sum(v.values(), []) for k, v in D.items()}), ("lang", {k: (v if isinstance(v, list) else [v]) for k, v in S.items()})):
    for k, lines in dd.items():
        for l in lines:
            for ph in re.findall(r"\{(\w+)\}", l):
                if ph not in known_ph: errors.append("%s %s: unknown placeholder {%s}" % (src, k, ph))

# ---------------------------------------------------------------- interventions
OBJECTS = {"ws", "item", "coffee_machine", "printer", "meeting_board", "ac", "lights", "promo_file", "fridge", "water_cooler", "kitchen_table",
           "microwave", "file_cabinet", "supply_shelf", "server_box", "meeting_table", "hr_cabinet", "sofa", "coat_rack", "plant", "front_door",
           "noticeboard", "wall_clock", "speaker", "alarm_panel"}
WS_TABS = {"pc", "mail", "phone", "papers"}
REACT_EFFECTS = {"trap", "chain", "intent", "meetup", "hunt", "call", "trigger", "arc_start", "away"}

def refs_of(effs):
    """Event ids an effect list can lead to."""
    out = []
    for f in effs:
        k = f.get("e")
        if k in ("trap", "chain", "intent", "meetup", "hunt") and f.get("event"):
            out.append(f["event"])
        elif k == "call" and f.get("fn") == "summon" and f.get("event"):
            out.append(f["event"])
        for sub in f.get("effects", []):
            out += refs_of([sub])
        if k == "pick":
            for opt in f["of"]: out += refs_of(opt)
    return out

def event_refs(eid):
    e = by_id.get(eid)
    if not e: return []
    effs = list(e.get("effects", []))
    for o in e.get("outcomes", []): effs += o.get("effects", [])
    return refs_of(effs)

def visible(eid):
    """A reaction event must show something: speech, a log line, an emote or a walk."""
    e = by_id.get(eid, {})
    effs = list(e.get("effects", []))
    for o in e.get("outcomes", []): effs += o.get("effects", [])
    return any(f.get("e") in ("say", "log", "emote", "expr", "intent", "meetup", "hunt", "act", "away", "chain") for f in effs)

iv_ids, iv_keys = set(), set()
iv_cat_count = {}
for d in IV:
    tag = "iv %s" % d["id"]
    if d["id"] in iv_ids: errors.append(tag + ": duplicate id")
    if d["key"] in iv_keys: errors.append(tag + ": duplicate key " + d["key"])
    iv_ids.add(d["id"]); iv_keys.add(d["key"])
    iv_cat_count[d["cat"]] = iv_cat_count.get(d["cat"], 0) + 1
    if not d["id"].startswith(d["cat"]): errors.append(tag + ": id does not match category " + d["cat"])
    if d["obj"] not in OBJECTS: errors.append(tag + ": unknown object " + d["obj"])
    if d["obj"] == "ws" and d.get("tab") not in WS_TABS: errors.append(tag + ": desk interventions need a tab")
    if d.get("needs") == "choice" and not d.get("choices"): errors.append(tag + ": choice without choices")
    if d.get("needs") not in (None, "", "person", "choice", "time"): errors.append(tag + ": bad needs " + str(d.get("needs")))
    walk_conds(d.get("conds", []), tag)
    walk_conds(d.get("pick", []), tag)
    for c in d.get("conds", []):
        if c.get("why") and c["why"] not in S: errors.append(tag + ": missing reason text " + c["why"])
    if d.get("legacy"):
        continue
    for k in (d["name"], d["name"] + ".d"):
        if k not in S: errors.append(tag + ": missing text " + k)
    if not d.get("log"): errors.append(tag + ": no log line")
    if not d.get("state"): errors.append(tag + ": no state change")
    walk_effects(d.get("state", []), tag)
    walk_effects(d.get("react", []), tag)
    reacts = refs_of(d.get("state", []) + d.get("react", []))
    # reactions driven by a simulation trigger the state change causes (e.g. meeting_door_locked)
    reacts += [x for x in d.get("watch", []) if x in by_id and by_id[x].get("trigger")]
    if not reacts: errors.append(tag + ": no reaction (trap/chain/visit...)")
    for r in reacts:
        if r not in ids: errors.append(tag + ": reaction event %s does not exist" % r)
        elif not visible(r): errors.append(tag + ": reaction event %s shows nothing" % r)
    # what the journal should count as this intervention's outcomes
    seen, todo = set(), list(reacts)
    while todo:
        x = todo.pop()
        if x in seen or x not in ids: continue
        seen.add(x)
        todo += event_refs(x)
    d["watch"] = sorted(set(d.get("watch", [])) | seen)
    for wid in d["watch"]:
        if wid not in ids: errors.append(tag + ": watch unknown event " + wid)
    if d.get("arc") and d["arc"] not in arc_ids: errors.append(tag + ": starts unknown arc " + d["arc"])
    if d.get("hidden"):
        if not d.get("combo"): errors.append(tag + ": hidden combination without ingredients")
        for cid in d.get("combo", []):
            if not any(x["id"] == cid for x in IV): errors.append(tag + ": combo ingredient %s unknown" % cid)
            if not any(c.get("c") == "iv" and c.get("id") == cid for c in d.get("conds", [])):
                errors.append(tag + ": combo ingredient %s is not checked in conds" % cid)
for cat in "ABCDEFGHIJ":
    n = iv_cat_count.get(cat, 0)
    if n < 20:
        (errors if STRICT else warnings).append("category %s has %d/20 interventions" % (cat, n))

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
from iv_helpers import CATS
dump("interventions.json", {"cats": CATS, "list": IV})
lines = sum(len(x) for v in D.values() for x in v.values())
init = [e for e in E if e.get("trigger") == "initiative"]
for wmsg in warnings:
    print("WARNING: " + wmsg)
print("Interventions: %d (%s)" % (len(IV), ", ".join("%s=%d" % (k, iv_cat_count.get(k, 0)) for k in "ABCDEFGHIJ")))
# what the interventions' consequences touch (state + reaction scenes they can lead to)
def _kinds(effs, acc):
    for f in effs:
        acc.add(f.get("e"))
        if f.get("e") == "log" and int(f.get("imp", 1)) >= 2:
            acc.add("log2")
        _kinds(f.get("effects", []), acc)
        if f.get("e") == "pick":
            for opt in f["of"]: _kinds(opt, acc)
touch = {"mem": 0, "rel": 0, "know": 0, "visible": 0}
for d in IV:
    if d.get("legacy"):
        continue
    acc = set()
    _kinds(d.get("state", []) + d.get("react", []), acc)
    for wid in d.get("watch", []):
        ev_ = by_id.get(wid, {})
        _kinds(ev_.get("effects", []), acc)
        for o in ev_.get("outcomes", []): _kinds(o.get("effects", []), acc)
    if "mem" in acc or "log2" in acc: touch["mem"] += 1
    if acc & {"rel", "bond", "favor"}: touch["rel"] += 1
    if acc & {"learn", "rumor", "reveal", "witness"}: touch["know"] += 1
    if acc & {"say", "emote", "expr", "log"}: touch["visible"] += 1
n_new = sum(1 for d in IV if not d.get("legacy"))
print("Data-driven interventions: %d — consequences leave memories %d, change relationships %d, spread knowledge/rumours %d, visible reactions %d" % (
    n_new, touch["mem"], touch["rel"], touch["know"], touch["visible"]))
dom = {}
for e in init:
    dom[e["domain"]] = dom.get(e["domain"], 0) + 1
print("NPC actions (initiatives): %d (%s)" % (len(init), ", ".join("%s=%d" % (k, dom.get(k, 0)) for k in DOMAINS)))
print("Story arcs: %d, stages %d, longest path %d" % (len(A), sum(len(a["stages"]) for a in A), max(len(a["stages"]) for a in A)))
print("OK: %d characters, %d facts, %d events (%d initiative), %d arcs (%d stages), %d rumour kinds, %d dialogue keys (%d lines), %d strings" % (
    len(CHARACTERS), len(FACTS), len(E), len(init), len(A), sum(len(a["stages"]) for a in A), len(RUMORS), len(D), lines, len(S)))
