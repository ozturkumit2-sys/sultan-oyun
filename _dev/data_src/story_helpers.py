# Extra authoring helpers for the living-office story layer (initiative events,
# story arcs, beliefs, bonds). Builds on the helpers in events.py.
from events import *          # noqa: F401,F403  (say, rel, role, c_*, s_* ...)
from events import E, ev      # noqa: F401
from dialogue_en import L     # noqa: F401
from lang_en import s as S_   # noqa: F401

TIERS = ("small", "medium", "big")

# ---------------------------------------------------------------- effects
def debunk(fact="$rumor", who=None, by="actor", when=None):
    r = {"e": "debunk", "fact": fact, "who": who or [], "by": by}
    if when: r["when"] = when
    return r

def distort(fact="$gossip", who="actor", p=1.0, key="gossip"):
    return {"e": "distort", "fact": fact, "who": who, "p": p, "key": key}

def forget(who, fact):
    return {"e": "forget", "who": who, "fact": fact}

def bond(a, b, kind, v=True, when=None):
    r = {"e": "bond", "a": a, "b": b, "kind": kind, "v": v}
    if when: r["when"] = when
    return r

def plan(who, kind, target="", v=True, heat=1.0, when=None):
    r = {"e": "plan", "who": who, "kind": kind, "target": target, "v": v, "heat": heat}
    if when: r["when"] = when
    return r

def morale(who, d, when=None):
    r = {"e": "morale", "who": who, "d": d}
    if when: r["when"] = when
    return r

def arc_start(arc, cast, vars=None, stage="", when=None, force=False):
    r = {"e": "arc_start", "arc": arc, "cast": cast, "vars": vars or {}}
    if stage: r["stage"] = stage
    if when: r["when"] = when
    if force: r["force"] = True
    return r

def arc_next(stage, wait=None, days=0, when=None):
    r = {"e": "arc_next", "stage": stage}
    if wait: r["wait"] = wait
    if days: r["days"] = days
    if when: r["when"] = when
    return r

def arc_end(result, when=None):
    r = {"e": "arc_end", "result": result}
    if when: r["when"] = when
    return r

def meetup(event, who=("actor", "target"), area="kitchen", roles=None, ttl=40, need=0, prio=58, when=None, delay=0):
    r = {"e": "meetup", "who": list(who), "area": area, "event": event, "ttl": ttl, "prio": prio}
    if roles: r["roles"] = roles
    if need: r["need"] = need
    if when: r["when"] = when
    if delay: r["delay"] = delay
    return r

def away(who, minutes, reason, when=None, delay=0):
    r = {"e": "away", "who": who, "minutes": minutes, "reason": reason}
    if when: r["when"] = when
    if delay: r["delay"] = delay
    return r

def visit(who, target, event, prio=60, ttl=60, roles=None, delay=0, when=None):
    return intent(who, "go_npc", target=target, event=event, prio=prio, ttl=ttl, roles=roles, delay=delay, when=when)

def go_desk(who, owner, event, prio=58, ttl=60, roles=None, delay=0, when=None):
    return intent(who, "go_desk", target=owner, event=event, prio=prio, ttl=ttl, roles=roles, delay=delay, when=when)

def go_place(who, place, event, prio=58, ttl=50, roles=None, delay=0, when=None, dur=4):
    return intent(who, "go_place", place=place, event=event, prio=prio, ttl=ttl, roles=roles, delay=delay, when=when, dur=dur)

def trigger(name, roles=None, vars=None, delay=0, when=None):
    r = {"e": "trigger", "name": name, "roles": roles or {"actor": "actor", "target": "target"}}
    if vars: r["vars"] = vars
    if delay: r["delay"] = delay
    if when: r["when"] = when
    return r

def act(who, a, place="", obj="", dur=6, target=""):
    r = {"e": "act", "who": who, "act": a, "dur": dur}
    if place: r["place"] = place
    if obj: r["obj"] = obj
    if target: r["target"] = target
    return r

def setv(key, v):
    return {"e": "set", "key": key, "v": v}

def special(fn, **kw):
    return call(fn, **kw)

# ---------------------------------------------------------------- conditions
def c_sure(who, fact, gt=None, lt=None, neg=False):
    c = {"c": "sure", "who": who, "fact": fact}
    if gt is not None: c["gt"] = gt
    if lt is not None: c["lt"] = lt
    if neg: c["not"] = True
    return c

def c_truth(fact, eq=True):
    return {"c": "truth", "fact": fact, "eq": eq}

def c_bond(a, b, kind, neg=False):
    c = {"c": "bond", "a": a, "b": b, "kind": kind}
    if neg: c["not"] = True
    return c

def c_plan(who, kind, target=None, neg=False):
    c = {"c": "plan", "who": who, "kind": kind}
    if target: c["target"] = target
    if neg: c["not"] = True
    return c

def c_morale(who, gt=None, lt=None):
    c = {"c": "morale", "who": who}
    if gt is not None: c["gt"] = gt
    if lt is not None: c["lt"] = lt
    return c

def c_fired(event, days=0, neg=False):
    c = {"c": "fired", "event": event, "days": days}
    if neg: c["not"] = True
    return c

def c_result(arc, result, days=99, neg=False):
    c = {"c": "result", "arc": arc, "result": result, "days": days}
    if neg: c["not"] = True
    return c

def c_story(who, lt=None, gt=None):
    c = {"c": "in_story", "who": who}
    if lt is not None: c["lt"] = lt
    if gt is not None: c["gt"] = gt
    return c

def c_zone(who, zones, neg=False):
    c = {"c": "zone", "who": who, "in": zones}
    if neg: c["not"] = True
    return c

def c_day(gte=None, lte=None):
    c = {"c": "day"}
    if gte is not None: c["gte"] = gte
    if lte is not None: c["lte"] = lte
    return c

def c_same(a, b, neg=False):
    c = {"c": "same", "a": a, "b": b}
    if neg: c["not"] = True
    return c

def c_dayflag_eq(key, v):
    return {"c": "dayflag", "key": key, "eq": v}

def c_work_left(who, gt=None, lt=None):
    c = {"c": "work_left", "who": who}
    if gt is not None: c["gt"] = gt
    if lt is not None: c["lt"] = lt
    return c

def c_meeting(key, eq=True):
    return {"c": "meeting", "key": key, "eq": eq}

# ---------------------------------------------------------------- score terms
def s_morale(who, w): return {"s": "morale", "who": who, "w": w}
def s_plan(who, kind, v=1.0, target=None):
    d = {"s": "plan", "who": who, "kind": kind, "v": v}
    if target: d["target"] = target
    return d
def s_bond(a, b, kind, v=1.0): return {"s": "bond", "a": a, "b": b, "kind": kind, "v": v}
def s_sure(who, fact, w): return {"s": "sure", "who": who, "fact": fact, "w": w}
def s_busy(who, w): return {"s": "busy", "who": who, "w": w}

# ---------------------------------------------------------------- roles
def actor(where=None, score=None):
    """The person who takes the initiative (picked by the StoryDirector)."""
    return role("actor", where=[c_avail("self")] + (where or []), score=score or [], exclude=[])

def by_fn(name, fn, where=None, optional=False, avail=True, exclude=None, **kw):
    return role(name, where=where or [], fn=fn, optional=optional, avail=avail, exclude=exclude, **kw)

def initiative(id, tier, roles, effects=None, outcomes=None, conditions=None, vars=None, cooldown=None,
               cooldown_days=None, scope="actor", max_day=None, priority=50, **kw):
    """An event a character starts on their own. `tier` drives the day's pacing."""
    d = dict(id=id, trigger="initiative", tier=tier, priority=priority, roles=roles, scope=scope)
    if effects: d["effects"] = effects
    if outcomes: d["outcomes"] = outcomes
    if conditions: d["conditions"] = conditions
    if vars: d["vars"] = vars
    if cooldown: d["cooldown"] = cooldown
    if cooldown_days: d["cooldown_days"] = cooldown_days
    if max_day: d["max_day"] = max_day
    d.update(kw)
    ev(**d)

def scene(id, effects=None, outcomes=None, conditions=None, roles=None, vars=None, priority=70, allow_absent=False, **kw):
    """The part of an event that plays once people have walked to each other."""
    d = dict(id=id, trigger="", priority=priority)
    if effects: d["effects"] = effects
    if outcomes: d["outcomes"] = outcomes
    if conditions: d["conditions"] = conditions
    if roles: d["roles"] = roles
    if vars: d["vars"] = vars
    if allow_absent: d["allow_absent"] = True
    d.update(kw)
    ev(**d)

# ---------------------------------------------------------------- story arcs
A = []
def arc(id, tier, first, stages, cooldown_days=3, max_active=1, cast=None):
    """A multi-stage story. Each stage plays an event; the event's outcome picks
    the next stage (arc_next), a detour, or the ending (arc_end)."""
    A.append({"id": id, "tier": tier, "first": first, "stages": stages, "cooldown_days": cooldown_days,
              "max_active": max_active, "cast": cast or []})

def stage(event, mode="now", actor="actor", target="", wait=(2, 10), ttl=90, window=None, fail="end:fizzled",
          area="", place="", prio=62, who=None, need=0, fail_log="", default_end="done", must=None):
    st = {"event": event, "mode": mode, "actor": actor, "wait": list(wait), "ttl": ttl, "fail": fail, "prio": prio,
          "default_end": default_end}
    if target: st["target"] = target
    if window: st["window"] = list(window)
    if area: st["area"] = area
    if place: st["place"] = place
    if who: st["who"] = who
    if need: st["need"] = need
    if must: st["must"] = list(must)
    if fail_log: st["fail_log"] = fail_log
    return st
