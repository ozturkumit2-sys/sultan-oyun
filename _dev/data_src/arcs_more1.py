# More story arcs (part 1). Same rules as arcs.py: each stage is an event; its
# outcome moves the story on (arc_next), takes a detour, or ends it (arc_end).
# Most can start on their own (an NPC's initiative) AND from a hidden combination.
from story_helpers import *  # noqa: F401,F403
from story_helpers import arc, stage, initiative
import story_helpers as _sh
from iv_helpers import S_, L, oset  # guarded: never overwrite existing text  # noqa: F811

BIG = "big"


def T(k, v):
    S_(k, v)


def title(arc_id, name, teaser):
    T("arc." + arc_id, name)
    T("arc.%s.teaser" % arc_id, teaser)


def start(id, arc_id, cast, roles, domain, conditions=None, vars=None, effects=None, cooldown_days=4, say_key=None, weight=1.0, tier=BIG):
    eff = ([say("actor", say_key)] if say_key else []) + (effects or []) + [arc_start(arc_id, cast)]
    conds = (conditions or []) + [{"c": "can_arc", "arc": arc_id, "cast": cast}]
    initiative(id, tier, roles=roles, conditions=conds, vars=vars, effects=eff, cooldown_days=cooldown_days, scope="global", weight=weight, domain=domain)


# =====================================================================
# 1. GHOST HUNT — the office decides it's haunted
# =====================================================================
title("ghost_hunt", "The Ghost Hunt", "{believer} is convinced the office is haunted.")
L("gh_announce", ["I'm telling you: this office is HAUNTED.", "Lights. Printers. Coffee machines. It's a ghost. I'm sure of it.", "Something is living in this office. Something... invisible."],
  ece=["There's a GHOST. I'm scared but also SO excited."], zeynep=["I've seen things. I'm keeping notes."])
T("log.gh_announce", "{believer} has declared the office officially haunted. Some people are nodding.")
start("start_ghost_hunt", "ghost_hunt", {"believer": "actor", "skeptic": "@burak"},
      [actor([c_trait("self", "curiosity", gt=0.6), {"c": "flag", "key": "ghost_belief"}, c_is("self", "burak", neg=True)],
             [s_trait("self", "curiosity", 1.0), s_trait("self", "gossip", 0.4)])], "comedy",
      conditions=[c_present("@burak"), {"c": "flag", "key": "ghost_belief"}], say_key="gh_announce", weight=1.4)
scene("gh_whisper", allow_absent=True, conditions=[c_present("believer")],
      effects=[emote("believer", "whisper"), say("believer", "gh_announce"), rumor("haunted", a="@ahmet", b="believer", juicy=0.6, truth=False, knowers=["believer"]),
               witness([learn("self", "$rumor", frm="believer")], near="believer", r=5), log("log.gh_announce", 3, "ghost", who=["believer"]),
               arc_next("recruit", wait=(10, 30))])
L("gh_recruit", ["Séance. Meeting room. After lunch. You in?", "We need to contact the ghost. Properly. Are you with me?"])
L("gh_recruit_yes", ["YES. I'll bring candles.", "I'm in. I've always wanted to do a séance."])
L("gh_recruit_no", ["Absolutely not. You need sleep.", "I'm not talking to the printer's soul."])
T("log.gh_recruit", "{believer} recruited {medium} for a séance in the meeting room.")
T("log.gh_refused", "{believer} wanted to hold a séance. Nobody would join. The ghost hunt is over.")
scene("gh_recruit", noise=0.8, conditions=[c_present("believer"), c_present("medium")],
      effects=[hold(["believer", "medium"], 4.5), emote("believer", "whisper"), say("believer", "gh_recruit", to="medium")],
      outcomes=[out("yes", [say("medium", "gh_recruit_yes", to="believer", delay=1.6), log("log.gh_recruit", 2, "ghost", who=["believer", "medium"]),
                            arc_next("seance", wait=(20, 60))], score=[s_trait("medium", "curiosity", 1.0), s_trait("medium", "humor", 0.5)]),
                out("no", [say("medium", "gh_recruit_no", to="believer", delay=1.6), mood("believer", -6), log("log.gh_refused", 2, "ghost"), arc_end("dismissed")],
                    score=[s_trait("medium", "diligence", 0.8), s_const(0.3)])])
L("gh_chant", ["Spirit of the office... are you there? Knock once for yes.", "Oh ghost... if you're here... flicker the lights."])
L("gh_scream", ["AAAAAH! IT ANSWERED!", "THE LIGHTS! DID YOU SEE THE LIGHTS?!"])
L("gh_nothing", ["...Nothing.", "Maybe it's on lunch break.", "Well. That was an hour of my life."])
T("log.gh_scream", "The séance in the meeting room went silent... then the lights flickered. Screams were heard across the office.")
T("log.gh_nothing", "The séance in the meeting room produced nothing but awkward silence.")
scene("gh_seance", noise=0.8,
      effects=[each([emote("self", "whisper")], where=[c_zone("self", ["meeting"])]), say("believer", "gh_chant")],
      outcomes=[out("scream", [{"e": "call", "fn": "flicker", "minutes": 3}, sfx("gasp", delay=2), each([say("self", "gh_scream", p=0.6, delay=2.2), emote("self", "exclaim", delay=2.2),
                               stress("self", 8)], where=[c_zone("self", ["meeting"])]), ghost(2), call("ghost_theory"), log("log.gh_scream", 4, "ghost"), arc_next("debunk", wait=(10, 30))],
                    score=[{"s": "rand", "v": 1.0}, s_const(0.4)]),
                out("nothing", [say("medium", "gh_nothing", delay=2.5), log("log.gh_nothing", 2, "ghost"), arc_end("anticlimax")], score=[s_const(0.6)])])
L("gh_debunk", ["It was a loose wire in the ceiling. Not a ghost. Please stop.", "I checked the breaker. Faulty relay. There is no ghost."])
L("gh_believe_burak", ["...Oh. A relay. Right. Of course.", "Fine. No ghost. ...Probably."])
L("gh_dont_believe", ["That's EXACTLY what a ghost would want you to say.", "You can't explain everything with 'relays', Burak."])
T("log.gh_debunked", "Burak explained the 'ghost' as a faulty relay. {believer} grudgingly gave up the ghost hunt.")
T("log.gh_believers", "Burak tried to debunk the ghost. {believer} refused to believe him. The office now has a resident ghost.")
scene("gh_debunk", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "gh_debunk", to="target")],
      outcomes=[out("believe", [say("target", "gh_believe_burak", to="actor", delay=1.6), rel("target", "actor", "respect", 6), flag("ghost_belief", 0),
                                log("log.gh_debunked", 3, "ghost", who=["believer"]), arc_end("debunked")], score=[s_trait("target", "honesty", 0.6), s_rel("target", "actor", "trust", 0.02)]),
                out("deny", [say("target", "gh_dont_believe", to="actor", delay=1.6), ghost(2), rel("actor", "target", "respect", -4),
                             log("log.gh_believers", 3, "ghost", who=["believer"]), arc_end("believers")], score=[s_trait("target", "curiosity", 1.0), s_const(0.2)])])
arc("ghost_hunt", BIG, "whisper", cooldown_days=6, stages={
    "whisper": stage("gh_whisper", "now", actor="believer", wait=(2, 8), ttl=80),
    "recruit": stage("gh_recruit", "visit", actor="believer", target="medium", ttl=60, fail="end:dismissed"),
    "seance": stage("gh_seance", "gather", actor="believer", area="meeting", need=2, ttl=50, window=("12:30", "16:30"), fail="end:no_seance",
                    who=["believer", "medium"], must=["believer"]),
    "debunk": stage("gh_debunk", "visit", actor="skeptic", target="believer", ttl=70, fail="end:believers"),
})

# recruit picks its medium when the arc starts
def _patch_recruit():
    for e in _sh.E:
        if e["id"] == "gh_whisper":
            e.setdefault("roles", []).append(role("medium", where=[c_avail("self"), c_not(c_same("self", "believer")), c_is("self", "burak", neg=True)],
                                                  score=[s_trait("self", "curiosity", 1.0), s_trait("self", "gossip", 0.5), s_rand(0.3)], exclude=["believer"]))
_patch_recruit()


# =====================================================================
# 2. THE OFFICE COUP — someone tries to run the place
# =====================================================================
title("office_coup", "The Coup", "{usurper} has decided the office needs new leadership.")
L("coup_announce", ["Attention, everyone! New efficiency measures, effective immediately.", "Listen up. While Ahmet's busy, I'm streamlining things."],
  deniz=["Team. A few changes. Effective now. Questions? No? Good."])
L("coup_follow", ["Sure, whatever you say.", "Okay! New rules!"])
L("coup_resist", ["Who put YOU in charge?", "You're not the boss.", "Nice try."])
T("log.coup_announce", "{usurper} stood in the middle of the office and announced 'new efficiency measures'. Ahmet wasn't consulted.")
start("start_coup", "office_coup", {"usurper": "actor", "boss": "@ahmet"},
      [actor([c_trait("self", "ambition", gt=0.75), c_trait("self", "cunning", gt=0.5), c_is("self", "ahmet", neg=True)],
             [s_trait("self", "ambition", 1.0), s_trait("self", "cunning", 0.8), s_rel("self", "@ahmet", "resentment", 0.02)])], "secret_plans",
      conditions=[c_any(c_not(c_avail("@ahmet")), c_rel("actor", "@ahmet", "respect", lt=15), {"c": "chance", "p": 0.25})], cooldown_days=8)
scene("coup_announce", noise=0.8, conditions=[c_present("usurper")],
      roles=[by_fn("ally", "best_of", of="usurper", lim=-20, optional=True, exclude=["usurper", "boss"])],
      effects=[hold(["usurper"], 5), say("usurper", "coup_announce"), emote("usurper", "idea"), log("log.coup_announce", 4, "boss", who=["usurper"]),
               each([say("self", "coup_follow", p=0.5, delay=1.6), rel("self", "usurper", "respect", 4)], exclude=["usurper", "boss"], stagger=0.5,
                    where=[c_rel("self", "usurper", "respect", gt=20)]),
               each([say("self", "coup_resist", p=0.6, delay=1.8), rel("self", "usurper", "rivalry", 8)], exclude=["usurper", "boss"], stagger=0.5,
                    where=[c_rel("self", "usurper", "respect", lt=20)])],
      outcomes=[out("recruit", [arc_next("ally", wait=(10, 30))], score=[s_const(1)], when=[c_filled("ally")]),
                out("solo", [arc_next("boss_hears", wait=(20, 50))], score=[s_const(0.1)])])
L("coup_ally_ask", ["You and me. When Ahmet's out, we run this place. Deal?", "I need a second-in-command. Interested?"])
L("coup_ally_yes", ["...Deal. What's in it for me?", "I'm listening."])
L("coup_ally_no", ["You're going to get us both fired.", "Leave me out of this."])
T("log.coup_ally", "{usurper} recruited {ally} as a 'deputy'. The coup has a cabinet.")
T("log.coup_alone", "{usurper} tried to recruit {ally}. {ally} wants nothing to do with it.")
scene("coup_ally", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), emote("actor", "whisper"), say("actor", "coup_ally_ask", to="target")],
      outcomes=[out("yes", [say("target", "coup_ally_yes", to="actor", delay=1.6), bond("actor", "target", "alliance"), log("log.coup_ally", 3, "scheme"),
                            arc_next("boss_hears", wait=(15, 40))], score=[s_trait("target", "ambition", 0.8), s_aff("target", "actor", 0.02)]),
                out("no", [say("target", "coup_ally_no", to="actor", delay=1.6), log("log.coup_alone", 2, "scheme"), arc_next("boss_hears", wait=(15, 40))],
                    score=[s_trait("target", "honesty", 0.8), s_rel("target", "@ahmet", "trust", 0.02)])])
L("coup_boss", ["I hear YOU'VE been running my office, {usurper}.", "'Efficiency measures', {usurper}? In MY office?"])
L("coup_bold", ["Someone had to. Things were falling apart.", "I took initiative. You're welcome."])
L("coup_crushed", ["You're on thin ice. Very thin.", "One more stunt and you're done here."])
L("coup_impressed", ["...Actually, some of those measures aren't bad. Write them up.", "Hm. Bold. Maybe too bold. But not stupid."])
T("log.coup_crushed", "Ahmet confronted {usurper} about the 'coup'. It did not go well for {usurper}.")
T("log.coup_impressed", "Ahmet confronted {usurper} about the 'coup' — and ended up adopting half the ideas.")
scene("coup_confront", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 6), expr("actor", "angry", 5), say("actor", "coup_boss", to="target"), say("target", "coup_bold", to="actor", delay=1.8)],
      outcomes=[out("crushed", [say("actor", "coup_crushed", to="target", delay=3.6), favor("target", -15), morale("target", -8), rel("actor", "target", "trust", -20),
                                bond("target", "ally", "alliance", False, when=[c_filled("ally")]), storm("target", delay=5), log("log.coup_crushed", 4, "boss"), arc_end("crushed")],
                    score=[s_trait("actor", "temper", 1.2), s_rel("actor", "target", "trust", -0.02)]),
                out("impressed", [say("actor", "coup_impressed", to="target", delay=3.6), favor("target", 8), rel("actor", "target", "respect", 15),
                                  log("log.coup_impressed", 4, "boss"), arc_end("adopted")], score=[s_rel("actor", "target", "respect", 0.03), s_const(0.3)])])
arc("office_coup", BIG, "announce", cooldown_days=8, stages={
    "announce": stage("coup_announce", "place", actor="usurper", place="announce", ttl=60),
    "ally": stage("coup_ally", "visit", actor="usurper", target="ally", ttl=60, fail="boss_hears"),
    "boss_hears": stage("coup_confront", "visit", actor="boss", target="usurper", ttl=200, fail="end:unnoticed"),
})


# =====================================================================
# 3. THE LOVE TRIANGLE
# =====================================================================
title("love_triangle", "The Love Triangle", "{lover} and {rival} both have their eye on {crush}.")
L("lt_notice", ["...Is {lover} flirting with {crush}? Right in front of me?", "Oh, I see how it is. {lover} and {crush}. Cute."])
T("log.lt_notice", "{rival} noticed {lover} flirting with {crush}. {rival} has feelings for {crush} too.")
start("start_love_triangle", "love_triangle", {"lover": "actor", "crush": "crush", "rival": "$rival"},
      [actor([{"c": "picks", "fn": "triangle", "of": "self"}], [s_trait("self", "sociability", 0.6)]), by_fn("crush", "triangle", of="actor")], "romance",
      cooldown_days=5)
scene("lt_notice", noise=0.8, allow_absent=True, conditions=[c_present("rival"), c_present("lover")],
      effects=[expr("rival", "angry", 5), emote("rival", "anger"), say("rival", "lt_notice"), rel("rival", "lover", "rivalry", 20), rel("rival", "lover", "resentment", 10),
               log("log.lt_notice", 3, "romance", who=["rival", "lover", "crush"]), arc_next("warning", wait=(10, 30))])
L("lt_warn", ["Back off. I saw {crush} first.", "Stay away from {crush}. I mean it."])
L("lt_backoff", ["...Fine. If it means that much to you.", "Okay. Okay. I'll step back."])
L("lt_never", ["May the best person win.", "Not a chance. {crush} can decide."])
T("log.lt_backoff", "{rival} told {lover} to back off from {crush}. {lover} stepped aside.")
T("log.lt_never", "{rival} told {lover} to back off from {crush}. {lover} refused. It's on.")
scene("lt_warn", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "lt_warn", to="target")],
      outcomes=[out("back", [say("target", "lt_backoff", to="actor", delay=1.6), rel("target", "crush", "romance", -15), log("log.lt_backoff", 3, "romance"), arc_end("yielded")],
                    score=[s_trait("target", "empathy", 0.8), s_aff("target", "actor", 0.02)]),
                out("never", [say("target", "lt_never", to="actor", delay=1.6), rel("actor", "target", "rivalry", 12, both=True), log("log.lt_never", 3, "romance"),
                              arc_next("gesture", wait=(10, 40))], score=[s_trait("target", "ambition", 0.6), s_rel("target", "crush", "romance", 0.03)])])
L("lt_gesture", ["I made you a coffee. The way you like it. With a heart in the foam.", "Got you something. Saw it and thought of you."])
L("lt_gesture_react", ["...That's really sweet.", "Oh! Thank you!", "You remembered?!"])
T("log.lt_gesture", "{lover} made a grand gesture for {crush} — with {rival} watching from across the room.")
scene("lt_gesture", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "lt_gesture", to="target"), say("target", "lt_gesture_react", to="actor", delay=1.6), emote("target", "love", delay=1.6),
               rel("target", "actor", "romance", 8), log("log.lt_gesture", 3, "romance", who=["lover", "crush"]), arc_next("choice", wait=(20, 60))])
L("lt_choice_ask", ["So. Me or {lover}? I need to know.", "I have to ask: is there something between you and {lover}?"])
L("lt_choose_rival", ["...Honestly? It's you. It was always you.", "You. Obviously you."])
L("lt_choose_lover", ["I'm sorry. I like {lover}.", "It's {lover}. I'm sorry."])
L("lt_choose_none", ["Neither of you! You're both ridiculous!", "I'm not a trophy. I'm not choosing anyone."])
T("log.lt_rival_wins", "{crush} chose {rival} over {lover}. The triangle is now a couple and one very sad person.")
T("log.lt_lover_wins", "{crush} chose {lover}. {rival} took it badly.")
T("log.lt_nobody", "{crush} told both {lover} and {rival} to grow up. Nobody wins.")
scene("lt_choice", noise=0.9, conditions=[c_present("rival"), c_present("crush")],
      effects=[hold(["rival", "crush"], 6), say("rival", "lt_choice_ask", to="crush")],
      outcomes=[out("rival", [say("crush", "lt_choose_rival", to="rival", delay=1.8), emote("rival", "love", delay=1.8), bond("rival", "crush", "romance"),
                              mood("lover", -15), log("log.lt_rival_wins", 4, "romance"), arc_end("chose_rival")],
                    score=[s_rel("crush", "rival", "romance", 0.04), s_aff("crush", "rival", 0.01)]),
                out("lover", [say("crush", "lt_choose_lover", to="rival", delay=1.8), expr("rival", "sad", 8, delay=1.8), bond("lover", "crush", "romance"), mood("rival", -18),
                              rel("rival", "lover", "resentment", 15), plan("rival", "revenge", "lover", heat=0.6), storm("rival", delay=3.5), log("log.lt_lover_wins", 4, "romance"), arc_end("chose_lover")],
                    score=[s_rel("crush", "lover", "romance", 0.04), s_aff("crush", "lover", 0.01)]),
                out("none", [say("crush", "lt_choose_none", to="rival", delay=1.8), mood("rival", -8), mood("lover", -8), log("log.lt_nobody", 3, "romance"), arc_end("neither")],
                    score=[s_trait("crush", "temper", 0.8), s_const(0.3)])])
arc("love_triangle", BIG, "notice", cooldown_days=5, stages={
    "notice": stage("lt_notice", "now", actor="rival", wait=(5, 20), ttl=90),
    "warning": stage("lt_warn", "visit", actor="rival", target="lover", ttl=60, fail="gesture"),
    "gesture": stage("lt_gesture", "visit", actor="lover", target="crush", ttl=70, fail="choice"),
    "choice": stage("lt_choice", "meet", actor="rival", target="crush", area="kitchen", ttl=70, fail="end:unresolved"),
})


# =====================================================================
# 4. THE SALARY REVOLT
# =====================================================================
title("salary_revolt", "The Salary Revolt", "{leader} thinks it's time everyone stood up together.")
L("sr_grumble", ["We work harder every year and earn LESS. Enough.", "Is anyone else sick of this? Because I am.", "We should do something. Together."])
T("log.sr_grumble", "{leader} gathered the unhappy ones in the kitchen. Talk turned to raises.")
start("start_salary_revolt", "salary_revolt", {"leader": "actor", "boss": "@ahmet"},
      [actor([c_morale("self", lt=52), c_is("self", "ahmet", neg=True), c_trait("self", "temper", gt=0.3)],
             [s_morale("self", -0.04), s_trait("self", "temper", 0.6), s_trait("self", "sociability", 0.5)])], "work_career",
      conditions=[{"c": "picks", "fn": "unhappy_crowd", "n": 2, "lim": 57}, c_present("@ahmet")], cooldown_days=7)
scene("sr_grumble", noise=0.8,
      effects=[say("leader", "sr_grumble"), each([say("self", "zero_grumble", p=0.4, delay=1.6), rel("self", "leader", "friendship", 4)], exclude=["leader"],
                                                 where=[c_zone("self", ["kitchen"])], stagger=0.6), log("log.sr_grumble", 3, "work", who=["leader"]),
               arc_next("petition", wait=(15, 40))])
L("sr_sign", ["Sign the petition? Fair raises for everyone.", "One signature. For all of us."])
L("sr_signed", ["Give me that pen.", "Signed. About time.", "Okay. I'm in."])
L("sr_refused", ["I can't risk it.", "Leave me out. I like my job.", "Not my fight."])
T("log.sr_enough", "{leader}'s raise petition has enough signatures. Next stop: Ahmet's office.")
T("log.sr_few", "{leader}'s raise petition got almost no signatures. The revolt fizzled.")
# who signs: the unhappy, the leader's friends, and anyone with a grudge against the boss
SIGNER = c_any(c_morale("self", lt=58), c_rel("self", "leader", "friendship", gt=45), c_rel("self", "@ahmet", "resentment", gt=20))
scene("sr_petition", noise=0.6, allow_absent=True, conditions=[c_present("leader")],
      roles=[role("cosigner", where=[c_avail("self"), SIGNER, c_is("self", "ahmet", neg=True)],
                  score=[s_aff("self", "leader", 0.02), s_trait("self", "temper", 0.5), s_rand(0.3)], exclude=["leader", "boss"], optional=True)],
      effects=[say("leader", "sr_sign"),
               each([say("self", "sr_signed", p=0.6, delay=1.4), npcflag("self", "signed")], exclude=["leader", "boss"], where=[SIGNER], stagger=0.7),
               each([say("self", "sr_refused", p=0.4, delay=1.4)], exclude=["leader", "boss"], where=[c_not(SIGNER)], stagger=0.7),
               arc_next("tally", wait=(8, 20))])
L("sr_count_many", ["Look at all these signatures. They can't ignore this.", "We've got numbers. Now we march."])
L("sr_count_few", ["...Two signatures. One of them is mine.", "Nobody signed. Cowards. All of them."])
scene("sr_tally", noise=0.6, allow_absent=True, conditions=[c_present("leader")],
      outcomes=[out("enough", [say("leader", "sr_count_many"), emote("leader", "idea"), log("log.sr_enough", 3, "work", who=["leader"]), arc_next("march", wait=(10, 30))],
                    score=[s_const(1)], when=[{"c": "picks", "fn": "signed_count", "n": 2}]),
                out("few", [say("leader", "sr_count_few"), expr("leader", "sad", 6), log("log.sr_few", 2, "work", who=["leader"]), mood("leader", -10), arc_end("fizzled")],
                    score=[s_const(0.1)])])
L("sr_demand", ["Ahmet Bey, we're asking for fair raises. All of us.", "We've signed a petition. We want to be paid fairly."])
L("sr_concede", ["...Fine. I'll take it to HQ. You'll get something. I promise.", "You make a fair point. I'll fight for it."])
L("sr_refuse", ["A PETITION? This isn't a union hall!", "Anyone unhappy knows where the door is."])
T("log.sr_concede", "{leader} led a group into Ahmet's office with a petition. Ahmet promised to fight for raises. Cheers all round.")
T("log.sr_refuse", "{leader} led a group into Ahmet's office with a petition. Ahmet threw them out. The mood is grim.")
scene("sr_march", noise=0.9,
      effects=[say("leader", "sr_demand")],
      outcomes=[out("concede", [say("boss", "sr_concede", delay=1.8), each([morale("self", 8), mood("self", 10), emote("self", "cheer", delay=2)], exclude=["boss"],
                                                                                where=[c_zone("self", ["boss"])]), favor("leader", -2), rel("boss", "leader", "respect", 8),
                                log("log.sr_concede", 4, "work", who=["leader"]), arc_end("raises")],
                    score=[s_trait("boss", "empathy", 1.0), s_mood("boss", 0.02), s_const(0.3)]),
                out("refuse", [say("boss", "sr_refuse", delay=1.8), expr("boss", "angry", 6, delay=1.8), each([morale("self", -6), plan("self", "job_search", "", heat=0.5)],
                               exclude=["boss"], where=[c_zone("self", ["boss"])]), favor("leader", -10), log("log.sr_refuse", 4, "work", who=["leader"]), arc_end("crushed")],
                    score=[s_trait("boss", "temper", 1.0), s_stress("boss", 0.01)])])
arc("salary_revolt", BIG, "grumble", cooldown_days=7, stages={
    "grumble": stage("sr_grumble", "gather", actor="leader", area="kitchen", need=3, ttl=50, fail="petition", exclude=["boss"]),
    "petition": stage("sr_petition", "now", actor="leader", ttl=90, fail="end:fizzled"),
    "tally": stage("sr_tally", "now", actor="leader", ttl=90, fail="end:fizzled"),
    "march": stage("sr_march", "gather", actor="leader", area="boss", need=3, ttl=60, window=("10:00", "16:30"), fail="end:lost_nerve",
                   who=["leader", "cosigner", "boss"], must=["leader", "boss"]),
})


# =====================================================================
# 5. THE LUNCH THIEF MYSTERY
# =====================================================================
title("lunch_mystery", "Who Stole the Lunch?", "{victim}'s lunch is gone and {victim} wants justice.")
L("lm_outrage", ["That's the THIRD time! I'm finding out who it is.", "Somebody in this office is a LUNCH THIEF. And I'm going to catch them."])
T("log.lm_outrage", "{victim} has had enough of lunch thefts and is launching an investigation.")
start("start_lunch_mystery", "lunch_mystery", {"victim": "actor", "detective": "$det"},
      [actor([c_npcflag("self", "lunch_victim")], [s_trait("self", "temper", 0.8), s_const(1)])], "arguments",
      vars=[var("det", "most_curious", **{"not": "actor"})], say_key="lm_outrage", cooldown_days=5, weight=3.0)
L("lm_hire", ["You notice everything. Help me catch a lunch thief?", "I need a detective. You're the nosiest person I know. That's a compliment."])
L("lm_accept", ["A mystery? I'm IN.", "Leave it to me. Nobody steals lunch on my watch."])
T("log.lm_hire", "{victim} hired {detective} to catch the lunch thief.")
scene("lm_hire", noise=0.7, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "lm_hire", to="target"), say("target", "lm_accept", to="actor", delay=1.6), emote("target", "idea", delay=1.6),
               log("log.lm_hire", 2, "conflict", who=["victim", "detective"]), arc_next("stakeout", days=1)])
L("lm_watch", ["*hiding behind the fridge door* Any minute now...", "Stakeout. Fridge. Eyes open."])
L("lm_caught", ["GOTCHA! Hands off that lunch, {culprit}!", "Caught red-handed, {culprit}! With a FORK!"])
L("lm_caught_excuse", ["I— it looked abandoned!", "I thought it was free food!", "It's not what it looks like. It's exactly what it looks like."])
L("lm_nobody", ["Nothing. Nobody. The thief must know we're watching.", "Two hours by the fridge. Not even a yoghurt."])
T("log.lm_caught", "{detective} staked out the fridge and caught {culprit} red-handed.")
T("log.lm_nobody", "{detective} staked out the fridge all lunch. The thief never showed.")
scene("lm_stakeout", noise=0.8, allow_absent=True, conditions=[c_present("detective")],
      vars=[var("culprit", "lunch_culprit", optional=True)],
      effects=[say("detective", "lm_watch"), emote("detective", "question")],
      outcomes=[out("caught", [say("detective", "lm_caught", delay=2), emote("detective", "exclaim", delay=2), say("$culprit", "lm_caught_excuse", delay=3.4, when=[c_present("$culprit")]),
                               rumor("stole_lunch", a="$culprit", b="victim", juicy=0.6, knowers=["detective"]), witness([learn("self", "$rumor")], near="detective", r=6),
                               log("log.lm_caught", 3, "conflict", who=["detective", "$culprit"]), arc_next("confront", wait=(3, 15))],
                    score=[s_const(1)], when=[c_filled("$culprit"), c_present("$culprit")]),
                out("nobody", [say("detective", "lm_nobody", delay=2), log("log.lm_nobody", 2, "conflict"), arc_next("bait", wait=(30, 80))], score=[s_const(0.2)])])
L("lm_bait", ["One extra-spicy 'lunch', labelled 'DO NOT EAT'. Let's see who can resist.", "*plants a suspiciously delicious box in the fridge* Bait's set."])
L("lm_spicy", ["HHHHH— WATER! WATER!", "WHY IS IT SO SPICY?!", "My mouth is on FIRE!"])
L("lm_laugh", ["HAHA! Serves you right!", "Somebody get them some milk!", "That's what you get for stealing!"])
L("lm_gotcha_bait", ["Caught by the chilli! It's {culprit}!", "The bait worked! {culprit}, you're busted!"])
T("log.lm_bait", "{detective} left an extra-spicy 'bait lunch' in the fridge to trap the thief.")
T("log.lm_bite", "{culprit} ate {detective}'s bait lunch and had to run for water. The lunch thief is unmasked.")
T("log.lm_no_bite", "Nobody touched {detective}'s bait lunch. The thief must be onto them. Case unsolved.")
scene("lm_bait", noise=0.8, allow_absent=True, conditions=[c_present("detective")],
      roles=[role("eater", where=[c_present("self"), c_trait("self", "honesty", lt=0.66), c_is("self", "ahmet", neg=True)],
                  score=[s_trait("self", "honesty", -1.0), s_rand(0.5)], exclude=["victim", "detective"], optional=True)],
      effects=[say("detective", "lm_bait"), emote("detective", "idea"), log("log.lm_bait", 2, "conflict", who=["detective"])],
      outcomes=[out("bite", [{"e": "set", "key": "culprit", "who": "eater"}, arc_next("bite", wait=(10, 40))], score=[s_const(1)], when=[c_filled("eater")]),
                out("none", [log("log.lm_no_bite", 2, "conflict", delay=1), arc_end("unsolved")], score=[s_const(0.1)])])
scene("lm_bite", noise=0.6, allow_absent=True, conditions=[c_present("$culprit")],
      effects=[expr("$culprit", "surprised", 6), say("$culprit", "lm_spicy"), fx("shake", "$culprit"), sfx("gasp"),
               say("detective", "lm_gotcha_bait", delay=2, when=[c_present("detective")]), emote("detective", "exclaim", delay=2),
               witness([say("self", "lm_laugh", p=0.4, delay=1.6), emote("self", "cheer", delay=1.6)], near="$culprit", r=5, exclude=["detective"]),
               rumor("stole_lunch", a="$culprit", b="victim", juicy=0.6, knowers=["detective"], origin="detective"),
               log("log.lm_bite", 3, "conflict", who=["$culprit", "detective"]), arc_next("confront", wait=(3, 15))])
L("lm_confront", ["{culprit}. You ate my lunch. Three times.", "So it was YOU all along, {culprit}."])
L("lm_sorry", ["...I'll buy you lunch for a week. I'm sorry.", "Okay. Guilty. Let me make it up to you."])
L("lm_deny", ["Prove it.", "Your 'detective' is lying.", "I don't know what you're talking about."])
T("log.lm_sorry", "{victim} confronted the lunch thief, {culprit}. {culprit} confessed and is buying lunch for a week.")
T("log.lm_deny", "{victim} confronted {culprit} about the stolen lunches. {culprit} denied everything.")
scene("lm_confront_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), expr("actor", "angry", 5), say("actor", "lm_confront", to="target")],
      outcomes=[out("sorry", [say("target", "lm_sorry", to="actor", delay=1.6), rel("actor", "target", "resentment", -8), mem("actor", "target", "made_up", 0.3, 0.6, "mem.made_up", 2),
                              log("log.lm_sorry", 3, "conflict"), arc_end("confessed")], score=[s_trait("target", "honesty", 1.0), s_trait("target", "empathy", 0.5)]),
                out("deny", [say("target", "lm_deny", to="actor", delay=1.6), rel("actor", "target", "resentment", 12), stat("arguments"), log("log.lm_deny", 3, "conflict"),
                             arc_end("denied")], score=[s_trait("target", "cunning", 1.0), s_const(0.2)])])
arc("lunch_mystery", BIG, "hire", cooldown_days=5, stages={
    "hire": stage("lm_hire", "visit", actor="victim", target="detective", wait=(5, 20), ttl=70, fail="end:gave_up"),
    "stakeout": stage("lm_stakeout", "place", actor="detective", place="k4", ttl=80, window=("12:00", "13:40"), fail="end:unsolved"),
    "bait": stage("lm_bait", "place", actor="detective", place="fridge", ttl=70, window=("12:30", "16:30"), fail="end:unsolved"),
    "bite": stage("lm_bite", "place", actor="$culprit", place="fridge", ttl=60, window=("09:40", "16:50"), fail="end:unsolved"),
    "confront": stage("lm_confront_scene", "visit", actor="victim", target="$culprit", ttl=60, fail="end:unsolved"),
})


# =====================================================================
# 6. THE WRONG PROMOTION (hidden combination J01)
# =====================================================================
title("wrong_promotion", "The Wrong Promotion", "Ahmet just announced a promotion nobody expected — not even the winner.")
L("wp_announce", ["Everyone! I'm proud to announce our new team lead: {credited}!", "Congratulations to {credited} — promoted, effective today!"])
L("wp_credited", ["Wait — ME? Really?!", "I... wow. Thank you?!"], deniz=["Finally. Recognition."])
L("wp_rightful", ["...What? That was supposed to be MINE.", "{credited}?! Based on WHAT?"])
T("log.wp_announce", "Reading straight from a tampered promotion file in the meeting, Ahmet announced {credited} as the new team lead. {rightful} is stunned.")
scene("wp_announce", noise=0.6, allow_absent=True, conditions=[c_present("boss")],
      effects=[say("boss", "wp_announce"), emote("credited", "cheer", delay=1.6), say("credited", "wp_credited", delay=1.6, when=[c_present("credited")]),
               say("rightful", "wp_rightful", delay=3.2, when=[c_present("rightful")]), expr("rightful", "angry", 8, delay=3.2), favor("credited", 15), mood("credited", 20),
               rel("rightful", "credited", "resentment", 20), rel("rightful", "credited", "rivalry", 15), morale("rightful", -10), sfx("crowd"),
               log("log.wp_announce", 5, "promotion", who=["credited", "rightful"]), arc_next("protest", wait=(10, 30))])
L("wp_protest", ["Ahmet Bey, with respect — that promotion file was wrong.", "Somebody tampered with the file. You know it was supposed to be me."])
L("wp_boss_doubt", ["...I'll look into it.", "Tampered? Hm. Let me check."])
L("wp_boss_stubborn", ["I've announced it. It stands.", "I don't reverse my decisions in public."])
T("log.wp_protest", "{rightful} went to Ahmet: the promotion file was tampered with.")
T("log.wp_stands", "Ahmet refused to reverse the promotion. {credited} keeps it. {rightful} is furious.")
scene("wp_protest", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "wp_protest", to="target"), log("log.wp_protest", 3, "promotion")],
      outcomes=[out("check", [say("target", "wp_boss_doubt", to="actor", delay=1.6), arc_next("correction", wait=(30, 90))],
                    score=[s_rel("target", "actor", "trust", 0.03), s_trait("target", "honesty", 0.8)]),
                out("stands", [say("target", "wp_boss_stubborn", to="actor", delay=1.6), morale("actor", -10), plan("actor", "revenge", "credited", heat=1.0),
                               log("log.wp_stands", 4, "promotion"), arc_end("stands")], score=[s_trait("target", "temper", 0.8), s_const(0.4)])])
L("wp_correct", ["Correction, everyone. The file was tampered with. The promotion goes to {rightful}.", "I made a mistake. {rightful} is our new team lead."])
L("wp_credited_crushed", ["...Of course. Of course it was a mistake.", "Wonderful. Promoted and demoted before lunch."])
T("log.wp_correct", "Ahmet publicly corrected the promotion: it goes to {rightful}. {credited} had it for exactly one afternoon.")
scene("wp_correct", noise=0.6, allow_absent=True, conditions=[c_present("boss")],
      effects=[say("boss", "wp_correct"), emote("rightful", "cheer", delay=1.6), favor("rightful", 10), favor("credited", -12), morale("rightful", 10), mood("credited", -18),
               say("credited", "wp_credited_crushed", delay=3, when=[c_present("credited")]), rel("credited", "rightful", "resentment", 12),
               log("log.wp_correct", 5, "promotion", who=["rightful", "credited"]), arc_end("corrected")])
arc("wrong_promotion", BIG, "announce", cooldown_days=10, stages={
    "announce": stage("wp_announce", "now", actor="boss", wait=(1, 3), ttl=60),
    "protest": stage("wp_protest", "visit", actor="rightful", target="boss", ttl=90, fail="end:stands"),
    "correction": stage("wp_correct", "place", actor="boss", place="announce", ttl=120, fail="end:quietly_fixed"),
})


# =====================================================================
# 7. THE SECRET ADMIRER
# =====================================================================
title("secret_admirer", "The Secret Admirer", "Someone has been leaving anonymous notes for {beloved}.")
L("sa_leave", ["*slides a folded note under {beloved}'s keyboard*", "*leaves a little note on {beloved}'s desk and walks away fast*"])
L("sa_find", ["'You make Mondays bearable.' No signature...", "Another anonymous note? Who IS this?"])
T("log.sa_leave", "Someone left an anonymous admiring note on {beloved}'s desk.")
start("start_secret_admirer", "secret_admirer", {"admirer": "actor", "beloved": "crush"},
      [actor([{"c": "picks", "fn": "crush_of", "of": "self"}, c_trait("self", "sociability", lt=0.7)], [s_trait("self", "sociability", -0.8), s_trait("self", "empathy", 0.5)]),
       by_fn("crush", "crush_of", of="actor", avail=False)], "romance",
      conditions=[c_bond("actor", "crush", "romance", neg=True), c_rel("actor", "crush", "romance", gt=18)], cooldown_days=6)
scene("sa_note", noise=0.6, allow_absent=True, conditions=[c_present("admirer")],
      effects=[say("admirer", "sa_leave"), emote("admirer", "love"), log("log.sa_leave", 2, "romance", who=["beloved"]), arc_next("wonder", wait=(15, 50))])
L("sa_guess", ["Was it you? The notes? Be honest.", "Somebody's leaving me notes. Is it you?"])
L("sa_wrong_yes", ["...Maybe.", "Guilty! I mean... yes?"])
L("sa_wrong_no", ["Notes? Not me. But I'm jealous!", "No... but now I want to know too."])
T("log.sa_guess_wrong", "{beloved} asked {suspect} if they were the secret admirer. {suspect} said yes. They are not.")
T("log.sa_guess_no", "{beloved} asked {suspect} about the secret notes. Not them. The mystery continues.")
scene("sa_wonder", noise=0.9, allow_absent=True, conditions=[c_present("beloved")],
      roles=[by_fn("suspect", "best_of", of="beloved", lim=-30, optional=True, exclude=["beloved", "admirer"])],
      effects=[say("beloved", "sa_find"), emote("beloved", "love"), mood("beloved", 10)],
      outcomes=[out("ask", [arc_next("guess", wait=(2, 6))], score=[s_trait("beloved", "curiosity", 1.0)], when=[c_filled("suspect")]),
                out("wait", [arc_next("reveal", days=1)], score=[s_const(0.4)])])
scene("sa_guess", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "sa_guess", to="target")],
      outcomes=[out("lie", [say("target", "sa_wrong_yes", to="actor", delay=1.6), rel("actor", "target", "romance", 8), log("log.sa_guess_wrong", 3, "romance"),
                            arc_next("reveal", wait=(30, 90))], score=[s_trait("target", "cunning", 1.0), s_rel("target", "actor", "romance", 0.02)]),
                out("no", [say("target", "sa_wrong_no", to="actor", delay=1.6), log("log.sa_guess_no", 2, "romance"), arc_next("reveal", wait=(30, 90))],
                    score=[s_trait("target", "honesty", 1.0)])])
L("sa_confess", ["The notes... they were me. All of them.", "I'm your secret admirer. Surprise?"])
L("sad_yes", ["...I was hoping it was you.", "Really? You? ...I'd like that."])
L("sa_kind_no", ["That's really sweet. But I don't feel the same. I'm sorry.", "I'm flattered. Truly. But... no."])
T("log.sa_yes", "{admirer} revealed they were the secret admirer. {beloved} was hoping it was them. A new couple!")
T("log.sa_no", "{admirer} revealed they were the secret admirer. {beloved} gently said no.")
scene("sa_reveal", noise=0.9, conditions=[c_present("admirer"), c_present("beloved")],
      effects=[hold(["admirer", "beloved"], 6), emote("admirer", "sweat"), say("admirer", "sa_confess", to="beloved")],
      outcomes=[out("yes", [say("beloved", "sad_yes", to="admirer", delay=1.8), emote("beloved", "love", delay=1.8), emote("admirer", "cheer", delay=2.4),
                            bond("admirer", "beloved", "romance"), rel("admirer", "beloved", "romance", 15, both=True), log("log.sa_yes", 4, "romance"), arc_end("together")],
                    score=[s_rel("beloved", "admirer", "romance", 0.04), s_aff("beloved", "admirer", 0.01)]),
                out("no", [say("beloved", "sa_kind_no", to="admirer", delay=1.8), expr("admirer", "sad", 8, delay=1.8), mood("admirer", -15), rel("admirer", "beloved", "romance", -20),
                           log("log.sa_no", 3, "romance"), arc_end("declined")], score=[s_const(1.2)])])
arc("secret_admirer", BIG, "note", cooldown_days=6, stages={
    "note": stage("sa_note", "desk", actor="admirer", target="beloved", ttl=80),
    "wonder": stage("sa_wonder", "now", actor="beloved", ttl=120, fail="reveal"),
    "guess": stage("sa_guess", "visit", actor="beloved", target="suspect", ttl=60, fail="reveal"),
    "reveal": stage("sa_reveal", "meet", actor="admirer", target="beloved", area="lounge", ttl=80, fail="end:never_told"),
})


# =====================================================================
# 8. THE STOLEN CLIENT
# =====================================================================
title("client_steal", "The Stolen Client", "{thief} has their eye on {victim}'s biggest client.")
L("cs_call", ["*on the phone* ...Yes, I'm handling the account now. {victim}? Oh, they're very busy.", "*whispering into phone* Let me take care of you personally."])
T("log.cs_call", "{thief} quietly called {victim}'s biggest client and offered to 'take care of them personally'.")
start("start_client_steal", "client_steal", {"thief": "actor", "victim": "@mert", "boss": "@ahmet"},
      [actor([c_trait("self", "cunning", gt=0.5), c_is("self", "mert", neg=True), c_is("self", "ahmet", neg=True), c_rel("self", "@mert", "rivalry", gt=4)],
             [s_trait("self", "cunning", 1.0), s_rel("self", "@mert", "rivalry", 0.02)])], "rivalry",
      conditions=[c_present("@mert"), c_present("@ahmet")], cooldown_days=6)
scene("cs_call", allow_absent=True, conditions=[c_present("thief")],
      effects=[act("thief", "phone", place="phone1", dur=5), say("thief", "cs_call", delay=1), favor("thief", 3),
               rumor("credit_steal", a="thief", b="victim", juicy=0.8, knowers=["thief"]), log("log.cs_call", 3, "scheme", who=["thief", "victim"]),
               arc_next("victim_learns", wait=(30, 90))])
L("cs_learn", ["My client says they've been 'working with {thief}'?!", "{thief} went behind my back to MY client!"])
T("log.cs_learn", "{victim} found out {thief} has been talking to their client behind their back.")
scene("cs_learn", allow_absent=True, conditions=[c_present("victim")],
      effects=[sfx("phone"), emote("victim", "phone"), expr("victim", "angry", 6, delay=1.4), say("victim", "cs_learn", delay=1.4), learn("victim", "$rumor", c=1.0),
               rel("victim", "thief", "resentment", 22), rel("victim", "thief", "rivalry", 15), log("log.cs_learn", 3, "scheme"), arc_next("race", wait=(5, 20))])
L("cs_pitch_boss", ["Ahmet Bey, that client is MINE. I built that account.", "Ahmet Bey, {thief} is poaching my client. I want it back."])
L("cs_boss_victim", ["You're right. Mert keeps the account. {thief}, back off.", "The account stays with you."])
L("cs_boss_thief", ["The client prefers {thief}. Results are results.", "Sorry. The client asked for {thief}."])
T("log.cs_victim_wins", "Ahmet ruled that {victim} keeps the client. {thief}'s poaching failed.")
T("log.cs_thief_wins", "Ahmet let {thief} keep {victim}'s client. {victim} is devastated.")
scene("cs_ruling", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5.5), say("actor", "cs_pitch_boss", to="target")],
      outcomes=[out("victim", [say("target", "cs_boss_victim", to="actor", delay=1.8), favor("thief", -8), favor("victim", 5), morale("victim", 6),
                               rel("target", "thief", "trust", -12), log("log.cs_victim_wins", 4, "boss"), arc_end("victim_keeps")],
                    score=[s_rel("target", "victim", "trust", 0.02), s_trait("target", "honesty", 0.6), {"s": "favor", "who": "victim", "w": 0.02}]),
                out("thief", [say("target", "cs_boss_thief", to="actor", delay=1.8), morale("victim", -12), favor("thief", 6), plan("victim", "revenge", "thief", heat=1.2),
                              plan("victim", "job_search", "", heat=0.5), log("log.cs_thief_wins", 4, "boss"), arc_end("thief_wins")],
                    score=[{"s": "favor", "who": "thief", "w": 0.02}, s_trait("target", "cunning", 0.5)])])
arc("client_steal", BIG, "call", cooldown_days=6, stages={
    "call": stage("cs_call", "place", actor="thief", place="phone1", wait=(5, 20), ttl=80, window=("09:40", "15:00")),
    "victim_learns": stage("cs_learn", "now", actor="victim", ttl=120, fail="end:never_found_out"),
    "race": stage("cs_ruling", "visit", actor="victim", target="boss", ttl=80, fail="end:thief_wins"),
})


# =====================================================================
# 9. THE EXPENSE SCANDAL
# =====================================================================
title("expense_scandal", "The Expense Scandal", "Zeynep found something odd in {suspect}'s expenses.")
L("es_spot", ["Hm. That's a lot of 'client lunches' for {suspect}.", "Three taxis to the same restaurant, {suspect}? On a Sunday?"])
T("log.es_spot", "Zeynep found something odd in {suspect}'s expense claims.")
start("start_expense_scandal", "expense_scandal", {"auditor": "@zeynep", "suspect": "suspect", "boss": "@ahmet"},
      [actor([c_is("self", "zeynep")], [s_trait("self", "curiosity", 1.0)]),
       role("suspect", where=[c_present("self"), c_is("self", "ahmet", neg=True)], score=[s_trait("self", "cunning", 1.0), s_rel("actor", "self", "rivalry", 0.02), s_rand(0.6)], exclude=["actor"])],
      "secret_plans", conditions=[c_present("@ahmet")], say_key=None, cooldown_days=7)
scene("es_spot", allow_absent=True, conditions=[c_present("auditor")],
      effects=[act("auditor", "archive", dur=5), say("auditor", "es_spot", delay=1), emote("auditor", "question", delay=1), log("log.es_spot", 2, "scheme", who=["suspect"]),
               arc_next("ask", wait=(10, 30))])
L("es_ask", ["{suspect}, can you explain these receipts?", "Quick question about your expenses, {suspect}..."])
L("es_explain", ["Those were legitimate! Client dinners!", "I can explain every single one."])
L("es_panic", ["...Can we keep this between us?", "Please don't take this to Ahmet."])
T("log.es_clear", "Zeynep questioned {suspect} about their expenses. Everything checked out.")
T("log.es_panic", "Zeynep questioned {suspect} about their expenses. {suspect} begged her to keep it quiet.")
scene("es_ask", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "es_ask", to="target")],
      outcomes=[out("clear", [say("target", "es_explain", to="actor", delay=1.6), rel("actor", "target", "trust", 6), log("log.es_clear", 2, "work"), arc_end("cleared")],
                    score=[s_trait("target", "honesty", 1.2)]),
                out("panic", [say("target", "es_panic", to="actor", delay=1.6), emote("target", "sweat", delay=1.6), rumor("scheme", a="target", b="actor", juicy=0.7, knowers=["actor"]),
                              log("log.es_panic", 3, "scheme"), arc_next("decide", wait=(5, 20))], score=[s_trait("target", "cunning", 0.8), s_trait("target", "honesty", -0.6)])])
L("es_report", ["Ahmet Bey, you need to see these expense claims.", "I found some irregularities. It's {suspect}."])
L("es_keep", ["...I'll keep it quiet. This time. You owe me.", "Our little secret. For now."])
T("log.es_report", "Zeynep reported {suspect}'s dodgy expenses to Ahmet.")
T("log.es_keep", "Zeynep decided to keep {suspect}'s expense secret — in exchange for a favour.")
scene("es_decide", noise=0.9, allow_absent=True, conditions=[c_present("auditor")],
      outcomes=[out("report", [arc_next("report", wait=(2, 8))],
                    score=[s_trait("auditor", "diligence", 0.8), s_rel("auditor", "suspect", "rivalry", 0.02)], when=[c_present("boss")]),
                out("keep", [say("auditor", "es_keep", delay=1), bond("auditor", "suspect", "alliance"), rel("suspect", "auditor", "trust", 6), log("log.es_keep", 3, "scheme"),
                             arc_end("blackmail")], score=[s_trait("auditor", "cunning", 1.0), s_aff("auditor", "suspect", 0.02)])])
scene("es_report_scene", conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "es_report", to="target"), expr("target", "angry", 5, delay=1.6), favor("suspect", -12), rel("target", "suspect", "trust", -18),
               call("scold", target="suspect", reason="general", prio=66, delay=3), log("log.es_report", 4, "scheme", who=["suspect"]), arc_end("reported")])
arc("expense_scandal", BIG, "spot", cooldown_days=7, stages={
    "spot": stage("es_spot", "now", actor="auditor", wait=(5, 20), ttl=80),
    "ask": stage("es_ask", "visit", actor="auditor", target="suspect", ttl=70, fail="end:dropped"),
    "decide": stage("es_decide", "now", actor="auditor", ttl=60, fail="end:dropped"),
    "report": stage("es_report_scene", "visit", actor="auditor", target="boss", ttl=90, fail="end:dropped"),
})


# =====================================================================
# 10. THE MENTOR MISMATCH
# =====================================================================
title("mentor_mismatch", "The Mentor Mismatch", "Ahmet has made {mentor} mentor {mentee}. Neither is thrilled.")
L("mm_assign", ["{mentor}, from today you're mentoring {mentee}. Make it work.", "New arrangement: {mentor} mentors {mentee}. Don't argue."])
L("mm_groan", ["...Great.", "Wonderful. Just wonderful.", "Of all people."])
T("log.mm_assign", "Ahmet paired {mentor} with {mentee} as mentor and mentee. They exchanged a look of pure dread.")
start("start_mentor_mismatch", "mentor_mismatch", {"boss": "actor", "mentor": "$a", "mentee": "$b"},
      [actor([c_is("self", "ahmet")], [s_const(1)])], "work_career", vars=[var("a", "rival_pair", lim=20)], cooldown_days=7)
scene("mm_assign", noise=0.6, allow_absent=True, conditions=[c_present("boss"), c_present("mentor"), c_present("mentee")],
      effects=[say("boss", "mm_assign"), say("mentor", "mm_groan", delay=1.6), say("mentee", "mm_groan", delay=2.6), log("log.mm_assign", 3, "work", who=["mentor", "mentee"]),
               arc_next("session", wait=(15, 45))])
L("mm_teach", ["Okay. Lesson one: how I do things. Which is correctly.", "Pay attention. I'll only explain this once."])
L("mm_useful", ["...Huh. That's actually really useful.", "Okay, I didn't know that. Thanks."])
L("mm_sabotage", ["(...and then you send it to the client without checking. Trust me.)", "(Always ignore Ahmet's deadlines. He loves that.)"])
T("log.mm_useful", "{mentor}'s first mentoring session with {mentee} was... actually helpful.")
T("log.mm_sabotage", "{mentor} gave {mentee} some very bad advice. On purpose.")
scene("mm_session", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5.5), say("actor", "mm_teach", to="target")],
      outcomes=[out("useful", [say("target", "mm_useful", to="actor", delay=1.8), work("target", 10), rel("target", "actor", "respect", 10), rel("actor", "target", "rivalry", -6, both=True),
                               log("log.mm_useful", 3, "help"), arc_next("evaluation", days=1)], score=[s_trait("actor", "empathy", 0.8), s_trait("actor", "honesty", 0.6)]),
                out("sabotage", [say("actor", "mm_sabotage", to="target", delay=1.8), npcflag("target", "bad_advice"), log("log.mm_sabotage", 3, "scheme"),
                                 arc_next("evaluation", days=1)], score=[s_trait("actor", "cunning", 1.0), s_rel("actor", "target", "rivalry", 0.02)])])
L("mm_eval_ask", ["So. How's the mentoring going, you two?", "Progress report. Both of you."])
L("mm_eval_good", ["Surprisingly well, actually.", "We've... figured it out."])
L("mm_eval_bad", ["{mentor} told me to ignore your deadlines!", "Ask {mentor} why my report went out unchecked."])
T("log.mm_good", "Ahmet checked on the mentoring. {mentor} and {mentee} have — astonishingly — become a good team.")
T("log.mm_bad", "Ahmet checked on the mentoring. {mentee} revealed {mentor}'s terrible advice. Ahmet is not pleased.")
scene("mm_eval", noise=0.8, conditions=[c_present("boss"), c_present("mentor"), c_present("mentee")],
      effects=[hold(["boss", "mentor", "mentee"], 5), say("boss", "mm_eval_ask")],
      outcomes=[out("good", [say("mentee", "mm_eval_good", delay=1.6), favor("mentor", 6), favor("mentee", 4), rel("mentor", "mentee", "friendship", 10, both=True),
                             log("log.mm_good", 3, "work"), arc_end("bonded")], score=[s_rel("mentee", "mentor", "respect", 0.03), s_const(0.3)],
                    when=[{"c": "npcflag", "who": "mentee", "key": "bad_advice", "not": True}]),
                out("bad", [say("mentee", "mm_eval_bad", delay=1.6), favor("mentor", -10), rel("boss", "mentor", "trust", -12), rel("mentee", "mentor", "resentment", 15),
                            log("log.mm_bad", 4, "boss"), arc_end("exposed")], score=[s_const(1)])])
arc("mentor_mismatch", BIG, "assign", cooldown_days=7, stages={
    "assign": stage("mm_assign", "now", actor="boss", wait=(3, 15), ttl=80),
    "session": stage("mm_session", "desk", actor="mentor", target="mentee", ttl=80, fail="evaluation"),
    "evaluation": stage("mm_eval", "now", actor="boss", ttl=200, fail="end:forgotten"),
})


# =====================================================================
# 11. THE RUMOUR WAR
# =====================================================================
title("rumor_war", "The Rumour War", "{gossip} and {enemy} are trading rumours about each other.")
L("rw_first", ["Did you know {enemy} once cried in the stationery cupboard? Twice?", "Between us: {enemy} still uses Comic Sans. On purpose."])
T("log.rw_first", "{gossip} fired the first shot: an embarrassing rumour about {enemy}.")
start("start_rumor_war", "rumor_war", {"gossip": "actor", "enemy": "enemy"},
      [actor([c_trait("self", "gossip", gt=0.55)], [s_trait("self", "gossip", 1.0), s_trait("self", "cunning", 0.5)]),
       by_fn("enemy", "worst_of", of="actor", lim=12)], "gossip", cooldown_days=5)
scene("rw_first", noise=0.6, allow_absent=True, conditions=[c_present("gossip"), c_present("enemy")],
      effects=[emote("gossip", "whisper"), say("gossip", "rw_first"), rumor("slacker", a="enemy", b="gossip", juicy=0.6, truth=False, knowers=["gossip"], origin="gossip"),
               each([learn("self", "$rumor", frm="gossip")], exclude=["gossip", "enemy"], where=[c_near("self", "gossip", 5)]), log("log.rw_first", 3, "rumor"),
               arc_next("retaliate", wait=(20, 60))])
L("rw_hear", ["{gossip} is saying WHAT about me?", "Oh, so that's the game, {gossip}? Fine."])
L("rw_back", ["Funny — I heard {gossip} reads other people's emails. Every day.", "You know {gossip} faked their CV? Ask anyone."])
T("log.rw_back", "{enemy} heard the rumour and hit back with one about {gossip}. The rumour war is on.")
scene("rw_retaliate", noise=0.6, allow_absent=True, conditions=[c_present("enemy")],
      roles=[by_fn("mediator", "mediator", a="gossip", b="enemy", optional=True, exclude=["gossip", "enemy"])],
      effects=[learn("enemy", "$rumor", c=0.9), expr("enemy", "angry", 5), say("enemy", "rw_hear"), say("enemy", "rw_back", delay=2),
               rumor("scheme", a="gossip", b="enemy", juicy=0.7, truth=False, knowers=["enemy"], origin="enemy", key="rumor2"),
               each([learn("self", "$rumor2", frm="enemy")], exclude=["gossip", "enemy"], where=[c_near("self", "enemy", 5)]),
               rel("gossip", "enemy", "resentment", 12, both=True), log("log.rw_back", 3, "rumor"), arc_next("sides", wait=(30, 80))])
L("rw_sides", ["Okay, this has to stop. Both of you. Kitchen. Now.", "Enough with the rumours. Let's sort this out like adults."])
L("rw_truce", ["...Fine. Truce. I'll stop if you stop.", "Okay. That got out of hand."])
L("rw_war", ["They started it!", "I'll stop when they apologise."])
T("log.rw_truce", "{mediator} sat {gossip} and {enemy} down in the kitchen. The rumour war ended in a truce.")
T("log.rw_war", "{mediator} tried to end the rumour war between {gossip} and {enemy}. It only got worse.")
scene("rw_sides", noise=0.9,
      effects=[say("mediator", "rw_sides", when=[c_filled("mediator"), c_zone("mediator", ["kitchen"])])],
      outcomes=[out("truce", [say("gossip", "rw_truce", delay=1.8), say("enemy", "rw_truce", delay=3.2), debunk("$rumor", who=["enemy"], by="gossip"),
                              rel("gossip", "enemy", "resentment", -10, both=True), stat("reconciliations"), log("log.rw_truce", 3, "friendship"), arc_end("truce")],
                    score=[s_trait("gossip", "empathy", 0.8), s_trait("enemy", "forgiveness", 0.8), s_const(0.3)], when=[c_filled("mediator"), c_zone("mediator", ["kitchen"])]),
                out("war", [say("gossip", "rw_war", delay=1.8), sfx("argue", delay=1.8), bond("gossip", "enemy", "feud"), stat("arguments"), storm("enemy", delay=3), log("log.rw_war", 4, "conflict"),
                            arc_end("feud")], score=[s_trait("gossip", "temper", 0.8), s_trait("enemy", "temper", 0.8), s_const(0.2)])])
arc("rumor_war", BIG, "first", cooldown_days=5, stages={
    "first": stage("rw_first", "now", actor="gossip", wait=(3, 12), ttl=80),
    "retaliate": stage("rw_retaliate", "now", actor="enemy", ttl=150, fail="end:ignored"),
    "sides": stage("rw_sides", "gather", actor="gossip", area="kitchen", need=3, ttl=80, fail="end:simmering", who=["gossip", "enemy", "mediator"], must=["gossip", "enemy"]),
})


# =====================================================================
# 12. THE OFFICE PARTY
# =====================================================================
title("office_party", "The Office Party", "{host} wants to throw a party. In the office. Today.")
L("op_pitch", ["Hear me out: party. Kitchen. 4 pm. Who's in?", "We need a party. I'm organising one. Today."], mert=["Party. Kitchen. Four o'clock. Spread the word, but not to Ahmet."])
L("op_ceren_yes", ["...Okay. A small one. I'll handle the snacks.", "Fine. But nobody touches the boss's mug."])
L("op_ceren_no", ["It's a Wednesday. No.", "Absolutely not. Ahmet would explode."])
T("log.op_yes", "{host} pitched an office party and {helper} said yes. Kitchen, 4 pm.")
T("log.op_no", "{host} pitched an office party. {helper} shut it down immediately.")
start("start_office_party", "office_party", {"host": "actor", "helper": "$helper", "boss": "@ahmet"},
      [actor([c_trait("self", "sociability", gt=0.75), c_trait("self", "humor", gt=0.5), c_time(before="14:30")],
             [s_trait("self", "sociability", 1.0), s_trait("self", "humor", 0.6), s_mood("self", 0.02)])], "socializing",
      vars=[var("helper", "best_of", of="actor", lim=0)], conditions=[{"c": "picks", "fn": "good_vibes"}], cooldown_days=6)
scene("op_pitch", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "op_pitch", to="target")],
      outcomes=[out("yes", [say("target", "op_ceren_yes", to="actor", delay=1.6), emote("actor", "cheer", delay=1.8), log("log.op_yes", 3, "celebration"),
                            arc_next("prep", wait=(20, 50))], score=[s_trait("target", "sociability", 0.8), s_aff("target", "actor", 0.02)]),
                out("no", [say("target", "op_ceren_no", to="actor", delay=1.6), mood("actor", -6), log("log.op_no", 2, "celebration"), arc_end("vetoed")],
                    score=[s_trait("target", "diligence", 0.8), s_const(0.2)])])
L("op_prep", ["*arranging snacks very quietly*", "Crisps here, cake there... nobody look.", "Party supplies. Totally normal kitchen supplies."])
L("op_boss_what", ["What's all this, {helper}?", "Why are there balloons in my kitchen?"])
L("op_cover", ["It's... the plant's birthday.", "Team-building snacks! Very professional.", "Healthy... motivational... cake."])
T("log.op_prep", "{helper} quietly set up snacks in the kitchen for {host}'s secret party.")
T("log.op_spotted", "Ahmet caught {helper} setting up party snacks. {helper} claimed it was 'the plant's birthday'. Ahmet looked unconvinced.")
scene("op_prep", noise=0.8, allow_absent=True, conditions=[c_present("helper")],
      effects=[say("helper", "op_prep"), emote("helper", "whisper"), log("log.op_prep", 2, "celebration", who=["helper", "host"])],
      outcomes=[out("spotted", [say("boss", "op_boss_what", to="helper", delay=1.6), emote("boss", "question", delay=1.6), say("helper", "op_cover", to="boss", delay=3.2),
                                emote("helper", "sweat", delay=3.2), rel("boss", "host", "suspicion", 15), rel("boss", "helper", "suspicion", 10), log("log.op_spotted", 3, "boss"),
                                arc_next("party", wait=(20, 50))], score=[s_const(5)], when=[c_present("boss"), c_near("boss", "helper", 5.5)]),
                out("quiet", [arc_next("party", wait=(20, 60))], score=[s_const(1)])])
L("op_dance", ["*dancing*", "Best. Wednesday. Ever.", "Who brought the speaker?!", "Snacks! Music! Freedom!"])
L("op_boss_join", ["...Is there cake? Fine. One slice.", "Hm. Five minutes. Then back to work."])
L("op_boss_stop", ["WHAT is going on in my kitchen?!", "This is a WORKPLACE! Party's over!"])
T("log.op_party", "The impromptu office party is in full swing in the kitchen.")
T("log.op_boss_join", "Ahmet walked in on the office party... and stayed for cake. Legendary.")
T("log.op_boss_stop", "Ahmet stormed in and shut the office party down.")
T("mem.op_party", "We had an amazing office party.")
T("log.op_secret", "The kitchen party went on for half an hour. Ahmet never found out. Probably.")
scene("op_party", noise=0.8,
      effects=[oset("music.genre", "pop"), each([say("self", "op_dance", p=0.5, delay=0.8), emote("self", "cheer"), mood("self", 10), stress("self", -8)],
                                                 where=[c_zone("self", ["kitchen"])], stagger=0.4),
               each([mem("self", "host", "party", 0.6, 0.7, "mem.op_party", 2)], exclude=["host"], where=[c_zone("self", ["kitchen"])]),
               log("log.op_party", 3, "celebration")],
      outcomes=[out("join", [say("boss", "op_boss_join", delay=3, when=[c_present("boss")]), rel("host", "boss", "friendship", 6), each([morale("self", 4)], where=[c_zone("self", ["kitchen"])]),
                             log("log.op_boss_join", 4, "celebration"), arc_end("legendary")], score=[s_mood("boss", 0.03), s_trait("boss", "empathy", 0.6), s_const(0.2)],
                    when=[c_zone("boss", ["kitchen"])]),
                out("stop", [say("boss", "op_boss_stop", delay=3, when=[c_present("boss")]), expr("boss", "angry", 6, delay=3), oset("music.genre", "", delay=3.2), favor("host", -6),
                             log("log.op_boss_stop", 4, "boss"), arc_end("shut_down")], score=[s_trait("boss", "temper", 1.0), s_stress("boss", 0.01)],
                    when=[c_zone("boss", ["kitchen"])]),
                out("secret", [log("log.op_secret", 3, "celebration"), each([morale("self", 3)], where=[c_zone("self", ["kitchen"])]), arc_end("secret")],
                    score=[s_const(5)], when=[c_zone("boss", ["kitchen"], neg=True)])])
arc("office_party", BIG, "pitch", cooldown_days=6, stages={
    "pitch": stage("op_pitch", "visit", actor="host", target="helper", wait=(3, 10), ttl=60, fail="end:vetoed"),
    "prep": stage("op_prep", "place", actor="helper", place="k1", ttl=70, fail="party"),
    "party": stage("op_party", "gather", actor="host", area="kitchen", need=4, ttl=60, window=("11:00", "17:15"), fail="end:no_show", must=["host"]),
})


# casts the automated story test uses to force-run each arc to an ending
TEST_CASTS = {
    "ghost_hunt": {"believer": "ece", "skeptic": "burak"},
    "office_coup": {"usurper": "deniz", "boss": "ahmet"},
    "love_triangle": {"lover": "mert", "crush": "ceren", "rival": "burak"},
    "salary_revolt": {"leader": "burak", "boss": "ahmet"},
    "lunch_mystery": {"victim": "burak", "detective": "zeynep"},
    "wrong_promotion": {"boss": "ahmet", "credited": "ece", "rightful": "selin"},
    "secret_admirer": {"admirer": "mert", "beloved": "ceren"},
    "client_steal": {"thief": "deniz", "victim": "mert", "boss": "ahmet"},
    "expense_scandal": {"auditor": "zeynep", "suspect": "deniz", "boss": "ahmet"},
    "mentor_mismatch": {"boss": "ahmet", "mentor": "selin", "mentee": "deniz"},
    "rumor_war": {"gossip": "ceren", "enemy": "deniz"},
    "office_party": {"host": "mert", "helper": "ceren", "boss": "ahmet"},
}
for _a in _sh.A:
    if _a["id"] in TEST_CASTS:
        _a["test"] = TEST_CASTS[_a["id"]]
