# Authoring helpers for the intervention database -> data/interventions.json
#
# An intervention = the object it lives on (+ tab for desks), activation conditions
# (each may say WHY it is unavailable), the real state change it makes, the
# reaction it sets up (usually a latent "trap": the consequence plays when someone
# runs into it), reuse rules and the log line. Reaction scenes are ordinary events.
from story_helpers import *  # noqa: F401,F403
from story_helpers import S_, L, ev, E  # noqa: F401
import lang_en

import dialogue_en as _dlg

# Guarded string/dialogue registration: intervention content must never overwrite
# an existing key (that would silently change an older event's text).
def S_(k, v):
    if k in lang_en.S and lang_en.S[k] != v:
        raise SystemExit("string key already used elsewhere: " + k)
    lang_en.S[k] = v

def L(key, generic=None, **per):
    if key in _dlg.D:
        raise SystemExit("dialogue key already used elsewhere: " + key)
    _dlg.L(key, generic, **per)

IV = []
CATS = {"A": "Computers & digital", "B": "Email & messages", "C": "Meetings & calendar", "D": "Documents & paperwork",
        "E": "Career, promotion & pay", "F": "Phones & calls", "G": "Kitchen & coffee", "H": "Equipment & environment",
        "I": "Social & gossip", "J": "Hidden combinations"}


def _s(k, v):
    S_(k, v)


def iv(id, key, cat, obj, title, desc, log=None, tab="", needs="", choices=None, pick=None, conds=None, state=None,
       react=None, reuse=None, hidden=False, combo=None, owners=None, vars=None, icon="", imp=2, watch=None, test=None,
       legacy="", absent_ok=False, owner_present=None, why=None, sfx="meddle", arc=""):
    """Register one intervention. `title`/`desc`/`log` are English UI strings."""
    d = {"id": id, "key": key, "cat": cat, "obj": obj, "name": ("act." + legacy) if legacy else ("iv." + key)}
    if not legacy:
        _s("iv." + key, title)
        _s("iv.%s.d" % key, desc)
    if tab: d["tab"] = tab
    if needs: d["needs"] = needs
    if choices: d["choices"] = choices
    if pick: d["pick"] = pick
    if conds: d["conds"] = conds
    if state: d["state"] = state
    if react: d["react"] = react
    d["reuse"] = reuse if reuse is not None else {"cool": 120, "day": 1}
    if hidden: d["hidden"] = True
    if combo: d["combo"] = combo
    if owners: d["owners"] = owners
    if vars: d["vars"] = vars
    if icon: d["icon"] = icon
    if imp != 2: d["imp"] = imp
    if watch: d["watch"] = watch
    if test: d["test"] = test
    if legacy: d["legacy"] = legacy
    if absent_ok: d["absent_ok"] = True
    if owner_present is not None: d["owner_present"] = owner_present
    if why: d["why"] = why
    if sfx != "meddle": d["sfx"] = sfx
    if arc: d["arc"] = arc          # the story this (hidden) intervention sets off
    if log:
        _s("log.iv." + key, log)
        d["log"] = "log.iv." + key
    IV.append(d)
    return d


def choice(v, label):
    k = "opt.iv." + str(v)
    if k not in lang_en.S:
        _s(k, label)
    return {"v": v, "label": k}


def why(cond, key, text=None):
    """Attach the reason shown when this condition blocks an intervention."""
    c = dict(cond)
    c["why"] = "why." + key
    if text and ("why." + key) not in lang_en.S:
        _s("why." + key, text)
    return c


# ---------------------------------------------------------------- effects
def trap(event, place="", who=None, not_=None, key="", uses=1, days=0, after=None, kind="place", on="", r=None,
         pair=None, spot=None, as_="actor", roles=None, replace=False, when=None):
    t = {"e": "trap", "kind": kind, "event": event, "uses": uses, "days": days, "as": as_}
    if replace: t["replace"] = True
    if when: t["when"] = when
    if place: t["place"] = place
    if who is not None: t["who"] = who
    if not_ is not None: t["not"] = not_
    if key: t["key"] = key
    if after is not None: t["after"] = after
    if on: t["on"] = on
    if r is not None: t["r"] = r
    if pair: t["pair"] = pair
    if spot is not None: t["spot"] = spot
    if roles is not None: t["roles"] = roles
    return t

def desk_trap(event, key, **kw):
    """Plays when the desk owner next sits down at their desk."""
    return trap(event, place="desk_{owner}", who="owner", key=key, **kw)

def on_trap(trigger, event, who=None, key="", days=0, uses=1, **kw):
    return trap(event, kind="on", on=trigger, who=who, key=key, days=days, uses=uses, **kw)


def private_vars(of="owner"):
    """Pickers for 'something private about X' (a real secret, a crush, or who they can't stand)."""
    return [var("secret", "secret_about", knower=of, about=of, optional=True),
            var("crush", "crush_of", of=of, optional=True),
            var("worst", "worst_of", of=of, lim=99, avail=False, optional=True)]


def private_info(of="owner", truth=True):
    """Effects that put X's private thing into $fact (a secret, or a fresh rumour)."""
    no_secret = {"c": "rolefilled", "who": "$secret", "not": True}
    return [setv("fact", "$secret"),
            rumor("crush", a=of, b="$crush", juicy=0.7, truth=truth, knowers=[], key="fact", when=[no_secret, c_filled("$crush")]),
            rumor("dislikes", a=of, b="$worst", juicy=0.6, truth=truth, knowers=[], key="fact",
                  when=[no_secret, {"c": "rolefilled", "who": "$crush", "not": True}, c_filled("$worst")])]

def near_trap(event, place, not_=None, key="", r=1.9, days=0, **kw):
    return trap(event, kind="near", place=place, not_=not_, key=key, r=r, days=days, **kw)

def pair_trap(event, a, b, key="", days=0, r=2.4, **kw):
    return trap(event, kind="pair", pair=[a, b], key=key, days=days, r=r, **kw)

def untrap(key):
    return {"e": "untrap", "key": key}

def oset(path, v=True, add=None, when=None, delay=0):
    d = {"e": "oset", "path": path, "v": v}
    if add is not None: d["add"] = add
    if when: d["when"] = when
    if delay: d["delay"] = delay
    return d

def pin(kind, about="target", by=""):
    return {"e": "pin", "kind": kind, "about": about, "by": by}

def unpin(kind):
    return {"e": "unpin", "kind": kind}

def mtg(key, v=True, who=None, d=None, delay=0, when=None):
    e = {"e": "meeting", "key": key, "v": v}
    if who: e["who"] = who
    if d is not None: e["d"] = d
    if delay: e["delay"] = delay
    if when: e["when"] = when
    return e

def npcval(who, key, v=None, d=None, delay=0, when=None):
    e = {"e": "npcval", "who": who, "key": key}
    if v is not None: e["v"] = v
    if d is not None: e["d"] = d
    if delay: e["delay"] = delay
    if when: e["when"] = when
    return e

def hunt(who, stops, event, prio=64, ttl=80, roles=None, delay=0, when=None):
    e = {"e": "hunt", "who": who, "stops": stops, "event": event, "prio": prio, "ttl": ttl}
    if roles: e["roles"] = roles
    if delay: e["delay"] = delay
    if when: e["when"] = when
    return e

def item_to(item, to):
    return {"e": "item_to", "item": item, "to": to}

def spotfx(spot):
    return {"e": "spotfx", "spot": spot}

def summon(who, event, prio=72, delay=0, when=None):
    """Ahmet calls someone into his office; `event` plays when they get there."""
    return call("summon", target=who, event=event, prio=prio, delay=delay, when=when)

def later(effects, delay):
    out = []
    for e in effects:
        e2 = dict(e)
        e2["delay"] = e2.get("delay", 0) + delay
        out.append(e2)
    return out


# ---------------------------------------------------------------- conditions
def c_os(path, eq=None, neg=False, gt=None, lt=None):
    c = {"c": "ostate", "path": path}
    if eq is not None: c["eq"] = eq
    if gt is not None: c["gt"] = gt
    if lt is not None: c["lt"] = lt
    if neg: c["not"] = True
    return c

def c_iv(id, days=0, same=None, neg=False):
    c = {"c": "iv", "id": id, "days": days}
    if same: c["same"] = same
    if neg: c["not"] = True
    return c

def c_trapk(key, neg=False):
    c = {"c": "trap", "key": key}
    if neg: c["not"] = True
    return c

def c_busy_meeting(who, neg=True):
    c = {"c": "in_meeting", "who": who}
    if neg: c["not"] = True
    return c

def c_pinned(kind, neg=False):
    c = {"c": "pins", "kind": kind}
    if neg: c["not"] = True
    return c


# ---------------------------------------------------------------- common reasons
def r_present(who="owner"):
    return why(c_present(who), "absent", "They're not in the office right now.")

def r_time(after=None, before=None, key="too_late", text="Too late in the day for that."):
    return why(c_time(after, before), key, text)

def r_meeting_pending():
    return why(c_meeting("ended", False), "meeting_over", "Today's meeting is already over.")

def r_meeting_not_started():
    return why(c_meeting("started", False), "meeting_started", "The meeting has already started.")
