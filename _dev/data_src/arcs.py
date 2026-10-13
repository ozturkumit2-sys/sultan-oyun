# Story arcs -> data/arcs.json (+ their stage events in data/events.json)
#
# An arc is a multi-stage story that can run over several days. Each stage:
#   event   : the data event that plays the stage
#   mode    : now | visit (actor walks to target) | desk (to target's desk) |
#             place (actor walks to a spot) | meet (both walk to an area) |
#             gather (everyone walks to an area)
#   wait    : minutes after the previous stage   window : time of day it may play
#   ttl     : how long people try before the stage fails -> `fail`
# A stage's outcome calls arc_next(...) (maybe a different branch, maybe the next
# day) or arc_end(result). Cast members are named roles ({thief}, {victim}...),
# and anyone a stage event recruits (e.g. a confidant) joins the cast.
from story_helpers import *  # noqa: F401,F403

BIG = "big"

def starter(id, arc_id, cast, roles, conditions=None, vars=None, effects=None, cooldown_days=4, drive_say=None, weight=1.0, tier=BIG, urgent=False):
    eff = []
    if drive_say:
        eff.append(say("actor", drive_say))
    eff += (effects or [])
    eff.append(arc_start(arc_id, cast))
    conds = (conditions or []) + [{"c": "can_arc", "arc": arc_id, "cast": cast}]
    extra = {"urgent": True} if urgent else {}
    initiative(id, tier, roles=roles, conditions=conds, vars=vars, effects=eff, cooldown_days=cooldown_days, scope="global", weight=weight, **extra)

def T(k, v):  # log/memory text
    S_(k, v)

# =====================================================================
# 1. THE STOLEN IDEA — someone pitches a rival's idea as their own
# =====================================================================
L("si_think", ["{victim}'s client proposal is brilliant. Shame if it stayed theirs.", "Some ideas are too good for the person who had them.",
               "Ahmet would love that proposal. From the right person."], deniz=["Selin's draft is on her screen again. Careless of her."])
starter("start_stolen_idea", "stolen_idea", {"thief": "actor", "victim": "victim", "boss": "@ahmet"},
        roles=[actor([c_trait("self", "cunning", gt=0.55), c_trait("self", "ambition", gt=0.55), c_is("self", "ahmet", neg=True), c_present("@ahmet")],
                     [s_trait("self", "cunning", 1.2), s_goal("self", "earn_promotion", 0.8)]),
               by_fn("victim", "rival_of", lim=30, avail=False)],
        drive_say="si_think", effects=[emote("actor", "idea")])

L("si_pitch", ["Ahmet Bey, I've been working on something. A new client workflow — saves us a week per project.",
               "Got five minutes? I have an idea that could change how we pitch.", "I've drafted a proposal. Bit of a game changer, if I say so myself."])
L("si_boss_wow", ["...That's actually brilliant. Why didn't anyone think of this before?", "Now THIS is what I like to see.", "Excellent. Write it up."])
T("log.si_pitch", "{thief} pitched {victim}'s client idea to Ahmet — as their own.")
scene("si_pitch", conditions=[c_avail("boss")],
    effects=[hold(["thief", "boss"], 5), say("thief", "si_pitch", to="boss"), say("boss", "si_boss_wow", to="thief", delay=1.8), emote("boss", "idea", delay=1.8),
             favor("thief", 8), rumor("credit_steal", a="thief", b="victim", juicy=0.85, knowers=["thief"]), log("log.si_pitch", 3, "scheme", who=["thief", "victim"]),
             arc_next("praise", wait=(10, 40))])

L("si_praise", ["Everyone! Listen up. {thief} has come up with an excellent proposal. Initiative! Learn from it!",
                "I want you all to know: {thief}'s new workflow idea is exactly the thinking this office needs."])
L("si_victim_what", ["...Wait. That's MY idea.", "Excuse me? That's my proposal.", "That's... that's what I've been working on for two weeks."])
L("si_thief_smug", ["Thank you, Ahmet Bey. Just doing my job.", "Happy to contribute."])
T("log.si_praise_heard", "Ahmet praised {thief}'s \"new idea\" in front of everyone. {victim} recognised it immediately.")
T("log.si_praise_away", "Ahmet praised {thief}'s \"new idea\" in front of everyone. {victim} wasn't there to hear it.")
T("mem.si_heard_my_idea", "Ahmet praised {thief} for an idea that sounds a lot like mine.")
scene("si_praise", conditions=[c_avail("boss"), c_present("thief")],
    effects=[hold(["boss", "thief"], 4.5), say("boss", "si_praise"), say("thief", "si_thief_smug", delay=2.0), emote("thief", "cheer", delay=2.0),
             witness([emote("self", "exclaim", delay=1.0), rel("self", "thief", "friendship", 2)], near="boss", r=6, exclude=["boss", "thief", "victim"])],
    outcomes=[
        out("heard", [say("victim", "si_victim_what", delay=3.2), expr("victim", "surprised", 5, delay=3.0), emote("victim", "question", delay=3.0),
                      learn("victim", "$rumor", c=0.55), mood("victim", -10), mem("victim", "thief", "suspicion", -0.4, 0.7, "mem.si_heard_my_idea", 2),
                      log("log.si_praise_heard", 3, "scheme", who=["thief", "victim"]), arc_next("suspicion", wait=(3, 12))],
            score=[s_const(3)], when=[c_present("victim"), {"c": "near", "a": "victim", "b": "boss", "lt": 7.5}]),
        out("away", [learn("victim", "$rumor", c=0.45), log("log.si_praise_away", 3, "scheme", who=["thief", "victim"]),
                     arc_next("suspicion", wait=(30, 70))], score=[s_const(1)]),
    ])

L("si_suspect", ["That was my idea. Wasn't it? Was my screen open when he walked by?", "Did {thief} see my draft? He must have...",
                 "I can't prove anything. Yet."], selin=["I will not let this go. I need proof."])
L("si_let_go", ["Maybe great minds think alike. ...Ugh.", "Whatever. I'll have a better one."])
T("log.si_suspicion", "{victim} is quietly sure {thief} stole their idea — but has no proof. Yet.")
T("log.si_brood", "{victim} has decided to get even with {thief} instead of proving anything.")
T("log.si_let_go", "{victim} decided it wasn't worth the fight. For now.")
scene("si_suspicion", noise=0.9, allow_absent=True, conditions=[c_avail("victim")],
    roles=[by_fn("confidant", "best_of", of="victim", lim=12, optional=True, avail=False, exclude=["victim", "thief", "boss"])],
    effects=[expr("victim", "angry", 5), emote("victim", "question"), say("victim", "si_suspect")],
    outcomes=[
        out("investigate", [log("log.si_suspicion", 2, "scheme", who=["victim", "thief"]), arc_next("ask_confidant", wait=(4, 15))],
            score=[s_trait("victim", "curiosity", 0.6), s_trait("victim", "honesty", 0.6), s_trait("victim", "temper", 0.4), s_const(0.6)],
            when=[c_filled("confidant")]),
        out("brood", [plan("victim", "revenge", "thief", heat=1.4), rel("victim", "thief", "rivalry", 12),
                      mem("victim", "thief", "credit_stolen", -0.7, 0.9, "mem.credit_stolen", 3), log("log.si_brood", 3, "scheme", who=["victim", "thief"]),
                      arc_end("grudge")], score=[s_trait("victim", "forgiveness", -1.0), s_trait("victim", "cunning", 0.6), s_const(0.2)]),
        out("let_go", [say("victim", "si_let_go", delay=1.6), mood("victim", -6), log("log.si_let_go", 2, "scheme", who=["victim"]), arc_end("let_go")],
            score=[s_trait("victim", "forgiveness", 1.2), s_const(0.2)]),
    ])

L("si_ask", ["Did you see {thief} anywhere near my desk this week?", "Be honest. Did {thief} come up with that proposal himself?",
             "I think {thief} stole my idea. Tell me I'm not crazy."])
L("si_conf_knows", ["You're not crazy. I heard he copied it.", "I KNEW something was off. Everyone's whispering about it."])
L("si_conf_burak", ["Ask Burak. He can see who opened which files.", "Burak keeps logs of everything. EVERYTHING."])
L("si_conf_dismiss", ["Aren't you being a bit paranoid?", "Ideas float around. Let it go.", "I didn't see anything. Sorry."])
T("log.si_conf_knows", "{confidant} confirmed {victim}'s suspicion: {thief} copied the idea.")
T("log.si_conf_burak", "{confidant} suggested {victim} ask Burak to check the file logs.")
T("log.si_conf_dismiss", "{confidant} told {victim} they were being paranoid. {victim} is left with nothing.")
scene("si_ask", noise=0.9, conditions=[c_present("victim"), c_present("confidant")],
    effects=[hold(["victim", "confidant"], 5), emote("victim", "whisper"), say("victim", "si_ask", to="confidant")],
    outcomes=[
        out("knows", [say("confidant", "si_conf_knows", to="victim", delay=1.8), learn("victim", "$rumor", frm="confidant"), learn("victim", "$rumor", c=0.85),
                      rel("victim", "confidant", "trust", 8), log("log.si_conf_knows", 3, "scheme", who=["confidant", "victim"]),
                      arc_next("showdown", wait=(5, 25))], score=[s_const(3)], when=[c_knows("confidant", "$rumor")]),
        out("burak", [say("confidant", "si_conf_burak", to="victim", delay=1.8), log("log.si_conf_burak", 2, "scheme", who=["confidant", "victim"]),
                      arc_next("evidence", wait=(5, 20))],
            score=[s_trait("confidant", "empathy", 0.6), s_const(0.8)], when=[c_present("@burak"), c_is("thief", "burak", neg=True), c_is("victim", "burak", neg=True)]),
        out("dismiss", [say("confidant", "si_conf_dismiss", to="victim", delay=1.8), rel("victim", "confidant", "trust", -4), mood("victim", -5),
                        plan("victim", "revenge", "thief", heat=0.8), log("log.si_conf_dismiss", 2, "scheme", who=["confidant", "victim"]), arc_end("buried")],
            score=[s_trait("confidant", "cunning", 0.6), s_aff("confidant", "thief", 0.015), s_const(0.3)]),
    ])

L("si_ask_burak", ["Burak, can you check who opened my proposal file last week?", "I need a favour. File logs. Quietly."])
L("si_burak_found", ["Copied from {thief}'s machine. Tuesday, 8:52 a.m. You didn't hear it from me.", "There. {thief}'s PC. Twice. Happy?"])
L("si_burak_no", ["I don't do office politics.", "Not my business. Sorry.", "If I start checking logs for everyone, I'll never leave."])
T("log.si_evidence", "Burak checked the file logs for {victim}: the proposal was copied from {thief}'s computer.")
T("log.si_no_evidence", "Burak refused to check the logs for {victim}. No proof.")
scene("si_evidence", noise=0.9, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), say("actor", "si_ask_burak", to="target")],
    outcomes=[
        out("found", [say("target", "si_burak_found", to="actor", delay=2.0), emote("actor", "exclaim", delay=2.0), learn("actor", "$rumor", c=1.0),
                      learn("target", "$rumor", c=1.0), rel("actor", "target", "trust", 12), rel("actor", "target", "friendship", 8),
                      log("log.si_evidence", 3, "scheme", who=["target", "victim"]), arc_next("showdown", wait=(5, 25))],
            score=[s_aff("target", "actor", 0.025), s_trait("target", "honesty", 0.8), s_const(0.2)]),
        out("refuse", [say("target", "si_burak_no", to="actor", delay=2.0), mood("actor", -6), plan("actor", "revenge", "thief", heat=1.0),
                       log("log.si_no_evidence", 2, "scheme", who=["target", "victim"]), arc_end("hidden")],
            score=[s_goal("target", "find_new_job", 0.6), s_stress("target", 0.01), s_aff("target", "actor", -0.015), s_const(0.7)]),
    ])

L("si_showdown", ["Ahmet Bey, the workflow proposal was mine. I can prove it.", "I need to show you something about {thief}'s \"idea\".",
                  "{thief} stole my proposal. Here are the file logs."])
L("si_boss_believes", ["...Get {thief} in here. Now.", "This is unacceptable. Thank you for telling me.", "I see. I'll deal with this personally."])
L("si_boss_dismiss", ["I don't have time for office politics.", "Ideas belong to the company, not to people.", "Sort it out between yourselves."])
T("log.si_exposed", "{victim} proved to Ahmet that {thief} stole their idea. {thief}'s reputation just collapsed.")
T("log.si_buried", "{victim} took the stolen idea to Ahmet. He didn't want to hear it. {victim} and {thief} aren't speaking.")
T("mem.si_exposed", "{victim} exposed me to Ahmet.")
T("mem.si_vindicated", "Ahmet believed me about {thief}.")
scene("si_showdown", noise=0.9, conditions=[c_present("victim"), c_present("boss")],
    effects=[hold(["victim", "boss"], 6), say("victim", "si_showdown", to="boss")],
    outcomes=[
        out("exposed", [say("boss", "si_boss_believes", to="victim", delay=2.0), expr("boss", "angry", 7, delay=2.0), favor("thief", -18), favor("victim", 12),
                        rel("boss", "thief", "trust", -25), rel("boss", "victim", "trust", 10), morale("victim", 8), mood("victim", 15),
                        mem("victim", "boss", "recognized", 0.6, 0.8, "mem.si_vindicated", 3),
                        mem("thief", "victim", "humiliated", -0.8, 1.0, "mem.si_exposed", 3), plan("thief", "revenge", "victim", heat=1.2),
                        reveal("$rumor"), each([learn("self", "$rumor", frm="victim", c=0.8)], exclude=["thief"]),
                        call("scold", target="thief", reason="general", prio=70, delay=3),
                        log("log.si_exposed", 5, "scheme", who=["victim", "thief"]), arc_end("exposed")],
            score=[s_rel("boss", "victim", "trust", 0.015), s_sure("victim", "$rumor", 0.8), s_rel("boss", "thief", "trust", -0.01)]),
        out("buried", [say("boss", "si_boss_dismiss", to="victim", delay=2.0), morale("victim", -10), mood("victim", -12),
                       bond("victim", "thief", "feud"), mem("victim", "thief", "credit_stolen", -0.8, 1.0, "mem.credit_stolen", 3),
                       log("log.si_buried", 4, "scheme", who=["victim", "thief"]), arc_end("buried")],
            score=[s_rel("boss", "thief", "trust", 0.02), s_trait("boss", "temper", 0.5), s_stress("boss", 0.01), s_const(0.6)]),
    ])

arc("stolen_idea", BIG, "pitch", cooldown_days=4, stages={
    "pitch": stage("si_pitch", "visit", actor="thief", target="boss", wait=(5, 20), ttl=70, window=("10:00", "15:30")),
    "praise": stage("si_praise", "visit", actor="boss", target="thief", ttl=80, fail="suspicion"),
    "suspicion": stage("si_suspicion", "now", actor="victim", ttl=150, fail="end:faded"),
    "ask_confidant": stage("si_ask", "meet", actor="victim", target="confidant", area="kitchen", ttl=60, fail="end:buried"),
    "evidence": stage("si_evidence", "visit", actor="victim", target="@burak", ttl=70, fail="end:hidden"),
    "showdown": stage("si_showdown", "meet", actor="victim", target="boss", area="boss", ttl=90, fail="retry"),
})

# =====================================================================
# 2. OFFICE ROMANCE — a crush, a secret date, getting caught, a decision
# =====================================================================
L("rom_think", ["Today's the day. I'm asking {crush} for coffee.", "Okay. Be cool. Be normal. Talk to {crush}.", "Deep breath. {crush}. Coffee. Words."],
  mert=["Mert, you close deals for a living. Close THIS one."])
starter("start_romance", "office_romance", {"lover": "actor", "crush": "crush"},
        roles=[actor([{"c": "picks", "fn": "crush_of", "of": "self"}], [s_goal("self", "win_ceren", 1.0), s_trait("self", "sociability", 0.4)]),
               by_fn("crush", "crush_of", where=[c_aff("self", "actor", gt=18)])],
        conditions=[c_bond("actor", "crush", "romance", neg=True), c_aff("actor", "crush", gt=25)],
        drive_say="rom_think", effects=[emote("actor", "love")], cooldown_days=5)

L("rom_ask", ["So... I was wondering. Coffee? Just us? Kitchen, later?", "You, me, terrible office coffee. Say three o'clock?",
              "Can I steal you for a coffee later? I promise to be charming."], mert=["I've rehearsed this. Coffee? With me? Later? ...That was the whole speech."])
L("rom_yes", ["...Okay. Yes. Later.", "I'd like that.", "Ha. Fine. You're buying."], ceren=["Fifteen minutes. Don't make it weird."])
L("rom_no", ["Oh — that's sweet. But let's keep it professional.", "I think we're better as friends.", "Ah... I'm really busy today. And... in general."])
T("log.rom_spark", "{lover} asked {crush} out for a quiet coffee. {crush} said yes!")
T("log.rom_friendzone", "{lover} asked {crush} out for coffee. Friend-zoned.")
T("mem.rom_no", "{crush} turned me down.")
scene("rom_spark", noise=0.9, conditions=[c_avail("crush")],
    effects=[hold(["lover", "crush"], 5), say("lover", "rom_ask", to="crush"), emote("lover", "sweat")],
    outcomes=[
        out("yes", [say("crush", "rom_yes", to="lover", delay=1.8), emote("crush", "love", delay=1.8), expr("lover", "happy", 6, delay=1.8),
                    mood("lover", 15), rel("crush", "lover", "friendship", 6), log("log.rom_spark", 3, "romance", who=["lover", "crush"]),
                    arc_next("date", wait=(20, 60))],
            score=[s_aff("crush", "lover", 0.03), s_mood("crush", 0.01), s_rand(0.4)]),
        out("no", [say("crush", "rom_no", to="lover", delay=1.8), expr("lover", "sad", 6, delay=1.8), mood("lover", -18), morale("lover", -3),
                   mem("lover", "crush", "rejected", -0.4, 0.8, "mem.rom_no", 3), log("log.rom_friendzone", 3, "romance", who=["lover", "crush"]),
                   arc_end("friendzoned")],
            score=[s_const(1.2), s_aff("crush", "lover", -0.01), s_stress("crush", 0.01)]),
    ])

L("rom_date", ["So. This is nice.", "I may have saved you the last good mug.", "Tell me something nobody here knows about you."])
L("rom_date_reply", ["You first.", "...I collect snow globes. Don't laugh.", "This is the best fifteen minutes of my week."])
T("log.rom_date", "{lover} and {crush} had their secret coffee date in the kitchen. They're definitely a thing now.")
scene("rom_date", conditions=[c_present("lover"), c_present("crush")],
    effects=[hold(["lover", "crush"], 6), say("lover", "rom_date", to="crush"), say("crush", "rom_date_reply", to="lover", delay=1.8),
             emote("lover", "love", delay=2.0), emote("crush", "love", delay=2.4), expr("lover", "happy", 8), expr("crush", "happy", 8, delay=1.8),
             rel("lover", "crush", "friendship", 12, both=True), rel("lover", "crush", "trust", 6, both=True), bond("lover", "crush", "romance"), flag("couple", True),
             mood("lover", 12), mood("crush", 10), log("log.rom_date", 3, "romance", who=["lover", "crush"]), arc_next("second_date", days=1)])

L("rom_spotted", ["WELL, well, well.", "I KNEW IT. I knew it!", "Oh this is too good."], zeynep=["And THAT is going in my notebook."], mert=["Get a room! A meeting room!"])
T("log.rom_caught", "{spotter} walked in on {lover} and {crush}'s cosy kitchen moment. The secret is out — sort of.")
T("log.rom_unseen", "{lover} and {crush} snuck another coffee together. Nobody noticed. Yet.")
scene("rom_caught", noise=0.9, conditions=[c_present("lover"), c_present("crush")],
    roles=[role("spotter", where=[c_avail("self")], score=[s_trait("self", "gossip", 1.2), s_trait("self", "curiosity", 0.6)],
                near="lover", r=6.5, optional=True, exclude=["lover", "crush"])],
    effects=[hold(["lover", "crush"], 5), say("lover", "date_whisper", to="crush"), emote("crush", "love", delay=1.6), rel("lover", "crush", "friendship", 5, both=True)],
    outcomes=[
        out("caught", [say("spotter", "rom_spotted", delay=2.2), emote("spotter", "exclaim", delay=2.2), emote("lover", "sweat", delay=2.8),
                       emote("crush", "sweat", delay=2.8), rumor("couple", a="lover", b="crush", juicy=0.9, knowers=["spotter"]),
                       log("log.rom_caught", 3, "romance", who=["spotter", "lover"]), arc_next("rumor", wait=(5, 25))],
            score=[s_const(2)], when=[c_filled("spotter")]),
        out("unseen", [log("log.rom_unseen", 2, "romance", who=["lover", "crush"]), arc_next("decision", days=1)], score=[s_const(1)]),
    ])

L("rom_gossip_start", ["Oh, I have to tell someone. I HAVE to.", "This cannot stay in my head."])
L("rom_gossip_tell", ["Guess who I caught being VERY cosy in the kitchen? {lover} and {crush}!", "{lover} and {crush}. Kitchen. Holding mugs. MEANINGFULLY."])
L("rom_gossip_react", ["No WAY.", "I knew it! The way they look at each other!", "Get OUT."])
T("log.rom_gossip", "{spotter} is telling {listener} all about {lover} and {crush}.")
scene("rom_gossip_start", conditions=[c_avail("spotter")],
    roles=[role("listener", where=[c_avail("self")], score=[s_trait("self", "gossip", 1.0), s_aff("spotter", "self", 0.01)],
                exclude=["spotter", "lover", "crush"], optional=True)],
    effects=[say("spotter", "rom_gossip_start"), visit("spotter", "listener", "rom_gossip_scene", prio=58, ttl=40, when=[c_filled("listener")],
                                                       roles={"lover": "lover", "crush": "crush"}),
             arc_next("decision", days=1)])
scene("rom_gossip_scene", conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 4.5), emote("actor", "whisper"), distort("$rumor", "actor", 1.0, key="rumor"), say("actor", "rom_gossip_tell", to="target"),
             learn("target", "$rumor", frm="actor"), say("target", "rom_gossip_react", delay=1.8), stat("rumors"),
             log("log.rom_gossip", 2, "rumor", who=["actor", "lover"])])

L("rom_decide_open", ["So... people are talking.", "Everyone knows, don't they.", "We need to talk about... us. And them."])
L("rom_public", ["Let them talk. I'm not hiding you.", "Honestly? I don't care who knows.", "We're adults. Let's just tell them."])
L("rom_secret", ["Let's keep it quiet. Just a bit longer.", "Not yet. Ahmet would make it weird.", "Our secret. For now."])
L("rom_breakup", ["Maybe this was a mistake. At work, I mean.", "I don't think I can do this with everyone watching.", "Let's... go back to being colleagues."])
L("rom_congrats", ["Aww! Finally!", "You two! Congrats!", "I knew it from DAY ONE."])
T("log.rom_public", "{lover} and {crush} stopped hiding it: they're officially together. The office cheered.")
T("log.rom_secret", "{lover} and {crush} decided to keep their relationship a secret. Good luck with that.")
T("log.rom_breakup", "{lover} and {crush} called it off. The kitchen will never be the same.")
T("mem.rom_breakup", "{crush} and I broke up.")
scene("rom_decision", noise=0.9, conditions=[c_present("lover"), c_present("crush")],
    effects=[hold(["lover", "crush"], 6), say("lover", "rom_decide_open", to="crush")],
    outcomes=[
        out("public", [say("crush", "rom_public", to="lover", delay=1.8), emote("lover", "cheer", delay=1.8), emote("crush", "love", delay=1.8),
                       mood("lover", 15), mood("crush", 15), morale("lover", 4), morale("crush", 4),
                       rumor("couple", a="lover", b="crush", juicy=0.6, knowers=[]), each([learn("self", "$rumor", c=1.0), say("self", "rom_congrats", p=0.35, delay=3.0)],
                                                                                      exclude=["lover", "crush"]),
                       log("log.rom_public", 4, "romance", who=["lover", "crush"]), arc_end("public")],
            score=[s_aff("crush", "lover", 0.02), s_mood("crush", 0.01), s_trait("crush", "honesty", 0.5)]),
        out("secret", [say("crush", "rom_secret", to="lover", delay=1.8), emote("lover", "ok", delay=1.8), log("log.rom_secret", 3, "romance", who=["lover", "crush"]),
                       arc_end("secret")],
            score=[s_trait("crush", "cunning", 0.6), s_const(0.5)]),
        out("breakup", [say("crush", "rom_breakup", to="lover", delay=1.8), expr("lover", "sad", 8, delay=1.8), expr("crush", "sad", 6, delay=1.8),
                        bond("lover", "crush", "romance", v=False), flag("couple", False), mood("lover", -25), morale("lover", -6), mood("crush", -8),
                        mem("lover", "crush", "heartbreak", -0.6, 0.9, "mem.rom_breakup", 3), log("log.rom_breakup", 4, "romance", who=["lover", "crush"]),
                        arc_end("breakup")],
            score=[s_stress("crush", 0.015), s_aff("crush", "lover", -0.01), s_const(0.7)]),
    ])

arc("office_romance", BIG, "spark", cooldown_days=5, stages={
    "spark": stage("rom_spark", "visit", actor="lover", target="crush", wait=(5, 20), ttl=60),
    "date": stage("rom_date", "meet", actor="lover", target="crush", area="kitchen", ttl=60, fail="retry"),
    "second_date": stage("rom_caught", "meet", actor="lover", target="crush", area="kitchen", ttl=70, fail="decision", window=("10:00", "16:30")),
    "rumor": stage("rom_gossip_start", "now", actor="spotter", ttl=60, fail="decision"),
    "decision": stage("rom_decision", "meet", actor="lover", target="crush", area="lounge", ttl=80, fail="retry"),
})

# =====================================================================
# 3. HEADHUNTED — a recruiter call, a "dentist appointment", an offer
# =====================================================================
starter("start_headhunted", "headhunted", {"seeker": "actor", "boss": "@ahmet"},
        roles=[actor([c_is("self", "ahmet", neg=True), c_any(c_goal("self", "find_new_job"), c_plan("self", "job_search")), c_morale("self", lt=62),
                      c_time(after="09:40", before="12:30"), c_present("@ahmet")],
                     [s_goal("self", "find_new_job", 1.0), s_plan("self", "job_search", 1.0), s_morale("self", -0.02)])],
        cooldown_days=5)

L("hh_call", ["Yes, this is {seeker}. ...Today? At two? I'll make it work.", "A second interview? Absolutely. I'll be there.", "Mm-hm. Yes. Quietly, please."])
L("hh_overheard", ["...Interview? Today?", "Was that a recruiter?!", "Ooh. Someone's got plans."])
T("log.hh_call", "{seeker} took a whispered call in the hallway: a job interview, this afternoon.")
T("log.hh_call_heard", "{seeker} took a whispered call about a job interview — and {listener} heard every word.")
scene("hh_call",
    roles=[role("listener", where=[c_avail("self")], score=[s_trait("self", "curiosity", 1.0)], near="seeker", r=4.5, optional=True, exclude=["seeker", "boss"])],
    effects=[act("seeker", "phone", place="phone4", dur=5), say("seeker", "hh_call"), plan("seeker", "job_search", "", heat=0.6)],
    outcomes=[
        out("heard", [say("listener", "hh_overheard", delay=2.0), emote("listener", "exclaim", delay=2.0),
                      rumor("interview", a="seeker", b="listener", juicy=0.85, knowers=["listener"], c=0.75), log("log.hh_call_heard", 3, "job", who=["seeker", "listener"]),
                      arc_next("excuse", wait=(10, 35))], score=[s_const(2)], when=[c_filled("listener")]),
        out("quiet", [log("log.hh_call", 2, "job", who=["seeker"]), arc_next("excuse", wait=(10, 35))], score=[s_const(1)]),
    ])

L("hh_excuse", ["Ahmet Bey, I need to step out for an hour. Dentist.", "I have a... doctor's appointment. This afternoon. Urgent.", "Family thing. Back in an hour, promise."],
  burak=["Dentist. Again. My teeth are... complicated."])
L("hh_ok", ["Fine. One hour.", "Go. Don't make it a habit.", "Hm. Alright."])
L("hh_no", ["AGAIN? No. We have a deadline.", "Absolutely not. Not today.", "Your teeth can wait."])
L("hh_sneak", ["Fine. I'll just... go anyway.", "...Then I'll take a very long lunch."])
T("log.hh_excuse", "{seeker} told Ahmet they had a dentist appointment. (They don't.)")
T("log.hh_excuse_no", "{seeker} asked to leave for a \"dentist appointment\". Ahmet said no. {seeker} is going anyway.")
scene("hh_excuse", noise=0.9, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 4.5), say("actor", "hh_excuse", to="target")],
    outcomes=[
        out("allowed", [say("target", "hh_ok", to="actor", delay=1.8), log("log.hh_excuse", 2, "job", who=["seeker"]), arc_next("away", wait=(2, 8))],
            score=[s_rel("target", "actor", "trust", 0.025), s_mood("target", 0.01), s_const(0.4)]),
        out("refused", [say("target", "hh_no", to="actor", delay=1.8), say("actor", "hh_sneak", delay=3.4), morale("actor", -5), setv("sneaked", True),
                        log("log.hh_excuse_no", 3, "job", who=["seeker"]), arc_next("away", wait=(15, 35))],
            score=[s_trait("target", "temper", 0.9), s_stress("target", 0.012)]),
    ])

L("hh_leaving", ["Right. Off to the... dentist.", "Back soon!", "*grabs jacket, leaves quickly*"])
T("log.hh_out", "{seeker} left the office for their \"dentist appointment\" — in their best shirt.")
scene("hh_leave", conditions=[c_avail("seeker")],
    effects=[say("seeker", "hh_leaving"), away("seeker", 55, "interview", delay=0.5), log("log.hh_out", 2, "job", who=["seeker"]),
             witness([emote("self", "question", delay=1.0)], near="seeker", r=5, exclude=["seeker"]), arc_next("questions", wait=(60, 80))])

L("hh_boss_ask", ["Long dentist appointment. With a tie?", "Your teeth look exactly the same.", "So. How was the... dentist?"])
L("hh_bluff", ["Root canal. Very painful. Don't ask.", "They were running late!", "...It went fine. Thanks."])
L("hh_boss_suspicious", ["Hm. I'm watching you.", "I wasn't born yesterday.", "Mm-hm."])
L("hh_boss_fine", ["Get some rest then.", "Fine. Back to work.", "Hm. Take care of those teeth."])
T("log.hh_suspected", "Ahmet noticed {seeker} came back from the \"dentist\" in a suit. He's suspicious.")
T("log.hh_unsuspected", "{seeker} came back from the \"interview\". Ahmet didn't suspect a thing.")
scene("hh_suspicion", noise=0.9, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 4.5), say("actor", "hh_boss_ask", to="target"), say("target", "hh_bluff", to="actor", delay=1.8), emote("target", "sweat", delay=1.8)],
    outcomes=[
        out("suspects", [say("actor", "hh_boss_suspicious", to="target", delay=3.4), rel("actor", "target", "trust", -10), favor("target", -4),
                         learn("actor", "$rumor", c=0.6, when=[c_filled("$rumor")]), log("log.hh_suspected", 3, "job", who=["seeker", "boss"]),
                         arc_next("offer", days=1)],
            score=[s_const(1.5)], when=[c_any(c_var("sneaked", eq=True), c_knows("actor", "$rumor"), c_trait("actor", "curiosity", gt=0.5))]),
        out("buys", [say("actor", "hh_boss_fine", to="target", delay=3.4), log("log.hh_unsuspected", 2, "job", who=["seeker"]), arc_next("offer", days=1)],
            score=[s_const(0.7)]),
    ])

L("hh_offer", ["I'll be honest. I have an offer from another company.", "They offered me more money. A lot more.", "I'm thinking of leaving. I wanted you to hear it from me."])
L("hh_counter", ["...What would it take for you to stay?", "We'll match it. And you get the new server budget.", "Don't do anything hasty. Let's talk numbers."])
L("hh_call_bluff", ["Then go. Nobody's irreplaceable.", "Good luck finding a place that tolerates you.", "Door's that way."])
L("hh_stay_happy", ["...Really? Okay. I'll stay.", "Deal. But I want it in writing."])
L("hh_stunned", ["...Right.", "I... see.", "Wow. Okay."])
T("log.hh_counter", "{seeker} told Ahmet about a job offer. Ahmet made a counteroffer — {seeker} is staying, with a raise.")
T("log.hh_bluff_called", "{seeker} told Ahmet about a job offer. Ahmet called the bluff: \"Then go.\" {seeker} is shaken.")
T("mem.hh_counter", "Ahmet fought to keep me.")
T("mem.hh_bluff", "Ahmet told me to leave if I wanted.")
scene("hh_offer", noise=0.9, conditions=[c_present("seeker"), c_present("boss")],
    effects=[hold(["seeker", "boss"], 6), say("seeker", "hh_offer", to="boss"), expr("boss", "surprised", 5, delay=1.0)],
    outcomes=[
        out("counter", [say("boss", "hh_counter", to="seeker", delay=2.0), say("seeker", "hh_stay_happy", to="boss", delay=3.6), emote("seeker", "cheer", delay=3.6),
                        morale("seeker", 22), mood("seeker", 20), goal("seeker", "get_recognition"), plan("seeker", "job_search", v=False),
                        rel("seeker", "boss", "trust", 15), rel("boss", "seeker", "trust", 6), mem("seeker", "boss", "recognized", 0.8, 0.9, "mem.hh_counter", 3),
                        log("log.hh_counter", 4, "job", who=["seeker", "boss"]), arc_end("stayed")],
            score=[{"s": "favor", "who": "seeker", "w": 0.015}, s_rel("boss", "seeker", "trust", 0.01), s_is("seeker", "burak", 0.4), s_const(0.3)]),
        out("bluff_called", [say("boss", "hh_call_bluff", to="seeker", delay=2.0), say("seeker", "hh_stunned", delay=3.6), expr("seeker", "sad", 7, delay=3.6),
                             morale("seeker", -15), mood("seeker", -18), plan("seeker", "job_search", "", heat=1.5), rel("seeker", "boss", "friendship", -15),
                             mem("seeker", "boss", "humiliated", -0.8, 1.0, "mem.hh_bluff", 3), log("log.hh_bluff_called", 4, "job", who=["seeker", "boss"]),
                             arc_end("bluff_called")],
            score=[s_trait("boss", "temper", 0.8), s_rel("boss", "seeker", "trust", -0.01), s_const(0.2)]),
    ])

arc("headhunted", BIG, "call", cooldown_days=6, stages={
    "call": stage("hh_call", "place", actor="seeker", place="phone4", wait=(5, 25), ttl=60),
    "excuse": stage("hh_excuse", "visit", actor="seeker", target="boss", ttl=70, window=("09:40", "14:30"), fail="away"),
    "away": stage("hh_leave", "now", actor="seeker", ttl=60, window=("09:40", "15:00"), fail="retry"),
    "questions": stage("hh_suspicion", "visit", actor="boss", target="seeker", ttl=150, fail="offer"),
    "offer": stage("hh_offer", "meet", actor="seeker", target="boss", area="boss", ttl=120, fail="retry", window=("09:40", "15:30")),
})

# =====================================================================
# 4. THE RESIGNATION LETTER
# =====================================================================
starter("start_resignation", "resignation", {"quitter": "actor", "friend": "friend", "boss": "@ahmet"},
        roles=[actor([c_morale("self", lt=44), c_is("self", "ahmet", neg=True), c_day(gte=2)], [s_morale("self", -0.04)]),
               by_fn("friend", "best_of", lim=5)],
        cooldown_days=5)

L("rs_vent", ["I'm doing it. I'm writing my resignation letter. Today.", "That's it. I'm done. I'm quitting.", "I've decided. I'm handing in my notice."])
L("rs_friend_shock", ["Wait — WHAT? You can't!", "Whoa, whoa. Sleep on it!", "You're serious?!"])
T("log.rs_vent", "{quitter} told {friend} in the kitchen: \"I'm writing my resignation letter. Today.\"")
scene("rs_vent", conditions=[c_present("quitter"), c_present("friend")],
    effects=[hold(["quitter", "friend"], 5), expr("quitter", "angry", 5), say("quitter", "rs_vent", to="friend"), say("friend", "rs_friend_shock", to="quitter", delay=1.8),
             emote("friend", "exclaim", delay=1.8), rumor("resigning", a="quitter", b="friend", juicy=0.8, knowers=["friend"], c=0.8),
             log("log.rs_vent", 3, "job", who=["quitter", "friend"]), arc_next("letter", wait=(10, 30))])

L("rs_print", ["\"Dear Ahmet Bey, effective immediately...\" Print.", "Print. Sign. Done.", "There. My freedom, in Times New Roman."])
L("rs_printer_broken", ["Of course. Even the printer won't let me quit.", "The printer is broken. The universe is mocking me."])
L("rs_spot_letter", ["Is that... a resignation letter?!", "Oh no. Oh no no."])
T("log.rs_print", "{quitter} printed a resignation letter.")
T("log.rs_print_seen", "{quitter} printed a resignation letter — and {spotter} saw it come out of the printer.")
T("log.rs_print_broken", "{quitter} tried to print a resignation letter. The printer was broken.")
scene("rs_print",
    roles=[role("spotter", where=[c_avail("self")], score=[s_trait("self", "curiosity", 1.0)], near="quitter", r=4.0, optional=True, exclude=["quitter", "friend", "boss"])],
    effects=[act("quitter", "print", place="printer", dur=3)],
    outcomes=[
        out("broken", [say("quitter", "rs_printer_broken", delay=1.0), expr("quitter", "angry", 4), log("log.rs_print_broken", 2, "job", who=["quitter"]),
                       arc_next("talk_out", wait=(5, 15))], score=[s_const(5)], when=[c_office("printer.broken", True)]),
        out("seen", [say("quitter", "rs_print", delay=1.0), say("spotter", "rs_spot_letter", delay=2.4), emote("spotter", "exclaim", delay=2.4),
                     learn("spotter", "$rumor", c=0.95), log("log.rs_print_seen", 3, "job", who=["quitter", "spotter"]), arc_next("talk_out", wait=(5, 20))],
            score=[s_const(2)], when=[c_filled("spotter")]),
        out("printed", [say("quitter", "rs_print", delay=1.0), log("log.rs_print", 2, "job", who=["quitter"]), arc_next("talk_out", wait=(5, 20))], score=[s_const(1)]),
    ])

L("rs_talk", ["Don't do this. Not like this. Not angry.", "What if I talk to Ahmet for you?", "We need you here. I need you here."])
L("rs_persuaded", ["...Okay. Maybe I'll wait a week.", "Fine. I'll put the letter in a drawer. For now.", "You're right. Thanks."])
L("rs_firm", ["No. My mind's made up.", "I'm going to Ahmet. Now.", "I appreciate it. But no."])
T("log.rs_persuaded", "{friend} talked {quitter} out of resigning. The letter went in a drawer.")
T("log.rs_firm", "{friend} begged {quitter} to stay. {quitter} is heading to Ahmet's office, letter in hand.")
scene("rs_talk_out", noise=0.9, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), say("actor", "rs_talk", to="target")],
    outcomes=[
        out("persuaded", [say("target", "rs_persuaded", to="actor", delay=1.8), morale("target", 10), rel("target", "actor", "friendship", 12),
                          mem("target", "actor", "helped_me", 0.8, 0.9, "mem.brought_snack", 2), log("log.rs_persuaded", 3, "job", who=["friend", "quitter"]),
                          arc_end("talked_out")],
            score=[s_aff("target", "actor", 0.015), s_trait("target", "forgiveness", 0.5), s_morale("target", 0.015)]),
        out("firm", [say("target", "rs_firm", to="actor", delay=1.8), expr("target", "angry", 4, delay=1.8), log("log.rs_firm", 3, "job", who=["quitter", "friend"]),
                     arc_next("boss_talk", wait=(3, 15))],
            score=[s_trait("target", "temper", 0.8), s_morale("target", -0.02), s_const(1.6)]),
    ])

L("rs_hand_in", ["Ahmet Bey. This is my resignation.", "I'm resigning. Here's my letter.", "I quit. Effective end of the month."])
L("rs_boss_beg", ["Wait. Sit down. What do you need? Let's talk.", "No, no, no. We can fix whatever this is.", "...I didn't realise it was this bad. What can I do?"])
L("rs_boss_tear", ["*tears letter in half* Funny. Now get back to work.", "Nice try. *rip* You're not going anywhere."])
L("rs_boss_accept", ["Fine. I accept.", "Very well. HR will be in touch.", "If that's what you want."])
L("rs_panic", ["Wait. You... accept? Just like that?", "...Oh. Okay. Um.", "I didn't actually think you'd say yes."])
T("log.rs_counter", "{quitter} handed Ahmet a resignation letter. Ahmet asked them to stay — and listened.")
T("log.rs_torn", "{quitter} handed Ahmet a resignation letter. Ahmet tore it in half. {quitter} is... staying?")
T("log.rs_accepted", "{quitter} handed Ahmet a resignation letter. He accepted it. {quitter} did not see that coming.")
T("mem.rs_accepted", "Ahmet accepted my resignation without blinking.")
scene("rs_boss", noise=0.9, conditions=[c_present("quitter"), c_present("boss")],
    effects=[hold(["quitter", "boss"], 6), say("quitter", "rs_hand_in", to="boss"), expr("boss", "surprised", 5, delay=1.0)],
    outcomes=[
        out("counter", [say("boss", "rs_boss_beg", to="quitter", delay=2.0), morale("quitter", 18), mood("quitter", 12), rel("quitter", "boss", "trust", 12),
                        mem("quitter", "boss", "recognized", 0.7, 0.8, "mem.hh_counter", 3), log("log.rs_counter", 4, "job", who=["quitter", "boss"]),
                        arc_end("stayed")],
            score=[{"s": "favor", "who": "quitter", "w": 0.025}, s_rel("boss", "quitter", "trust", 0.02)]),
        out("torn", [say("boss", "rs_boss_tear", to="quitter", delay=2.0), expr("quitter", "surprised", 5, delay=2.0), morale("quitter", 6),
                     log("log.rs_torn", 4, "job", who=["quitter", "boss"]), arc_end("torn_up")],
            score=[s_trait("boss", "humor", 1.0), s_rel("boss", "quitter", "trust", 0.015), s_const(0.2)]),
        out("accepted", [say("boss", "rs_boss_accept", to="quitter", delay=2.0), say("quitter", "rs_panic", delay=3.6), expr("quitter", "sad", 8, delay=3.6),
                         morale("quitter", -12), stress("quitter", 20), mem("quitter", "boss", "humiliated", -0.6, 0.9, "mem.rs_accepted", 3),
                         log("log.rs_accepted", 4, "job", who=["quitter", "boss"]), arc_next("aftermath", days=1)],
            score=[s_trait("boss", "temper", 1.0), s_stress("boss", 0.01), s_const(0.2)]),
    ])

L("rs_after", ["So... I asked for my letter back this morning.", "Turns out I don't actually want to leave.", "I'm staying. Please don't make it weird."])
L("rs_after_react", ["Welcome back. You never left.", "Ha! I knew it.", "Good. I'd have missed you."])
T("log.rs_after", "{quitter} quietly asked Ahmet for their resignation letter back. Everyone pretended not to notice.")
scene("rs_after", conditions=[c_avail("quitter")],
    effects=[expr("quitter", "sad", 4), say("quitter", "rs_after"), each([say("self", "rs_after_react", p=0.3, delay=1.6)], exclude=["quitter"],
                                                                            where=[{"c": "near", "a": "self", "b": "quitter", "lt": 6}]),
             morale("quitter", 5), log("log.rs_after", 3, "job", who=["quitter"]), arc_end("took_it_back")])

arc("resignation", BIG, "vent", cooldown_days=5, stages={
    "vent": stage("rs_vent", "meet", actor="quitter", target="friend", area="kitchen", wait=(5, 20), ttl=60, fail="letter"),
    "letter": stage("rs_print", "place", actor="quitter", place="printer", ttl=60, fail="talk_out"),
    "talk_out": stage("rs_talk_out", "visit", actor="friend", target="quitter", ttl=60, fail="boss_talk"),
    "boss_talk": stage("rs_boss", "meet", actor="quitter", target="boss", area="boss", ttl=90, fail="retry"),
    "aftermath": stage("rs_after", "now", actor="quitter", ttl=200),
})

# =====================================================================
# 5. THE MISSING CONTRACT — panic, a search, the wrong suspect, a guilty conscience
# =====================================================================
starter("start_missing_contract", "missing_contract", {"owner": "actor", "culprit": "culprit", "boss": "@ahmet"},
        roles=[actor([c_is("self", in_=["selin", "zeynep", "mert", "deniz", "ceren"]), c_act("self", ["work"])], [s_trait("self", "diligence", 0.8), s_rand(0.6)]),
               by_fn("culprit", "clumsy_one", **{"not": "actor"}, avail=False)],
        cooldown_days=4)

L("mc_panic", ["The Yıldız contract! It was RIGHT HERE!", "Where is the signed contract?! WHERE?!", "No. No no no. The original contract is gone."],
  zeynep=["The contract. The ORIGINAL. With the wet signatures!"], selin=["Did someone take the contract from my desk?!"])
L("mc_witness", ["What's going on?", "Uh oh.", "Did you check the archive?"])
T("log.mc_panic", "{owner}'s signed client contract has vanished from their desk. Panic.")
scene("mc_panic", conditions=[c_avail("owner")],
    effects=[expr("owner", "surprised", 6), emote("owner", "exclaim"), say("owner", "mc_panic"), stress("owner", 15), sfx("papers"),
             witness([say("self", "mc_witness", p=0.5, delay=1.6)], near="owner", r=5, exclude=["owner"]), log("log.mc_panic", 3, "documents", who=["owner"]),
             arc_next("search", wait=(2, 6))])

L("mc_search", ["Not under A. Not under C. Not under CONTRACT.", "It has to be here somewhere...", "Who organises this archive, a raccoon?"])
L("mc_suspect_think", ["Wait... {suspect} was hanging around my desk this morning.", "{suspect}. It must have been {suspect}.", "I bet {suspect} borrowed it. Without asking."])
T("log.mc_search", "{owner} searched the whole archive for the missing contract. Nothing. Now they suspect {suspect}.")
scene("mc_search", noise=0.9, allow_absent=True, conditions=[c_present("owner")],
    vars=[var("suspect", "suspect", of="owner", optional=True)],
    effects=[act("owner", "archive", place="archive", dur=4), say("owner", "mc_search"), sfx("papers")],
    outcomes=[
        out("remember", [{"e": "set", "key": "suspect", "who": "culprit"}, say("owner", "mc_suspect_think", delay=2.4), emote("owner", "idea", delay=2.4),
                         log("log.mc_search", 2, "documents", who=["owner"]), arc_next("accuse", wait=(3, 10))],
            score=[s_trait("owner", "curiosity", 1.0), s_const(0.3)], when=[c_present("culprit")]),
        out("suspect", [say("owner", "mc_suspect_think", delay=2.4), emote("owner", "question", delay=2.4), log("log.mc_search", 2, "documents", who=["owner"]),
                        arc_next("accuse", wait=(3, 10))], score=[s_const(1)], when=[c_filled("$suspect")]),
        out("nobody", [arc_next("culprit_conscience", wait=(10, 30))], score=[s_const(0.1)]),
    ])

L("mc_ask", ["Did you take a contract from my desk? Blue folder?", "I'm not accusing you, but... the contract. Have you seen it?", "Be honest: did you borrow my contract?"])
L("mc_confess_now", ["...Oh no. The blue folder? I filed it. In the archive. Under \"Y\". Sorry!", "Was it blue? I might have filed it. By accident."])
L("mc_deny_guilty", ["Me? No. Never touched it.", "Why would I take your contract?"])
L("mc_offended", ["Are you accusing me?!", "Wow. Thanks for the trust.", "I've never even SEEN your contract."])
T("log.mc_confess_now", "{owner} asked {suspect} about the missing contract. {suspect} remembered filing it by mistake.")
T("log.mc_wrong_suspect", "{owner} accused {suspect} of taking the contract. {suspect} had nothing to do with it — and is offended.")
T("log.mc_guilty_deny", "{owner} asked {suspect} about the contract. {suspect} denied it. (They filed it by mistake.)")
T("mem.mc_accused", "{owner} accused me of taking their contract.")
scene("mc_accuse", noise=0.9, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), say("actor", "mc_ask", to="target")],
    outcomes=[
        out("confess", [say("target", "mc_confess_now", to="actor", delay=1.8), emote("target", "sweat", delay=1.8), rel("actor", "target", "trust", -3),
                        log("log.mc_confess_now", 3, "documents", who=["owner", "culprit"]), arc_next("found", wait=(1, 3))],
            score=[s_const(3), s_trait("target", "honesty", 1.0)], when=[c_same("target", "culprit"), c_trait("target", "honesty", gt=0.5)]),
        out("guilty_deny", [say("target", "mc_deny_guilty", to="actor", delay=1.8), log("log.mc_guilty_deny", 3, "documents", who=["owner", "culprit"]),
                            arc_next("culprit_conscience", wait=(10, 35))],
            score=[s_const(2)], when=[c_same("target", "culprit")]),
        out("innocent", [say("target", "mc_offended", to="actor", delay=1.8), expr("target", "angry", 5, delay=1.8), rel("target", "actor", "friendship", -10),
                         rel("target", "actor", "trust", -8), mem("target", "actor", "falsely_accused", -0.6, 0.8, "mem.mc_accused", 3), setv("wrongly_accused", True),
                         log("log.mc_wrong_suspect", 3, "misunderstanding", who=["owner", "$suspect"]), arc_next("culprit_conscience", wait=(10, 35))],
            score=[s_const(1)]),
    ])

L("mc_realise", ["Wait. The blue folder I filed this morning... oh no.", "Was that... their contract? In the archive? Oh no.", "...I think I know where the contract is."])
T("log.mc_realise", "{culprit} just realised the missing contract is the folder they filed in the archive this morning.")
scene("mc_conscience", noise=0.9, conditions=[c_avail("culprit")],
    effects=[expr("culprit", "surprised", 5), emote("culprit", "sweat"), say("culprit", "mc_realise"), log("log.mc_realise", 3, "documents", who=["culprit"])],
    outcomes=[
        out("confess", [arc_next("confession", wait=(2, 6))], score=[s_trait("culprit", "honesty", 1.0), s_trait("culprit", "empathy", 0.3)]),
        out("sneak", [arc_next("found_mystery", wait=(5, 12))], score=[s_trait("culprit", "cunning", 1.0), s_goal("culprit", "be_liked", 0.4), s_const(0.5)]),
    ])

L("mc_confess", ["I'm so sorry. I filed your contract in the archive by mistake.", "It was me. Archive. Under Y. I'm an idiot.", "Your contract is safe. I... misfiled it. Sorry!"])
L("mc_forgive", ["Oh thank GOD. ...Okay. It happens.", "You scared me to death. But thank you for telling me.", "Fine. Just... label things."])
L("mc_furious", ["Do you know what that contract is WORTH?!", "Unbelievable. I accused someone else because of you!"])
L("mc_owe_apology", ["...I owe {suspect} an apology.", "Oh no. I accused {suspect}."])
T("log.mc_confessed", "{culprit} confessed to {owner}: the contract was misfiled. Crisis over.")
T("mem.mc_confessed", "{culprit} owned up to losing my contract.")
scene("mc_confess", noise=0.9, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5.5), say("actor", "mc_confess", to="target"), stress("target", -10), log("log.mc_confessed", 3, "documents", who=["culprit", "owner"]),
             say("target", "mc_owe_apology", delay=4.2, when=[c_var("wrongly_accused", eq=True)]),
             plan("target", "apologize", "$suspect", heat=1.0, when=[c_var("wrongly_accused", eq=True)])],
    outcomes=[
        out("forgive", [say("target", "mc_forgive", to="actor", delay=1.8), rel("target", "actor", "trust", 4), mem("target", "actor", "honest", 0.4, 0.6, "mem.mc_confessed", 2),
                        arc_end("confessed")], score=[s_trait("target", "forgiveness", 1.0), s_aff("target", "actor", 0.01)]),
        out("furious", [say("target", "mc_furious", to="actor", delay=1.8), expr("target", "angry", 6, delay=1.8), rel("target", "actor", "friendship", -8),
                        stress("actor", 10), arc_end("confessed_angry")], score=[s_trait("target", "temper", 1.0), s_const(0.2)]),
    ])

L("mc_found_back", ["It's... back on my desk? It wasn't here an hour ago!", "The contract! It's here! How?!"])
L("mc_still_blame", ["{suspect} must have put it back. Guilty conscience.", "Of course it reappears after I asked {suspect}."])
T("log.mc_mystery", "{culprit} secretly slipped the contract back onto {owner}'s desk. {owner} still blames {suspect}.")
T("log.mc_mystery_nosuspect", "{culprit} secretly slipped the contract back onto {owner}'s desk. Nobody will ever know.")
scene("mc_found", allow_absent=True, conditions=[c_present("owner")],
    effects=[expr("owner", "surprised", 5), say("owner", "mc_found_back"), emote("owner", "question"), stress("owner", -10)],
    outcomes=[
        out("blames", [say("owner", "mc_still_blame", delay=2.2), rel("owner", "$suspect", "trust", -8), mem("owner", "$suspect", "suspect_files", -0.5, 0.8, "mem.misfiled", 2),
                       log("log.mc_mystery", 3, "misunderstanding", who=["culprit", "owner"]), arc_end("mystery")],
            score=[s_const(2)], when=[c_filled("$suspect"), c_same("$suspect", "culprit", neg=True)]),
        out("clean", [ghost(), log("log.mc_mystery_nosuspect", 3, "documents", who=["culprit", "owner"]), arc_end("mystery")], score=[s_const(1)]),
    ])

L("mc_found_quick", ["THERE it is. Archive, under Y. Of course.", "Got it! Never do that again.", "Found it. My heart can't take this."])
T("log.mc_found_quick", "{owner} got the contract back from the archive. Panic over.")
scene("mc_found_quick", allow_absent=True, conditions=[c_present("owner")],
    effects=[say("owner", "mc_found_quick"), emote("owner", "ok"), stress("owner", -12), log("log.mc_found_quick", 2, "documents", who=["owner"]), arc_end("found")])

arc("missing_contract", BIG, "panic", cooldown_days=4, stages={
    "panic": stage("mc_panic", "now", actor="owner", wait=(2, 8), ttl=60),
    "search": stage("mc_search", "place", actor="owner", place="archive", ttl=50, fail="culprit_conscience"),
    "accuse": stage("mc_accuse", "visit", actor="owner", target="$suspect", ttl=60, fail="culprit_conscience"),
    "culprit_conscience": stage("mc_conscience", "now", actor="culprit", ttl=120, fail="end:lost_forever"),
    "confession": stage("mc_confess", "visit", actor="culprit", target="owner", ttl=60, fail="found_mystery"),
    "found_mystery": stage("mc_found", "now", actor="owner", ttl=150),
    "found": stage("mc_found_quick", "now", actor="owner", ttl=60),
})

# =====================================================================
# 6. THE DELETED FOLDER — one wrong click wipes the shared drive
# =====================================================================
starter("start_deleted_folder", "deleted_folder", {"culprit": "actor", "it": "@burak", "boss": "@ahmet"},
        roles=[actor([c_act("self", ["work"]), c_trait("self", "clumsiness", gt=0.25), c_is("self", in_=["burak", "ahmet"], neg=True)],
                     [s_trait("self", "clumsiness", 1.5), s_stress("self", 0.01)])],
        conditions=[c_present("@ahmet")], cooldown_days=5)

L("df_oops", ["Wait. Where's the shared folder? Did I just... delete... everything?", "I pressed \"empty bin\". Why is the SHARED drive empty?!",
              "Okay. Don't panic. Everything is gone. DON'T PANIC."], ece=["Oh no. Oh no no no no no. NO."])
T("log.df_oops", "{culprit} accidentally deleted the entire shared folder. Nobody knows yet.")
scene("df_oops", noise=0.9, conditions=[c_avail("culprit")],
    effects=[expr("culprit", "surprised", 7), emote("culprit", "sweat"), say("culprit", "df_oops"), stress("culprit", 22), log("log.df_oops", 3, "documents", who=["culprit"])],
    outcomes=[
        out("ask", [arc_next("ask_it", wait=(1, 4))], score=[s_trait("culprit", "honesty", 1.0), s_trait("culprit", "empathy", 0.4), s_aff("culprit", "it", 0.01)],
            when=[c_present("it"), c_is("culprit", "burak", neg=True)]),
        out("hide", [arc_next("alarm", wait=(10, 25))], score=[s_goal("culprit", "be_liked", 0.6), s_trait("culprit", "cunning", 0.8), s_const(1.0)]),
    ])

L("df_ask_it", ["Burak... hypothetically... if someone deleted the shared drive...", "Please don't be mad. I deleted the shared folder.", "I need help. Big help. Secret help."])
L("df_it_quiet", ["...Breathe. There's a backup from last night. Nobody needs to know.", "Restoring now. You owe me coffee. For a month."])
L("df_it_lecture", ["You WHAT? ...Fine. Backup. But we are having a talk about the bin.", "Restoring. And I'm disabling your delete key."])
L("df_it_nobackup", ["The backup failed last night. There is no backup. You need to tell Ahmet.", "...There's no backup. I'm so sorry."])
T("log.df_quiet", "{culprit} confessed the deleted folder to Burak. He restored it from backup — quietly.")
T("log.df_nobackup", "{culprit} confessed the deleted folder to Burak. There's no backup.")
T("mem.df_saved", "Burak saved me from disaster and kept quiet.")
scene("df_ask", noise=0.9, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5.5), emote("actor", "whisper"), say("actor", "df_ask_it", to="target"), expr("target", "surprised", 4, delay=1.2)],
    outcomes=[
        out("quiet", [say("target", "df_it_quiet", to="actor", delay=2.0), emote("actor", "love", delay=2.0), stress("actor", -20),
                      rel("actor", "target", "friendship", 18), rel("actor", "target", "trust", 15), bond("actor", "target", "mentor"),
                      mem("actor", "target", "helped_me", 0.9, 1.0, "mem.df_saved", 3), log("log.df_quiet", 3, "help", who=["it", "culprit"]), arc_end("saved_quietly")],
            score=[s_aff("target", "actor", 0.015), s_trait("target", "empathy", 0.6), s_const(0.2)]),
        out("lecture", [say("target", "df_it_lecture", to="actor", delay=2.0), stress("actor", -10), rel("actor", "target", "trust", 8),
                        log("log.df_quiet", 3, "help", who=["it", "culprit"]), arc_end("saved_lecture")],
            score=[s_trait("target", "temper", 0.6), s_const(0.4)]),
        out("nobackup", [say("target", "df_it_nobackup", to="actor", delay=2.0), expr("actor", "sad", 6, delay=2.0), log("log.df_nobackup", 3, "documents", who=["culprit"]),
                         arc_next("alarm", wait=(5, 15))], score=[s_const(0.9)]),
    ])

L("df_alarm", ["My files! The shared folder is EMPTY!", "Where did EVERYTHING go?!", "Three months of work. Gone. GONE."])
L("df_alarm_react", ["Mine too!", "What?! The whole drive?", "Burak! BURAAAK!", "This is a disaster."])
L("df_alarm_suspect", ["{suspect} was poking around the drive yesterday...", "I bet {suspect} did something."])
T("log.df_alarm", "{victim} discovered the shared drive is empty. Office-wide panic. Fingers point at {suspect}.")
scene("df_alarm",
    roles=[role("victim", where=[c_avail("self"), c_is("self", "ahmet", neg=True)], score=[s_trait("self", "diligence", 1.0), s_rand(0.5)],
                exclude=["culprit", "it", "boss"])],
    vars=[var("suspect", "suspect", of="victim", optional=True)],
    effects=[expr("victim", "surprised", 6), emote("victim", "exclaim"), say("victim", "df_alarm"), stress("victim", 15), sfx("gasp"),
             each([emote("self", "exclaim", delay=1.0), say("self", "df_alarm_react", p=0.4, delay=1.5), stress("self", 8)], exclude=["victim"], stagger=0.5),
             emote("culprit", "sweat", delay=2.0), say("victim", "df_alarm_suspect", delay=3.0, when=[c_filled("$suspect")]),
             rumor("lost_file", a="$suspect", b="victim", juicy=0.6, truth=False, knowers=["victim"], origin="victim", when=[c_filled("$suspect"), c_same("$suspect", "culprit", neg=True)]),
             log("log.df_alarm", 4, "documents", who=["victim"]), arc_next("hunt", wait=(3, 10))])

L("df_hunt", ["WHO touched the shared drive?! I want a name!", "Nobody leaves until I know who deleted those files!", "Somebody here destroyed three months of work."])
L("df_confess", ["...It was me. I'm so sorry. I clicked the wrong thing.", "Me. It was me. I'll fix it. Somehow."])
L("df_boss_forgive", ["...Mistakes happen. Burak, fix it.", "Thank you for owning up. Burak! Backups!"])
L("df_boss_blame", ["{suspect}! It was you, wasn't it?", "I'm looking at you, {suspect}."])
L("df_protest", ["What? I didn't touch anything!", "That's not fair!"])
T("log.df_confessed", "Ahmet demanded a name. {culprit} stepped forward and confessed to deleting the shared drive.")
T("log.df_boss_blames", "Ahmet demanded a name. Nobody spoke — so he blamed {suspect}. ({culprit} said nothing.)")
scene("df_hunt", noise=0.9,
    effects=[say("boss", "df_hunt"), expr("boss", "angry", 8), sfx("slam"), each([stress("self", 6), emote("self", "sweat", delay=0.8)], exclude=["boss"], stagger=0.3)],
    outcomes=[
        out("confess", [say("culprit", "df_confess", delay=2.2), expr("culprit", "sad", 6, delay=2.2), say("boss", "df_boss_forgive", delay=4.0),
                        rel("boss", "culprit", "trust", -4), favor("culprit", -4), each([rel("self", "culprit", "trust", 3)], exclude=["culprit", "boss"]),
                        log("log.df_confessed", 4, "documents", who=["culprit", "boss"]), arc_next("restore", wait=(5, 15))],
            score=[s_trait("culprit", "honesty", 1.2), s_const(0.2)], when=[c_present("culprit")]),
        out("blame", [say("boss", "df_boss_blame", delay=2.2), say("$suspect", "df_protest", delay=3.8), expr("$suspect", "angry", 5, delay=3.8),
                      rel("boss", "$suspect", "trust", -10), favor("$suspect", -5), mem("$suspect", "boss", "falsely_accused", -0.6, 0.8, "mem.falsely_accused", 3),
                      log("log.df_boss_blames", 4, "blame", who=["boss", "$suspect"]), arc_next("restore", wait=(5, 15))],
            score=[s_const(1)], when=[c_filled("$suspect"), c_present("$suspect"), c_same("$suspect", "culprit", neg=True)]),
        out("nobody", [arc_next("restore", wait=(5, 15))], score=[s_const(0.1)]),
    ])

L("df_restore", ["Restored from the off-site backup. You're welcome.", "Everything's back. And the logs say it was deleted from {culprit}'s computer.", "All restored. Mostly."])
L("df_cover", ["Restored. Looks like a sync error. Happens.", "All back. Probably a glitch."])
T("log.df_exposed", "Burak restored the shared drive — and the logs showed it was deleted from {culprit}'s computer.")
T("log.df_covered", "Burak restored the shared drive and blamed a \"sync error\". He's protecting {culprit}.")
T("log.df_restored", "Burak restored the shared drive. The crisis is over.")
scene("df_restore", noise=0.9, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), sfx("fixed"), each([stress("self", -10), emote("self", "ok", delay=1.0)], exclude=[], stagger=0.3)],
    outcomes=[
        out("exposed", [say("actor", "df_restore", to="target"), favor("culprit", -6), rel("boss", "culprit", "trust", -12), stress("culprit", 15),
                        debunk("$rumor", who=["boss", "$suspect"], by="actor", when=[c_filled("$rumor")]),
                        log("log.df_exposed", 4, "documents", who=["it", "culprit"]), arc_end("exposed")],
            score=[s_trait("actor", "honesty", 1.0), s_aff("actor", "culprit", -0.02)], when=[c_var("last_outcome", eq="blame")]),
        out("covered", [say("actor", "df_cover", to="target"), rel("culprit", "actor", "friendship", 15), rel("culprit", "actor", "trust", 12),
                        log("log.df_covered", 3, "protect", who=["it", "culprit"]), arc_end("covered")],
            score=[s_aff("actor", "culprit", 0.03), s_trait("actor", "empathy", 0.5)], when=[c_var("last_outcome", eq="blame")]),
        out("restored", [say("actor", "df_cover", to="target"), log("log.df_restored", 3, "help", who=["it"]), arc_end("restored")], score=[s_const(0.5)]),
    ])

arc("deleted_folder", BIG, "oops", cooldown_days=6, stages={
    "oops": stage("df_oops", "now", actor="culprit", wait=(1, 5), ttl=60),
    "ask_it": stage("df_ask", "visit", actor="culprit", target="it", ttl=45, fail="alarm"),
    "alarm": stage("df_alarm", "now", actor="culprit", ttl=90, fail="end:quietly_lost"),
    "hunt": stage("df_hunt", "place", actor="boss", place="announce", ttl=60, fail="restore"),
    "restore": stage("df_restore", "visit", actor="it", target="boss", ttl=90, fail="end:restored_late"),
})

# =====================================================================
# 7. LAYOFF PANIC — a half-heard phone call turns into office-wide fear
# =====================================================================
starter("start_layoff_panic", "layoff_panic", {"ear": "actor", "boss": "@ahmet"},
        roles=[actor([c_trait("self", "curiosity", gt=0.55), c_trait("self", "gossip", gt=0.3), c_is("self", "ahmet", neg=True), c_present("@ahmet"),
                      c_time(after="09:50", before="14:30")],
                     [s_trait("self", "curiosity", 1.0), s_trait("self", "gossip", 0.8)])],
        cooldown_days=6)

L("lp_phone", ["...We have to cut something. Someone has to go. ...Yes. By Friday.", "Too expensive. It's out. ...I don't care how long it's been here."])
L("lp_gasp", ["Wait. Someone has to GO?!", "Layoffs?! By FRIDAY?!", "Oh no. Oh no no no."])
T("log.lp_overheard", "{ear} overheard Ahmet on the phone: \"someone has to go by Friday.\" (He was talking about the coffee subscription.)")
scene("lp_overhear", allow_absent=True, conditions=[c_present("ear"), c_present("boss")],
    roles=[role("listener", where=[c_avail("self")], score=[s_aff("ear", "self", 0.02), s_trait("self", "gossip", 0.6), s_rand(0.5)], exclude=["ear", "boss"])],
    effects=[act("boss", "phone", place="desk_ahmet", dur=4), say("boss", "lp_phone", delay=0.5), expr("ear", "surprised", 6, delay=1.8), emote("ear", "exclaim", delay=1.8),
             say("ear", "lp_gasp", delay=2.0), rumor("layoffs", a="boss", b="ear", juicy=0.95, truth=False, knowers=["ear"], c=0.85, origin="ear"),
             stress("ear", 15), log("log.lp_overheard", 3, "misunderstanding", who=["ear", "boss"]), arc_next("spread", wait=(4, 12))])

L("lp_tell", ["Don't freak out. But there are going to be layoffs. By Friday.", "I heard Ahmet. Someone's getting fired. By Friday!", "Update your CV. I'm serious."])
L("lp_tell_react", ["WHAT?!", "Who? WHO?", "Oh my god. I have rent!"])
T("log.lp_spread", "{ear} told {listener} in the kitchen: layoffs are coming. The fear is spreading.")
scene("lp_spread", conditions=[c_present("ear"), c_present("listener")],
    effects=[hold(["ear", "listener"], 5), emote("ear", "whisper"), say("ear", "lp_tell", to="listener"), say("listener", "lp_tell_react", to="ear", delay=1.8),
             expr("listener", "surprised", 5, delay=1.8), learn("listener", "$rumor", frm="ear"), stat("rumors"),
             log("log.lp_spread", 3, "rumor", who=["ear", "listener"]), arc_next("panic", wait=(8, 20))])

L("lp_doom", ["We're doomed.", "I'm updating my CV. Right now.", "Is it me? It's me, isn't it.", "I KNEW I shouldn't have bought that car."],
  mert=["If I go, I'm taking the good stapler."], burak=["...Good timing, actually."], ece=["But I'm an intern! Can they fire interns?!"])
T("log.lp_panic", "The layoff rumour is everywhere. People are whispering, updating CVs and eyeing each other. {brave} is going to ask Ahmet directly.")
scene("lp_panic", noise=0.9,
    roles=[role("brave", where=[c_avail("self"), c_is("self", "ahmet", neg=True)], score=[s_trait("self", "temper", 0.8), s_trait("self", "honesty", 0.8), s_rand(0.4)],
                exclude=["boss"], optional=True)],
    effects=[each([learn("self", "$rumor", frm="ear", c=0.55), stress("self", 6), say("self", "lp_doom", p=0.35, delay=1.2), emote("self", "sweat", delay=1.0)],
                  exclude=["boss"], stagger=0.6),
             each([plan("self", "job_search", "", heat=0.6)], exclude=["boss"], where=[c_morale("self", lt=45)])],
    outcomes=[
        out("brave", [log("log.lp_panic", 4, "rumor", who=["brave"]), arc_next("confront_boss", wait=(3, 12))], score=[s_const(1)], when=[c_filled("brave")]),
        out("silent", [arc_next("announce", wait=(30, 60))], score=[s_const(0.1)]),
    ])

L("lp_ask_boss", ["Ahmet Bey, we need to know. Are there going to be layoffs?", "Is it true someone's getting fired by Friday?", "The whole office is panicking. Are we being let go?"])
L("lp_boss_baffled", ["LAYOFFS? Who said anything about layoffs?!", "What on earth are you talking about?", "Fired? Nobody's being fired! Who started this?"])
T("log.lp_confront", "{brave} asked Ahmet point-blank about the layoffs. Ahmet had no idea what they were talking about.")
scene("lp_confront", conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), say("actor", "lp_ask_boss", to="target"), say("target", "lp_boss_baffled", to="actor", delay=1.8),
             expr("target", "surprised", 5, delay=1.8), debunk("$rumor", who=["actor"], by="target"), log("log.lp_confront", 3, "rumor", who=["brave", "boss"]),
             arc_next("announce", wait=(3, 8))])

L("lp_announce", ["EVERYONE. There are NO layoffs. I cancelled the COFFEE SUBSCRIPTION.", "Listen! Nobody is being fired! I was talking about the coffee machine contract!",
                  "For the record: the only thing leaving this office is the expensive coffee."])
L("lp_relief", ["Oh thank god.", "The COFFEE?!", "I cried in the bathroom for nothing?", "...Wait, no more good coffee?"])
T("log.lp_debunked", "Ahmet announced there are no layoffs — he'd only cancelled the coffee subscription. Everyone knows who started the panic: {ear}.")
scene("lp_announce",
    effects=[say("boss", "lp_announce"), sfx("slam"), debunk("$rumor", who=["ear"], by="boss"),
             each([debunk("$rumor", who=["self"], by="boss"), stress("self", -12), say("self", "lp_relief", p=0.45, delay=1.4), emote("self", "cheer", delay=1.2),
                   rel("self", "ear", "trust", -5)], exclude=["boss", "ear"], stagger=0.5),
             expr("ear", "sad", 6, delay=2.0), emote("ear", "sweat", delay=2.0), log("log.lp_debunked", 4, "rumor", who=["boss", "ear"]), arc_end("debunked")])

arc("layoff_panic", BIG, "overhear", cooldown_days=7, stages={
    "overhear": stage("lp_overhear", "desk", actor="ear", target="boss", wait=(3, 10), ttl=40, window=("09:50", "15:00")),
    "spread": stage("lp_spread", "meet", actor="ear", target="listener", area="kitchen", ttl=50, fail="panic"),
    "panic": stage("lp_panic", "now", actor="ear", ttl=90, fail="announce"),
    "confront_boss": stage("lp_confront", "visit", actor="brave", target="boss", ttl=60, fail="announce"),
    "announce": stage("lp_announce", "place", actor="boss", place="announce", ttl=120, fail="end:faded"),
})

# =====================================================================
# 8. THE SECRET ALLIANCE — a pact, traded secrets, a strike, a leak, betrayal
# =====================================================================
starter("start_secret_alliance", "secret_alliance", {"schemer": "actor", "partner": "partner", "mark": "$enemy", "boss": "@ahmet"}, weight=1.4,
        roles=[actor([c_trait("self", "cunning", gt=0.55), c_is("self", "ahmet", neg=True)], [s_trait("self", "cunning", 1.2), s_trait("self", "ambition", 0.6)]),
               role("partner", where=[c_avail("self"), c_aff("actor", "self", gt=0), c_is("self", "ahmet", neg=True), c_bond("actor", "self", "alliance", neg=True)],
                    score=[s_trait("self", "cunning", 1.0), s_trait("self", "gossip", 0.6), s_aff("actor", "self", 0.01)], exclude=["actor"])],
        vars=[var("enemy", "common_enemy", a="actor", b="partner")],
        conditions=[c_is("$enemy", "ahmet", neg=True)], cooldown_days=6)

L("sa_offer", ["We both have a {mark} problem. Let's solve it together.", "You hear things. I know how to use them. Partners?",
               "{mark} is in our way. Help me and you'll be first in line when I'm team lead."])
L("sa_yes", ["...I'm in. Nobody can know.", "Deal. This conversation never happened.", "What's in it for me? ...Fine. Deal."])
L("sa_no", ["No. Find someone else to do your dirty work.", "Absolutely not. And watch yourself.", "I'm not that kind of person."])
T("log.sa_pact", "{schemer} and {partner} made a secret pact against {mark} in the archive.")
T("log.sa_refused", "{schemer} proposed a pact against {mark}. {partner} refused — and is thinking about warning {mark}.")
scene("sa_proposal", noise=0.9, conditions=[c_present("schemer"), c_present("partner")],
    effects=[hold(["schemer", "partner"], 5.5), emote("schemer", "whisper"), say("schemer", "sa_offer", to="partner")],
    outcomes=[
        out("yes", [say("partner", "sa_yes", to="schemer", delay=1.8), bond("schemer", "partner", "alliance"), plan("schemer", "undermine", "mark", heat=1.5),
                    rel("schemer", "partner", "trust", 10, both=True), log("log.sa_pact", 4, "alliance", who=["schemer", "partner"]), arc_next("trade", days=1)],
            score=[s_trait("partner", "cunning", 1.2), s_aff("partner", "mark", -0.02), s_aff("partner", "schemer", 0.01)]),
        out("no", [say("partner", "sa_no", to="schemer", delay=1.8), rel("partner", "schemer", "trust", -12),
                   rumor("scheme", a="schemer", b="mark", juicy=0.85, knowers=["partner"]), log("log.sa_refused", 3, "alliance", who=["schemer", "partner"]),
                   arc_next("warning", wait=(10, 40))],
            score=[s_trait("partner", "honesty", 1.2), s_aff("partner", "mark", 0.02)]),
    ])

L("sa_warn", ["Watch your back with {schemer}. They asked me to help bring you down.", "I'm only telling you because it's not right: {schemer} is plotting against you."])
L("sa_warn_thanks", ["...I knew it. Thank you.", "Of course they are. Thanks for telling me.", "I owe you one."])
T("log.sa_warned", "{partner} warned {mark}: {schemer} is plotting against them.")
scene("sa_warning", conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), emote("actor", "whisper"), say("actor", "sa_warn", to="target"), say("target", "sa_warn_thanks", to="actor", delay=1.8),
             learn("target", "$rumor", frm="actor", c=0.9), rel("target", "actor", "trust", 15), rel("target", "actor", "friendship", 10),
             rel("target", "schemer", "rivalry", 15), plan("target", "revenge", "schemer", heat=0.6), log("log.sa_warned", 4, "alliance", who=["partner", "mark"]),
             arc_end("warned")])

L("sa_trade", ["What have you got on {mark}?", "Anything useful? Anything at all?"])
L("sa_give_secret", ["Oh, I've got something. {dirt}", "This stays between us: {dirt}"])
L("sa_make_up", ["Nothing real. But people believe what they hear often enough...", "Nothing. So we'll invent something. Lazy, sneaks off early. Easy."])
T("log.sa_trade", "In the archive, {partner} handed {schemer} dirt on {mark}: \"{dirt}\"")
T("log.sa_invent", "{schemer} and {partner} had no real dirt on {mark}, so they made some up.")
scene("sa_trade", noise=0.9, conditions=[c_present("schemer"), c_present("partner")],
    vars=[var("dirt", "secret_about", knower="partner", about="mark", optional=True)],
    effects=[hold(["schemer", "partner"], 5), emote("partner", "whisper"), say("schemer", "sa_trade", to="partner")],
    outcomes=[
        out("secret", [say("partner", "sa_give_secret", to="schemer", delay=1.8), learn("schemer", "$dirt", frm="partner"), reveal("$dirt"),
                       log("log.sa_trade", 3, "alliance", who=["schemer", "partner"]), arc_next("strike", wait=(10, 40))],
            score=[s_const(2)], when=[c_filled("$dirt")]),
        out("invent", [say("partner", "sa_make_up", to="schemer", delay=1.8),
                       rumor("slacker", a="mark", b="schemer", juicy=0.8, truth=False, knowers=["schemer", "partner"], key="dirt"),
                       log("log.sa_invent", 3, "alliance", who=["schemer", "partner"]), arc_next("strike", wait=(10, 40))], score=[s_const(1)]),
    ])

L("sa_strike", ["Ahmet Bey, I don't like saying this, but you should know: {dirt}", "I'm worried about {mark}. Did you know {dirt}"])
L("sa_boss_hmm", ["...Is that so? Interesting.", "I'll keep that in mind.", "Hm. That changes things."])
T("log.sa_strike", "{schemer} went to Ahmet with the dirt on {mark}. Ahmet listened.")
scene("sa_strike", noise=0.9, conditions=[c_avail("target")],
    roles=[role("informant", where=[c_avail("self"), c_aff("self", "mark", gt=15)], score=[s_trait("self", "curiosity", 0.8), s_aff("self", "mark", 0.02)],
                exclude=["schemer", "partner", "mark", "boss"], optional=True)],
    effects=[hold(["actor", "target"], 5), say("actor", "sa_strike", to="target"), say("target", "sa_boss_hmm", to="actor", delay=1.8),
             learn("target", "$dirt", frm="actor"), favor("mark", -8), favor("actor", 3), rel("target", "mark", "trust", -8),
             log("log.sa_strike", 4, "scheme", who=["schemer", "mark"])],
    outcomes=[
        out("seen", [arc_next("tip", wait=(15, 45))], score=[s_const(1)], when=[c_filled("informant")]),
        out("clean", [arc_end("success")], score=[s_const(0.2)]),
    ])

L("sa_tip", ["I saw {schemer} and {partner} whispering in the archive. Then {schemer} went straight to Ahmet about you.",
             "Heads up: {schemer} has been talking to Ahmet about you. And {partner} is in on it."])
L("sa_tip_react", ["{partner}?! I trusted them!", "Of course. Of COURSE.", "...Thank you for telling me."])
T("log.sa_tip", "{informant} tipped off {mark}: {schemer} and {partner} have been working against them.")
scene("sa_tip", noise=0.9, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), emote("actor", "whisper"), say("actor", "sa_tip", to="target"), say("target", "sa_tip_react", to="actor", delay=1.8),
             expr("target", "angry", 6, delay=1.8), rumor("alliance", a="schemer", b="partner", juicy=0.8, knowers=["actor", "target"]),
             rel("target", "actor", "trust", 12), rel("target", "schemer", "trust", -20), rel("target", "partner", "trust", -20),
             log("log.sa_tip", 4, "alliance", who=["informant", "mark"])],
    outcomes=[
        out("confront", [arc_next("showdown", wait=(5, 20))], score=[s_trait("target", "temper", 1.0), s_trait("target", "honesty", 0.5)]),
        out("revenge", [plan("target", "revenge", "schemer", heat=1.5), arc_end("revenge_plotted")], score=[s_trait("target", "cunning", 1.0), s_const(0.5)]),
    ])

L("sa_confront", ["You and {schemer}? Really? After everything?", "I know about the archive. I know about Ahmet. Explain.", "How much did {schemer} promise you?"])
L("sa_betray", ["It was all {schemer}'s idea! I just... listened!", "I'm out. I never wanted this. Talk to {schemer}."])
L("sa_loyal", ["I don't know what you're talking about.", "You're imagining things.", "Prove it."])
T("log.sa_betrayed", "{mark} confronted {partner}, who immediately sold out {schemer}. The alliance is dead.")
T("log.sa_loyal", "{mark} confronted {partner}. {partner} stayed loyal to {schemer} and denied everything.")
T("mem.sa_betrayed", "{partner} sold me out.")
scene("sa_showdown", noise=0.9, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5.5), expr("actor", "angry", 6), say("actor", "sa_confront", to="target")],
    outcomes=[
        out("betray", [say("target", "sa_betray", to="actor", delay=1.8), emote("target", "sweat", delay=1.8), bond("schemer", "partner", "alliance", v=False),
                       learn("actor", "$rumor", c=1.0), rel("schemer", "partner", "trust", -30), mem("schemer", "partner", "betrayed", -0.8, 1.0, "mem.sa_betrayed", 3),
                       bond("schemer", "partner", "feud"), rel("actor", "target", "trust", 5), log("log.sa_betrayed", 5, "alliance", who=["partner", "schemer"]),
                       arc_end("betrayed")],
            score=[s_trait("target", "empathy", 0.6), s_trait("target", "honesty", 0.6), s_aff("target", "actor", 0.015), s_aff("target", "schemer", -0.015), s_const(0.5)]),
        out("loyal", [say("target", "sa_loyal", to="actor", delay=1.8), rel("actor", "target", "trust", -15), rel("actor", "target", "friendship", -12),
                      log("log.sa_loyal", 4, "alliance", who=["partner", "mark"]), arc_end("loyal")],
            score=[s_trait("target", "cunning", 1.0), s_aff("target", "schemer", 0.015)]),
    ])

arc("secret_alliance", BIG, "proposal", cooldown_days=6, stages={
    "proposal": stage("sa_proposal", "meet", actor="schemer", target="partner", area="archive", wait=(5, 25), ttl=60, fail="retry"),
    "warning": stage("sa_warning", "visit", actor="partner", target="mark", ttl=90, fail="end:kept_quiet"),
    "trade": stage("sa_trade", "meet", actor="schemer", target="partner", area="archive", ttl=90, fail="retry"),
    "strike": stage("sa_strike", "visit", actor="schemer", target="boss", ttl=80, fail="retry"),
    "tip": stage("sa_tip", "visit", actor="informant", target="mark", ttl=80, fail="end:success"),
    "showdown": stage("sa_showdown", "visit", actor="mark", target="partner", ttl=80, fail="end:simmering"),
})

# =====================================================================
# 9. SURPRISE BIRTHDAY
# =====================================================================
starter("start_birthday", "birthday", {"organizer": "actor", "bday": "bday"},
        roles=[actor([c_trait("self", "empathy", gt=0.45), c_time(before="13:30")], [s_trait("self", "empathy", 1.0), s_goal("self", "keep_peace", 0.5)]),
               by_fn("bday", "birthday_person", avail=False, where=[c_present("self")], exclude=["actor"])],
        conditions=[c_dayflag("birthday")], cooldown_days=1, tier="medium", weight=5.0, urgent=True)

L("bd_plan", ["Wait — it's {bday}'s birthday today! Nobody's planned anything?!", "{bday}'s birthday. Cake. Card. Surprise. Go go go.",
              "Operation Birthday is a go. Target: {bday}."], ece=["IT'S {bday}'S BIRTHDAY! Okay, quiet, quiet. Secret mission."])
T("log.bd_plan", "{organizer} found out it's {bday}'s birthday and is secretly organising a surprise.")
scene("bd_plan", conditions=[c_avail("organizer")],
    roles=[by_fn("helper", "best_of", of="organizer", lim=-10, optional=True, exclude=["organizer", "bday"])],
    effects=[emote("organizer", "idea"), say("organizer", "bd_plan"), log("log.bd_plan", 2, "celebration", who=["organizer"])],
    outcomes=[
        out("helper", [arc_next("collect", wait=(5, 15))], score=[s_const(1)], when=[c_filled("helper")]),
        out("solo", [arc_next("hide_cake", wait=(10, 30))], score=[s_const(0.1)]),
    ])

L("bd_collect", ["Psst. Chip in for {bday}'s cake? And sign this card. Don't let them see!", "Five lira for {bday}'s surprise. It's a secret!"])
L("bd_collect_yes", ["Ooh, yes! Here.", "Count me in. Where do I sign?", "A surprise? I love it."])
L("bd_collect_blab", ["A SURPRISE? For {bday}? Oh, I'm terrible at secrets...", "Ha! I won't tell. Probably."])
T("log.bd_collect", "{organizer} is quietly collecting money and signatures for {bday}'s surprise.")
T("log.bd_collect_blab", "{organizer} recruited {helper} for {bday}'s surprise. {helper} is famously bad at secrets.")
scene("bd_collect", noise=0.9, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 4.5), emote("actor", "whisper"), say("actor", "bd_collect", to="target"), rel("actor", "target", "friendship", 3, both=True)],
    outcomes=[
        out("yes", [say("target", "bd_collect_yes", to="actor", delay=1.6), log("log.bd_collect", 2, "celebration", who=["organizer"]), arc_next("hide_cake", wait=(10, 30))],
            score=[s_trait("target", "honesty", 0.5), s_const(0.6)]),
        out("blab", [say("target", "bd_collect_blab", to="actor", delay=1.6), setv("leak", True), log("log.bd_collect_blab", 2, "celebration", who=["organizer", "helper"]),
                     arc_next("hide_cake", wait=(10, 30))],
            score=[s_trait("target", "gossip", 1.2), s_trait("target", "honesty", -0.6)]),
    ])

L("bd_hide", ["Cake in the fridge. Behind the yogurts. Perfect.", "Hidden. Nobody will look behind the pickles."])
L("bd_mert_cake", ["Ooh, is this cake for anyone?", "Is this... a whole cake? Can I—"], mert=["Is this cake for anyone? Asking for me."])
L("bd_dont", ["DON'T. TOUCH. IT.", "That is for {bday}! Hands off!", "Put. The fork. Down."])
T("log.bd_hide", "{organizer} hid {bday}'s birthday cake in the fridge.")
T("log.bd_almost", "{organizer} hid {bday}'s cake in the fridge. {snacker} nearly ate it.")
scene("bd_hide", noise=0.9,
    roles=[role("snacker", where=[c_avail("self")], score=[s_trait("self", "humor", 0.6), s_trait("self", "honesty", -0.4), s_rand(0.5)], near="organizer", r=5,
                optional=True, exclude=["organizer", "bday"])],
    effects=[say("organizer", "bd_hide"), emote("organizer", "whisper")],
    outcomes=[
        out("almost", [say("snacker", "bd_mert_cake", delay=1.8), say("organizer", "bd_dont", to="snacker", delay=3.2), emote("snacker", "sweat", delay=3.2),
                       log("log.bd_almost", 2, "celebration", who=["organizer", "snacker"]), arc_next("surprise", wait=(20, 50))],
            score=[s_const(2)], when=[c_filled("snacker")]),
        out("hidden", [log("log.bd_hide", 1, "celebration", who=["organizer"]), arc_next("surprise", wait=(20, 50))], score=[s_const(1)]),
    ])

L("bd_surprise", ["SURPRISE!!!", "HAPPY BIRTHDAY!", "🎂 SURPRIIIISE!"])
L("bd_bday_happy", ["You guys! Oh my god! I thought everyone forgot!", "No WAY. For me?!", "I'm not crying. You're crying."],
  ahmet=["...Hmph. Well. Thank you. All of you."], burak=["...I hate surprises. ...Thank you."], deniz=["Well. This is... unexpectedly nice."])
L("bd_bday_knew", ["Ha! I knew! Someone can't keep a secret!", "I saw the cake this morning. But I'm STILL touched!"])
L("bd_sing", ["♪ Happy birthday to you ♪", "Speech! Speech!", "Make a wish!", "Cake! CAKE!"])
L("bd_where", ["Wait. Where's {bday}?!", "We forgot to bring the birthday person.", "...Did anyone actually tell {bday} to come?"])
T("log.bd_party", "Surprise! The office threw {bday} a birthday party in the kitchen. Even Ahmet had cake.")
T("log.bd_party_leak", "The office threw {bday} a surprise birthday party. Thanks to {helper}, it wasn't much of a surprise — but {bday} loved it.")
T("log.bd_missed", "The office gathered in the kitchen for {bday}'s surprise party. {bday} never showed up.")
T("mem.bd_party", "Everyone threw me a surprise birthday party.")
scene("bd_surprise",
    outcomes=[
        out("party", [each([say("self", "bd_surprise", p=0.6), emote("self", "cheer"), mood("self", 6), rel("self", "bday", "friendship", 3)], exclude=["bday"], stagger=0.3,
                           where=[c_zone("self", ["kitchen"])]),
                      expr("bday", "happy", 10, ), emote("bday", "love", ), say("bday", "bd_bday_happy", delay=1.8), mood("bday", 30), morale("bday", 8), stress("bday", -15),
                      each([say("self", "bd_sing", p=0.4, delay=3.0), rel("bday", "self", "friendship", 4)], exclude=["bday"], stagger=0.4, where=[c_zone("self", ["kitchen"])]),
                      mem("bday", "organizer", "party", 0.9, 1.0, "mem.bd_party", 3), sfx("crowd"), log("log.bd_party", 4, "celebration", who=["bday", "organizer"]),
                      arc_end("party")],
            score=[s_const(2)], when=[c_zone("bday", ["kitchen"]), c_not(c_var("leak", eq=True))]),
        out("leak", [each([say("self", "bd_surprise", p=0.6), emote("self", "cheer"), mood("self", 5)], exclude=["bday"], stagger=0.3, where=[c_zone("self", ["kitchen"])]),
                     say("bday", "bd_bday_knew", delay=1.6), emote("bday", "love", delay=1.6), mood("bday", 20), morale("bday", 5),
                     mem("bday", "organizer", "party", 0.8, 0.9, "mem.bd_party", 3), sfx("crowd"), log("log.bd_party_leak", 4, "celebration", who=["bday", "helper"]),
                     arc_end("party_spoiled")],
            score=[s_const(2)], when=[c_zone("bday", ["kitchen"]), c_var("leak", eq=True)]),
        out("missed", [say("organizer", "bd_where", delay=1.0), emote("organizer", "sweat", delay=1.0),
                       each([emote("self", "question", delay=1.4)], exclude=["organizer"], where=[c_zone("self", ["kitchen"])]),
                       log("log.bd_missed", 3, "celebration", who=["organizer", "bday"]), arc_end("missed")], score=[s_const(0.5)]),
    ])

arc("birthday", BIG, "plan", cooldown_days=1, max_active=1, stages={
    "plan": stage("bd_plan", "now", actor="organizer", wait=(1, 5), ttl=90),
    "collect": stage("bd_collect", "visit", actor="organizer", target="helper", ttl=50, fail="hide_cake"),
    "hide_cake": stage("bd_hide", "place", actor="organizer", place="fridge", ttl=60, fail="surprise"),
    "surprise": stage("bd_surprise", "gather", actor="organizer", area="kitchen", need=4, ttl=60, window=("13:20", "16:50"), fail="end:no_party", must=["bday"]),
})

# =====================================================================
# 10. THE BLAME GAME — a client complaint and a hunt for someone to blame
# =====================================================================
starter("start_blame_game", "blame_game", {"boss": "actor", "culprit": "culprit"},
        roles=[actor([c_is("self", "ahmet"), c_time(after="10:00", before="15:30")], [s_stress("self", 0.02), s_trait("self", "temper", 0.6)]),
               role("culprit", where=[c_avail("self"), c_is("self", "ahmet", neg=True)],
                    score=[s_trait("self", "diligence", -1.2), s_trait("self", "clumsiness", 0.8), s_rand(0.6)], exclude=["actor"])],
        cooldown_days=5)

L("bg_phone", ["WHAT? The figures were WRONG? ...I'll call you back.", "...The client says WHAT? Our numbers were off by a ZERO?!", "I understand. It won't happen again."])
T("log.bg_complaint", "A client called Ahmet, furious: the numbers we sent were wrong. (It was {culprit}'s spreadsheet.)")
scene("bg_complaint", conditions=[c_present("boss")],
    effects=[act("boss", "phone", place="desk_ahmet", dur=4), say("boss", "bg_phone"), expr("boss", "angry", 8), sfx("slam", delay=2.0), stress("boss", 15),
             emote("culprit", "sweat", delay=2.5), log("log.bg_complaint", 3, "blame", who=["boss", "culprit"]), arc_next("hunt", wait=(2, 6))])

L("bg_hunt", ["Someone sent the client WRONG figures. I want a name. NOW.", "Who prepared the client numbers?! Step forward!", "I will find out who did this. Better if you tell me first."])
T("log.bg_hunt", "Ahmet stood in the middle of the office demanding to know who sent the wrong figures.")
scene("bg_hunt",
    effects=[say("boss", "bg_hunt"), expr("boss", "angry", 8), each([stress("self", 6), emote("self", "sweat", delay=0.8)], exclude=["boss"], stagger=0.3),
             log("log.bg_hunt", 3, "blame", who=["boss"]), arc_next("culprit_move", wait=(1, 4))])

L("bg_shift_think", ["If anyone asks, {scapegoat} sent those numbers.", "Not me. Definitely not me. {scapegoat}, maybe."])
L("bg_hide_think", ["Please don't look at me. Please don't look at me.", "Maybe it'll blow over...", "*hides behind monitor*"])
T("log.bg_shift", "{culprit} quietly told Ahmet that {scapegoat} sent the wrong figures. It was {culprit}.")
T("log.bg_hide", "{culprit} kept their head down. Ahmet is now looking at {scapegoat}.")
scene("bg_move", noise=0.9, conditions=[c_present("culprit")],
    vars=[var("scapegoat", "suspect", of="culprit", optional=True), var("boss_pick", "suspect", of="boss", optional=True)],
    outcomes=[
        out("confess", [arc_next("confession", wait=(1, 4))], score=[s_trait("culprit", "honesty", 1.0), s_const(-0.25)]),
        out("shift", [say("culprit", "bg_shift_think"), rumor("blamed", a="$scapegoat", b="culprit", juicy=0.6, truth=False, knowers=["boss"], origin="culprit"),
                      rel("boss", "$scapegoat", "trust", -6), log("log.bg_shift", 4, "blame", who=["culprit", "$scapegoat"]), arc_next("accusation", wait=(3, 10))],
            score=[s_trait("culprit", "cunning", 1.3), s_trait("culprit", "honesty", -0.8)],
            when=[c_filled("$scapegoat"), c_same("$scapegoat", "boss", neg=True), c_present("$scapegoat")]),
        out("hide", [say("culprit", "bg_hide_think"), setv("scapegoat", "$boss_pick"), log("log.bg_hide", 3, "blame", who=["culprit"]), arc_next("accusation", wait=(3, 10))],
            score=[s_const(0.45), s_trait("culprit", "honesty", -0.6), s_stress("culprit", 0.01), s_goal("culprit", "be_liked", 0.4)],
            when=[c_filled("$boss_pick"), c_same("$boss_pick", "culprit", neg=True), c_present("$boss_pick")]),
        out("fallback", [arc_next("confession", wait=(5, 15))], score=[s_const(0.05)]),
    ])

L("bg_confess", ["Ahmet Bey... it was me. I mixed up the columns.", "The figures were mine. I'm sorry. I'll call the client myself.", "It was my mistake."])
L("bg_respect", ["...Thank you for telling me. Fix it. Today.", "At least you're honest. Call them back.", "Hm. Mistakes happen. Don't let it happen twice."])
L("bg_explode", ["A ZERO?! Do you know how that makes us look?!", "Unacceptable! Completely unacceptable!"])
T("log.bg_confessed", "{culprit} walked into Ahmet's office and admitted the wrong figures were theirs.")
scene("bg_confess", noise=0.9, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), say("actor", "bg_confess", to="target"), log("log.bg_confessed", 3, "blame", who=["culprit", "boss"])],
    outcomes=[
        out("respect", [say("target", "bg_respect", to="actor", delay=1.8), favor("actor", -3), rel("target", "actor", "trust", 6), stress("actor", -6), arc_end("owned_up")],
            score=[s_rel("target", "actor", "trust", 0.02), s_const(0.5)]),
        out("explode", [say("target", "bg_explode", to="actor", delay=1.8), expr("target", "angry", 7, delay=1.8), favor("actor", -8), stress("actor", 15),
                        mem("actor", "target", "scolded", -0.5, 0.8, "mem.scolded", 2), stat("scoldings"), arc_end("scolded")],
            score=[s_trait("target", "temper", 1.0), s_stress("target", 0.01)]),
    ])

L("bg_accuse", ["{scapegoat}. The client figures. Explain.", "I hear it was YOU who sent those numbers.", "My office has a question for you, {scapegoat}: why?"])
L("bg_proof", ["Check the file history. I haven't opened that spreadsheet in weeks.", "It wasn't me. Look at the timestamps.", "Ask {culprit} who last edited it."])
L("bg_crushed", ["...I didn't do it. But fine.", "I don't know what to say.", "...Okay."])
T("log.bg_proof", "Ahmet accused {scapegoat} of the wrong figures. {scapegoat} told him to check the file history.")
T("log.bg_injustice", "Ahmet blamed {scapegoat} for the wrong figures. {scapegoat} took it — but it was {culprit}.")
T("mem.bg_injustice", "Ahmet blamed me for {culprit}'s mistake.")
scene("bg_accuse", noise=0.9, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), expr("actor", "angry", 6), say("actor", "bg_accuse", to="target")],
    outcomes=[
        out("proof", [say("target", "bg_proof", to="actor", delay=1.8), expr("target", "angry", 5, delay=1.8), log("log.bg_proof", 3, "blame", who=["scapegoat", "boss"]),
                      arc_next("truth", wait=(3, 12))],
            score=[s_trait("target", "diligence", 1.0), s_trait("target", "temper", 0.6), s_trait("target", "honesty", 0.4)]),
        out("crushed", [say("target", "bg_crushed", to="actor", delay=1.8), expr("target", "sad", 6, delay=1.8), favor("target", -8), morale("target", -8),
                        mem("target", "actor", "falsely_accused", -0.7, 0.9, "mem.bg_injustice", 3),
                        plan("target", "revenge", "culprit", heat=1.0, when=[c_knows("target", "$rumor")]),
                        log("log.bg_injustice", 4, "blame", who=["scapegoat", "culprit"]), arc_end("injustice")],
            score=[s_trait("target", "temper", -1.0), s_trait("target", "empathy", 0.5), s_const(0.6)]),
    ])

L("bg_truth", ["The file history says YOU edited that spreadsheet. Not {scapegoat}.", "So. Timestamps. Funny things, timestamps.", "You let {scapegoat} take the blame?"])
L("bg_caught", ["I... I can explain.", "It was an honest mistake!", "...Yes. It was me."])
T("log.bg_truth", "The file history doesn't lie: the figures were {culprit}'s. Ahmet now knows {culprit} let {scapegoat} take the blame.")
T("mem.bg_caught", "Ahmet caught me blaming {scapegoat}.")
scene("bg_truth", conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5.5), say("actor", "bg_truth", to="target"), say("target", "bg_caught", to="actor", delay=1.8), emote("target", "sweat", delay=1.8),
             favor("target", -12), rel("actor", "target", "trust", -18), favor("scapegoat", 6), rel("actor", "scapegoat", "trust", 8),
             debunk("$rumor", who=["boss", "scapegoat"], by="boss", when=[c_filled("$rumor")]),
             mem("target", "actor", "humiliated", -0.7, 0.9, "mem.bg_caught", 3), mem("scapegoat", "culprit", "falsely_accused", -0.6, 0.8, "mem.blamed_me", 3),
             rel("scapegoat", "culprit", "friendship", -15), rel("scapegoat", "culprit", "trust", -20), stat("scoldings"),
             log("log.bg_truth", 5, "blame", who=["culprit", "scapegoat"]), arc_end("truth")])

arc("blame_game", BIG, "complaint", cooldown_days=5, stages={
    "complaint": stage("bg_complaint", "now", actor="boss", wait=(2, 8), ttl=60),
    "hunt": stage("bg_hunt", "place", actor="boss", place="announce", ttl=50, fail="culprit_move"),
    "culprit_move": stage("bg_move", "now", actor="culprit", ttl=60, fail="end:blew_over"),
    "confession": stage("bg_confess", "visit", actor="culprit", target="boss", ttl=60, fail="end:blew_over"),
    "accusation": stage("bg_accuse", "visit", actor="boss", target="$scapegoat", ttl=70, fail="end:blew_over"),
    "truth": stage("bg_truth", "visit", actor="boss", target="culprit", ttl=90, fail="end:half_truth"),
})

# =====================================================================
# 11. MENTOR & PROTÉGÉ — covering for a junior's mistake
# =====================================================================
starter("start_mentor", "mentor_protect", {"mentor": "actor", "protege": "protege", "boss": "@ahmet"},
        roles=[actor([c_trait("self", "empathy", gt=0.45), c_trait("self", "diligence", gt=0.65), c_is("self", in_=["ahmet", "ece"], neg=True), c_present("@ahmet")],
                     [s_trait("self", "empathy", 1.0), s_trait("self", "diligence", 0.5)]),
               role("protege", where=[c_avail("self"), c_is("self", "ahmet", neg=True), c_aff("actor", "self", gt=12)],
                    score=[s_is("self", "ece", 1.5), s_trait("self", "clumsiness", 0.8), s_aff("actor", "self", 0.01)], exclude=["actor"])],
        cooldown_days=5)

L("mp_mistake", ["Oh no. I typed the wrong totals into {mentor}'s report. And it's already on Ahmet's desk!", "I mixed up two columns in {mentor}'s report. Ahmet has it. I'm dead."])
T("log.mp_mistake", "{protege} realised they put the wrong numbers into {mentor}'s report — and Ahmet already has it.")
scene("mp_mistake", conditions=[c_avail("protege")],
    effects=[expr("protege", "surprised", 6), emote("protege", "sweat"), say("protege", "mp_mistake"), stress("protege", 18),
             log("log.mp_mistake", 3, "protect", who=["protege", "mentor"]), arc_next("cover", wait=(3, 10))])

L("mp_cover", ["Ahmet Bey, there's an error in my report. My fault. Corrected version in ten minutes.", "I made a mistake in the totals. It's fixed. It won't happen again."])
L("mp_boss_mild", ["Hm. Not like you. Fix it.", "Alright. Ten minutes."])
L("mp_boss_annoyed", ["Sloppy. I expected better from you.", "Mistakes in MY reports? Again?"])
T("log.mp_cover", "{mentor} told Ahmet the report error was their own fault — to protect {protege}.")
scene("mp_cover", noise=0.9, conditions=[c_avail("target")],
    roles=[by_fn("rival", "rival_of", of="mentor", lim=25, optional=True, avail=False, exclude=["mentor", "protege", "boss"])],
    effects=[hold(["actor", "target"], 5), say("actor", "mp_cover", to="target"), bond("mentor", "protege", "mentor"),
             log("log.mp_cover", 3, "protect", who=["mentor", "protege"])],
    outcomes=[
        out("mild_rival", [say("target", "mp_boss_mild", to="actor", delay=1.8), favor("mentor", -3), arc_next("exploit", wait=(10, 35))],
            score=[s_rel("target", "actor", "trust", 0.02)], when=[c_filled("rival"), c_present("rival")]),
        out("annoyed_rival", [say("target", "mp_boss_annoyed", to="actor", delay=1.8), favor("mentor", -6), stress("mentor", 8), arc_next("exploit", wait=(10, 35))],
            score=[s_trait("target", "temper", 1.0), s_const(0.6)], when=[c_filled("rival"), c_present("rival")]),
        out("mild", [say("target", "mp_boss_mild", to="actor", delay=1.8), favor("mentor", -3), arc_next("thanks", wait=(10, 30))], score=[s_const(0.4)]),
    ])

L("mp_exploit", ["Funny thing, Ahmet Bey — I heard that report error was the intern's. Someone's covering. Not very transparent, is it?",
                 "You know {mentor} is covering for {protege}, right? Just thought you should know."])
L("mp_boss_hmm", ["...Covering? In MY office?", "Is that so.", "I'll look into it."])
L("mp_boss_dismiss", ["I don't care whose typo it was. Get back to work.", "Office gossip is not a performance review, Deniz."])
T("log.mp_exploit", "{rival} told Ahmet that {mentor} was covering for {protege}. Ahmet is not pleased.")
T("log.mp_exploit_fail", "{rival} tried to use {mentor}'s cover-up against them. Ahmet wasn't interested.")
scene("mp_exploit", noise=0.9, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), say("actor", "mp_exploit", to="target")],
    outcomes=[
        out("works", [say("target", "mp_boss_hmm", to="actor", delay=1.8), rel("target", "mentor", "trust", -8), favor("rival", 3),
                      log("log.mp_exploit", 3, "scheme", who=["rival", "mentor"]), arc_next("protege_speaks", wait=(5, 20))],
            score=[s_rel("target", "actor", "trust", 0.01), s_const(1.3)]),
        out("dismissed", [say("target", "mp_boss_dismiss", to="actor", delay=1.8), favor("rival", -2), log("log.mp_exploit_fail", 2, "scheme", who=["rival"]),
                          arc_next("thanks", wait=(10, 30))], score=[s_trait("target", "temper", 0.5), s_rel("target", "mentor", "trust", 0.008)]),
    ])

L("mp_confess", ["Ahmet Bey — the mistake was mine. {mentor} was protecting me. Please don't blame them.", "It was me. Not {mentor}. I'm sorry."])
L("mp_boss_respect", ["...Hm. Loyalty AND honesty. Both of you, back to work.", "Fine. I respect that. Don't let it happen again."])
T("log.mp_confess", "{protege} marched into Ahmet's office and confessed: the error was theirs, {mentor} was protecting them.")
scene("mp_confess", conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), say("actor", "mp_confess", to="target"), say("target", "mp_boss_respect", to="actor", delay=1.8),
             rel("target", "mentor", "trust", 10), rel("target", "protege", "trust", 6), favor("mentor", 4), favor("rival", -4),
             log("log.mp_confess", 4, "protect", who=["protege", "mentor"]), arc_next("thanks", wait=(5, 20))])

L("mp_thank", ["Thank you. For covering for me. You didn't have to.", "Why did you do that for me?", "I owe you. Big time."])
L("mp_mentor_reply", ["That's what we do here. Next time, double-check the totals.", "Everyone messes up once. Just not twice.", "You'd do the same for me."])
T("log.mp_bonded", "{protege} thanked {mentor} over coffee. Those two have each other's backs now.")
T("mem.mp_bonded", "{mentor} protected me when I messed up.")
scene("mp_thanks", conditions=[c_present("mentor"), c_present("protege")],
    effects=[hold(["mentor", "protege"], 5), say("protege", "mp_thank", to="mentor"), say("mentor", "mp_mentor_reply", to="protege", delay=1.8),
             emote("protege", "love", delay=1.8), rel("protege", "mentor", "friendship", 18, both=True, k=0.7), rel("protege", "mentor", "trust", 15),
             mem("protege", "mentor", "defended_me", 0.9, 1.0, "mem.mp_bonded", 3), morale("protege", 6),
             log("log.mp_bonded", 3, "protect", who=["mentor", "protege"]), arc_end("bonded")])

arc("mentor_protect", BIG, "mistake", cooldown_days=5, stages={
    "mistake": stage("mp_mistake", "now", actor="protege", wait=(3, 12), ttl=60),
    "cover": stage("mp_cover", "visit", actor="mentor", target="boss", ttl=70, fail="end:never_covered"),
    "exploit": stage("mp_exploit", "visit", actor="rival", target="boss", ttl=80, fail="thanks"),
    "protege_speaks": stage("mp_confess", "visit", actor="protege", target="boss", ttl=70, fail="thanks"),
    "thanks": stage("mp_thanks", "meet", actor="protege", target="mentor", area="kitchen", ttl=80, fail="end:unspoken"),
})

# =====================================================================
# 12. PUSHING FOR PROMOTION
# =====================================================================
starter("start_promo_push", "promotion_push", {"climber": "actor", "boss": "@ahmet"},
        roles=[actor([c_goal("self", "earn_promotion"), {"c": "promoted", "who": "self", "not": True}, c_present("@ahmet"), c_time(after="09:40", before="14:00")],
                     [s_trait("self", "ambition", 1.0), s_morale("self", -0.01)])],
        cooldown_days=5)

L("pp_ask", ["Ahmet Bey, I'd like to talk about the team lead position.", "I think I've earned a shot at team lead. I'd like to know where I stand.", "What would it take for me to get promoted?"])
L("pp_prove", ["Prove it. Land the Kaya account pitch. By tomorrow.", "Results talk. Bring me a pitch that wins Kaya.", "Show me. Then we talk."])
L("pp_dismiss", ["Now is not the time.", "When there's a position, I'll let you know.", "Patience. Everyone wants to be promoted."])
L("pp_promise", ["You're first in line. Don't tell anyone I said that.", "Keep doing what you're doing. It's yours soon."])
T("log.pp_prove", "{climber} asked Ahmet about a promotion. Ahmet's answer: \"Prove it.\" The race is on.")
T("log.pp_dismiss", "{climber} asked Ahmet about a promotion and got brushed off.")
T("log.pp_promise", "{climber} asked Ahmet about a promotion. He hinted it's theirs.")
T("mem.pp_brushed", "Ahmet brushed off my promotion request.")
scene("pp_request", noise=0.9, conditions=[c_present("climber"), c_present("boss")],
    effects=[hold(["climber", "boss"], 5.5), say("climber", "pp_ask", to="boss")],
    outcomes=[
        out("prove", [say("boss", "pp_prove", to="climber", delay=1.8), emote("climber", "idea", delay=1.8), call("extra_work", target="climber", units=24, task="kaya_pitch"),
                      plan("climber", "prove_self", "", heat=1.5), log("log.pp_prove", 3, "promotion", who=["climber", "boss"]), arc_next("grind", wait=(20, 50))],
            score=[s_const(1.0), s_trait("boss", "diligence", 0.5)]),
        out("dismiss", [say("boss", "pp_dismiss", to="climber", delay=1.8), expr("climber", "sad", 5, delay=1.8), morale("climber", -8),
                        mem("climber", "boss", "humiliated", -0.4, 0.7, "mem.pp_brushed", 2), log("log.pp_dismiss", 3, "promotion", who=["climber"]), arc_end("brushed_off")],
            score=[s_trait("boss", "temper", 0.6), s_stress("boss", 0.012), s_const(0.5)]),
        out("promise", [say("boss", "pp_promise", to="climber", delay=1.8), emote("climber", "cheer", delay=1.8), morale("climber", 10), mood("climber", 12),
                        log("log.pp_promise", 3, "promotion", who=["climber"]), arc_end("promised")],
            score=[{"s": "favor", "who": "climber", "w": 0.03}, s_rel("boss", "climber", "trust", 0.01), s_const(-1.5)]),
    ])

L("pp_grind", ["Lunch? No. Pitch.", "Slide twelve. Slide THIRTEEN.", "If I finish this, I'm team lead. FOCUS."])
T("log.pp_grind", "{climber} is working like a machine on the Kaya pitch. Someone has noticed: {rival}.")
T("log.pp_grind_solo", "{climber} is working like a machine on the Kaya pitch.")
scene("pp_grind", noise=0.9, conditions=[c_present("climber")],
    roles=[by_fn("rival", "rival_of", of="climber", lim=30, optional=True, avail=False, exclude=["climber", "boss"])],
    effects=[say("climber", "pp_grind"), stress("climber", 10), work("climber", 8)],
    outcomes=[
        out("rival", [log("log.pp_grind", 3, "promotion", who=["climber", "rival"]), arc_next("sabotage", wait=(10, 30))], score=[s_const(1)], when=[c_filled("rival")]),
        out("solo", [log("log.pp_grind_solo", 2, "promotion", who=["climber"]), arc_next("present", wait=(30, 70))], score=[s_const(0.2)]),
    ])

L("pp_sabotage", ["Shame if these slides got... shuffled.", "Oops. Is this the final version? Was.", "Nothing personal."])
T("log.pp_sabotage", "While {climber} was away, {rival} quietly wrecked their pitch notes.")
scene("pp_sabotage", allow_absent=True, conditions=[c_present("rival"), {"c": "activity", "who": "climber", "in": ["work", "review"], "not": True}],
    effects=[emote("rival", "whisper"), say("rival", "pp_sabotage"), call("mess_desk", who="rival", target="climber"), work("climber", -12), setv("sabotaged", True),
             log("log.pp_sabotage", 4, "scheme", who=["rival", "climber"]), arc_next("present", wait=(20, 50))])

L("pp_present", ["...and that's why Kaya will sign with us. Questions?", "Here's the pitch. Three slides. No fluff.", "I'd like to walk you through the Kaya proposal."])
L("pp_great", ["...That's excellent. Really excellent.", "Now THAT is a team lead's work.", "I'm impressed."])
L("pp_flop", ["The numbers are a mess. What happened?", "This isn't ready.", "I expected more."])
L("pp_flop_excuse", ["Someone messed with my desk! My notes were everywhere!", "I... it was ready this morning!"])
T("log.pp_great", "{climber} nailed the Kaya pitch in the meeting room. Ahmet was visibly impressed.")
T("log.pp_flop", "{climber}'s Kaya pitch fell apart in front of Ahmet.")
T("log.pp_flop_sab", "{climber}'s Kaya pitch fell apart — the notes had been sabotaged. Ahmet doesn't know that.")
T("mem.pp_great", "Ahmet loved my pitch.")
scene("pp_present", noise=0.9, conditions=[c_present("climber"), c_present("boss")],
    effects=[hold(["climber", "boss"], 6), say("climber", "pp_present", to="boss")],
    outcomes=[
        out("great", [say("boss", "pp_great", to="climber", delay=2.0), emote("climber", "cheer", delay=2.0), favor("climber", 12), morale("climber", 8), mood("climber", 15),
                      stat("praises"), mem("climber", "boss", "praised", 0.7, 0.9, "mem.pp_great", 3), log("log.pp_great", 3, "promotion", who=["climber"]),
                      arc_next("verdict", days=1)],
            score=[s_trait("climber", "diligence", 1.2), s_stress("climber", -0.01), s_const(0.6)]),
        out("flop", [say("boss", "pp_flop", to="climber", delay=2.0), expr("climber", "sad", 6, delay=2.0), favor("climber", -5), mood("climber", -12),
                     say("climber", "pp_flop_excuse", delay=3.6, when=[c_var("sabotaged", eq=True)]),
                     log("log.pp_flop_sab", 3, "promotion", who=["climber"], when=[c_var("sabotaged", eq=True)]),
                     log("log.pp_flop", 3, "promotion", who=["climber"], when=[c_not(c_var("sabotaged", eq=True))]),
                     arc_next("verdict", days=1)],
            score=[s_stress("climber", 0.012), s_const(0.3), {"s": "if", "cond": c_var("sabotaged", eq=True), "v": 1.2}]),
    ])

L("pp_verdict_open", ["About yesterday...", "I've been thinking about the team lead role."])
L("pp_yes", ["When the position opens, it's yours.", "You've earned it. Officially, soon."])
L("pp_not_yet", ["Not yet. Keep working.", "You're close. Not there."])
T("log.pp_yes", "Ahmet told {climber} they're next in line for team lead.")
T("log.pp_not_yet", "Ahmet told {climber}: \"Not yet.\" {climber} took it badly.")
scene("pp_verdict", noise=0.9, conditions=[c_present("climber"), c_present("boss")],
    effects=[hold(["climber", "boss"], 5), say("boss", "pp_verdict_open", to="climber")],
    outcomes=[
        out("yes", [say("boss", "pp_yes", to="climber", delay=1.8), emote("climber", "cheer", delay=1.8), morale("climber", 12), favor("climber", 6),
                    plan("climber", "prove_self", v=False), log("log.pp_yes", 4, "promotion", who=["climber"]), arc_end("next_in_line")],
            score=[{"s": "favor", "who": "climber", "w": 0.03}]),
        out("no", [say("boss", "pp_not_yet", to="climber", delay=1.8), expr("climber", "angry", 5, delay=1.8), morale("climber", -10),
                   plan("climber", "job_search", "", heat=0.8, when=[c_morale("climber", lt=40)]), log("log.pp_not_yet", 3, "promotion", who=["climber"]),
                   arc_end("not_yet")], score=[s_const(1.6)]),
    ])

arc("promotion_push", BIG, "request", cooldown_days=5, stages={
    "request": stage("pp_request", "meet", actor="climber", target="boss", area="boss", wait=(5, 20), ttl=70),
    "grind": stage("pp_grind", "now", actor="climber", ttl=90, fail="present"),
    "sabotage": stage("pp_sabotage", "desk", actor="rival", target="climber", ttl=60, fail="present"),
    "present": stage("pp_present", "meet", actor="climber", target="boss", area="meeting", ttl=100, fail="verdict"),
    "verdict": stage("pp_verdict", "meet", actor="climber", target="boss", area="boss", ttl=120, fail="retry"),
})

# =====================================================================
# 13. THE REVENGE PLOT
# =====================================================================
starter("start_revenge", "revenge_plot", {"avenger": "actor", "victim": "victim", "accomplice": "accomplice"},
        roles=[actor([c_plan("self", "revenge")], [s_plan("self", "revenge", 1.5), s_trait("self", "forgiveness", -0.8)]),
               by_fn("victim", "plan_target", kind="revenge", avail=False, where=[c_present("self")]),
               by_fn("accomplice", "best_of", lim=10, exclude=["actor", "victim"])],
        cooldown_days=4)

L("rv_brood", ["I'm going to get {victim} back. And you're going to help.", "{victim} has it coming. I have a plan.", "Revenge is a dish best served... by Friday."])
L("rv_in", ["...Okay, I'm listening. What's the plan?", "Ha! Count me in.", "Fine. But nothing that gets us fired."])
L("rv_calm", ["Let it go. It's not worth it.", "Revenge? Seriously? Talk to them instead.", "You'll regret it. Don't."])
L("rv_calmed", ["...Maybe you're right.", "Ugh. Fine. You're too reasonable."])
T("log.rv_plot", "{avenger} is plotting revenge against {victim} — and {accomplice} is in on it.")
T("log.rv_calmed", "{avenger} wanted revenge on {victim}. {accomplice} talked them down.")
scene("rv_brood", noise=0.9, conditions=[c_present("avenger"), c_present("accomplice")],
    effects=[hold(["avenger", "accomplice"], 5), emote("avenger", "whisper"), say("avenger", "rv_brood", to="accomplice")],
    outcomes=[
        out("in", [say("accomplice", "rv_in", to="avenger", delay=1.8), rel("avenger", "accomplice", "trust", 6), log("log.rv_plot", 3, "scheme", who=["avenger", "victim"]),
                   arc_next("prank", wait=(15, 45))],
            score=[s_trait("accomplice", "humor", 0.6), s_trait("accomplice", "cunning", 0.6), s_aff("accomplice", "victim", -0.03), s_const(0.9)]),
        out("calm", [say("accomplice", "rv_calm", to="avenger", delay=1.8), say("avenger", "rv_calmed", delay=3.4), plan("avenger", "revenge", "victim", heat=-1.5),
                     log("log.rv_calmed", 2, "friendship", who=["accomplice", "avenger"]), arc_end("talked_down")],
            score=[s_trait("accomplice", "empathy", 1.0), s_trait("accomplice", "honesty", 0.5)]),
    ])

L("rv_prank", ["Swapping the keyboard keys. Every. Single. One.", "Salt in the sugar jar. Their jar.", "Changing the desktop wallpaper to... this.",
               "Taping a photo of Ahmet inside the drawer. Enjoy."])
T("log.rv_prank", "{avenger} sneaked over to {victim}'s empty desk and set up a prank.")
scene("rv_prank", allow_absent=True, conditions=[c_present("avenger")],
    effects=[emote("avenger", "whisper"), say("avenger", "rv_prank"), npcflag("victim", "pranked"), log("log.rv_prank", 3, "prank", who=["avenger", "victim"]),
             arc_next("discovery", wait=(5, 20))])

L("rv_found", ["WHO swapped my keyboard keys?!", "My sugar is SALT. Who did this?!", "Why is Ahmet's face in my drawer?!", "My wallpaper is a llama. WHY."])
L("rv_knows", ["{avenger}. It was {avenger}. I KNOW it was.", "Of course. {avenger}. Payback, huh?"])
L("rv_wrong", ["This has {suspect} written all over it.", "{suspect}! I know it was you!"])
T("log.rv_found_right", "{victim} found the prank and knew instantly: it was {avenger}.")
T("log.rv_found_wrong", "{victim} found the prank — and blamed {suspect}. ({avenger} did it.)")
scene("rv_discover", noise=0.9, conditions=[c_avail("victim")],
    vars=[var("suspect", "suspect", of="victim", desk=True, optional=True)],
    effects=[expr("victim", "angry", 6), emote("victim", "anger"), say("victim", "rv_found"), stress("victim", 8)],
    outcomes=[
        out("right", [say("victim", "rv_knows", delay=1.8), learn("victim", "$rumor", c=1.0, when=[c_filled("$rumor")]), log("log.rv_found_right", 3, "prank", who=["victim", "avenger"]),
                      arc_next("confront", wait=(2, 8))],
            score=[s_const(2)], when=[c_any(c_bond("victim", "avenger", "feud"), c_mem("victim", "argued", about="avenger", days=3),
                                            c_mem("victim", "feud", about="avenger", days=4), c_same("$suspect", "avenger"))]),
        out("wrong", [say("victim", "rv_wrong", delay=1.8), rel("victim", "$suspect", "trust", -10), mem("victim", "$suspect", "pranked_me", -0.4, 0.7, "mem.pranked", 2),
                      log("log.rv_found_wrong", 3, "misunderstanding", who=["victim", "$suspect"]), plan("avenger", "revenge", "victim", v=False), arc_end("wrong_target")],
            score=[s_const(1)], when=[c_filled("$suspect"), c_same("$suspect", "avenger", neg=True)]),
        out("shrug", [plan("avenger", "revenge", "victim", v=False), arc_end("unnoticed")], score=[s_const(0.2)]),
    ])

L("rv_confront", ["Was this you? Be honest.", "Real mature. Real mature.", "You want a war? You've got one."])
L("rv_gloat", ["Ha! Took you long enough.", "Now we're even.", "Oops. Did I do that?"])
L("rv_sorry", ["...Yeah. That was me. It was stupid. I'm sorry.", "Okay, okay. I was angry. Truce?"])
L("rv_accept_sorry", ["...Fine. Truce. But fix my keyboard.", "Okay. We're even. Done."])
T("log.rv_war", "{victim} confronted {avenger} about the prank. {avenger} gloated. It's war now.")
T("log.rv_truce", "{victim} confronted {avenger} about the prank. {avenger} apologised — a truce, for now.")
scene("rv_confront", noise=0.9, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), expr("actor", "angry", 6), say("actor", "rv_confront", to="target")],
    outcomes=[
        out("gloat", [say("target", "rv_gloat", to="actor", delay=1.8), expr("actor", "angry", 8, delay=1.8), sfx("argue", delay=1.8), stat("arguments"),
                      rel("actor", "target", "friendship", -15, both=True), rel("actor", "target", "rivalry", 12, both=True), bond("avenger", "victim", "feud"),
                      plan("victim", "revenge", "avenger", heat=1.2), plan("avenger", "revenge", "victim", v=False),
                      log("log.rv_war", 4, "conflict", who=["victim", "avenger"]), arc_end("war")],
            score=[s_trait("target", "cunning", 0.8), s_trait("target", "temper", 0.6), s_trait("target", "empathy", -0.6), s_const(0.5)]),
        out("sorry", [say("target", "rv_sorry", to="actor", delay=1.8), say("actor", "rv_accept_sorry", to="target", delay=3.4),
                      plan("avenger", "revenge", "victim", v=False), bond("avenger", "victim", "feud", v=False), rel("actor", "target", "friendship", 6, both=True),
                      log("log.rv_truce", 3, "friendship", who=["victim", "avenger"]), arc_end("truce")],
            score=[s_trait("target", "empathy", 1.0), s_trait("target", "forgiveness", 0.6)]),
    ])

arc("revenge_plot", BIG, "brood", cooldown_days=4, stages={
    "brood": stage("rv_brood", "meet", actor="avenger", target="accomplice", area="kitchen", wait=(5, 20), ttl=60, fail="retry"),
    "prank": stage("rv_prank", "desk", actor="avenger", target="victim", ttl=90, fail="retry"),
    "discovery": stage("rv_discover", "now", actor="victim", ttl=200, fail="end:unnoticed"),
    "confront": stage("rv_confront", "visit", actor="victim", target="avenger", ttl=60, fail="end:simmering"),
})

# =====================================================================
# 14. FEUD & MEDIATION (started when an argument turns into "not speaking")
# =====================================================================
L("fm_cold_a", ["*takes the long way around {b}'s desk*", "I'm not sitting near {b}.", "Tell {b} I'm busy. Forever."])
L("fm_cold_b", ["Oh, is {a} pretending I don't exist? Fine. Two can play.", "*loudly ignores {a}*"])
T("log.fm_cold", "Day two of {a} and {b} not speaking. The office walks on eggshells around them. {mediator} has noticed.")
T("log.fm_cold_alone", "Day two of {a} and {b} not speaking. Nobody dares to get involved.")
scene("fm_cold", noise=0.9, conditions=[c_present("a")],
    roles=[by_fn("mediator", "mediator", a="a", b="b", optional=True, exclude=["a", "b"])],
    effects=[say("a", "fm_cold_a"), emote("a", "cloud"), say("b", "fm_cold_b", delay=2.0, when=[c_present("b")]), mood("a", -4), mood("b", -4)],
    outcomes=[
        out("mediator", [log("log.fm_cold", 3, "conflict", who=["a", "b"]), arc_next("talk_a", wait=(10, 40))], score=[s_const(1)], when=[c_filled("mediator")]),
        out("alone", [log("log.fm_cold_alone", 2, "conflict", who=["a", "b"]), arc_end("still_feuding")], score=[s_const(0.1)]),
    ])

L("fm_talk", ["You two can't keep doing this. It's making everyone miserable.", "Can we talk about you and {other}? Five minutes?", "Life's too short. Just talk to them."])
L("fm_open", ["...I know. I miss how it was.", "Fine. If they apologise, I'll listen.", "Maybe. I'm tired of this too."])
L("fm_stubborn", ["No. Not after what they did.", "Stay out of it. Please.", "They know what they did."])
T("log.fm_talk_ok", "{mediator} talked to {target} about the feud with {other}. {target} is softening.")
T("log.fm_talk_no", "{mediator} tried to talk {target} into making peace with {other}. {target} refused.")
for side, other in (("a", "b"), ("b", "a")):
    scene("fm_talk_" + side, noise=0.9, conditions=[c_avail("target")],
        effects=[hold(["actor", "target"], 5), {"e": "set", "key": "other", "who": other}, say("actor", "fm_talk", to="target")],
        outcomes=[
            out("open", [say("target", "fm_open", to="actor", delay=1.8), rel("target", "actor", "friendship", 6), log("log.fm_talk_ok", 2, "friendship", who=["mediator", side]),
                         arc_next("talk_b" if side == "a" else "summit", wait=(5, 25))],
                score=[s_trait("target", "forgiveness", 1.2), s_aff("target", "actor", 0.02), s_const(0.6)]),
            out("stubborn", [say("target", "fm_stubborn", to="actor", delay=1.8), log("log.fm_talk_no", 2, "conflict", who=["mediator", side]), arc_end("stubborn")],
                score=[s_trait("target", "forgiveness", -0.8), s_plan("target", "revenge", 0.8), s_const(0.3)]),
        ])

L("fm_summit_open", ["...Hi.", "So. Um.", "This is awkward."])
L("fm_summit_sorry", ["I'm sorry. I said things I didn't mean.", "I was out of line. I'm sorry.", "Can we just... start over?"])
L("fm_summit_yes", ["Me too. I'm sorry too.", "Yeah. Let's start over.", "Come here, you idiot."])
L("fm_summit_blowup", ["Sorry? THAT'S your apology?", "You haven't changed at all.", "Forget it."])
T("log.fm_reconciled", "{a} and {b} finally talked it out in the kitchen. They're friends again — thanks to {mediator}.")
T("log.fm_worse", "{mediator} got {a} and {b} in the same room. It went terribly. The feud is worse than ever.")
T("mem.fm_made_up", "{b} and I made up.")
scene("fm_summit", noise=0.9, conditions=[c_present("a"), c_present("b")],
    effects=[hold(["a", "b"], 6), say("a", "fm_summit_open", to="b"), say("a", "fm_summit_sorry", to="b", delay=1.6)],
    outcomes=[
        out("reconciled", [say("b", "fm_summit_yes", to="a", delay=3.2), emote("a", "love", delay=3.2), emote("b", "love", delay=3.2), expr("a", "happy", 6, delay=3.2),
                           expr("b", "happy", 6, delay=3.2), bond("a", "b", "feud", v=False), plan("a", "revenge", "b", v=False), plan("b", "revenge", "a", v=False),
                           rel("a", "b", "friendship", 25, both=True), rel("a", "b", "rivalry", -15, both=True), rel("a", "b", "trust", 12, both=True),
                           rel("a", "mediator", "friendship", 8), rel("b", "mediator", "friendship", 8),
                           mem("a", "b", "made_up", 0.7, 0.9, "mem.made_up", 3), mem("b", "a", "made_up", 0.7, 0.9, "mem.made_up", 3), stat("reconciliations"),
                           log("log.fm_reconciled", 4, "friendship", who=["a", "b"]), arc_end("reconciled")],
            score=[s_trait("b", "forgiveness", 1.2), s_trait("a", "forgiveness", 0.6), s_aff("b", "a", 0.01), s_const(1.4)]),
        out("worse", [say("b", "fm_summit_blowup", to="a", delay=3.2), expr("a", "angry", 6, delay=3.2), expr("b", "angry", 6, delay=3.2), sfx("argue", delay=3.2),
                      rel("a", "b", "friendship", -12, both=True), stat("arguments"), log("log.fm_worse", 4, "conflict", who=["a", "b"]), arc_end("worse")],
            score=[s_trait("b", "temper", 0.8), s_plan("b", "revenge", 0.5, target="a"), s_const(0.1)]),
    ])

arc("feud_mediation", BIG, "cold_day", cooldown_days=2, max_active=2, stages={
    "cold_day": stage("fm_cold", "now", actor="a", wait=(600, 700), ttl=300, window=("09:40", "16:30"), fail="end:faded"),
    "talk_a": stage("fm_talk_a", "visit", actor="mediator", target="a", ttl=80, fail="end:nobody_helped"),
    "talk_b": stage("fm_talk_b", "visit", actor="mediator", target="b", ttl=80, fail="end:half_way"),
    "summit": stage("fm_summit", "meet", actor="a", target="b", area="kitchen", ttl=80, fail="retry"),
})

# =====================================================================
# 15. BOSS VS EMPLOYEE
# =====================================================================
starter("start_boss_clash", "boss_clash", {"rebel": "actor", "boss": "@ahmet"},
        roles=[actor([c_is("self", "ahmet", neg=True), c_trait("self", "temper", gt=0.45), c_present("@ahmet"),
                      c_any(c_rel("self", "@ahmet", "trust", lt=20), c_mem("self", "scolded", about="@ahmet", days=2), c_mem("self", "boss_snapped", days=2),
                            c_mem("self", "overworked", days=2))],
                     [s_trait("self", "temper", 1.0), s_rel("self", "@ahmet", "trust", -0.02), s_stress("self", 0.01)])],
        cooldown_days=5)

L("bc_hover", ["Why is this taking so long?", "I'm going to stand here until it's done.", "Is that the font you're using? Really?"])
L("bc_tense", ["...It'll be done when it's done.", "I'm working as fast as I can.", "*types very, very loudly*"])
T("log.bc_hover", "Ahmet is hovering over {rebel}'s desk. Again. {rebel} is reaching boiling point.")
scene("bc_hover", noise=0.9, conditions=[c_present("rebel")],
    roles=[by_fn("ally", "best_of", of="rebel", lim=15, optional=True, exclude=["rebel", "boss"])],
    effects=[hold(["boss", "rebel"], 4.5), say("boss", "bc_hover", to="rebel"), say("rebel", "bc_tense", delay=1.8), stress("rebel", 12), expr("rebel", "angry", 4, delay=1.8),
             log("log.bc_hover", 2, "boss", who=["boss", "rebel"])],
    outcomes=[
        out("ally", [arc_next("vent", wait=(10, 30))], score=[s_const(1)], when=[c_filled("ally")]),
        out("alone", [arc_next("clash", wait=(15, 40))], score=[s_const(0.2)]),
    ])

L("bc_vent", ["If he hovers over my desk ONE more time...", "I swear I'm going to say something today.", "I can't work like this. I'm going to tell him."])
L("bc_egg", ["Do it. Someone has to.", "Tell him! We've all been thinking it.", "I've got your back."])
L("bc_calm", ["Don't. Not today. He's in a mood.", "Pick your battles. This isn't the one.", "Breathe. Coffee first."])
T("log.bc_vent_egg", "{rebel} vented to {ally} about Ahmet. {ally} told them to stand up to him.")
T("log.bc_vent_calm", "{rebel} vented to {ally} about Ahmet. {ally} talked them down.")
scene("bc_vent", noise=0.9, conditions=[c_present("rebel"), c_present("ally")],
    effects=[hold(["rebel", "ally"], 5), say("rebel", "bc_vent", to="ally")],
    outcomes=[
        out("egg", [say("ally", "bc_egg", to="rebel", delay=1.8), rel("rebel", "ally", "trust", 6), log("log.bc_vent_egg", 3, "boss", who=["rebel", "ally"]),
                    arc_next("clash", wait=(10, 35))], score=[s_trait("ally", "temper", 0.8), s_rel("ally", "boss", "trust", -0.02), s_const(0.8)]),
        out("calm", [say("ally", "bc_calm", to="rebel", delay=1.8), stress("rebel", -8), log("log.bc_vent_calm", 2, "friendship", who=["ally", "rebel"]), arc_end("calmed")],
            score=[s_trait("ally", "empathy", 0.7), s_goal("ally", "keep_peace", 0.6)]),
    ])

L("bc_clash", ["With respect, Ahmet Bey — I can't work with you breathing down my neck!", "Enough! Either trust me to do my job or do it yourself!",
               "You hover, you nag, you never say thank you. I'm done pretending that's fine."])
L("bc_boss_reply", ["EXCUSE me?", "How DARE you talk to me like that!", "In front of everyone? Really?"])
L("bc_gasp", ["Oh no.", "Did they just...", "*gasp*", "Popcorn. Someone get popcorn."])
T("log.bc_clash", "{rebel} stood up and told Ahmet off in front of the whole office. Everyone froze.")
scene("bc_clash", noise=0.9, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 6), expr("target", "angry", 8), emote("target", "anger"), say("target", "bc_clash", to="actor"),
             say("actor", "bc_boss_reply", to="target", delay=1.8), expr("actor", "angry", 8, delay=1.8), sfx("argue", delay=1.8),
             witness([say("self", "bc_gasp", p=0.5, delay=2.6), emote("self", "exclaim", delay=2.4)], near="target", r=7, exclude=["actor", "target"]),
             rel("target", "actor", "trust", -10), rel("actor", "target", "trust", -12), stat("arguments"), log("log.bc_clash", 4, "boss", who=["rebel", "boss"])],
    outcomes=[
        out("sides", [arc_next("sides", wait=(1, 3))], score=[s_const(1)], when=[c_filled("ally"), c_present("ally")]),
        out("alone", [arc_next("aftermath", wait=(10, 30))], score=[s_const(0.3)]),
    ])

L("bc_side", ["They're right, actually.", "Ahmet Bey, we all feel the same way.", "For what it's worth — I agree."])
L("bc_boss_isolated", ["...Is that so.", "Everyone? Really?", "Hm."])
T("log.bc_sides", "{ally} backed {rebel} up in front of Ahmet. A few others nodded. Ahmet looks shaken.")
scene("bc_sides", allow_absent=True, conditions=[c_present("ally"), c_present("boss")],
    effects=[say("ally", "bc_side", to="boss"), emote("ally", "exclaim"), say("boss", "bc_boss_isolated", delay=1.8), expr("boss", "surprised", 5, delay=1.8),
             stress("boss", 15), favor("ally", -4), rel("rebel", "ally", "friendship", 15), rel("rebel", "ally", "trust", 12),
             mem("rebel", "ally", "defended_me", 0.8, 0.9, "mem.shielded", 3), log("log.bc_sides", 4, "boss", who=["ally", "rebel"]), arc_next("aftermath", wait=(15, 40))])

L("bc_after_open", ["My office. Now.", "About earlier..."])
L("bc_boss_sorry", ["...Maybe I've been a bit much. I'll back off.", "I hear you. I'll try. That's all I'll say.", "Fine. I'll stop hovering. Mostly."])
L("bc_boss_warning", ["That was your final warning. Next time, HR.", "Talk to me like that again and you're out.", "Consider this a formal warning."])
T("log.bc_truce", "Behind closed doors, Ahmet admitted he'd been too much. {rebel} walked out smiling.")
T("log.bc_warning", "Behind closed doors, Ahmet gave {rebel} a final warning. {rebel} walked out pale.")
T("mem.bc_warning", "Ahmet gave me a final warning.")
T("mem.bc_truce", "Ahmet actually listened to me.")
scene("bc_aftermath", noise=0.9, conditions=[c_present("rebel"), c_present("boss")],
    effects=[hold(["rebel", "boss"], 6), say("boss", "bc_after_open", to="rebel")],
    outcomes=[
        out("truce", [say("boss", "bc_boss_sorry", to="rebel", delay=1.8), morale("rebel", 12), rel("rebel", "boss", "trust", 10), mem("rebel", "boss", "recognized", 0.6, 0.8, "mem.bc_truce", 3),
                      log("log.bc_truce", 4, "boss", who=["boss", "rebel"]), arc_end("truce")],
            score=[s_rel("boss", "rebel", "trust", 0.015), s_mood("boss", 0.01), s_const(1.0)]),
        out("warning", [say("boss", "bc_boss_warning", to="rebel", delay=1.8), expr("rebel", "sad", 6, delay=1.8), morale("rebel", -15), favor("rebel", -10),
                        plan("rebel", "job_search", "", heat=1.2), mem("rebel", "boss", "humiliated", -0.7, 0.9, "mem.bc_warning", 3),
                        log("log.bc_warning", 4, "boss", who=["boss", "rebel"]), arc_end("warning")],
            score=[s_trait("boss", "temper", 0.8), s_stress("boss", 0.012)]),
    ])

arc("boss_clash", BIG, "micromanage", cooldown_days=5, stages={
    "micromanage": stage("bc_hover", "desk", actor="boss", target="rebel", wait=(5, 20), ttl=60, fail="retry"),
    "vent": stage("bc_vent", "meet", actor="rebel", target="ally", area="kitchen", ttl=60, fail="clash"),
    "clash": stage("bc_clash", "visit", actor="boss", target="rebel", ttl=90, fail="aftermath"),
    "sides": stage("bc_sides", "now", actor="ally", ttl=20, fail="aftermath"),
    "aftermath": stage("bc_aftermath", "meet", actor="rebel", target="boss", area="boss", ttl=120, fail="retry"),
})

# =====================================================================
# 16. THE BOSS'S NIECE
# =====================================================================
starter("start_niece", "niece_secret", {"niece": "actor", "boss": "@ahmet"},
        roles=[actor([c_is("self", "ece"), {"c": "fact_exists", "fact": "ece_relative"}, c_present("@ahmet")], [s_const(0.5)])],
        conditions=[{"c": "flag", "key": "niece_out", "not": True}], cooldown_days=8)

L("ns_slip", ["Uncle— I mean, Ahmet Bey! Here's the file!", "Amca, the— AHMET BEY. Sorry. The report.", "Here you go, Uncle Ahm— Mr. Ahmet. Sir."])
L("ns_boss_cough", ["*cough* Thank you, ECE.", "...Yes. Thank you. Intern.", "*very loud cough*"])
L("ns_witness", ["...Uncle?!", "Did she just say UNCLE?", "Oh-ho-ho."])
T("log.ns_slip", "Ece accidentally called Ahmet \"Uncle\". {witness} heard it.")
T("log.ns_slip_safe", "Ece accidentally called Ahmet \"Uncle\". Luckily, nobody was close enough to hear.")
scene("ns_slip", noise=0.9, conditions=[c_avail("target")],
    roles=[role("witness", where=[c_avail("self")], score=[s_trait("self", "curiosity", 1.0), s_trait("self", "gossip", 0.8)], near="niece", r=6.0,
                optional=True, exclude=["niece", "boss", "@ceren"])],
    effects=[hold(["niece", "boss"], 4), say("niece", "ns_slip", to="boss"), say("boss", "ns_boss_cough", delay=1.6), emote("niece", "sweat", delay=1.0)],
    outcomes=[
        out("heard", [say("witness", "ns_witness", delay=2.6), emote("witness", "exclaim", delay=2.6),
                      rumor("nepotism_hint", a="niece", b="boss", juicy=0.8, knowers=["witness"], c=0.5), log("log.ns_slip", 3, "secret", who=["niece", "witness"]),
                      arc_next("probe", wait=(10, 40))], score=[s_const(2)], when=[c_filled("witness")]),
        out("safe", [log("log.ns_slip_safe", 2, "secret", who=["niece"]), arc_end("unnoticed")], score=[s_const(1)]),
    ])

L("ns_probe", ["So... \"Uncle Ahmet\"? Want to explain?", "Ece, sweetie. Uncle? Really?", "Is there something you'd like to tell me about you and Ahmet?"])
L("ns_lie", ["It's a... Turkish thing! We call all bosses uncle!", "Uncle? I said \"ankle\"! I hurt my ankle!", "I didn't say uncle. Did I? No."])
L("ns_truth", ["...Okay. He's my uncle. Please, PLEASE don't tell anyone.", "Fine. Yes. My mum's brother. I wanted to make it on my own."])
L("ns_promise", ["My lips are sealed. Mostly.", "Your secret's safe with me.", "Aww. Of course I won't tell."])
T("log.ns_lie", "{witness} asked Ece about the \"Uncle\" slip. Ece told a terrible lie about ankles.")
T("log.ns_truth", "{witness} asked Ece about the \"Uncle\" slip. Ece confessed: Ahmet is her uncle.")
scene("ns_probe", noise=0.9, conditions=[c_present("witness"), c_present("niece")],
    effects=[hold(["witness", "niece"], 5), emote("witness", "whisper"), say("witness", "ns_probe", to="niece")],
    outcomes=[
        out("lie", [say("niece", "ns_lie", to="witness", delay=1.8), emote("niece", "sweat", delay=1.8), log("log.ns_lie", 3, "secret", who=["witness", "niece"]),
                    arc_next("verify", wait=(10, 30))],
            score=[s_const(0.8), s_goal("niece", "be_liked", 0.3)]),
        out("truth", [say("niece", "ns_truth", to="witness", delay=1.8), learn("witness", "ece_relative", c=1.0), reveal("ece_relative"),
                      say("witness", "ns_promise", to="niece", delay=3.4), rel("niece", "witness", "trust", 8), log("log.ns_truth", 4, "secret", who=["witness", "niece"]),
                      arc_next("spread", wait=(15, 50))],
            score=[s_trait("niece", "honesty", 0.8), s_aff("niece", "witness", 0.01)]),
    ])

L("ns_verify", ["Ceren, you know everything. Is Ece related to Ahmet?", "Quick question, totally innocent: is Ece Ahmet's niece?"])
L("ns_keeper_no", ["Not my place to say.", "I don't discuss people's families. Sorry.", "Ask Ece. Or better: don't."])
L("ns_keeper_slip", ["...Who told you? — I mean. No comment.", "I... can't confirm that. Which is not a no."])
T("log.ns_stonewalled", "{witness} tried to get Ceren to confirm the Ece-Ahmet rumour. Ceren gave nothing away.")
T("log.ns_keeper_slip", "{witness} pressed Ceren about Ece and Ahmet. Ceren's \"no comment\" said everything.")
scene("ns_verify", noise=0.9, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), say("actor", "ns_verify", to="target")],
    outcomes=[
        out("stonewall", [say("target", "ns_keeper_no", to="actor", delay=1.8), rel("actor", "target", "trust", -3), log("log.ns_stonewalled", 2, "secret", who=["witness"]),
                          arc_end("stonewalled")], score=[s_trait("target", "honesty", 0.6), s_trait("target", "cunning", 0.6), s_const(0.4)]),
        out("slip", [say("target", "ns_keeper_slip", to="actor", delay=1.8), emote("target", "sweat", delay=1.8), learn("actor", "ece_relative", c=0.9), reveal("ece_relative"),
                     log("log.ns_keeper_slip", 3, "secret", who=["witness", "keeper"]), arc_next("spread", wait=(10, 40))],
            score=[s_trait("actor", "cunning", 0.6), s_const(0.8)]),
    ])

L("ns_spread", ["You won't BELIEVE this. Ece is Ahmet's NIECE.", "Remember how Ece got the internship with no interview? Guess why. Uncle Ahmet.",
                "Nepotism alert. Ece. Ahmet. Family."])
L("ns_spread_react", ["THAT explains so much.", "Seriously?! Unbelievable.", "I KNEW she was getting special treatment."], ceren=["...I really wish you hadn't told me that."])
T("log.ns_spread", "{witness} told {listener} that Ece is Ahmet's niece. By tomorrow, everyone will know.")
scene("ns_spread_scene", conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), emote("actor", "whisper"), say("actor", "ns_spread", to="target"), say("target", "ns_spread_react", to="actor", delay=1.8),
             learn("target", "ece_relative", frm="actor"), stat("rumors"), log("log.ns_spread", 4, "secret", who=["witness", "listener"])])
scene("ns_spread", conditions=[c_avail("witness")],
    roles=[role("listener", where=[c_avail("self"), c_knows("self", "ece_relative", neg=True)], score=[s_rel("self", "niece", "rivalry", 0.02), s_trait("self", "ambition", 0.6),
                                                                                                     s_trait("self", "gossip", 0.4)],
                exclude=["witness", "niece", "boss"], optional=True)],
    effects=[visit("witness", "listener", "ns_spread_scene", prio=58, ttl=40, when=[c_filled("listener")], roles={"witness": "witness", "listener": "listener"}),
             flag("niece_out", True), arc_next("reckoning", days=1)])

L("ns_reckon", ["I know what everyone's saying. Yes, Ahmet is my uncle. And I'm going to work twice as hard to prove I belong here.",
                "Okay. Everyone knows. He's my uncle. I never asked for special treatment. Judge me by my work."])
L("ns_support", ["Fair enough. You've always pulled your weight.", "Honestly? You're the hardest worker here.", "Respect, Ece."])
L("ns_cold", ["Easy to say when your uncle signs your evaluation.", "Mm-hm.", "Sure."], deniz=["Family business, is it?"])
T("log.ns_accepted", "Ece faced the office about being Ahmet's niece. Most of them decided she'd earned her place.")
T("log.ns_resented", "Ece faced the office about being Ahmet's niece. The room stayed cold.")
scene("ns_reckoning", noise=0.9, conditions=[c_avail("niece")],
    effects=[say("niece", "ns_reckon"), expr("niece", "sad", 4), reveal("ece_relative"),
             each([learn("self", "ece_relative", c=1.0)], exclude=["niece"])],
    outcomes=[
        out("accepted", [each([say("self", "ns_support", p=0.4, delay=1.6), rel("self", "niece", "trust", 6)], exclude=["niece", "boss"], stagger=0.5,
                              where=[c_aff("self", "niece", gt=10)]),
                         emote("niece", "love", delay=3.0), morale("niece", 6), log("log.ns_accepted", 4, "secret", who=["niece"]), arc_end("accepted")],
            score=[s_trait("niece", "diligence", 1.0), s_trait("niece", "empathy", 0.6)]),
        out("resented", [each([say("self", "ns_cold", p=0.4, delay=1.6), rel("self", "niece", "trust", -4)], exclude=["niece", "boss"], stagger=0.5,
                              where=[c_aff("self", "niece", lt=25)]),
                         expr("niece", "sad", 8, delay=3.0), mood("niece", -20), morale("niece", -10), log("log.ns_resented", 4, "secret", who=["niece"]),
                         arc_end("resented")], score=[s_const(0.9)]),
    ])

arc("niece_secret", BIG, "slip", cooldown_days=10, stages={
    "slip": stage("ns_slip", "visit", actor="niece", target="boss", wait=(5, 20), ttl=60),
    "probe": stage("ns_probe", "meet", actor="witness", target="niece", area="kitchen", ttl=60, fail="verify"),
    "verify": stage("ns_verify", "visit", actor="witness", target="@ceren", ttl=60, fail="end:stalled"),
    "spread": stage("ns_spread", "now", actor="witness", ttl=90, fail="end:kept"),
    "reckoning": stage("ns_reckoning", "now", actor="niece", ttl=240, fail="end:blew_over"),
})
