# Event definitions -> data/events.json
# Authored in Python for comments & helpers; the game only reads the JSON.
#
# An event = trigger + filter + conditions + roles + vars + (effects | outcomes).
# Outcomes are scored from personality/relationships/memory, so the same trigger
# plays out differently depending on who is involved and what happened before.

# ---------------------------------------------------------------- effect helpers
def say(who, line, to=None, delay=0, p=None, when=None):
    d = {"e": "say", "who": who, "line": line}
    if to: d["to"] = to
    if delay: d["delay"] = delay
    if p is not None: d["p"] = p
    if when: d["when"] = when
    return d

def emote(who, v, delay=0, when=None):
    d = {"e": "emote", "who": who, "v": v}
    if delay: d["delay"] = delay
    if when: d["when"] = when
    return d

def expr(who, v, secs=5, delay=0):
    d = {"e": "expr", "who": who, "v": v, "secs": secs}
    if delay: d["delay"] = delay
    return d

def rel(a, b, stat, d, both=False, k=1.0, when=None):
    r = {"e": "rel", "a": a, "b": b, "stat": stat, "d": d}
    if both:
        r["both"] = True
        if k != 1.0: r["both_k"] = k
    if when: r["when"] = when
    return r

def mood(who, d, when=None):
    r = {"e": "mood", "who": who, "d": d}
    if when: r["when"] = when
    return r

def stress(who, d, when=None):
    r = {"e": "stress", "who": who, "d": d}
    if when: r["when"] = when
    return r

def mem(who, about, kind, val, w=0.7, text="", imp=1, when=None):
    r = {"e": "mem", "who": who, "about": about, "kind": kind, "val": val, "w": w, "text": text, "imp": imp}
    if when: r["when"] = when
    return r

def log(text, imp=2, cat="misc", who="actor", delay=0, when=None):
    r = {"e": "log", "text": text, "imp": imp, "cat": cat, "who": who}
    if delay: r["delay"] = delay
    if when: r["when"] = when
    return r

def stat(key, n=1, a="actor", b="target", when=None):
    r = {"e": "stat", "key": key, "n": n, "a": a, "b": b}
    if when: r["when"] = when
    return r

def hold(who, dur):
    return {"e": "hold", "who": who, "dur": dur}

def intent(who, type_, target="", event="", prio=60, ttl=90, place="", obj="", roles=None, delay=0, when=None, dur=None):
    r = {"e": "intent", "who": who, "type": type_, "prio": prio, "ttl": ttl}
    if target: r["target"] = target
    if event: r["event"] = event
    if place: r["place"] = place
    if obj: r["obj"] = obj
    if roles: r["roles"] = roles
    if delay: r["delay"] = delay
    if when: r["when"] = when
    if dur is not None: r["dur"] = dur
    return r

def chain(event, delay=0, roles=None, when=None):
    r = {"e": "chain", "event": event}
    if roles: r["roles"] = roles
    if delay: r["delay"] = delay
    if when: r["when"] = when
    return r

def witness(effects, near="actor", r=4.5, exclude=None, mx=8):
    return {"e": "witness", "near": near, "r": r, "exclude": exclude or ["actor", "target"], "effects": effects, "max": mx}

def each(effects, exclude=None, stagger=0.0, where=None):
    r = {"e": "each", "effects": effects, "exclude": exclude or [], "stagger": stagger}
    if where: r["where"] = where
    return r

def learn(who, fact, frm="", c=None, when=None, delay=0):
    r = {"e": "learn", "who": who, "fact": fact}
    if frm: r["from"] = frm
    if c is not None: r["c"] = c
    if when: r["when"] = when
    if delay: r["delay"] = delay
    return r

def reveal(fact):
    return {"e": "reveal", "fact": fact}

def rumor(kind, a="actor", b="target", juicy=0.5, knowers=None, truth=True, origin="actor", key="rumor", c=None, when=None):
    r = {"e": "rumor", "kind": kind, "a": a, "b": b, "juicy": juicy, "knowers": knowers or []}
    if not truth: r["truth"] = False
    if origin != "actor": r["origin"] = origin
    if key != "rumor": r["key"] = key
    if c is not None: r["c"] = c
    if when: r["when"] = when
    return r

def call(fn, delay=0, when=None, **kw):
    r = {"e": "call", "fn": fn}
    r.update(kw)
    if delay: r["delay"] = delay
    if when: r["when"] = when
    return r

def favor(about, d, when=None):
    r = {"e": "favor", "about": about, "d": d}
    if when: r["when"] = when
    return r

def fx(v, who="actor", delay=0):
    r = {"e": "fx", "v": v, "who": who}
    if delay: r["delay"] = delay
    return r

def sfx(id_, delay=0):
    r = {"e": "sfx", "id": id_}
    if delay: r["delay"] = delay
    return r

def ghost(d=1):
    return {"e": "ghost", "d": d}

def flag(key, v=True, day=False):
    return {"e": "flag", "key": key, "v": v, "day": day}

def npcflag(who, key, v=True):
    return {"e": "npcflag", "who": who, "key": key, "v": v}

def work(who, d):
    return {"e": "work", "who": who, "d": d}

def meet(who, v="board"):
    return {"e": "meet", "who": who, "v": v}

def cancel(who, type_=""):
    return {"e": "cancel", "who": who, "type": type_}

def pick(*options):
    return {"e": "pick", "of": list(options)}

def obj(o, key, v):
    return {"e": "obj", "obj": o, "key": key, "v": v}

def goal(who, v):
    return {"e": "goal", "who": who, "v": v}

# ---------------------------------------------------------------- condition helpers
def c_trait(who, t, gt=None, lt=None):
    c = {"c": "trait", "who": who, "t": t}
    if gt is not None: c["gt"] = gt
    if lt is not None: c["lt"] = lt
    return c

def c_rel(a, b, stat, gt=None, lt=None):
    c = {"c": "rel", "a": a, "b": b, "stat": stat}
    if gt is not None: c["gt"] = gt
    if lt is not None: c["lt"] = lt
    return c

def c_aff(a, b, gt=None, lt=None):
    c = {"c": "affinity", "a": a, "b": b}
    if gt is not None: c["gt"] = gt
    if lt is not None: c["lt"] = lt
    return c

def c_is(who, id_=None, in_=None, neg=False):
    c = {"c": "is", "who": who}
    if in_ is not None: c["in"] = in_
    else: c["id"] = id_
    if neg: c["not"] = True
    return c

def c_not(cond):
    d = dict(cond); d["not"] = True
    return d

def c_chance(p):
    return {"c": "chance", "p": p}

def c_avail(who):
    return {"c": "available", "who": who}

def c_present(who):
    return {"c": "present", "who": who}

def c_near(a, b, lt):
    return {"c": "near", "a": a, "b": b, "lt": lt}

def c_var(key, eq=None, in_=None, gt=None, lt=None):
    c = {"c": "var", "key": key}
    if eq is not None: c["eq"] = eq
    if in_ is not None: c["in"] = in_
    if gt is not None: c["gt"] = gt
    if lt is not None: c["lt"] = lt
    return c

def c_office(key, eq):
    return {"c": "office", "key": key, "eq": eq}

def c_goal(who, g=None, in_=None):
    c = {"c": "goal", "who": who}
    if in_ is not None: c["in"] = in_
    else: c["goal"] = g
    return c

def c_mem(who, kind, about=None, days=99):
    c = {"c": "mem", "who": who, "kind": kind, "days": days}
    if about: c["about"] = about
    return c

def c_stress(who, gt=None, lt=None):
    c = {"c": "stress", "who": who}
    if gt is not None: c["gt"] = gt
    if lt is not None: c["lt"] = lt
    return c

def c_mood(who, gt=None, lt=None):
    c = {"c": "mood", "who": who}
    if gt is not None: c["gt"] = gt
    if lt is not None: c["lt"] = lt
    return c

def c_knows(who, fact, neg=False):
    c = {"c": "knows", "who": who, "fact": fact}
    if neg: c["not"] = True
    return c

def c_filled(who):
    return {"c": "rolefilled", "who": who}

def c_act(who, in_):
    return {"c": "activity", "who": who, "in": in_}

def c_any(*conds):
    return {"c": "any", "of": list(conds)}

def c_flag(key, eq=None, neg=False):
    c = {"c": "flag", "key": key}
    if eq is not None: c["eq"] = eq
    if neg: c["not"] = True
    return c

def c_dayflag(key, neg=False):
    c = {"c": "dayflag", "key": key}
    if neg: c["not"] = True
    return c

def c_npcflag(who, key, neg=False):
    c = {"c": "npcflag", "who": who, "key": key}
    if neg: c["not"] = True
    return c

def c_time(after=None, before=None):
    c = {"c": "time"}
    if after: c["after"] = after
    if before: c["before"] = before
    return c

def c_stat(key, gte):
    return {"c": "stat", "key": key, "gte": gte}

def c_disc(who, gt):
    return {"c": "discomfort", "who": who, "gt": gt}

# ---------------------------------------------------------------- score helpers
def s_trait(who, t, w=1.0): return {"s": "trait", "who": who, "t": t, "w": w}
def s_rel(a, b, stat, w): return {"s": "rel", "a": a, "b": b, "stat": stat, "w": w}
def s_aff(a, b, w): return {"s": "affinity", "a": a, "b": b, "w": w}
def s_is(who, id_=None, v=1.0, in_=None):
    d = {"s": "is", "who": who, "v": v}
    if in_ is not None: d["in"] = in_
    else: d["id"] = id_
    return d
def s_stress(who, w): return {"s": "stress", "who": who, "w": w}
def s_mood(who, w): return {"s": "mood", "who": who, "w": w}
def s_mem(who, about, w): return {"s": "mem", "who": who, "about": about, "w": w}
def s_const(v): return {"s": "const", "v": v}
def s_rand(v): return {"s": "rand", "v": v}
def s_dist(a, b, w): return {"s": "dist", "a": a, "b": b, "w": w}
def s_goal(who, g, v): return {"s": "goal", "who": who, "goal": g, "v": v}
def s_if(cond, v, else_=0.0): return {"s": "if", "cond": cond, "v": v, "else": else_}
def s_disc(who, w): return {"s": "discomfort", "who": who, "w": w}

def role(name, where=None, score=None, exclude=None, optional=False, near=None, r=5.0, avail=True, pick_="best", pool="present", fn=None, **kw):
    d = {"name": name, "where": where or [], "score": score or [], "exclude": exclude if exclude is not None else ["actor", "target"],
         "optional": optional, "available": avail, "pick": pick_, "pool": pool}
    if near: d["near"] = near; d["r"] = r
    if fn: d["fn"] = fn
    d.update(kw)
    return d

def var(name, fn, optional=False, **kw):
    d = {"name": name, "fn": fn, "optional": optional}
    d.update(kw)
    return d

def out(id_, effects, score=None, when=None):
    return {"id": id_, "effects": effects, "score": score or [s_const(0.0)], "when": when or []}

E = []
def ev(**kw):
    E.append(kw)


# =====================================================================
# MALFUNCTIONS: printer & coffee
# =====================================================================
HELPER_ROLE = role("helper", where=[c_avail("self")],
                   score=[s_is("self", "burak", 2.4), s_aff("actor", "self", 0.02), s_dist("actor", "self", -0.07),
                          s_trait("self", "empathy", 0.5)], exclude=["actor"], optional=True)

ev(id="printer_broken", trigger="object_failed", filter={"obj": "printer"}, priority=70, scope="actor", cooldown=20,
   roles=[HELPER_ROLE],
   effects=[expr("actor", "surprised", 3), emote("actor", "exclaim"), say("actor", "printer_dead"), stress("actor", 8),
            mem("actor", "", "printer_broken", -0.2, 0.5), sfx("printer_fail"),
            log("log.printer_broken", 2, "malfunction")],
   outcomes=[
       out("self_fix", [say("actor", "printer_selffix", delay=1.2), call("fix_intent", obj="printer", requester="actor", prio=66)],
           score=[s_const(5)], when=[c_is("actor", "burak")]),
       out("ask_help", [say("actor", "printer_need_help", delay=1.2),
                        intent("actor", "go_npc", target="helper", event="help_request", prio=66, ttl=60, roles={"requester": "actor"})],
           score=[s_const(1.0), s_trait("actor", "sociability", 0.6), s_if(c_is("helper", "burak"), 0.4)],
           when=[c_present("helper")]),
       out("kick", [say("actor", "printer_kick", delay=1.0), emote("actor", "anger", delay=1.0), sfx("thump", delay=1.0),
                    fx("shake", "actor", delay=1.0), stress("actor", 5), call("give_up_printing"),
                    witness([say("self", "witness_kick", p=0.5, delay=2.0)], r=5),
                    log("log.printer_kicked", 2, "malfunction", delay=1.0)],
           score=[s_trait("actor", "temper", 1.3), s_stress("actor", 0.01)], when=[c_trait("actor", "temper", gt=0.45)]),
       out("give_up", [say("actor", "printer_giveup", delay=1.4), call("give_up_printing"), mood("actor", -5)],
           score=[s_const(0.3), s_trait("actor", "diligence", -0.3)]),
   ])

ev(id="help_request", trigger="", priority=80,
   conditions=[c_avail("target")],
   effects=[hold(["actor", "target"], 4.5), say("actor", "ask_help_obj", to="target")],
   outcomes=[
       out("helps", [say("target", "agree_help", delay=1.5), emote("target", "ok", delay=1.5),
                     rel("actor", "target", "friendship", 6), rel("actor", "target", "trust", 5),
                     rel("target", "actor", "friendship", 3),
                     mem("actor", "target", "helped_me", 0.6, 0.8, "mem.helped_me", 2),
                     mem("target", "actor", "i_helped", 0.3, 0.5),
                     stat("helps"), call("fix_intent", who="target", obj="$obj", requester="actor", prio=68, delay=1.6),
                     log("log.help_agreed", 2, "help")],
           score=[s_aff("target", "actor", 0.025), s_trait("target", "empathy", 1.2), s_is("target", "burak", 0.5),
                  s_stress("target", -0.012), s_mem("target", "actor", 0.8), s_const(0.4)]),
       out("refuses", [say("target", "refuse_help", delay=1.5), say("actor", "react_refused", delay=3.0),
                       expr("actor", "angry", 5, delay=3.0), emote("actor", "anger", delay=3.0),
                       rel("actor", "target", "friendship", -10), rel("actor", "target", "trust", -8),
                       mem("actor", "target", "refused_help", -0.7, 0.9, "mem.refused_help", 3),
                       stat("refusals"), rumor("refused_help", a="target", b="actor", juicy=0.45, knowers=["actor"]),
                       witness([learn("self", "$rumor")], r=4.5),
                       call("give_up_printing"),
                       log("log.help_refused", 3, "conflict")],
           score=[s_rel("target", "actor", "rivalry", 0.02), s_stress("target", 0.015), s_trait("target", "empathy", -0.9),
                  s_aff("target", "actor", -0.015), s_mem("target", "actor", -0.9),
                  s_if(c_goal("target", "find_new_job"), 0.3), s_const(0.45)]),
       out("later", [say("target", "help_later", delay=1.5), say("actor", "fine_wait", delay=3.0),
                     call("fix_intent", who="target", obj="$obj", requester="actor", prio=55, delay=12),
                     log("log.help_later", 1, "help")],
           score=[s_const(0.25), s_trait("target", "diligence", 0.35)]),
   ])

ev(id="lights_restored", trigger="fix_done", filter={"obj": "lights"}, priority=75,
   effects=[say("actor", "lights_fixed_me"), stat("helps"),
            each([say("self", "lights_back", p=0.45), rel("self", "actor", "friendship", 3)], exclude=["actor"], stagger=0.35),
            log("log.lights_fixed", 2, "help")])

ev(id="fix_done", trigger="fix_done", priority=60,
   outcomes=[
       out("thanked", [say("actor", "fixed_it", to="requester"), say("requester", "thanks_fix", to="actor", delay=1.5),
                       rel("requester", "actor", "friendship", 8), rel("requester", "actor", "trust", 4),
                       log("log.fixed_for", 2, "help")],
           score=[s_const(2)], when=[c_present("requester"), c_near("actor", "requester", 6.0), c_is("requester", "", neg=True)]),
       out("solo", [say("actor", "fixed_solo"), log("log.fixed", 1, "help")], score=[s_const(1)]),
   ])

ev(id="coffee_broken", trigger="object_failed", filter={"obj": "coffee"}, priority=70, scope="actor", cooldown=30,
   roles=[HELPER_ROLE],
   vars=[var("suspect", "suspect", loc="coffee", optional=True)],
   effects=[expr("actor", "surprised", 3), emote("actor", "exclaim"), say("actor", "coffee_dead"), stress("actor", 10),
            mood("actor", -8), mem("actor", "", "coffee_broken", -0.3, 0.5), log("log.coffee_broken", 2, "malfunction")],
   outcomes=[
       out("ece_tries", [say("actor", "ece_try_fix", delay=1.2), hold(["actor"], 4),
                         pick([obj("coffee", "broken", False), say("actor", "ece_fix_success", delay=3.5), sfx("fixed", delay=3.5),
                               witness([rel("self", "actor", "friendship", 5), say("self", "praise_ece", p=0.5, delay=4.5)], r=6),
                               log("log.ece_fixed", 3, "help", delay=3.5)],
                              [say("actor", "ece_fix_fail", delay=3.5), emote("actor", "sweat", delay=3.5), stress("actor", 10),
                               fx("spill", "actor", delay=3.5), sfx("splash", delay=3.5),
                               witness([say("self", "witness_spill", p=0.5, delay=4.5)], r=5), log("log.ece_spill", 2, "malfunction", delay=3.5)],
                              [say("actor", "ece_fix_fail", delay=3.5), emote("actor", "sweat", delay=3.5), stress("actor", 10),
                               fx("spill", "actor", delay=3.5), sfx("splash", delay=3.5), log("log.ece_spill", 2, "malfunction", delay=3.5)])],
           score=[s_const(4)], when=[c_is("actor", "ece")]),
       out("rage", [say("actor", "coffee_rage", delay=1.2), emote("actor", "anger", delay=1.2), sfx("thump", delay=1.2),
                    fx("shake", "actor", delay=1.2), witness([say("self", "witness_coffee_rage", p=0.5, delay=2.5)]),
                    intent("actor", "go_npc", target="helper", event="help_request", prio=55, ttl=60, roles={"requester": "actor"},
                           when=[c_present("helper")])],
           score=[s_trait("actor", "temper", 1.2), s_stress("actor", 0.01)]),
       out("blame", [say("actor", "coffee_blame", delay=1.2), stat("blames"),
                     rumor("blamed", a="$suspect", b="actor", juicy=0.4, knowers=["actor"]),
                     witness([learn("self", "$rumor")]),
                     mem("actor", "$suspect", "suspect_coffee", -0.4, 0.7, "mem.suspect_coffee", 2), rel("actor", "$suspect", "trust", -6),
                     intent("actor", "go_npc", target="$suspect", event="accusation", prio=58, ttl=80),
                     log("log.coffee_blame", 2, "conflict")],
           score=[s_rel("actor", "$suspect", "rivalry", 0.02), s_trait("actor", "forgiveness", -0.6), s_trait("actor", "gossip", 0.3), s_const(0.3)],
           when=[c_filled("$suspect"), c_rel("actor", "$suspect", "trust", lt=25), c_present("$suspect")]),
       out("ask_fix", [say("actor", "coffee_ask_fix", delay=1.2),
                       intent("actor", "go_npc", target="helper", event="help_request", prio=56, ttl=60, roles={"requester": "actor"})],
           score=[s_trait("actor", "empathy", 0.5), s_const(0.35)], when=[c_present("helper")]),
       out("sad", [say("actor", "coffee_sad", delay=1.2), mood("actor", -6), emote("actor", "cloud", delay=1.2)],
           score=[s_trait("actor", "temper", -0.8), s_const(0.3)]),
   ])

ev(id="coffee_ghost", trigger="coffee_ghost", priority=65,
   roles=[role("credited", where=[c_avail("self")], score=[s_is("self", "burak", 1.5), s_aff("actor", "self", 0.01), s_is("self", "ece", 0.5), s_rand(0.8)],
               exclude=["actor"], optional=True)],
   effects=[expr("actor", "surprised", 3), say("actor", "coffee_works_again")],
   outcomes=[
       out("credit", [say("actor", "coffee_who_fixed", delay=1.5),
                      intent("actor", "go_npc", target="credited", event="thank_wrong_person", prio=45, ttl=40, delay=1.5)],
           score=[s_const(1.0), s_trait("actor", "sociability", 0.4)], when=[c_present("credited")]),
       out("spooky", [say("actor", "coffee_spooky", delay=1.5), ghost(), call("ghost_theory"), log("log.coffee_mystery", 2, "ghost")],
           score=[s_trait("actor", "curiosity", 1.0), s_const(0.2)]),
   ])

ev(id="thank_wrong_person", trigger="", priority=70, conditions=[c_avail("target")],
   effects=[hold(["actor", "target"], 4), say("actor", "thanks_coffee_fix", to="target")],
   outcomes=[
       out("takes_credit", [say("target", "take_credit", delay=1.5), rel("actor", "target", "friendship", 8),
                            stat("wrong_rewards"), mem("target", "actor", "took_credit", 0.2, 0.4),
                            log("log.wrong_credit", 3, "reward")],
           score=[s_trait("target", "cunning", 1.0), s_trait("target", "honesty", -1.0), s_const(0.3)]),
       out("honest", [say("target", "not_me", delay=1.5), say("actor", "then_who", delay=3.0), ghost(),
                      rel("actor", "target", "trust", 3), log("log.not_me", 2, "ghost")],
           score=[s_trait("target", "honesty", 1.0), s_const(0.2)]),
   ])

ev(id="it_patrol", trigger="tick", priority=30, cooldown=24, chance=0.65,
   roles=[role("actor", where=[c_is("self", "burak"), c_avail("self")], exclude=[])],
   outcomes=[
       out("fix_printer", [say("actor", "burak_sigh_fix"), call("fix_intent", obj="printer", requester="", prio=50)],
           score=[s_const(1)], when=[c_office("printer.broken", True), c_office("printer.discovered", True), c_office("printer.fixing", "")]),
       out("fix_coffee", [say("actor", "burak_sigh_fix_coffee"), call("fix_intent", obj="coffee", requester="", prio=50)],
           score=[s_const(0.9)], when=[c_office("coffee.broken", True), c_office("coffee.discovered", True), c_office("coffee.fixing", "")]),
   ])

# =====================================================================
# LIGHTS
# =====================================================================
ev(id="lights_off_panic", trigger="lights_off", priority=90,
   roles=[role("fixer", where=[c_avail("self")], score=[s_is("self", "burak", 2.5), s_is("self", "ceren", 1.0), s_is("self", "ahmet", 0.6),
                                                       s_trait("self", "diligence", 0.5), s_rand(0.3)], exclude=[], optional=True)],
   effects=[each([expr("self", "surprised", 4), emote("self", "exclaim"), say("self", "lights_out_react", p=0.6)], stagger=0.3),
            ghost(), log("log.lights_out", 3, "ghost", who="fixer"),
            say("fixer", "lights_will_fix", delay=2.6), call("lights_fixer", who="fixer", delay=2.6),
            chain("ece_spill", delay=1.4, roles={"actor": "@ece"}),
            chain("dark_scheme", delay=2.2, roles={"actor": "@deniz"})])

ev(id="ece_spill", trigger=["encounter"], priority=22, scope="actor", cooldown=200,
   roles=[role("target", where=[c_avail("self")], score=[s_dist("actor", "self", -1.0)], exclude=["actor"], near="actor", r=3.2)],
   conditions=[c_is("actor", "ece"), c_trait("actor", "clumsiness", gt=0.55), c_chance(0.2), c_avail("actor")],
   effects=[hold(["actor", "target"], 3.5), fx("spill", "target"), sfx("splash"), say("actor", "ece_spill_oops", to="target"),
            stress("actor", 10), mood("actor", -6)],
   outcomes=[
       out("forgive", [say("target", "spill_forgive", delay=1.6), rel("target", "actor", "friendship", 4), rel("actor", "target", "friendship", 5),
                       log("log.spill_forgiven", 2, "friendship")],
           score=[s_trait("target", "forgiveness", 1.0), s_aff("target", "actor", 0.015), s_const(0.2)]),
       out("angry", [say("target", "spill_angry", delay=1.6), expr("target", "angry", 5, delay=1.6), rel("target", "actor", "friendship", -8),
                     stress("target", 8), mem("target", "actor", "spilled_on_me", -0.4, 0.6, "mem.spilled", 2),
                     log("log.spill_angry", 2, "conflict")],
           score=[s_trait("target", "temper", 1.0), s_stress("target", 0.01)]),
   ])

ev(id="dark_scheme", trigger="", priority=50,
   conditions=[c_chance(0.55), c_trait("actor", "cunning", gt=0.6), c_avail("actor"), c_present("@selin"),
               c_office("lights.on", False)],
   effects=[say("actor", "dark_scheme_whisper"), call("npc_move_item", item="usb", to="desk_deniz"),
            flag("thief_usb", "deniz"), log("log.dark_scheme", 3, "scheme")])

ev(id="lights_on_ghost", trigger="lights_on_ghost", priority=60,
   effects=[each([emote("self", "question"), say("self", "lights_ghost_on", p=0.45)], stagger=0.3), ghost(),
            call("ghost_theory"), log("log.lights_ghost_on", 2, "ghost", who="")])

ev(id="dark_bonding", trigger="dark_pair", priority=40, scope="pair", cooldown=80, max_day=4,
   conditions=[c_avail("actor"), c_avail("target"), c_aff("actor", "target", gt=-25)],
   effects=[hold(["actor", "target"], 3.5), say("actor", "dark_scared", to="target"), say("target", "dark_comfort", to="actor", delay=1.5),
            rel("actor", "target", "friendship", 8, both=True), mem("actor", "target", "dark_bond", 0.4, 0.6, "mem.dark_bond", 2),
            mem("target", "actor", "dark_bond", 0.4, 0.6, "mem.dark_bond", 2), log("log.dark_bond", 2, "friendship")])

# =====================================================================
# TEMPERATURE
# =====================================================================
ev(id="temp_changed", trigger="temp_changed", priority=60,
   effects=[each([say("self", "too_cold", p=0.55, when=[c_var("temp", lt=21)]), emote("self", "shiver", when=[c_var("temp", lt=21)]),
                  say("self", "too_hot", p=0.55, when=[c_var("temp", gt=23)]), emote("self", "sweat", when=[c_var("temp", gt=23)])],
                 stagger=0.5, where=[c_disc("self", 18)]),
            ghost(), log("log.temp_changed", 2, "ghost", who="")])

ev(id="thermo_complaint", trigger="thermo_discomfort", priority=50, scope="actor", cooldown=60,
   outcomes=[
       out("go_fix", [say("actor", "temp_complain"), call("thermostat_intent", prio=52)],
           score=[s_trait("actor", "temper", 1.0), s_disc("actor", 0.01), s_const(0.2)], when=[c_disc("actor", 28)]),
       out("suffer", [say("actor", "temp_suffer"), stress("actor", 3), emote("actor", "cloud")],
           score=[s_trait("actor", "temper", -0.6), s_const(0.5)]),
   ])

ev(id="thermostat_war", trigger="thermostat_changed", priority=55, cooldown=100,
   roles=[role("target", where=[c_avail("self"), c_disc("self", 22)], score=[s_rel("self", "actor", "rivalry", 0.02), s_trait("self", "temper", 1.0), s_rand(0.3)],
               exclude=["actor"])],
   outcomes=[
       out("argue", [intent("target", "go_npc", target="actor", event="thermo_argument", prio=55, ttl=30)],
           score=[s_trait("target", "temper", 1.2), s_rel("target", "actor", "rivalry", 0.02)], when=[c_trait("target", "temper", gt=0.35)]),
       out("grumble", [say("target", "thermo_grumble"), mem("target", "actor", "thermostat", -0.3, 0.5), log("log.thermo_grumble", 1, "conflict", who="target")],
           score=[s_const(0.5)]),
   ])

ev(id="thermo_argument", trigger="", priority=70, conditions=[c_avail("target")],
   effects=[hold(["actor", "target"], 5), say("actor", "thermo_argue_1", to="target"), say("target", "thermo_argue_2", to="actor", delay=1.5),
            say("actor", "thermo_argue_3", to="target", delay=3.0),
            rel("actor", "target", "friendship", -6, both=True), rel("actor", "target", "rivalry", 5, both=True), stat("arguments"),
            rumor("argument", juicy=0.4, knowers=["actor", "target"]), witness([learn("self", "$rumor")]),
            sfx("argue", delay=1.5), log("log.thermo_war", 3, "conflict"), dict(call("thermostat_intent", prio=56, delay=4), p=0.35)])

# =====================================================================
# DESK FILES / ACCUSATIONS
# =====================================================================
ev(id="desk_messed", trigger="desk_messed", priority=75,
   vars=[var("suspect", "suspect", desk=True, optional=True)],
   effects=[expr("actor", "angry", 5), emote("actor", "exclaim"), stress("actor", 12), mood("actor", -10), work("actor", -8),
            mem("actor", "", "desk_ransacked", -0.3, 0.6, "mem.desk_messed", 2), stat("pranks_found"), sfx("papers"),
            log("log.files_messed", 2, "prank")],
   outcomes=[
       out("spooky", [say("actor", "files_flew"), emote("actor", "question", delay=1.0), ghost(), call("ghost_theory"),
                      witness([emote("self", "exclaim"), say("self", "witness_ghost", p=0.6, delay=1.5)], r=6),
                      log("log.files_flew", 3, "ghost")],
           score=[s_const(9)], when=[c_var("live", eq=True)]),
       out("confront", [say("actor", "who_did_this"), say("actor", "suspect_named", delay=1.4),
                        mem("actor", "$suspect", "suspect_files", -0.6, 0.8, "mem.suspects_files", 2),
                        rel("actor", "$suspect", "trust", -10), stat("blames"),
                        intent("actor", "go_npc", target="$suspect", event="accusation", prio=64, ttl=80),
                        log("log.suspects", 2, "conflict")],
           score=[s_trait("actor", "temper", 1.0), s_rel("actor", "$suspect", "rivalry", 0.02), s_trait("actor", "forgiveness", -0.3)],
           when=[c_filled("$suspect"), c_present("$suspect"), c_any(c_trait("actor", "temper", gt=0.45), c_rel("actor", "$suspect", "rivalry", gt=30))]),
       out("ask_around", [say("actor", "who_did_this"), witness([say("self", "dont_look_at_me", p=0.6, delay=1.6)], r=5),
                          rumor("blamed", a="$suspect", b="actor", juicy=0.35, knowers=["actor"]),
                          chain("zeynep_knows", delay=2.5, roles={"actor": "@zeynep", "target": "actor"})],
           score=[s_trait("actor", "sociability", 0.8), s_trait("actor", "gossip", 0.4)]),
       out("quiet", [say("actor", "tidy_sigh"), mem("actor", "$suspect", "suspect_files", -0.3, 0.6, "mem.quiet_grudge", 2,
                                                   when=[c_filled("$suspect")]),
                     log("log.quiet_grudge", 2, "conflict", when=[c_filled("$suspect")])],
           score=[s_trait("actor", "temper", -1.0), s_trait("actor", "diligence", 0.3), s_const(0.5)]),
       out("ece_helps", [say("actor", "who_did_this"), chain("ece_tidy_help", delay=1.6, roles={"actor": "@ece", "target": "actor"})],
           score=[s_const(0.9), s_rand(0.6)], when=[c_is("actor", "ece", neg=True), c_avail("@ece"), c_near("actor", "@ece", 7)]),
   ])

ev(id="ece_tidy_help", trigger="", priority=60, conditions=[c_avail("actor"), c_avail("target")],
   effects=[intent("actor", "go_npc", target="target", event="ece_tidy_scene", prio=58, ttl=30)])

ev(id="ece_tidy_scene", trigger="", priority=70, conditions=[c_avail("target")],
   effects=[hold(["actor", "target"], 4), say("actor", "ece_offer_tidy", to="target"), say("target", "ece_tidy_thanks", to="actor", delay=1.6),
            rel("target", "actor", "friendship", 10), rel("target", "actor", "trust", 6), work("target", 6),
            mem("target", "actor", "helped_me", 0.6, 0.7, "mem.ece_tidied", 2), stat("helps"), log("log.ece_tidy", 2, "solidarity")])

ev(id="zeynep_knows", trigger="", priority=55,
   vars=[var("suspect", "suspect", of="target", desk=True)],
   conditions=[c_avail("actor"), c_avail("target"), c_near("actor", "target", 8), c_is("target", "zeynep", neg=True)],
   effects=[hold(["actor", "target"], 4.5), say("actor", "i_think_i_know", to="target"), say("target", "who_was_it", to="actor", delay=1.4),
            say("actor", "zeynep_accuse", to="target", delay=2.8), rel("target", "$suspect", "trust", -8),
            mem("target", "$suspect", "zeynep_said", -0.4, 0.6, "mem.zeynep_pointed", 2),
            rumor("blamed", a="$suspect", b="target", juicy=0.45, knowers=["actor", "target"]), stat("rumors"),
            log("log.zeynep_points", 3, "rumor")])

ev(id="accusation", trigger="", priority=85, conditions=[c_avail("target")],
   effects=[hold(["actor", "target"], 5.5),
            say("actor", "accuse_files", to="target", when=[c_var("incident", in_=["", "files"])]),
            say("actor", "accuse_coffee", to="target", when=[c_var("incident", eq="coffee")]),
            say("actor", "accuse_item", to="target", when=[c_var("incident", eq="item")]),
            say("actor", "accuse_promo", to="target", when=[c_var("incident", eq="promo")]),
            say("actor", "accuse_lunch", to="target", when=[c_var("incident", eq="lunch")]),
            chain("defense", delay=1.2)],
   outcomes=[
       out("guilty_deny", [say("target", "smooth_deny", delay=1.5), say("actor", "not_convinced", delay=3.0),
                           rel("actor", "target", "trust", -12), rel("actor", "target", "rivalry", 8),
                           log("log.guilty_denies", 3, "scheme")],
           score=[s_const(9)], when=[c_is("target", "deniz"), c_var("item", eq="usb"), c_flag("thief_usb", eq="deniz")]),
       out("angry_denial", [say("target", "deny_angry", to="actor", delay=1.4), say("actor", "insist", to="target", delay=2.8),
                            say("target", "deny_angry2", to="actor", delay=4.2), expr("actor", "angry", 6), expr("target", "angry", 6, delay=1.4),
                            emote("target", "anger", delay=1.4), emote("actor", "anger", delay=2.8),
                            rel("actor", "target", "friendship", -14, both=True), rel("actor", "target", "trust", -10, both=True),
                            rel("actor", "target", "rivalry", 10, both=True), stress("actor", 10), stress("target", 12),
                            stat("arguments"), mem("target", "actor", "falsely_accused", -0.8, 0.9, "mem.falsely_accused", 3),
                            mem("actor", "target", "argued", -0.5, 0.7, "mem.argued", 2),
                            rumor("argument", juicy=0.55, knowers=["actor", "target"]),
                            witness([learn("self", "$rumor"), say("self", "witness_argument", p=0.35, delay=3.0)], r=5.5),
                            sfx("argue", delay=1.4), fx("anger", "target", delay=1.4), log("log.argument", 3, "conflict")],
           score=[s_trait("target", "temper", 1.4), s_rel("target", "actor", "rivalry", 0.02), s_aff("target", "actor", -0.01),
                  s_is("target", "burak", 0.6), s_stress("target", 0.006)]),
       out("calm_denial", [say("target", "deny_calm", to="actor", delay=1.4), say("actor", "sorry_accuse", to="target", delay=2.9),
                           rel("actor", "target", "trust", 4), rel("target", "actor", "trust", -4),
                           mem("target", "actor", "accused_me", -0.3, 0.6, "mem.accused_me", 2), log("log.accuse_calm", 2, "conflict")],
           score=[s_trait("target", "empathy", 1.0), s_rel("actor", "target", "trust", 0.02), s_trait("actor", "forgiveness", 0.5)]),
       out("take_blame", [say("target", "take_blame", to="actor", delay=1.5), say("actor", "accept_apology", to="target", delay=3.0),
                          rel("actor", "target", "trust", -3), rel("actor", "target", "friendship", 4), mood("target", -8), stress("target", 6),
                          mem("target", "actor", "took_blame", -0.1, 0.5, "mem.took_blame", 3), stat("took_blame"),
                          rumor("took_blame", a="target", b="actor", juicy=0.5, knowers=["actor", "target"]),
                          witness([learn("self", "$rumor")]), log("log.took_blame", 3, "drama")],
           score=[s_is("target", "ece", 0.8), s_trait("target", "empathy", 0.6), s_trait("target", "temper", -1.0), s_goal("target", "be_liked", 0.5)],
           when=[c_any(c_is("target", "ece"), c_trait("target", "empathy", gt=0.7))]),
   ])

ev(id="defense", trigger="", priority=70, allow_absent=True,
   roles=[role("defender", where=[c_avail("self"), {"c": "any", "of": [c_rel("self", "target", "friendship", gt=26), {"c": "bond", "a": "self", "b": "target", "kind": "alliance"}]}],
               score=[s_aff("self", "target", 0.02), s_trait("self", "empathy", 0.5), s_trait("self", "temper", 0.2), s_aff("self", "actor", -0.01),
                      {"s": "bond", "a": "self", "b": "target", "kind": "alliance", "v": 1.5}],
               near="target", r=5.5)],
   conditions=[c_chance(0.65), c_present("actor"), c_present("target")],
   effects=[say("defender", "defend", to="actor", delay=3.0), say("actor", "stay_out", to="defender", delay=4.6, when=[c_trait("actor", "temper", gt=0.5)]),
            rel("target", "defender", "friendship", 12), rel("target", "defender", "trust", 10), rel("actor", "defender", "trust", -8),
            rel("defender", "target", "friendship", 4), mem("target", "defender", "defended_me", 0.8, 0.9, "mem.defended_me", 3),
            stat("defenses"), log("log.defended", 3, "solidarity", who="defender", delay=3.0)])

ev(id="big_fight", trigger="argument", priority=60, cooldown=200, also=True, max_day=1,
   conditions=[c_stat("arguments", 3), c_chance(0.4), c_time(after="10:00")],
   effects=[each([say("self", "fight_crowd", p=0.55, delay=1.0), emote("self", "exclaim"), stress("self", 6)],
                 exclude=["actor", "target"], stagger=0.3, where=[c_near("self", "actor", 7)]),
            stat("big_fights"), sfx("crowd"), log("log.big_fight", 4, "conflict"),
            chain("manager_outburst", delay=4, roles={"actor": "@ahmet", "target": "actor", "other": "target"})])

ev(id="manager_outburst", trigger="", priority=80, allow_absent=True,
   conditions=[c_avail("actor"), c_is("target", "ahmet", neg=True)],
   effects=[say("actor", "boss_outburst"), expr("actor", "angry", 7), emote("actor", "anger"), sfx("slam"),
            each([stress("self", 8), expr("self", "sad", 4), emote("self", "sweat")], exclude=["actor"], stagger=0.2),
            rel("target", "actor", "friendship", -6), rel("other", "actor", "friendship", -6), stat("scoldings"),
            mem("target", "actor", "scolded", -0.5, 0.7, "mem.boss_yelled", 2), mem("other", "actor", "scolded", -0.5, 0.7, "mem.boss_yelled", 2),
            log("log.boss_outburst", 4, "boss")])

# =====================================================================
# ITEMS
# =====================================================================
ev(id="item_missing", trigger="item_missing", priority=70,
   effects=[expr("actor", "surprised", 4), emote("actor", "question"),
            say("actor", "missing_glasses", when=[c_var("item", eq="glasses")]),
            say("actor", "missing_usb", when=[c_var("item", eq="usb")]),
            say("actor", "missing_mug", when=[c_var("item", eq="mug")]),
            say("actor", "missing_planner", when=[c_var("item", eq="planner")]),
            say("actor", "missing_charger", when=[c_var("item", eq="charger")]),
            stress("actor", 6), log("log.item_missing", 2, "prank"), call("search_item", prio=60)])

ev(id="item_found", trigger="item_found", priority=70, allow_absent=True,
   outcomes=[
       out("suspect_owner", [expr("actor", "angry", 5), say("actor", "found_at_desk"),
                             mem("actor", "owner", "took_my_item", -0.6, 0.8, "mem.took_item", 2), rel("actor", "owner", "trust", -10),
                             stat("blames"), {"e": "set", "key": "incident", "v": "item"},
                             intent("actor", "go_npc", target="owner", event="accusation", prio=62, ttl=60),
                             log("log.item_found_desk", 3, "conflict")],
           score=[s_rel("actor", "owner", "rivalry", 0.02), s_rel("actor", "owner", "trust", -0.012), s_trait("actor", "temper", 0.6), s_const(0.4)],
           when=[c_filled("owner"), c_present("owner")]),
       out("laugh_off", [say("actor", "found_at_friend"), log("log.item_found_friend", 2, "prank")],
           score=[s_aff("actor", "owner", 0.02), s_trait("actor", "humor", 0.5)], when=[c_filled("owner")]),
       out("weird_place", [say("actor", "found_weird_place"), ghost(), log("log.item_found_weird", 2, "ghost")],
           score=[s_const(1.0)], when=[c_filled("owner", ) | {"not": True}]),
       out("relief", [say("actor", "found_item_relief"), log("log.item_found", 1, "prank")], score=[s_const(0.1)]),
   ])

ev(id="foreign_item", trigger="foreign_item", priority=60, allow_absent=True,
   outcomes=[
       out("pocket", [say("actor", "pocket_item"), flag("thief_usb", "deniz"), log("log.item_pocketed", 3, "scheme")],
           score=[s_const(3)], when=[c_is("actor", "deniz"), c_var("item", eq="usb"), c_chance(0.6)]),
       out("return_kindly", [say("actor", "found_foreign_item"), call("return_item"), log("log.item_return_start", 1, "prank")],
           score=[s_trait("actor", "empathy", 1.2), s_trait("actor", "honesty", 0.6), s_aff("actor", "owner", 0.01)]),
       out("ignore", [say("actor", "whose_is_this")], score=[s_const(0.4), s_trait("actor", "empathy", -0.4)]),
   ])

ev(id="item_returned", trigger="", priority=75, conditions=[c_avail("target")],
   effects=[hold(["actor", "target"], 3.5), say("actor", "return_item_line", to="target"), say("target", "thanks_return", to="actor", delay=1.5),
            rel("target", "actor", "friendship", 14), rel("target", "actor", "trust", 10), rel("actor", "target", "friendship", 4),
            mem("target", "actor", "returned_item", 0.8, 0.9, "mem.returned_item", 3), stat("helps"), cancel("target", "search"),
            emote("target", "love", delay=1.5), log("log.item_returned", 3, "friendship")])

# =====================================================================
# EMAIL
# =====================================================================
ev(id="email_all_scene", trigger="", priority=90, allow_absent=True,
   effects=[expr("actor", "surprised", 7), emote("actor", "exclaim"), say("actor", "email_oops", delay=0.4), sfx("gasp", delay=0.4),
            each([emote("self", "exclaim", delay=0.6), say("self", "email_read_all", p=0.5, delay=0.8)], exclude=["actor", "subject"], stagger=0.7),
            # secrets
            say("subject", "secret_exposed", delay=3.0, when=[c_var("etype", in_=["secret", "gossip_digest"]), c_present("subject"), c_is("subject", "", neg=True)] ),
            say("actor", "own_secret_out", delay=2.2, when=[c_var("etype", eq="secret")]),
            stress("subject", 18, when=[c_var("etype", in_=["secret", "gossip_digest"])]),
            rel("subject", "actor", "friendship", -18, when=[c_var("etype", eq="gossip_digest")]),
            rel("subject", "actor", "trust", -28, when=[c_var("etype", eq="gossip_digest")]),
            intent("subject", "go_npc", target="actor", event="email_confront", prio=66, ttl=60, delay=4,
                   when=[c_var("etype", in_=["gossip_digest", "rant", "scheme"]), c_present("subject")]),
            chain("crush_exposed", delay=3, roles={"actor": "@ceren", "target": "@mert"}, when=[c_var("etype", eq="love")]),
            call("scold", target="actor", reason="email", prio=66, delay=3, when=[c_var("etype", eq="complaint_boss")]),
            each([say("self", "team_complaint_react", p=0.5, delay=2)], exclude=["actor"], stagger=0.6, where=[c_var("etype", eq="complaint_team")]),
            say("actor", "boss_backpedal", delay=4.5, when=[c_var("etype", eq="complaint_team")]),
            stat("secrets_revealed", 0)])

ev(id="email_redirect_scene", trigger="", priority=90, allow_absent=True,
   effects=[say("actor", "email_sent_wrong", delay=0.5), emote("actor", "sweat", delay=0.5),
            emote("target", "exclaim", delay=1.6), say("target", "email_redirect_read", delay=1.8),
            intent("target", "go_npc", target="actor", event="email_confront", prio=66, ttl=60, delay=3.5,
                   when=[c_any({"c": "same", "a": "target", "b": "subject"}), c_var("etype", in_=["rant", "scheme", "gossip_digest"])]),
            call("scold", target="actor", reason="email", prio=66, delay=3, when=[c_var("etype", eq="complaint_boss"), c_is("target", "ahmet")]),
            chain("crush_exposed", delay=3, roles={"actor": "@ceren", "target": "@mert"}, when=[c_var("etype", eq="love"), c_is("target", "ceren")]),
            intent("target", "go_npc", target="actor", event="tease_crush", prio=30, ttl=60, delay=5,
                   when=[c_var("etype", eq="love"), c_is("target", "ceren", neg=True)])])

ev(id="email_confront", trigger="", priority=82, conditions=[c_avail("target")],
   effects=[hold(["actor", "target"], 5), say("actor", "email_confront", to="target")],
   outcomes=[
       out("apology", [say("target", "email_apology", to="actor", delay=1.6), say("actor", "email_apology_accept", to="target", delay=3.2),
                       rel("actor", "target", "friendship", 6), log("log.email_apology", 2, "conflict")],
           score=[s_trait("target", "empathy", 1.0), s_trait("target", "honesty", 0.5), s_trait("actor", "forgiveness", 0.6)]),
       out("argument", [say("target", "email_defiant", to="actor", delay=1.6), say("actor", "email_furious", to="target", delay=3.2),
                        expr("actor", "angry", 6), expr("target", "angry", 6, delay=1.6),
                        rel("actor", "target", "friendship", -12, both=True), rel("actor", "target", "rivalry", 8, both=True),
                        stat("arguments"), rumor("argument", juicy=0.6, knowers=["actor", "target"]),
                        witness([learn("self", "$rumor"), say("self", "witness_argument", p=0.3, delay=3.5)]),
                        sfx("argue", delay=1.6), log("log.argument_email", 3, "conflict")],
           score=[s_trait("target", "temper", 1.0), s_trait("target", "cunning", 0.4), s_rel("target", "actor", "rivalry", 0.02)]),
   ])

ev(id="crush_exposed", trigger="", priority=75, allow_absent=True, conditions=[c_present("actor"), c_present("target")],
   outcomes=[
       out("flattered", [say("actor", "crush_flattered"), say("target", "mert_blush", delay=1.6), emote("target", "love", delay=1.6),
                         emote("actor", "love"), rel("actor", "target", "friendship", 12, both=True), log("log.crush_sweet", 3, "romance")],
           score=[s_aff("actor", "target", 0.03), s_mood("actor", 0.01)]),
       out("awkward", [say("actor", "crush_awkward"), expr("target", "sad", 6, delay=1.0), mood("target", -15),
                       rel("actor", "target", "friendship", -6), log("log.crush_awkward", 3, "romance")],
           score=[s_const(0.8), s_aff("actor", "target", -0.01)]),
   ])

ev(id="tease_crush", trigger="", priority=50, conditions=[c_avail("target")],
   effects=[hold(["actor", "target"], 3), say("actor", "tease_crush_line", to="target"), say("target", "mert_blush", to="actor", delay=1.5),
            emote("target", "sweat", delay=1.5), rel("actor", "target", "friendship", 2), log("log.tease_crush", 2, "romance")])

# =====================================================================
# MEETING
# =====================================================================
ev(id="board_noticed", trigger="board_noticed", priority=55,
   outcomes=[
       out("ceren_alarm", [say("actor", "board_who_moved"), emote("actor", "question"), ghost(),
                           log("log.ceren_noticed_board", 2, "meeting"),
                           intent("actor", "go_npc", target="@ahmet", event="inform_boss_meeting", prio=50, ttl=60)],
           score=[s_const(5)], when=[c_is("actor", "ceren"), c_present("@ahmet")]),
       out("noted", [say("actor", "board_moved_note", p=0.6)], score=[s_const(1)]),
   ])

ev(id="inform_boss_meeting", trigger="", priority=70, conditions=[c_avail("target")],
   effects=[hold(["actor", "target"], 3.5), say("actor", "tell_boss_meeting_moved", to="target"), meet("target", "board")],
   outcomes=[
       out("fine", [say("target", "boss_meeting_moved_ok", to="actor", delay=1.5), rel("target", "actor", "trust", 2)],
           score=[s_rel("target", "actor", "trust", 0.02), s_trait("target", "temper", -0.5)]),
       out("blames_her", [say("target", "boss_meeting_moved_blame", to="actor", delay=1.5), rel("target", "actor", "trust", -6),
                          rel("actor", "target", "friendship", -5), mem("actor", "target", "blamed_me", -0.4, 0.6, "mem.boss_blamed", 2),
                          stat("blames"), log("log.boss_blames_ceren", 3, "boss")],
           score=[s_trait("target", "temper", 1.0), s_stress("target", 0.01)]),
   ])

ev(id="board_changed", trigger="board_changed", priority=40,
   roles=[role("actor", where=[c_avail("self"), {"c": "zone", "who": "self", "in": ["meeting"]}], exclude=[])],
   effects=[emote("actor", "question"), say("actor", "board_changed_live"), meet("actor", "board"), ghost()])

ev(id="meeting_start", trigger="meeting_start", priority=50,
   effects=[say("actor", "meeting_open")])

ev(id="meeting_boss_late", trigger="meeting_boss_late", priority=60,
   effects=[each([say("self", "boss_finally", p=0.45)], exclude=["actor"], stagger=0.5, where=[c_act("self", ["meeting"])])],
   outcomes=[
       out("blame_ceren", [say("actor", "boss_blames_calendar", delay=2.0), rel("actor", "@ceren", "trust", -8), rel("@ceren", "actor", "friendship", -8),
                           mem("@ceren", "actor", "blamed_me", -0.5, 0.7, "mem.boss_blamed", 2), stat("blames"),
                           log("log.boss_late_blame", 3, "meeting")],
           score=[s_trait("actor", "temper", 1.2), s_const(0.1)], when=[c_present("@ceren")]),
       out("laugh", [say("actor", "boss_late_laugh", delay=2.0), log("log.boss_late", 2, "meeting")], score=[s_const(0.6)]),
   ])

ev(id="meeting_late", trigger="meeting_late", priority=70,
   effects=[emote("actor", "sweat"), say("actor", "late_excuse", to="target")],
   outcomes=[
       out("blame_board", [say("actor", "board_said_other_time", to="target", delay=1.4), say("target", "who_changed_board", delay=2.8),
                           ghost(), rel("target", "@ceren", "trust", -4), log("log.late_board_confusion", 3, "ghost")],
           score=[s_const(1.4)], when=[c_office("board.changed", True), c_chance(0.75)]),
       out("scold", [say("target", "boss_scold_late", to="actor", delay=1.4), expr("actor", "sad", 5, delay=1.4), stress("actor", 12),
                     mood("actor", -10), rel("actor", "target", "friendship", -6), mem("actor", "target", "scolded", -0.5, 0.7, "mem.scolded_late", 2),
                     stat("scoldings"), favor("actor", -4), rumor("late", a="actor", b="target", juicy=0.3, knowers=[]),
                     witness([learn("self", "$rumor")], r=6), log("log.late_scolded", 3, "meeting")],
           score=[s_trait("target", "temper", 1.2), s_rel("target", "actor", "trust", -0.015), s_stress("target", 0.01), s_is("actor", "mert", 0.4)],
           when=[c_is("actor", "ece", neg=True)]),
       out("let_go", [say("target", "boss_sit_down", to="actor", delay=1.4), log("log.late", 2, "meeting")], score=[s_const(0.5)]),
   ])

ev(id="meeting_wait_timeout", trigger="meeting_wait_timeout", priority=50,
   effects=[say("actor", "where_is_everyone"), mood("actor", -6), stress("actor", 5), emote("actor", "question"),
            mem("actor", "", "missed_meeting", -0.2, 0.5), log("log.meeting_wait", 2, "meeting")])

ev(id="meeting_absent", trigger="meeting_absent", priority=55, allow_absent=True,
   conditions=[c_chance(0.85), c_present("target")],
   effects=[mem("target", "actor", "no_show", -0.6, 0.8), favor("actor", -6), rel("target", "actor", "trust", -10),
            call("scold", target="actor", reason="meeting", prio=60), log("log.meeting_absent", 2, "meeting")])

ev(id="boss_scold", trigger="", priority=80, conditions=[c_avail("target")],
   effects=[hold(["actor", "target"], 4.5),
            say("actor", "scold_meeting", to="target", when=[c_var("reason", eq="meeting")]),
            say("actor", "scold_email", to="target", when=[c_var("reason", eq="email")]),
            say("actor", "scold_deadline", to="target", when=[c_var("reason", eq="deadline")]),
            say("actor", "scold_general", to="target", when=[c_var("reason", in_=["general", ""])]),
            stat("scoldings"), expr("actor", "angry", 5),
            {"e": "trigger", "name": "scolded", "roles": {"actor": "actor", "target": "target"}}],
   outcomes=[
       out("takes_it", [say("target", "sorry_boss", to="actor", delay=1.6), stress("target", 10), mood("target", -8),
                        mem("target", "actor", "scolded", -0.4, 0.6, "mem.scolded", 2), log("log.scolded", 3, "boss")],
           score=[s_trait("target", "temper", -1.0), s_const(0.6)]),
       out("talks_back", [say("target", "talk_back", to="actor", delay=1.6), say("actor", "boss_how_dare", to="target", delay=3.0),
                          rel("actor", "target", "trust", -8, both=True), stress("actor", 6), stress("target", 8), favor("target", -6),
                          mem("target", "actor", "scolded", -0.6, 0.8, "mem.talked_back", 3), log("log.talked_back", 3, "boss")],
           score=[s_trait("target", "temper", 1.2), s_goal("target", "find_new_job", 0.5)]),
   ])

ev(id="meeting_present", trigger="meeting_present", priority=80, allow_absent=True,
   outcomes=[
       out("great", [say("actor", "present_good"), say("target", "boss_praise", to="actor", delay=2.0), favor("actor", 10),
                     rel("target", "actor", "trust", 6), mood("actor", 12), stat("praises"),
                     mem("actor", "target", "praised", 0.5, 0.7, "mem.praised", 2), log("log.present_good", 2, "meeting"),
                     say("other", "rival_jealous", delay=3.6, when=[c_present("other")]), rel("other", "actor", "rivalry", 6, when=[c_present("other")])],
           score=[s_const(2)], when=[c_var("prepared", eq=True)]),
       out("no_usb", [say("actor", "present_no_usb"), expr("actor", "surprised", 6), say("target", "boss_unimpressed", to="actor", delay=2.0),
                      favor("actor", -8), stress("actor", 15), mood("actor", -10), mem("actor", "", "lost_usb_presentation", -0.5, 0.7, "mem.no_usb", 3),
                      log("log.present_no_usb", 3, "meeting"),
                      chain("credit_steal", delay=2.5, roles={"actor": "other", "target": "actor"}, when=[c_present("other")])],
           score=[s_const(3)], when=[c_var("has_usb", eq=False)]),
       out("unprepared", [say("actor", "present_bad"), say("target", "boss_unimpressed", to="actor", delay=2.0), favor("actor", -8),
                          stress("actor", 12), mood("actor", -8), log("log.present_bad", 2, "meeting"),
                          chain("credit_steal", delay=2.5, roles={"actor": "other", "target": "actor"}, when=[c_present("other")])],
           score=[s_const(1)], when=[c_var("prepared", eq=False)]),
   ])

ev(id="credit_steal", trigger="", priority=75, allow_absent=True,
   conditions=[c_avail("actor"), c_present("@ahmet"), c_trait("actor", "cunning", gt=0.55), c_chance(0.75)],
   effects=[say("actor", "credit_steal_pitch", to="@ahmet"), say("@ahmet", "boss_impressed_thief", to="actor", delay=2.0),
            favor("actor", 12), favor("target", -4), rumor("credit_steal", a="actor", b="target", juicy=0.8, knowers=["actor"]),
            witness([learn("self", "$rumor")], r=5), stat("wrong_rewards"), log("log.credit_steal", 4, "scheme"),
            chain("credit_fight", delay=3.5, roles={"actor": "target", "target": "actor"}, when=[c_present("target"), c_near("actor", "target", 6)])])

ev(id="credit_fight", trigger="", priority=78, conditions=[c_present("target")],
   effects=[say("actor", "that_was_my_work", to="target"), say("target", "prove_it", to="actor", delay=1.6), expr("actor", "angry", 6),
            rel("actor", "target", "rivalry", 15, both=True), rel("actor", "target", "friendship", -15, both=True), stat("arguments"),
            mem("actor", "target", "credit_stolen", -0.9, 1.0, "mem.credit_stolen", 3), log("log.credit_fight", 4, "conflict")])

ev(id="meeting_opportunity", trigger="meeting_opportunity", priority=70, allow_absent=True,
   conditions=[c_chance(0.7), c_trait("actor", "cunning", gt=0.6), c_present("actor")],
   effects=[say("actor", "credit_steal_pitch", to="target"), say("target", "boss_impressed_thief", to="actor", delay=2.0), favor("actor", 12),
            rumor("credit_steal", a="actor", b="victim", juicy=0.8, knowers=["actor"]), witness([learn("self", "$rumor")], r=5),
            stat("wrong_rewards"), log("log.credit_steal_absent", 4, "scheme")])

ev(id="meeting_banter", trigger="meeting_banter", priority=30,
   roles=[role("joker", where=[c_act("self", ["meeting"]), {"c": "is", "who": "self", "id": "ahmet", "not": True}],
               score=[s_trait("self", "humor", 1.0), s_rand(0.4)], exclude=["actor"], avail=False)],
   effects=[say("joker", "meeting_joke")],
   outcomes=[
       out("laugh", [say("actor", "boss_laughs", delay=1.6), rel("actor", "joker", "friendship", 3), mood("actor", 5)],
           score=[s_trait("actor", "humor", 1.0), s_mood("actor", 0.01), s_rand(0.4)]),
       out("annoyed", [say("actor", "boss_not_funny", delay=1.6), favor("joker", -2)], score=[s_trait("actor", "temper", 0.6), s_stress("actor", 0.01)]),
   ])

# =====================================================================
# PROMOTION
# =====================================================================
ev(id="promo_reviewed", trigger="promo_reviewed", priority=70, allow_absent=True,
   effects=[say("actor", "promo_reading"), emote("actor", "idea"), log("log.promo_reviewed", 3, "promotion"),
            chain("ceren_notices_promo", delay=30, roles={"actor": "@ceren", "victim": "victim", "credited": "credited"})])

ev(id="promo_reviewed_clean", trigger="promo_reviewed_clean", priority=20,
   effects=[say("actor", "promo_reading_clean", p=0.6)])

ev(id="ceren_notices_promo", trigger="", priority=50, allow_absent=True,
   conditions=[c_chance(0.55), c_present("actor"), c_present("victim"), c_is("victim", "", neg=True)],
   outcomes=[
       out("tell", [intent("actor", "go_npc", target="victim", event="ceren_tells_victim", prio=48, ttl=90, roles={"credited": "credited"}),
                    log("log.ceren_notices_promo", 2, "promotion")],
           score=[s_aff("actor", "victim", 0.02), s_trait("actor", "honesty", 0.6)], when=[c_aff("actor", "victim", gt=15)]),
       out("quiet", [mem("actor", "", "promo_secret", 0.0, 0.5)], score=[s_const(0.4)]),
   ])

ev(id="ceren_tells_victim", trigger="", priority=72, allow_absent=True, conditions=[c_avail("target")],
   effects=[hold(["actor", "target"], 4), say("actor", "promo_tip", to="target"), say("target", "promo_outraged", to="actor", delay=1.6),
            expr("target", "angry", 6, delay=1.6), rel("target", "credited", "trust", -15), rel("target", "credited", "rivalry", 12),
            rel("target", "actor", "friendship", 8),
            mem("target", "credited", "sabotaged_promo", -0.8, 0.9, "mem.sabotaged_promo", 3), log("log.promo_tip", 3, "promotion"),
            {"e": "set", "key": "incident", "v": "promo"},
            intent("target", "go_npc", target="credited", event="accusation", prio=60, ttl=90, delay=2,
                   when=[c_present("credited"), c_is("credited", "", neg=True)])])

ev(id="promotion", trigger="promotion", priority=95, allow_absent=True,
   effects=[say("actor", "promo_announce", when=[c_var("kind", eq="promotion")]),
            say("actor", "award_announce", when=[c_var("kind", eq="award")]),
            say("winner", "promo_winner", delay=2.4), emote("winner", "love", delay=2.4), mood("winner", 25), stress("winner", -10),
            each([say("self", "promo_clap", p=0.35, delay=3.2)], exclude=["actor", "winner", "loser"], stagger=0.4),
            log("log.promotion", 4, "promotion", who="winner", when=[c_var("kind", eq="promotion")]),
            log("log.award", 3, "promotion", who="winner", when=[c_var("kind", eq="award")]),
            say("loser", "promo_loser", delay=4.2, when=[c_present("loser")]), mood("loser", -20), stress("loser", 12),
            rel("loser", "winner", "rivalry", 15), mem("loser", "winner", "lost_promo", -0.6, 0.8, "mem.lost_promo", 3),
            log("log.promotion_rigged", 5, "promotion", who="winner", delay=0.5, when=[c_var("rigged", eq=True)]),
            stat("wrong_rewards", when=[c_var("rigged", eq=True)]),
            chain("promo_grudge", delay=12, roles={"actor": "loser", "target": "winner"}, when=[c_is("loser", "selin")])])

ev(id="promo_grudge", trigger="", priority=55, allow_absent=True, conditions=[c_present("actor"), c_present("target")],
   outcomes=[
       out("confront", [{"e": "set", "key": "incident", "v": "promo"},
                        intent("actor", "go_npc", target="target", event="accusation", prio=55, ttl=60)],
           score=[s_trait("actor", "temper", 1.0), s_rel("actor", "target", "rivalry", 0.01)]),
       out("cold", [say("actor", "cold_grudge"), mem("actor", "target", "grudge", -0.6, 0.9, "mem.grudge", 3)], score=[s_const(0.6)]),
   ])

# =====================================================================
# FAKE PHONE NOTIFICATIONS
# =====================================================================
ev(id="notif_boss", trigger="notif", filter={"kind": "boss"}, priority=70,
   effects=[say("actor", "notif_boss_read"), emote("actor", "sweat"), stress("actor", 6),
            intent("actor", "go_place", place="boss_front", event="boss_confused", prio=74, ttl=40, roles={"target": "@ahmet"}),
            log("log.notif_boss", 2, "ghost")])

ev(id="notif_food", trigger="notif", filter={"kind": "food"}, priority=70,
   effects=[say("actor", "notif_food_read"), emote("actor", "love"),
            intent("actor", "go_place", place="fridge", event="no_food", prio=55, ttl=40), log("log.notif_food", 2, "ghost")])

ev(id="notif_cancel", trigger="notif", filter={"kind": "cancel"}, priority=70,
   effects=[say("actor", "notif_cancel_read"), call("meeting_cancel_belief"), log("log.notif_cancel", 2, "ghost")])

ev(id="notif_admirer", trigger="notif", filter={"kind": "admirer"}, priority=70,
   roles=[role("crush", where=[c_avail("self")], score=[s_aff("actor", "self", 0.02), s_trait("self", "humor", 0.3), s_rand(0.8),
                                                       s_if(c_is("actor", "ceren"), 0.0), s_if({"c": "all", "of": [c_is("actor", "ceren"), c_is("self", "mert")]}, 2.0)],
               exclude=["actor"], optional=True)],
   effects=[say("actor", "notif_admirer_read"), emote("actor", "love"), mood("actor", 15), log("log.notif_admirer", 2, "romance"),
            intent("actor", "go_npc", target="crush", event="admirer_ask", prio=45, ttl=50, delay=2, when=[c_present("crush")])])

ev(id="boss_confused", trigger="", priority=80, allow_absent=True, conditions=[c_avail("target")],
   effects=[hold(["actor", "target"], 4.5), say("actor", "you_wanted_me", to="target"), say("target", "i_didnt_call", to="actor", delay=1.5), ghost()],
   outcomes=[
       out("annoyed", [say("target", "boss_get_back_to_work", to="actor", delay=3.0), rel("actor", "target", "friendship", -4), stress("actor", 6),
                       mem("actor", "target", "boss_snapped", -0.3, 0.5), log("log.boss_confused_annoyed", 2, "ghost")],
           score=[s_trait("target", "temper", 1.0), s_stress("target", 0.01)]),
       out("friendly", [say("target", "boss_since_youre_here", to="actor", delay=3.0), rel("actor", "target", "friendship", 6, both=True),
                        favor("actor", 4), log("log.boss_confused_friendly", 2, "friendship")],
           score=[s_rel("target", "actor", "trust", 0.02), s_mood("target", 0.01)]),
   ])

ev(id="no_food", trigger="", priority=60,
   vars=[var("suspect", "suspect", optional=True)],
   effects=[say("actor", "no_food_here"), mood("actor", -8), emote("actor", "cloud")],
   outcomes=[
       out("blame_prank", [say("actor", "who_pranked", delay=1.6), mem("actor", "$suspect", "pranked_me", -0.3, 0.6, "mem.pranked", 2),
                           rel("actor", "$suspect", "trust", -5), log("log.no_food_blame", 2, "prank")],
           score=[s_trait("actor", "temper", 0.8), s_const(0.3)], when=[c_filled("$suspect")]),
       out("sigh", [say("actor", "fridge_sigh", delay=1.6), log("log.no_food", 2, "prank")], score=[s_const(0.5)]),
   ])

ev(id="admirer_ask", trigger="", priority=60, conditions=[c_avail("target")],
   effects=[hold(["actor", "target"], 3.5), say("actor", "admirer_was_it_you", to="target")],
   outcomes=[
       out("sweet", [say("target", "admirer_maybe", to="actor", delay=1.6), rel("actor", "target", "friendship", 10, both=True),
                     emote("actor", "love", delay=1.6), log("log.admirer_sweet", 3, "romance")],
           score=[s_aff("target", "actor", 0.025), s_trait("target", "humor", 0.3)]),
       out("awkward", [say("target", "admirer_no", to="actor", delay=1.6), mood("actor", -6), log("log.admirer_awkward", 2, "romance")],
           score=[s_const(0.7)]),
   ])

# =====================================================================
# SECRETS
# =====================================================================
ev(id="boss_learns_job_hunt", trigger="fact_learned", filter={"fact": "burak_job_hunt", "actor": "ahmet"}, priority=70, allow_absent=True,
   conditions=[c_present("actor"), c_present("@burak")],
   effects=[expr("actor", "angry", 6), say("actor", "boss_job_hunt_discovered"), log("log.boss_learns_job", 4, "secret"),
            call("summon", target="@burak", event="job_hunt_talk", prio=76, delay=2)])

ev(id="job_hunt_talk", trigger="", priority=80, allow_absent=True, conditions=[c_avail("target")],
   effects=[hold(["actor", "target"], 5.5), say("target", "boss_job_hunt_confront", to="actor")],
   outcomes=[
       out("counteroffer", [say("target", "boss_counteroffer", to="actor", delay=2.0), say("actor", "burak_surprised_stay", to="target", delay=3.6),
                            mood("actor", 20), goal("actor", "get_recognition"), rel("actor", "target", "friendship", 15),
                            rel("actor", "target", "trust", 12), log("log.counteroffer", 4, "boss")],
           score=[s_rel("target", "actor", "trust", 0.02), s_mem("target", "actor", 0.8), s_const(0.2)]),
       out("clash", [say("actor", "burak_defiant", to="target", delay=2.0), say("target", "boss_cold", to="actor", delay=3.6),
                     rel("actor", "target", "friendship", -15, both=True), stress("actor", 12), favor("actor", -10),
                     log("log.job_hunt_clash", 4, "boss")],
           score=[s_trait("actor", "temper", 0.8), s_trait("target", "temper", 0.8), s_stress("actor", 0.01)]),
   ])

ev(id="nepotism_reveal", trigger="fact_learned", filter={"fact": "ece_relative"}, priority=50, allow_absent=True,
   conditions=[c_dayflag("nepotism_scene", neg=True), c_present("actor"), c_is("actor", in_=["ece", "ahmet"], neg=True)],
   effects=[flag("nepotism_scene", True, day=True), say("actor", "nepotism_mutter"), expr("@ece", "sad", 6), mood("@ece", -15),
            stress("@ece", 12), log("log.nepotism", 3, "secret")])

ev(id="review_shock", trigger="fact_learned", filter={"fact": "ahmet_review", "actor": "ahmet"}, priority=60, allow_absent=True,
   conditions=[c_present("actor")],
   effects=[expr("actor", "surprised", 6), say("actor", "boss_review_shock"), goal("actor", "impress_hq"), log("log.boss_review", 4, "secret")])

ev(id="secret_call", trigger="secret_call", priority=45, max_day=2,
   roles=[role("listener", where=[c_avail("self")], score=[s_trait("self", "curiosity", 1.0), s_dist("actor", "self", -0.2)],
               exclude=["actor"], near="actor", r=3.8, optional=True)],
   effects=[say("actor", "secret_call_line"), reveal("burak_job_hunt")],
   outcomes=[
       out("overheard", [learn("listener", "burak_job_hunt", frm="actor"), emote("listener", "exclaim", delay=1.4),
                         say("listener", "overheard_call", delay=1.6), log("log.overheard_call", 3, "secret", who="listener")],
           score=[s_const(1)], when=[c_present("listener"), c_knows("listener", "burak_job_hunt", neg=True)]),
       out("alone", [], score=[s_const(0.1)]),
   ])

# =====================================================================
# SOCIAL LIFE (encounters, chats, desk chatter)
# =====================================================================
ev(id="gossip_share", trigger=["encounter", "chat", "desk_chat"], priority=62, scope="pair", cooldown=100, max_day=10,
   vars=[var("gossip", "gossip_fact")],
   conditions=[c_avail("target"), c_trait("actor", "gossip", gt=0.3)],
   effects=[hold(["actor", "target"], 4.5), say("actor", "gossip_open", to="target"), say("actor", "gossip_tell", to="target", delay=1.5),
            learn("target", "$gossip", frm="actor"), rel("actor", "target", "friendship", 2), stat("rumors"), log("log.gossip", 2, "rumor")],
   outcomes=[
       out("shocked", [say("target", "gossip_react", to="actor", delay=3.0)], score=[s_const(0.6)]),
       out("disapprove", [say("target", "gossip_disapprove", to="actor", delay=3.0), rel("target", "actor", "trust", -5)],
           score=[s_trait("target", "honesty", 1.0), s_trait("target", "gossip", -1.0)]),
       out("eager", [say("target", "gossip_eager", to="actor", delay=3.0), rel("target", "actor", "friendship", 4)],
           score=[s_trait("target", "gossip", 1.2), s_trait("target", "curiosity", 0.4)]),
   ])

ev(id="flirt", trigger=["encounter", "chat"], priority=55, scope="pair", cooldown=120, max_day=3,
   conditions=[c_is("actor", "mert"), c_is("target", "ceren"), c_goal("actor", "win_ceren"), c_avail("target")],
   effects=[hold(["actor", "target"], 4), say("actor", "flirt_line", to="target")],
   outcomes=[
       out("charmed", [say("target", "flirt_charmed", to="actor", delay=1.6), rel("actor", "target", "friendship", 4, both=True),
                       emote("actor", "love", delay=1.6), log("log.flirt_good", 2, "romance")],
           score=[s_aff("target", "actor", 0.015), s_mood("target", 0.01), s_rand(0.5)]),
       out("brushed", [say("target", "flirt_brush", to="actor", delay=1.6), mood("actor", -6), emote("actor", "cloud", delay=1.6),
                       log("log.flirt_bad", 2, "romance")],
           score=[s_const(0.5), s_stress("target", 0.01)]),
   ])

ev(id="couple_forms", trigger=["encounter", "chat"], priority=66, max_day=1,
   conditions=[c_is("actor", in_=["mert", "ceren"]), c_is("target", in_=["mert", "ceren"]), c_flag("couple", neg=True), {"c": "day", "gte": 3},
               c_rel("actor", "target", "friendship", gt=68), c_rel("target", "actor", "friendship", gt=62), c_chance(0.5)],
   effects=[hold(["actor", "target"], 4), say("actor", "date_ask", to="target"), say("target", "date_yes", to="actor", delay=1.6),
            emote("actor", "love", delay=1.6), emote("target", "love", delay=1.6), flag("couple", True),
            rumor("couple", juicy=0.85, knowers=["actor", "target"]), reveal("$rumor"), mood("actor", 20), mood("target", 15),
            log("log.secret_couple", 4, "romance")])

ev(id="secret_friends_spotted", trigger=["encounter", "chat"], priority=35, scope="pair", cooldown=400, max_day=2,
   roles=[role("spotter", where=[c_avail("self"), c_trait("self", "gossip", gt=0.5)], score=[s_trait("self", "gossip", 1.0)],
               near="actor", r=4.5)],
   conditions=[c_aff("actor", "target", gt=48), c_aff("target", "actor", gt=48), c_chance(0.15)],
   effects=[rumor("secret_friends", juicy=0.5, knowers=["spotter"]), say("spotter", "spotted_secret_friends"), emote("spotter", "idea"),
            log("log.secret_friends", 2, "rumor", who="spotter")])

ev(id="jealousy", trigger=["encounter", "desk_chat"], priority=45, scope="pair", cooldown=120,
   conditions=[c_rel("actor", "target", "rivalry", gt=32), c_mem("target", "praised", days=0), c_avail("target")],
   effects=[say("actor", "jealous_jab", to="target"), rel("actor", "target", "rivalry", 6), stat("jealousy"), log("log.jealousy", 2, "conflict")],
   outcomes=[
       out("smug", [say("target", "jealous_smug", to="actor", delay=1.6), rel("actor", "target", "rivalry", 4)], score=[s_trait("target", "cunning", 1.0)]),
       out("hurt", [say("target", "jealous_hurt", to="actor", delay=1.6), mood("target", -6)], score=[s_trait("target", "empathy", 0.8)]),
   ])

ev(id="reconciliation", trigger=["encounter", "chat", "desk_chat"], priority=64, scope="pair", cooldown=240,
   conditions=[c_aff("actor", "target", gt=-48, lt=6), c_rel("actor", "target", "friendship", lt=10), c_mood("actor", gt=-10),
               c_stress("actor", lt=60), c_any(c_trait("actor", "forgiveness", gt=0.35), c_trait("actor", "empathy", gt=0.6)),
               c_any(c_mem("actor", "argued", days=3), c_mem("actor", "falsely_accused", days=3), c_mem("actor", "refused_help", days=3),
                     c_mem("actor", "accused_me", days=3), c_mem("actor", "thermostat", days=3)),
               c_chance(0.55), c_avail("target")],
   effects=[hold(["actor", "target"], 4.5), say("actor", "apology_offer", to="target")],
   outcomes=[
       out("makeup", [say("target", "apology_accept", to="actor", delay=1.6), rel("actor", "target", "friendship", 20, both=True),
                      rel("actor", "target", "trust", 10, both=True), rel("actor", "target", "rivalry", -10, both=True),
                      mem("actor", "target", "made_up", 0.6, 0.8, "mem.made_up", 3), mem("target", "actor", "made_up", 0.6, 0.8, "mem.made_up", 3),
                      {"e": "bond", "a": "actor", "b": "target", "kind": "feud", "v": False},
                      emote("actor", "love", delay=1.6), stat("reconciliations"), log("log.reconcile", 3, "friendship")],
           score=[s_trait("target", "forgiveness", 1.2), s_mood("target", 0.01), s_const(0.2)]),
       out("rebuffed", [say("target", "apology_reject", to="actor", delay=1.6), rel("actor", "target", "friendship", -4),
                        emote("actor", "cloud", delay=1.6), log("log.reconcile_fail", 2, "conflict")],
           score=[s_trait("target", "forgiveness", -1.0), s_stress("target", 0.01), s_const(0.3)]),
   ])

ev(id="grudge_flare", trigger=["encounter", "desk_chat"], priority=50, scope="pair", cooldown=150,
   conditions=[c_aff("actor", "target", lt=-28), c_stress("actor", gt=35), c_trait("actor", "temper", gt=0.38), c_chance(0.5), c_avail("target")],
   effects=[hold(["actor", "target"], 4.5), say("actor", "grudge_jab", to="target"), say("target", "grudge_reply", to="actor", delay=1.5)],
   outcomes=[
       out("argument", [say("actor", "grudge_escalate", to="target", delay=3.0), expr("actor", "angry", 5), expr("target", "angry", 5, delay=1.5),
                        rel("actor", "target", "friendship", -8, both=True), rel("actor", "target", "rivalry", 6, both=True), stat("arguments"),
                        rumor("argument", juicy=0.5, knowers=["actor", "target"]), witness([learn("self", "$rumor")]),
                        sfx("argue", delay=1.5), log("log.argument_grudge", 3, "conflict")],
           score=[s_trait("target", "temper", 1.2), s_stress("target", 0.01)]),
       out("walk_away", [say("target", "walk_away", to="actor", delay=3.0), log("log.cold", 1, "conflict")], score=[s_const(0.5)]),
   ])

ev(id="small_talk", trigger=["encounter", "chat", "desk_chat"], priority=10, scope="pair", cooldown=20,
   vars=[var("topic", "topic")],
   conditions=[c_avail("target")],
   effects=[call("share_board", target="target"), call("share_board", who="target", target="actor")],
   outcomes=[
       out("joke", [hold(["actor", "target"], 3.5), say("actor", "joke", to="target"), say("target", "joke_laugh", to="actor", delay=1.5),
                    rel("actor", "target", "friendship", 3, both=True), mood("target", 4)],
           score=[s_trait("actor", "humor", 1.2), s_trait("target", "humor", 0.4), s_mood("target", 0.006)], when=[c_trait("actor", "humor", gt=0.6)]),
       out("groan", [hold(["actor", "target"], 3.5), say("actor", "joke", to="target"), say("target", "joke_groan", to="actor", delay=1.5)],
           score=[s_trait("actor", "humor", 0.6), s_trait("target", "humor", -0.8), s_stress("target", 0.006)], when=[c_trait("actor", "humor", gt=0.6)]),
       out("chat", [hold(["actor", "target"], 3.5), say("actor", "topic_open", to="target"), say("target", "topic_reply", to="actor", delay=1.5),
                    rel("actor", "target", "friendship", 2, both=True)],
           score=[s_const(0.6), s_aff("target", "actor", 0.005)], when=[c_aff("target", "actor", gt=-25)]),
       out("nod", [emote("actor", "wave"), emote("target", "wave", delay=0.8), rel("actor", "target", "friendship", 1, both=True)],
           score=[s_const(0.55), s_trait("actor", "sociability", -0.4)], when=[c_aff("target", "actor", gt=-25)]),
       out("cold", [say("actor", "topic_open", to="target"), say("target", "cold_shoulder", to="actor", delay=1.4), rel("actor", "target", "friendship", -2)],
           score=[s_const(2)], when=[c_aff("target", "actor", lt=-25)]),
   ])

ev(id="coffee_gift", trigger="", priority=60, conditions=[c_avail("target")],
   effects=[hold(["actor", "target"], 3.5), say("actor", "coffee_gift_offer", to="target")],
   outcomes=[
       out("delighted", [say("target", "coffee_gift_thanks", to="actor", delay=1.5), rel("target", "actor", "friendship", 9), mood("target", 6),
                         stress("target", -5), log("log.coffee_gift", 2, "friendship")],
           score=[s_const(1.0), s_aff("target", "actor", 0.005)]),
       out("spill", [fx("spill", "target", delay=1.0), sfx("splash", delay=1.0), say("actor", "ece_spill_oops", to="target", delay=1.0),
                     say("target", "spill_forgive", to="actor", delay=2.4, when=[c_trait("target", "forgiveness", gt=0.45)]),
                     say("target", "spill_angry", to="actor", delay=2.4, when=[c_trait("target", "forgiveness", lt=0.45)]),
                     rel("target", "actor", "friendship", -5, when=[c_trait("target", "forgiveness", lt=0.45)]),
                     log("log.coffee_gift_spill", 2, "prank")],
           score=[s_trait("actor", "clumsiness", 0.9), s_rand(0.5)]),
   ])

ev(id="ceren_briefing", trigger="", priority=55, conditions=[c_avail("target")],
   vars=[var("gossip", "gossip_fact", optional=True)],
   effects=[npcflag("actor", "briefed"), hold(["actor", "target"], 3.5), say("actor", "ceren_brief", to="target"),
            say("target", "boss_brief_reply", to="actor", delay=1.5), call("share_board", target="target"), rel("target", "actor", "trust", 2)],
   outcomes=[
       out("snitch", [say("actor", "ceren_snitch", to="target", delay=3.0), learn("target", "$gossip", frm="actor"), log("log.ceren_snitch", 3, "secret")],
           score=[s_const(1)], when=[c_filled("$gossip"), c_goal("actor", "stay_informed"), c_chance(0.3)]),
       out("routine", [], score=[s_const(0.5)]),
   ])

ev(id="deniz_pitch", trigger="", priority=55, conditions=[c_avail("target")],
   vars=[var("gossip", "gossip_fact", optional=True)],
   effects=[npcflag("actor", "sucked_up"), hold(["actor", "target"], 3.5), say("actor", "deniz_suckup", to="target")],
   outcomes=[
       out("snitch", [say("actor", "deniz_snitch", to="target", delay=1.6), learn("target", "$gossip", frm="actor"), favor("actor", 3),
                      log("log.deniz_snitch", 4, "scheme")],
           score=[s_const(1.5)], when=[c_filled("$gossip"), c_chance(0.4)]),
       out("works", [say("target", "boss_pleased", to="actor", delay=1.6), favor("actor", 5)],
           score=[s_rel("target", "actor", "trust", 0.02), s_mood("target", 0.01), s_rand(0.5)]),
       out("annoyed", [say("target", "boss_too_ambitious", to="actor", delay=1.6), favor("actor", -2)],
           score=[s_rel("target", "actor", "rivalry", 0.03), s_trait("target", "temper", 0.4)]),
   ])

ev(id="manager_check", trigger="patrol_check", priority=50, scope="pair", cooldown=60,
   conditions=[c_avail("target")],
   outcomes=[
       out("praise", [hold(["actor", "target"], 3), say("actor", "boss_check_good", to="target"), say("target", "thanks_boss", to="actor", delay=1.4),
                      favor("target", 3), rel("target", "actor", "friendship", 3), stat("praises"),
                      mem("target", "actor", "praised", 0.4, 0.6, "mem.boss_praised", 2), log("log.boss_praise", 1, "boss")],
           score=[s_rel("actor", "target", "trust", 0.02), s_trait("target", "diligence", 0.8)], when=[c_act("target", ["work"])]),
       out("scold_idle", [hold(["actor", "target"], 3.5), say("actor", "boss_check_idle", to="target"), say("target", "idle_excuse", to="actor", delay=1.4),
                          stress("target", 8), favor("target", -3), stat("scoldings"),
                          mem("target", "actor", "scolded", -0.4, 0.6, "mem.scolded_idle", 2), log("log.boss_idle_scold", 2, "boss")],
           score=[s_trait("actor", "temper", 1.0), s_stress("actor", 0.01), s_const(0.3)],
           when=[c_act("target", ["coffee", "chat", "water", "rest", "wander", "phone"]), c_is("target", in_=["ece", "ceren"], neg=True)]),
       out("nag", [hold(["actor", "target"], 3), say("actor", "boss_check_nag", to="target"), say("target", "yes_boss", to="actor", delay=1.4),
                   stress("target", 3)], score=[s_const(0.4)]),
   ])

ev(id="workload_vent", trigger="stressed", priority=40, scope="actor", cooldown=70,
   roles=[role("listener", where=[c_avail("self")], score=[s_aff("actor", "self", 0.02), s_dist("actor", "self", -0.1)], exclude=["actor"],
               near="actor", r=5.5)],
   effects=[hold(["actor", "listener"], 3.5), say("actor", "stress_vent", to="listener")],
   outcomes=[
       out("comfort", [say("listener", "comfort", to="actor", delay=1.5), rel("actor", "listener", "friendship", 5, both=True),
                       stress("actor", -10), log("log.vent_comfort", 1, "friendship")],
           score=[s_trait("listener", "empathy", 1.2), s_aff("listener", "actor", 0.01)]),
       out("not_now", [say("listener", "not_now", to="actor", delay=1.5), rel("actor", "listener", "friendship", -3)],
           score=[s_stress("listener", 0.012), s_trait("listener", "empathy", -0.5), s_const(0.3)]),
   ])

ev(id="unexpected_solidarity", trigger="deadline_near", priority=60, scope="actor", cooldown=240,
   roles=[role("helper", where=[c_avail("self"), c_is("self", "ahmet", neg=True)],
               score=[s_trait("self", "empathy", 1.2), s_trait("self", "diligence", 0.4), s_rel("self", "actor", "friendship", 0.005), s_rand(0.5)],
               exclude=["actor"], optional=True)],
   effects=[say("actor", "deadline_panic"), emote("actor", "sweat"), stress("actor", 10)],
   outcomes=[
       out("help", [intent("helper", "go_npc", target="actor", event="solidarity_help", prio=52, ttl=40)],
           score=[s_const(1)], when=[c_present("helper"), c_trait("helper", "empathy", gt=0.42), c_chance(0.65)]),
       out("alone", [say("actor", "deadline_alone", delay=1.4)], score=[s_const(0.2)]),
   ])

ev(id="solidarity_help", trigger="", priority=70, conditions=[c_avail("target")],
   effects=[hold(["actor", "target"], 4.5), say("actor", "offer_help_work", to="target"), say("target", "accept_help_work", to="actor", delay=1.5),
            work("target", 18), rel("target", "actor", "trust", 12), mem("target", "actor", "helped_deadline", 0.8, 0.9, "mem.helped_deadline", 3),
            stat("helps")],
   outcomes=[
       out("unexpected", [rel("target", "actor", "friendship", 20), rel("actor", "target", "friendship", 8), log("log.unexpected_help", 3, "solidarity")],
           score=[s_const(2)], when=[c_rel("target", "actor", "friendship", lt=18)]),
       out("friendly", [rel("target", "actor", "friendship", 10), log("log.help_deadline", 2, "solidarity")], score=[s_const(1)]),
   ])

ev(id="deadline_missed", trigger="task_missed", priority=50,
   effects=[say("actor", "deadline_missed_line"), stress("actor", 8), mood("actor", -10), favor("actor", -6),
            call("scold", target="actor", reason="deadline", prio=55, when=[c_present("@ahmet"), c_chance(0.6)]),
            log("log.deadline_missed", 2, "work")])

ev(id="late_to_work", trigger="late_to_work", priority=50,
   effects=[emote("actor", "sweat"), say("actor", "late_morning")],
   outcomes=[
       out("boss_sees", [say("@ahmet", "boss_late_morning", delay=1.6), stat("late_arrivals"), favor("actor", -3),
                         mem("actor", "@ahmet", "scolded", -0.3, 0.5, "mem.late_morning", 2), log("log.late_morning", 2, "boss")],
           score=[s_const(1)], when=[c_present("@ahmet"), c_is("actor", "ahmet", neg=True), c_chance(0.7)]),
       out("sneak", [log("log.sneak_in", 1, "boss")], score=[s_const(0.2)]),
   ])

ev(id="office_ghost_theory", trigger="tick", priority=35, max_day=1,
   roles=[role("actor", where=[c_avail("self")], score=[s_trait("self", "curiosity", 1.0), s_rand(0.3)], exclude=[]),
          role("target", where=[c_avail("self")], score=[s_dist("actor", "self", -0.2), s_rand(0.3)], exclude=["actor"], near="actor", r=6)],
   conditions=[{"c": "ghost", "gte": 4}],
   effects=[hold(["actor", "target"], 4.5), say("actor", "ghost_theory", to="target"), say("target", "ghost_reply", to="actor", delay=1.6),
            emote("target", "sweat", delay=1.6), call("ghost_theory"), rumor("haunted", juicy=0.4, knowers=["actor", "target"]),
            log("log.ghost_theory", 3, "ghost")])

ev(id="clique_lunch", trigger="lunch_start", priority=30, allow_absent=True,
   effects=[call("cliques", delay=8)])
