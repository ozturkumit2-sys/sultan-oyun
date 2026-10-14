# Reusable reaction mechanics for interventions. Every intervention has its own
# discovery scene (own lines, own log, own consequences); these shared scenes and
# outcome builders are the follow-ups people choose between depending on who they
# are: blame someone, suspect a ghost, call IT, keep a secret, spread it, confront
# the person it's about, tell the boss, thank the wrong person...
from iv_helpers import *  # noqa: F401,F403


# ---- in intervention scenes, follow-ups carry the whole cast (owner, target, friend...)
import story_helpers as _sh
import events as _ev


def chain(event, delay=0, roles=None, when=None):
    r = _ev.chain(event, delay=delay, roles=roles, when=when)
    r["all"] = True
    return r


def visit(who, target, event, prio=60, ttl=60, roles=None, delay=0, when=None):
    r = _sh.visit(who, target, event, prio=prio, ttl=ttl, roles=roles, delay=delay, when=when)
    r["all"] = True
    return r


def meetup(event, who=("actor", "target"), area="kitchen", roles=None, ttl=40, need=0, prio=58, when=None, delay=0):
    r = _sh.meetup(event, who=who, area=area, roles=roles, ttl=ttl, need=need, prio=prio, when=when, delay=delay)
    r["all"] = True
    return r


def pick_role(role, fn, keep=False, **kw):
    """Fill a role when the intervention is applied (after the player picked a target)."""
    d = {"e": "call", "fn": "pick_role", "role": role, "pfn": fn}
    if keep: d["keep"] = True
    d.update(kw)
    return d


def setf(key, f):
    return {"e": "set", "key": key, "f": f}

def what(k, text):
    """A noun phrase usable as {what} in lines ("the flowers", "your report")."""
    if ("what." + k) not in lang_en.S:
        S_("what." + k, text)
    return k


# =====================================================================
# Accusing the wrong person (the ghost did it — but people blame each other)
# =====================================================================
L("ivm_who", ["Okay. Who did this?", "Somebody did this on purpose.", "Who's been messing with my stuff?!"],
  selin=["Someone is sabotaging me. Again."], ahmet=["WHO is responsible for this?"], burak=["This wasn't a bug. This was a person."],
  ece=["Did... did I do this? No. Someone else did this."], mert=["Alright, prankster. Show yourself."])
L("ivm_blame", ["This has {suspect} written all over it.", "I bet it was {suspect}.", "{suspect}. It's always {suspect}."],
  selin=["I know exactly who did this. {suspect}."], zeynep=["Oh, I have a theory. Her name— his name is {suspect}."], deniz=["{suspect} wants me to slip up. Cute."])
L("ivm_accuse", ["{target}. Was that you? Be honest.", "Okay {target}, joke's over. Was it you?", "I know it was you, {target}."],
  selin=["{target}, I'd like an explanation. Now."], ahmet=["{target}! My office would be a good place to confess."], burak=["{target}. Logs don't lie. Neither should you."],
  ece=["{target}... um... was it you? Sorry for asking!"])
L("ivm_innocent", ["What? I didn't touch anything!", "Me?! I've been at my desk all day!", "Why does everybody always blame me?"],
  mert=["I'd LOVE to take credit for that, but no."], deniz=["Please. If it were me, you'd never find out."], ece=["It wasn't me! I swear on my coffee!"],
  zeynep=["Darling, I only TALK about pranks."], burak=["I have better things to do. Like literally anything."])
L("ivm_accuse_argue", ["Don't lie to me.", "Sure. And I'm the CEO.", "Unbelievable."], selin=["You're lying, and we both know it."])
L("ivm_accuse_sorry", ["...Okay. Maybe it wasn't you. Sorry.", "Fine. My mistake.", "Then who on earth...?"])
L("ivm_accuse_laugh", ["Ha! Okay, okay. Truce?", "Fine. But I'm watching you.", "If it wasn't you, I owe you a coffee."])
S_("log.ivm_accuse_fight", "{actor} accused {target} of the prank. {target} swears they're innocent — the argument got loud.")
S_("log.ivm_accuse_sorry", "{actor} accused {target} of the prank, then believed them. Awkward, but fine.")
S_("log.ivm_accuse_laugh", "{actor} accused {target} of the prank. They ended up laughing about it.")
S_("mem.ivm_falsely_accused", "{actor} accused me of something I didn't do.")
S_("mem.ivm_suspect", "I'm fairly sure {suspect} messed with my things.")

scene("ivm_accuse", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), expr("actor", "angry", 5), say("actor", "ivm_accuse", to="target"),
               say("target", "ivm_innocent", to="actor", delay=1.6), emote("target", "question", delay=1.6),
               mem("target", "actor", "falsely_accused", -0.5, 0.8, "mem.ivm_falsely_accused", 2),
               rel("target", "actor", "resentment", 10), rel("target", "actor", "trust", -6)],
      outcomes=[
          out("argue", [say("actor", "ivm_accuse_argue", to="target", delay=3.2), sfx("argue", delay=3.2), stat("arguments"),
                        rel("actor", "target", "friendship", -8, both=True), rel("actor", "target", "suspicion", 12),
                        rumor("argument", juicy=0.45, knowers=["actor", "target"]), witness([learn("self", "$rumor")]),
                        plan("target", "revenge", "actor", heat=0.6, when=[c_trait("target", "forgiveness", lt=0.45)]),
                        log("log.ivm_accuse_fight", 3, "conflict")],
              score=[s_trait("actor", "temper", 1.2), s_rel("actor", "target", "suspicion", 0.02), s_rel("actor", "target", "rivalry", 0.015)]),
          out("believe", [say("actor", "ivm_accuse_sorry", to="target", delay=3.2), rel("actor", "target", "suspicion", -15),
                          rel("actor", "target", "trust", 2), log("log.ivm_accuse_sorry", 2, "misunderstanding")],
              score=[s_trait("actor", "empathy", 0.9), s_trait("actor", "forgiveness", 0.6), s_rel("actor", "target", "trust", 0.015), s_const(0.2)]),
          out("laugh", [say("actor", "ivm_accuse_laugh", to="target", delay=3.2), rel("actor", "target", "friendship", 3, both=True),
                        rel("actor", "target", "suspicion", -8), log("log.ivm_accuse_laugh", 2, "friendship")],
              score=[s_trait("actor", "humor", 1.0), s_trait("target", "humor", 0.5)], when=[c_trait("actor", "humor", gt=0.5)]),
      ])


# =====================================================================
# Calling IT (Burak) to fix something the ghost broke
# =====================================================================
L("ivm_it_ask", ["{target}, something's wrong with my computer. Help?", "{target}! Emergency. Tech emergency.", "Can you look at my machine? It's possessed."],
  ahmet=["{target}. My computer. Now."], selin=["{target}, I'm on a deadline and my PC just betrayed me."], ece=["{target}, I think I broke the internet. Again."],
  mert=["{target}, my favourite genius. I have a tiny problem."])
L("ivm_it_yes", ["Give me two minutes.", "Move over. Let me see.", "Okay, okay. I'm on it."], burak=["*sigh* Turn it off and— never mind. I'll do it."])
L("ivm_it_grumble", ["Open a ticket.", "After lunch. Maybe.", "Have you tried turning it off and on?"], burak=["I'm one person, people.", "Ticket. Queue. Patience."])
L("ivm_it_sabotage", ["That's not a glitch. Someone did this on purpose.", "Interesting. This was done by hand.", "Somebody's been at your keyboard."],
  burak=["This wasn't an accident. Someone touched your machine."])
L("ivm_it_thanks", ["You're a lifesaver.", "Thank you!!", "I owe you one."], mert=["I owe you a kebab. Two kebabs."])
S_("log.ivm_it_fixed", "{target} fixed {actor}'s computer problem in two minutes flat.")
S_("log.ivm_it_grumble", "{actor} asked {target} for tech help and got told to open a ticket.")
S_("log.ivm_it_sabotage", "{target} looked at {actor}'s computer: \"Someone did this on purpose.\" Now {actor} is suspicious.")
S_("mem.ivm_it_helped", "{target} rescued my computer.")

scene("ivm_it_fix", noise=0.7, conditions=[c_avail("target")],
      vars=[var("suspect", "suspect", desk=True, optional=True)],
      effects=[hold(["actor", "target"], 4.5), say("actor", "ivm_it_ask", to="target")],
      outcomes=[
          out("fix", [say("target", "ivm_it_yes", to="actor", delay=1.6), emote("target", "ok", delay=1.6), oset("{fixpath}", False),
                      say("actor", "ivm_it_thanks", to="target", delay=3.2), rel("actor", "target", "friendship", 5), rel("actor", "target", "respect", 6),
                      mem("actor", "target", "helped_me", 0.5, 0.7, "mem.ivm_it_helped", 2), stat("helps"), log("log.ivm_it_fixed", 2, "help")],
              score=[s_trait("target", "empathy", 0.8), s_aff("target", "actor", 0.02), s_trait("target", "diligence", 0.4), s_const(0.3)]),
          out("grumble", [say("target", "ivm_it_grumble", to="actor", delay=1.6), oset("{fixpath}", False, delay=14), mood("actor", -4),
                          rel("actor", "target", "friendship", -3), log("log.ivm_it_grumble", 1, "work")],
              score=[s_stress("target", 0.015), s_goal("target", "find_new_job", 0.5), s_aff("target", "actor", -0.01), s_const(0.2)]),
          out("sabotage", [say("target", "ivm_it_sabotage", to="actor", delay=1.6), oset("{fixpath}", False), emote("actor", "exclaim", delay=2.6),
                           rel("actor", "target", "respect", 5), rel("actor", "$suspect", "suspicion", 15, when=[c_filled("$suspect")]),
                           mem("actor", "$suspect", "suspect_prank", -0.4, 0.7, "mem.ivm_suspect", 2, when=[c_filled("$suspect")]),
                           log("log.ivm_it_sabotage", 3, "prank")],
              score=[s_trait("target", "curiosity", 0.8), s_trait("target", "honesty", 0.4), s_const(0.1)]),
      ])


# =====================================================================
# Holding a secret: keep it, spread it, ask the person, or tell the boss
# =====================================================================
L("ivm_keep", ["...I didn't see that. I didn't see anything.", "Not my business. Not my business.", "I'll keep that to myself."],
  ceren=["Some things are better left unsaid."], burak=["Noted. Deleted. Moving on."], ece=["My lips are sealed! ...Mostly sealed."])
L("ivm_ask_think", ["I should just ask {subject} if it's true.", "Is that even true? I'll ask {subject}.", "Better hear it from {subject} directly."])
L("ivm_juicy", ["Oh. Oh my.", "Well, well, well.", "Wait till people hear THIS."], zeynep=["Christmas came early!"], deniz=["Interesting. Very interesting."])
L("ivm_tattle", ["Ahmet Bey, I think you should know something.", "Ahmet Bey, got a minute? It's about {subject}.", "I don't like telling tales, but... {gossip}"],
  deniz=["I hate to be the one to tell you, Ahmet Bey... {gossip}"], selin=["Ahmet Bey, this affects the team: {gossip}"])
L("ivm_boss_cares", ["Is that so? I'll be keeping an eye on {subject}.", "Thank you for telling me.", "Hm. That's... very useful to know."])
L("ivm_boss_tattle_no", ["I don't run a playground. Back to work.", "Office gossip doesn't interest me.", "And why are you telling me this?"])
S_("log.ivm_keep", "{actor} found out something about {subject} — and quietly decided to keep it.")
S_("log.ivm_spread_start", "{actor} found out something about {subject}. It's too good not to share.")
S_("log.ivm_tattle", "{actor} went straight to Ahmet about {subject}. Ahmet listened.")
S_("log.ivm_tattle_no", "{actor} went to Ahmet about {subject}. Ahmet wasn't interested in tattling.")
S_("mem.ivm_kept_secret", "I kept {subject}'s secret.")
S_("mem.ivm_tattled", "{actor} ran to Ahmet about me.")

scene("ivm_secret", noise=0.9, allow_absent=True, conditions=[c_present("actor")],
      vars=[var("subject", "rumor_subject", fact="$fact")],
      effects=[emote("actor", "exclaim"), setv("gossip", "$fact")],
      outcomes=[
          out("keep", [say("actor", "ivm_keep"), mem("actor", "$subject", "kept_secret", 0.2, 0.6, "mem.ivm_kept_secret", 2), rel("actor", "$subject", "trust", 4),
                       log("log.ivm_keep", 2, "secret", who=["actor", "$subject"])],
              score=[s_rel("actor", "$subject", "trust", 0.025), s_rel("actor", "$subject", "friendship", 0.015), s_trait("actor", "honesty", 0.6),
                     s_trait("actor", "gossip", -1.0), s_const(0.2)]),
          out("spread", [say("actor", "ivm_juicy"), log("log.ivm_spread_start", 2, "rumor", who=["actor", "$subject"]), chain("ivm_spread", delay=2)],
              score=[s_trait("actor", "gossip", 1.4), s_rel("actor", "$subject", "resentment", 0.015), s_rel("actor", "$subject", "friendship", -0.01)]),
          out("ask", [say("actor", "ivm_ask_think"), visit("actor", "$subject", "rumor_check_scene", prio=58, ttl=50, delay=2)],
              score=[s_trait("actor", "honesty", 0.8), s_aff("actor", "$subject", 0.012), s_const(0.1)],
              when=[c_present("$subject"), c_truth("$fact", False), c_not(c_same("actor", "$subject"))]),
          out("tattle", [say("actor", "ivm_juicy"), visit("actor", "@ahmet", "ivm_tell_boss", prio=58, ttl=60, delay=2, roles={"subject": "$subject"})],
              score=[s_rel("actor", "$subject", "rivalry", 0.03), s_trait("actor", "cunning", 0.6), s_goal("actor", "earn_promotion", 0.4)],
              when=[c_present("@ahmet"), c_is("$subject", "ahmet", neg=True), c_is("actor", "ahmet", neg=True), c_rel("actor", "$subject", "rivalry", gt=30)]),
      ])

ev(id="ivm_spread", trigger="", priority=55,
   roles=[role("target", where=[c_avail("self"), c_knows("self", "$fact", neg=True), c_not(c_same("self", "$subject"))],
               score=[s_aff("actor", "self", 0.02), s_trait("self", "gossip", 0.6), s_dist("actor", "self", -0.05)], exclude=["actor"])],
   conditions=[c_avail("actor")],
   effects=[emote("actor", "whisper"), say("actor", "kg_psst", to="target"), setv("gossip", "$fact"),
            meetup("kitchen_gossip_scene", area="kitchen", ttl=35)])

scene("ivm_tell_boss", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "ivm_tattle", to="target"), learn("target", "$fact", frm="actor")],
      outcomes=[
          out("listens", [say("target", "ivm_boss_cares", to="actor", delay=1.8), favor("$subject", -6), rel("target", "$subject", "trust", -8),
                          rel("target", "actor", "trust", 3), mem("$subject", "actor", "tattled", -0.5, 0.7, "mem.ivm_tattled", 2, when=[c_knows("$subject", "$fact")]),
                          log("log.ivm_tattle", 3, "boss", who=["actor", "$subject"])],
              score=[s_trait("target", "temper", 0.6), s_rel("target", "actor", "trust", 0.015), s_const(0.5)]),
          out("dismiss", [say("target", "ivm_boss_tattle_no", to="actor", delay=1.8), rel("target", "actor", "respect", -6), mood("actor", -5),
                          log("log.ivm_tattle_no", 2, "boss", who=["actor", "$subject"])],
              score=[s_trait("target", "empathy", 0.5), s_rel("target", "$subject", "trust", 0.02), s_const(0.2)]),
      ])


# =====================================================================
# Thanking (or confronting) the wrong person
# =====================================================================
L("ivm_misattrib", ["Hey {target}... was that you? {what}?", "{target}! I know it was you. {what}!", "So... {what}. That was you, right?"],
  ece=["{target}! Was it you?? {what}!"], selin=["{target}, did you have something to do with {what}?"], ahmet=["{target}. {what}. Explain."])
L("ivm_take_credit", ["...Yes. Yes it was. You're welcome.", "Guilty. I mean — glad you liked it.", "Maybe. Who's asking?"],
  deniz=["Naturally. I'm full of surprises."], mert=["Haha, yeah! Totally me. Definitely."])
L("ivm_not_me", ["Me? No idea what you're talking about.", "That wasn't me. Sorry.", "Huh? I didn't do anything."], ceren=["That wasn't me. But I'd like to know who it was."])
L("ivm_blush", ["I... um... maybe?", "*blushes* Who told you?", "It doesn't matter who it was. Does it?"])
S_("log.ivm_credit", "{actor} thanked {target} for {what}. {target} took the credit. It wasn't them.")
S_("log.ivm_not_me", "{actor} thought {target} was behind {what}. {target} had no idea what they were talking about.")
S_("log.ivm_blush", "{actor} asked {target} about {what}. {target} went red and wouldn't say no. Something's happening there.")
S_("mem.ivm_thought_kind", "{target} did something nice for me. (Or so I think.)")

scene("ivm_misattrib", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "ivm_misattrib", to="target")],
      outcomes=[
          out("credit", [say("target", "ivm_take_credit", to="actor", delay=1.7), emote("actor", "love", delay=2.5, when=[c_rel("actor", "target", "romance", gt=25)]),
                         rel("actor", "target", "friendship", 8), rel("actor", "target", "romance", 6, when=[c_rel("actor", "target", "romance", gt=10)]),
                         mem("actor", "target", "kindness", 0.5, 0.8, "mem.ivm_thought_kind", 2), log("log.ivm_credit", 3, "misunderstanding")],
              score=[s_trait("target", "cunning", 1.0), s_trait("target", "honesty", -0.8), s_rel("target", "actor", "romance", 0.02)]),
          out("deny", [say("target", "ivm_not_me", to="actor", delay=1.7), emote("actor", "question", delay=2.6), rel("actor", "target", "trust", 2),
                       log("log.ivm_not_me", 2, "misunderstanding")],
              score=[s_trait("target", "honesty", 1.0), s_const(0.3)]),
          out("blush", [say("target", "ivm_blush", to="actor", delay=1.7), emote("target", "love", delay=1.7), rel("actor", "target", "romance", 10, both=True),
                        rumor("crush", a="target", b="actor", juicy=0.6, knowers=[]), witness([learn("self", "$rumor")], r=5),
                        log("log.ivm_blush", 3, "romance")],
              score=[s_rel("target", "actor", "romance", 0.04), s_const(-0.5)], when=[c_rel("target", "actor", "romance", gt=20)]),
      ])


# =====================================================================
# Summoned by the boss because of something the ghost planted
# =====================================================================
L("ivm_boss_ask", ["Sit down. I've been told about {what}.", "Explain {what} to me.", "We need to talk about {what}."])
L("ivm_boss_clueless", ["I... honestly have no idea what you mean.", "That's news to me, Ahmet Bey.", "There must be some mistake."])
L("ivm_boss_scold", ["Then you'd better figure it out. Fast.", "I expect better from you.", "This is your last warning."])
L("ivm_boss_ok", ["...Fine. Odd. Very odd. Go.", "Hm. A misunderstanding, then. Dismissed.", "Then someone in this office has a sense of humour."])
S_("log.ivm_boss_scold", "Ahmet called {actor} in about {what}. {actor} had no idea — and got a lecture anyway.")
S_("log.ivm_boss_ok", "Ahmet called {actor} in about {what}. It was a misunderstanding. Ahmet's now suspicious of everyone.")
S_("mem.ivm_lectured", "Ahmet lectured me about {what}. I didn't do anything!")

scene("ivm_boss_talk", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5.5), say("target", "ivm_boss_ask", to="actor"), say("actor", "ivm_boss_clueless", to="target", delay=1.8),
               emote("actor", "sweat", delay=1.8), stress("actor", 8)],
      outcomes=[
          out("scold", [say("target", "ivm_boss_scold", to="actor", delay=3.4), expr("target", "angry", 5, delay=3.4), favor("actor", -5), morale("actor", -3),
                        mem("actor", "target", "scolded", -0.5, 0.8, "mem.ivm_lectured", 2), rel("actor", "target", "resentment", 6),
                        log("log.ivm_boss_scold", 3, "boss")],
              score=[s_trait("target", "temper", 1.0), s_stress("target", 0.01), s_rel("target", "actor", "trust", -0.01)]),
          out("ok", [say("target", "ivm_boss_ok", to="actor", delay=3.4), ghost(), call("ghost_theory"), log("log.ivm_boss_ok", 2, "boss")],
              score=[s_rel("target", "actor", "trust", 0.02), s_const(0.4)]),
      ])


# =====================================================================
# Shared outcome builders for discovery scenes
# =====================================================================
def O_blame(mtext="mem.ivm_suspect", score_k=1.0):
    return out("blame", [say("actor", "ivm_who"), say("actor", "ivm_blame", delay=1.4), expr("actor", "angry", 5),
                         rel("actor", "$suspect", "suspicion", 18), rel("actor", "$suspect", "trust", -6),
                         mem("actor", "$suspect", "suspect_prank", -0.4, 0.7, mtext, 2), stat("blames"),
                         rumor("blamed", a="$suspect", b="actor", juicy=0.4, knowers=["actor"]), witness([learn("self", "$rumor")], r=4),
                         visit("actor", "$suspect", "ivm_accuse", prio=60, ttl=60, delay=2, when=[c_trait("actor", "temper", gt=0.4)])],
               score=[s_trait("actor", "temper", 1.0 * score_k), s_rel("actor", "$suspect", "rivalry", 0.02), s_rel("actor", "$suspect", "suspicion", 0.02),
                      s_trait("actor", "forgiveness", -0.4)],
               when=[c_filled("$suspect"), c_present("$suspect")])

def O_ghost():
    return out("ghost", [say("actor", "lights_ghost_on"), emote("actor", "question"), ghost(), call("ghost_theory"),
                         witness([emote("self", "exclaim"), say("self", "witness_ghost", p=0.5, delay=1.5)], r=5)],
               score=[s_trait("actor", "curiosity", 0.9), s_const(0.15)])

def O_shrug(line="ivm_shrug"):
    return out("shrug", [say("actor", line), mood("actor", -3)],
               score=[s_trait("actor", "forgiveness", 0.6), s_trait("actor", "humor", 0.4), s_const(0.1)])

L("ivm_shrug", ["Weird. Whatever.", "Okay... moving on.", "Not today, universe.", "I don't even want to know."],
  mert=["Ha. Somebody's bored."], burak=["Fine. Fixed. Next."], ceren=["Hm. I'll make a note of that."])

def O_it(fixpath):
    return out("call_it", [setf("fixpath", fixpath), say("actor", "ivm_who"),
                           visit("actor", "@burak", "ivm_it_fix", prio=62, ttl=60, delay=1.5)],
               score=[s_const(0.5), s_trait("actor", "sociability", 0.4)],
               when=[c_present("@burak"), c_is("actor", "burak", neg=True)])
