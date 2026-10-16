# More story arcs (part 3): stories the office starts on its own.
# Each begins with one character's initiative (domain-tagged NPC action), runs
# 3-5 stages with branches, and can be nudged by the player along the way.
from story_helpers import *  # noqa: F401,F403
from story_helpers import arc, stage
import story_helpers as _sh
from iv_helpers import S_, L, oset  # noqa: F811  (guarded: never overwrite existing text)
from arcs_more1 import title, start, T, BIG


# =====================================================================
# 22. THE BREAK-UP
# =====================================================================
title("breakup", "The Break-up", "{a} and {b} are fighting. The whole office is pretending not to listen.")
L("bu_spark", ["You ALWAYS do this!", "It's not about the dishes. It's never about the dishes.", "Fine. FINE."])
L("bu_spark_back", ["Me?! You're the one who forgot!", "Oh, so it's MY fault now?", "Don't 'fine' me."])
L("bu_storm", ["I need some air.", "We'll talk later. Or not."])
L("bu_makeup", ["...Sorry. I'm just tired.", "Okay. I overreacted. Coffee?"])
T("log.bu_storm", "{a} and {b} had a whispered fight in the lounge. {b} stormed off. The office is officially worried.")
T("log.bu_makeup", "{a} and {b} had a small fight in the lounge — and made up two minutes later.")
start("start_breakup", "breakup", {"a": "actor", "b": "partner"},
      [actor([c_stress("self", gt=22)], [s_stress("self", 0.03), s_trait("self", "temper", 0.8)]), by_fn("partner", "partner_of", of="actor")], "romance", cooldown_days=8)
scene("bu_fight", noise=0.8, conditions=[c_present("a"), c_present("b")],
      effects=[hold(["a", "b"], 6), expr("a", "angry", 5), say("a", "bu_spark", to="b"), say("b", "bu_spark_back", to="a", delay=1.8), expr("b", "angry", 5, delay=1.8)],
      outcomes=[out("storm", [say("b", "bu_storm", delay=3.6), storm("b", delay=4.2), rel("a", "b", "resentment", 10, both=True), rel("a", "b", "romance", -8, both=True), stress("a", 8),
                              witness([emote("self", "sweat", delay=3.6)], near="a", r=5, exclude=["a", "b"]), log("log.bu_storm", 4, "romance", who=["a", "b"]),
                              arc_next("sides", wait=(10, 40))], score=[s_trait("b", "temper", 1.0), s_stress("b", 0.02), s_const(0.4)]),
                out("makeup", [say("a", "bu_makeup", to="b", delay=3.6), emote("b", "love", delay=4), log("log.bu_makeup", 2, "romance", who=["a", "b"]), arc_end("made_up")],
                    score=[s_trait("a", "forgiveness", 0.6), s_rel("a", "b", "romance", 0.005), s_const(0.1)])])
L("bu_side_a", ["Honestly? {b} has been impossible lately.", "I'm on your side. Always."])
L("bu_side_b", ["You should talk to {b}. Properly.", "Don't throw it away over nothing."])
T("log.bu_sides", "{confidant} talked to {a} about the fight with {b}. Friends are starting to take sides.")
scene("bu_sides", noise=0.8, allow_absent=True, conditions=[c_present("a")],
      roles=[by_fn("confidant", "best_of", of="a", lim=0, optional=True, exclude=["a", "b"])],
      effects=[emote("a", "cloud")],
      outcomes=[out("against", [say("confidant", "bu_side_a", to="a"), rel("confidant", "b", "friendship", -6), rel("a", "b", "resentment", 6),
                                log("log.bu_sides", 3, "romance", who=["confidant", "a"]), arc_next("talk", wait=(30, 90))],
                    score=[s_trait("confidant", "gossip", 0.8), s_aff("confidant", "b", -0.02)], when=[c_filled("confidant")]),
                out("for", [say("confidant", "bu_side_b", to="a"), rel("a", "b", "resentment", -6), log("log.bu_sides", 3, "romance", who=["confidant", "a"]),
                            arc_next("talk", wait=(20, 60))], score=[s_trait("confidant", "empathy", 1.0)], when=[c_filled("confidant")]),
                out("alone", [arc_next("talk", wait=(30, 90))], score=[s_const(0.05)])])
L("bu_talk", ["Can we talk? Really talk?", "About earlier..."])
L("bu_together", ["I don't want to lose you over something this stupid.", "Let's never fight in the lounge again. Deal?"])
L("bu_over", ["...I think we need a break. A real one.", "Maybe we're better as colleagues."])
T("log.bu_together", "{a} and {b} talked it out. Still together — and holding hands at the coffee machine, which is worse.")
T("log.bu_over", "{a} and {b} have broken up. The office will be awkward for a while.")
T("mem.bu_over", "We broke up.")
scene("bu_talk", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 6), say("actor", "bu_talk", to="target")],
      outcomes=[out("together", [say("target", "bu_together", to="actor", delay=1.8), emote("actor", "love", delay=1.8), rel("actor", "target", "romance", 10, both=True),
                                 rel("actor", "target", "resentment", -12, both=True), log("log.bu_together", 4, "romance"), arc_end("together")],
                    score=[s_rel("target", "actor", "romance", 0.03), s_trait("target", "forgiveness", 0.8)]),
                out("over", [say("target", "bu_over", to="actor", delay=1.8), expr("actor", "sad", 10, delay=1.8), bond("actor", "target", "romance", False), mood("actor", -20),
                             mood("target", -12), mem("actor", "target", "breakup", -0.6, 0.9, "mem.bu_over", 3), mem("target", "actor", "breakup", -0.5, 0.9, "mem.bu_over", 3),
                             rumor("argument", a="actor", b="target", juicy=0.7, knowers=[]), log("log.bu_over", 5, "romance"), arc_end("broke_up")],
                    score=[s_rel("target", "actor", "resentment", 0.04), s_const(0.3)])])
arc("breakup", BIG, "fight", cooldown_days=8, stages={
    "fight": stage("bu_fight", "meet", actor="a", target="b", area="lounge", wait=(3, 12), ttl=60, fail="end:avoided"),
    "sides": stage("bu_sides", "now", actor="a", ttl=90, fail="talk"),
    "talk": stage("bu_talk", "visit", actor="a", target="b", ttl=120, fail="end:cold"),
})


# =====================================================================
# 23. THE OFFICE KITTEN
# =====================================================================
title("office_pet", "The Office Kitten", "{smuggler} has smuggled a kitten into the office.")
L("pet_sneak", ["*whispering into a cardboard box* Shh. Shh. You're a stapler now.", "Nobody look in this box. It's... files. Very fluffy files."])
L("pet_mew", ["*mew*", "*tiny mew*"])
T("log.pet_sneak", "{smuggler} arrived with a suspicious cardboard box. The box is meowing.")
start("start_office_pet", "office_pet", {"smuggler": "actor", "boss": "@ahmet", "accomplice": "$acc"},
      [actor([c_trait("self", "empathy", gt=0.6), c_time(before="11:30"), c_is("self", "ahmet", neg=True)], [s_trait("self", "empathy", 1.0), s_trait("self", "humor", 0.5)])],
      "comedy", vars=[var("acc", "best_of", of="actor", lim=0)], conditions=[c_present("@ahmet"), c_chance(0.35)], cooldown_days=9)
scene("pet_sneak", noise=0.6, allow_absent=True, conditions=[c_present("smuggler")],
      effects=[emote("smuggler", "whisper"), say("smuggler", "pet_sneak"), say("smuggler", "pet_mew", delay=2), sfx("pop", delay=2),
               witness([emote("self", "question", delay=2.2)], near="smuggler", r=5, exclude=["smuggler"]), log("log.pet_sneak", 3, "secret", who=["smuggler"]),
               arc_next("hide", wait=(5, 20))])
L("pet_ask", ["I need you to hide a kitten in the archive. Don't ask questions.", "Okay, I found her in the car park. Help me hide her from Ahmet?"])
L("pet_yes", ["A KITTEN?! Give her to me. I'll guard her with my life.", "...Fine. But I'm naming her."])
L("pet_no", ["Absolutely not. I'm allergic to unemployment.", "No. Ahmet will kill us both."])
T("log.pet_hidden", "{smuggler} and {accomplice} hid a kitten in the archive. Several people now 'need files' every five minutes.")
T("log.pet_alone", "{accomplice} refused to help hide the kitten. {smuggler} is hiding it under their desk.")
scene("pet_hide", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), emote("actor", "whisper"), say("actor", "pet_ask", to="target")],
      outcomes=[out("yes", [say("target", "pet_yes", to="actor", delay=1.6), emote("target", "love", delay=1.6), rel("actor", "target", "friendship", 10, both=True),
                            bond("actor", "target", "alliance"), log("log.pet_hidden", 3, "secret"), arc_next("found", wait=(30, 90))],
                    score=[s_trait("target", "empathy", 1.0), s_aff("target", "actor", 0.02)]),
                out("no", [say("target", "pet_no", to="actor", delay=1.6), log("log.pet_alone", 2, "secret"), arc_next("found", wait=(20, 60))],
                    score=[s_trait("target", "diligence", 0.8), s_const(0.2)])])
L("pet_boss_hear", ["...Is something MEOWING in my office?", "Why is there a kitten on my keyboard?!"])
L("pet_melts", ["...Oh. Oh, look at her little face. Fine. She stays. She's the office manager now.", "Who's a good kitty? Not a word to HQ, anyone."])
L("pet_furious", ["Out. The kitten goes. TODAY. And {smuggler}: my office. Now.", "This is an office, not a zoo!"])
T("log.pet_melts", "Ahmet found the kitten. He melted. The office has a new mascot.")
T("log.pet_furious", "Ahmet found the kitten and exploded. The kitten went to {smuggler}'s neighbour. {smuggler} got a lecture.")
T("mem.pet_melts", "Ahmet let us keep the office kitten.")
scene("pet_found", noise=0.6, allow_absent=True, conditions=[c_present("boss")],
      effects=[say("boss", "pet_boss_hear"), emote("boss", "exclaim")],
      outcomes=[out("melts", [say("boss", "pet_melts", delay=2.4), emote("boss", "love", delay=2.4), each([mood("self", 12), morale("self", 4), stress("self", -6),
                              mem("self", "boss", "kitten", 0.5, 0.6, "mem.pet_melts", 2)], exclude=["boss"]), rel("smuggler", "boss", "friendship", 10),
                              log("log.pet_melts", 4, "celebration", who=["smuggler"]), arc_end("mascot")],
                    score=[s_trait("boss", "empathy", 1.2), s_mood("boss", 0.02)]),
                out("furious", [say("boss", "pet_furious", delay=2.4), expr("boss", "angry", 6, delay=2.4), favor("smuggler", -8), mood("smuggler", -12),
                                call("scold", target="smuggler", reason="general", prio=66, delay=5), log("log.pet_furious", 4, "boss", who=["smuggler"]), arc_end("banished")],
                    score=[s_trait("boss", "temper", 1.0), s_stress("boss", 0.01)])])
arc("office_pet", BIG, "sneak", cooldown_days=9, stages={
    "sneak": stage("pet_sneak", "now", actor="smuggler", wait=(2, 8), ttl=60),
    "hide": stage("pet_hide", "visit", actor="smuggler", target="accomplice", ttl=70, fail="found"),
    "found": stage("pet_found", "now", actor="boss", ttl=240, fail="end:never_found"),
})


# =====================================================================
# 24. THE PRANK WAR
# =====================================================================
title("prank_war", "The Prank War", "{p1} pranked {p2}. {p2} will not let this go.")
L("pw_first", ["*wraps {p2}'s whole desk in cling film* Perfect.", "*replaces {p2}'s mouse with a potato* Art."])
T("log.pw_first", "{p1} pranked {p2}'s desk. The prank war has begun.")
start("start_prank_war", "prank_war", {"p1": "actor", "p2": "p2", "boss": "@ahmet"},
      [actor([c_trait("self", "humor", gt=0.6), c_is("self", "ahmet", neg=True)], [s_trait("self", "humor", 1.0), s_mood("self", 0.01)]),
       by_fn("p2", "best_of", of="actor", lim=10, exclude=["actor", "@ahmet"])], "comedy", conditions=[c_present("@ahmet"), c_chance(0.5)], cooldown_days=7)
scene("pw_first", noise=0.6, allow_absent=True, conditions=[c_present("p1")],
      effects=[emote("p1", "whisper"), say("p1", "pw_first"), npcflag("p2", "pranked"), log("log.pw_first", 3, "prank", who=["p1", "p2"]), arc_next("revenge", wait=(20, 60))])
L("pw_found", ["...CLING FILM?! Oh, it's ON, {p1}.", "A POTATO. You'll pay for this, {p1}."])
L("pw_revenge", ["*fills {p1}'s drawer with 300 sticky notes* Phase one complete.", "*sets {p1}'s keyboard to Turkish-F layout* Mwahaha."])
T("log.pw_revenge", "{p2} struck back at {p1} with a bigger prank. Nobody's desk is safe.")
scene("pw_revenge", noise=0.6, allow_absent=True, conditions=[c_present("p2")],
      effects=[say("p2", "pw_found"), expr("p2", "angry", 4), say("p2", "pw_revenge", delay=2), emote("p2", "idea", delay=2), rel("p2", "p1", "rivalry", 6),
               log("log.pw_revenge", 3, "prank", who=["p2", "p1"]), arc_next("finale", wait=(30, 90))])
L("pw_ultimate", ["The ultimate prank. Bucket of confetti. Over the door. When {p2} walks in...", "*balances a bucket of confetti on the boss-office door* ...Wait, wrong door."])
L("pw_boss_hit", ["*covered in confetti* ...WHO. DID. THIS.", "*spits out confetti* I am going to count to three."])
L("pw_boss_laughs", ["...Ha. HA. Okay, that's actually good. Both of you, back to work.", "I haven't laughed like that in years. Don't tell anyone."])
L("pw_boss_rage", ["{p1}! {p2}! My office! NOW!", "This ends TODAY. Both of you. Written warning."])
T("log.pw_laugh", "{p1}'s ultimate prank hit Ahmet instead of {p2}. Ahmet... laughed. The prank war ends as office legend.")
T("log.pw_rage", "{p1}'s ultimate prank hit Ahmet instead of {p2}. Both pranksters got a written warning.")
scene("pw_finale", noise=0.6, allow_absent=True, conditions=[c_present("p1"), c_present("boss")],
      effects=[say("p1", "pw_ultimate"), sfx("thump", delay=2.4), fx("shake", "boss", delay=2.4), expr("boss", "surprised", 4, delay=2.4), say("boss", "pw_boss_hit", delay=3)],
      outcomes=[out("laugh", [say("boss", "pw_boss_laughs", delay=5), emote("boss", "cheer", delay=5), rel("boss", "p1", "friendship", 8), rel("p1", "p2", "rivalry", -10, both=True),
                              rel("p1", "p2", "friendship", 10, both=True), log("log.pw_laugh", 5, "prank", who=["p1", "p2"]), arc_end("legend")],
                    score=[s_trait("boss", "humor", 1.4), s_mood("boss", 0.02)]),
                out("rage", [say("boss", "pw_boss_rage", delay=5), expr("boss", "angry", 8, delay=5), favor("p1", -12), favor("p2", -8), stat("scoldings"),
                             log("log.pw_rage", 5, "boss", who=["p1", "p2"]), arc_end("warned")], score=[s_trait("boss", "temper", 1.0), s_stress("boss", 0.01)])])
arc("prank_war", BIG, "first", cooldown_days=7, stages={
    "first": stage("pw_first", "desk", actor="p1", target="p2", wait=(3, 12), ttl=60),
    "revenge": stage("pw_revenge", "desk", actor="p2", target="p1", ttl=120, fail="finale"),
    "finale": stage("pw_finale", "place", actor="p1", place="boss_front", ttl=120, window=("10:00", "16:30"), fail="end:ceasefire"),
})


# =====================================================================
# 25. THE NOISE WAR
# =====================================================================
title("noise_war", "The Noise War", "{quiet} can't concentrate. {loud} can't stop talking.")
L("nw_ask", ["Could you PLEASE keep it down? Some of us are working.", "Sorry — could you be a bit quieter? I'm on a deadline."])
L("nw_sorry", ["Oh! Sorry. Didn't realise. I'll whisper.", "My bad. Inside voice. Got it."])
L("nw_louder", ["It's an OPEN-PLAN office. It's called COMMUNICATION.", "Buy headphones."])
T("log.nw_sorry", "{quiet} asked {loud} to keep it down. {loud} apologised. Peace, for now.")
T("log.nw_louder", "{quiet} asked {loud} to keep it down. {loud} got louder. The noise war is on.")
start("start_noise_war", "noise_war", {"quiet": "actor", "loud": "loud"},
      [actor([c_trait("self", "sociability", lt=0.5), c_stress("self", gt=18)], [s_trait("self", "diligence", 0.8), s_stress("self", 0.02)]),
       role("loud", where=[c_present("self"), c_trait("self", "sociability", gt=0.65), c_is("self", "ahmet", neg=True)], score=[s_trait("self", "sociability", 1.0), s_rand(0.3)])],
      "arguments", cooldown_days=6)
scene("nw_ask", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "nw_ask", to="target")],
      outcomes=[out("sorry", [say("target", "nw_sorry", to="actor", delay=1.6), rel("actor", "target", "respect", 4), log("log.nw_sorry", 2, "conflict"), arc_end("quiet")],
                    score=[s_trait("target", "empathy", 0.8), s_aff("target", "actor", 0.01)]),
                out("louder", [say("target", "nw_louder", to="actor", delay=1.6), expr("actor", "angry", 5, delay=1.6), rel("actor", "target", "resentment", 10),
                               log("log.nw_louder", 3, "conflict"), arc_next("music", wait=(10, 40))],
                    score=[s_trait("target", "temper", 0.8), s_trait("target", "sociability", 0.6), s_const(0.3)])])
L("nw_music", ["Oh, you want noise? *turns the office speaker up* ENJOY.", "Fine. If I can't have quiet, NOBODY can. *cranks the music*"])
L("nw_annoyed", ["Who put on THIS music?!", "My ears!", "Can someone turn that off?"])
T("log.nw_music", "{loud} cranked the office speaker to win the noise war. Everyone else lost.")
scene("nw_music", noise=0.6, allow_absent=True, conditions=[c_present("loud")],
      effects=[say("loud", "nw_music"), oset("music.genre", "arabesk"), sfx("crowd", delay=1),
               each([say("self", "nw_annoyed", p=0.5, delay=1.6), stress("self", 6)], exclude=["loud"], stagger=0.6, where=[c_near("self", "loud", 9)]),
               log("log.nw_music", 3, "conflict", who=["loud"]), arc_next("showdown", wait=(10, 30))])
L("nw_showdown", ["Enough. This ends now. Kitchen. Both of you.", "You two are driving everyone mad. Sit. Talk."])
L("nw_truce", ["...Headphones for me, quiet hours for you?", "Fine. Music only after four. Deal."])
L("nw_war", ["Never. I'll bring a TRUMPET tomorrow.", "Not until they apologise for the arabesk."])
T("log.nw_truce", "{mediator} sat {quiet} and {loud} down in the kitchen. Quiet hours agreed. The noise war is over.")
T("log.nw_war", "{mediator} tried to end the noise war. {loud} threatened to bring a trumpet. It's a feud now.")
scene("nw_showdown", noise=0.9,
      roles=[by_fn("mediator", "mediator", a="quiet", b="loud", optional=True, exclude=["quiet", "loud"])],
      effects=[say("mediator", "nw_showdown", when=[c_filled("mediator")]), oset("music.genre", "")],
      outcomes=[out("truce", [say("loud", "nw_truce", delay=1.8), say("quiet", "nw_truce", delay=3.2), rel("quiet", "loud", "resentment", -12, both=True), stat("reconciliations"),
                              log("log.nw_truce", 3, "friendship"), arc_end("truce")], score=[s_trait("loud", "empathy", 0.8), s_trait("quiet", "forgiveness", 0.8), s_const(0.3)]),
                out("war", [say("loud", "nw_war", delay=1.8), bond("quiet", "loud", "feud"), stat("arguments"), storm("quiet", delay=3), log("log.nw_war", 4, "conflict"), arc_end("feud")],
                    score=[s_trait("loud", "temper", 0.8), s_trait("quiet", "temper", 0.6)])])
arc("noise_war", BIG, "ask", cooldown_days=6, stages={
    "ask": stage("nw_ask", "visit", actor="quiet", target="loud", wait=(2, 8), ttl=60, fail="end:suffered_quietly"),
    "music": stage("nw_music", "now", actor="loud", ttl=90, fail="showdown"),
    "showdown": stage("nw_showdown", "meet", actor="quiet", target="loud", area="kitchen", ttl=90, fail="end:simmering"),
})


# =====================================================================
# 26. THE PITCH BATTLE
# =====================================================================
title("pitch_battle", "The Pitch Battle", "{a} and {b} each think they have the better idea. Ahmet will decide.")
L("pb_challenge", ["Ahmet wants new ideas by four. Mine's better than yours. Want to bet?", "Pitch-off. You and me. Ahmet's office. Four o'clock."])
L("pb_accept", ["You're on.", "Oh, it is SO on.", "Prepare to lose."])
T("log.pb_challenge", "{a} challenged {b} to a pitch battle in front of Ahmet. {b} accepted.")
start("start_pitch_battle", "pitch_battle", {"a": "actor", "b": "b", "boss": "@ahmet"},
      [actor([c_trait("self", "ambition", gt=0.6), c_time(before="13:30"), c_is("self", "ahmet", neg=True)], [s_trait("self", "ambition", 1.0)]),
       by_fn("b", "rival_of", of="actor", lim=15)], "work_career", conditions=[c_present("@ahmet")], cooldown_days=6)
scene("pb_challenge", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "pb_challenge", to="target"), say("target", "pb_accept", to="actor", delay=1.6), rel("actor", "target", "rivalry", 6, both=True),
               log("log.pb_challenge", 3, "work"), arc_next("prep", wait=(10, 30))])
L("pb_prep", ["*typing furiously* Slide nine needs more synergy.", "Okay. Graphs. Big ones. Ahmet loves big graphs."])
T("log.pb_prep", "{a} and {b} are both furiously preparing their pitches. Nobody dares to interrupt.")
scene("pb_prep", noise=0.6, allow_absent=True, conditions=[c_present("a")],
      effects=[say("a", "pb_prep"), work("a", 10), work("b", 10), stress("a", 6), stress("b", 6), emote("a", "idea"), emote("b", "sweat"),
               log("log.pb_prep", 2, "work", who=["a", "b"]), arc_next("pitch", wait=(20, 60))])
L("pb_present", ["Picture this: everything, but faster.", "My idea will save us thirty percent. Possibly forty."])
L("pb_win_a", ["{a}'s idea. Go with it. {b}, good effort.", "I'm going with {a}. Congratulations."])
L("pb_win_b", ["{b}, that's the one. {a}, back to the drawing board.", "{b} wins. That was sharp."])
L("pb_both", ["Why not both? {a} and {b}: you're a team now. Don't kill each other.", "Combine them. Together. Today."])
T("log.pb_a", "Ahmet picked {a}'s idea in the pitch battle. {b} is taking it badly.")
T("log.pb_b", "Ahmet picked {b}'s idea in the pitch battle. {a} lost their own challenge.")
T("log.pb_both", "Ahmet liked both pitches and told {a} and {b} to work together. Neither looks pleased.")
scene("pb_pitch", noise=0.8,
      effects=[say("a", "pb_present"), say("b", "pb_present", delay=2.4)],
      outcomes=[out("a", [say("boss", "pb_win_a", delay=4.6), favor("a", 10), favor("b", -4), emote("a", "cheer", delay=4.6), rel("b", "a", "resentment", 10), storm("b", delay=6),
                          log("log.pb_a", 4, "work", who=["a", "b"]), arc_end("a_wins")], score=[s_trait("a", "diligence", 0.8), {"s": "favor", "who": "a", "w": 0.02}]),
                out("b", [say("boss", "pb_win_b", delay=4.6), favor("b", 10), favor("a", -6), emote("b", "cheer", delay=4.6), mood("a", -10), storm("a", delay=6),
                          log("log.pb_b", 4, "work", who=["a", "b"]), arc_end("b_wins")], score=[s_trait("b", "diligence", 0.8), {"s": "favor", "who": "b", "w": 0.02}]),
                out("both", [say("boss", "pb_both", delay=4.6), rel("a", "b", "rivalry", -6, both=True), bond("a", "b", "alliance"), log("log.pb_both", 4, "work", who=["a", "b"]),
                             arc_end("merged")], score=[s_trait("boss", "empathy", 0.8), s_const(0.3)])])
arc("pitch_battle", BIG, "challenge", cooldown_days=6, stages={
    "challenge": stage("pb_challenge", "visit", actor="a", target="b", wait=(3, 10), ttl=60, fail="end:backed_down"),
    "prep": stage("pb_prep", "now", actor="a", ttl=90, fail="pitch"),
    "pitch": stage("pb_pitch", "gather", actor="a", area="boss", need=3, ttl=60, window=("14:30", "16:50"), fail="end:no_show", who=["a", "b", "boss"], must=["a", "b", "boss"]),
})


# =====================================================================
# 27. KARAOKE AFTER WORK
# =====================================================================
title("karaoke_night", "Karaoke After Work", "{host} is organising karaoke. {shy} has a secret.")
L("kn_invite", ["KARAOKE! Kitchen! After five! Bring your voice!", "Tonight: office karaoke. Attendance is mandatory. Joking. Mostly."])
T("log.kn_invite", "{host} announced karaoke in the kitchen after work.")
start("start_karaoke", "karaoke_night", {"host": "actor", "shy": "$shy"},
      [actor([c_trait("self", "sociability", gt=0.7), c_time(after="10:30", before="14:00")], [s_trait("self", "sociability", 1.0), s_mood("self", 0.02)])],
      "socializing", vars=[var("shy", "most_curious", **{"not": "actor"})], conditions=[{"c": "picks", "fn": "good_vibes", "lim": -5}], cooldown_days=8)
scene("kn_invite", noise=0.6, allow_absent=True, conditions=[c_present("host")],
      effects=[say("host", "kn_invite"), emote("host", "cheer"), each([emote("self", "question", delay=1.2)], exclude=["host"], where=[c_near("self", "host", 8)]),
               log("log.kn_invite", 3, "celebration", who=["host"]), arc_next("rehearse", wait=(20, 60))])
L("kn_rehearse", ["*very quietly, in the archive* ♪ ...and my heart goes boom-boom for youuu... ♪", "*humming scales behind the filing cabinet*"])
L("kn_overheard", ["...Was that {shy}? Singing? Like THAT?", "Wait. {shy} can SING?"])
T("log.kn_rehearse", "{shy} was caught rehearsing for karaoke in the archive. Turns out {shy} can really sing.")
scene("kn_rehearse", noise=0.6, allow_absent=True, conditions=[c_present("shy")],
      effects=[say("shy", "kn_rehearse"), witness([say("self", "kn_overheard", p=0.7, delay=2), emote("self", "exclaim", delay=2), rel("self", "shy", "respect", 6)], near="shy", r=6,
                                                   exclude=["shy"]),
               log("log.kn_rehearse", 3, "secret", who=["shy"]), arc_next("night", wait=(30, 90))])
L("kn_sing", ["♪ PRINTER, PRINTER, PRINT MY HEAAART ♪", "♪ Monday, oh Monday, why do you hate meee? ♪", "♪ Ofisin yıldızııı, kahvenin kraliçesiii ♪"])
L("kn_star", ["...WOW. Encore! ENCORE!", "{shy}, where have you been hiding THAT?"])
L("kn_flop", ["*cracks on the high note* ...I'm fine. Totally fine.", "*sings the wrong song entirely*"])
T("log.kn_star", "Office karaoke: quiet {shy} brought the house down. Standing ovation in the kitchen.")
T("log.kn_flop", "Office karaoke: {host} cracked on the high note in front of everyone. It will be remembered.")
T("mem.kn_star", "Karaoke night in the kitchen was amazing.")
scene("kn_night", noise=0.8,
      effects=[say("host", "kn_sing"), sfx("crowd", delay=1), each([mood("self", 8), stress("self", -6)], where=[c_zone("self", ["kitchen"])])],
      outcomes=[out("star", [say("shy", "kn_sing", delay=2.4), each([say("self", "kn_star", p=0.5, delay=4), emote("self", "cheer", delay=4), rel("self", "shy", "friendship", 6),
                                                                      mem("self", "shy", "karaoke", 0.5, 0.6, "mem.kn_star", 2)], exclude=["shy"], where=[c_zone("self", ["kitchen"])]),
                             mood("shy", 20), morale("shy", 6), log("log.kn_star", 4, "celebration", who=["shy"]), arc_end("star_is_born")],
                    score=[s_const(1.0)], when=[c_zone("shy", ["kitchen"])]),
                out("flop", [say("host", "kn_flop", delay=2.4), expr("host", "surprised", 4, delay=2.4), each([say("self", "gen_laugh", p=0.5, delay=3.6)], exclude=["host"],
                                                                                                         where=[c_zone("self", ["kitchen"])]),
                             log("log.kn_flop", 3, "celebration", who=["host"]), arc_end("cracked")], score=[s_const(0.4)])])
arc("karaoke_night", BIG, "invite", cooldown_days=8, stages={
    "invite": stage("kn_invite", "place", actor="host", place="announce", wait=(3, 10), ttl=60),
    "rehearse": stage("kn_rehearse", "place", actor="shy", place="archive", ttl=120, fail="night"),
    "night": stage("kn_night", "gather", actor="host", area="kitchen", need=3, ttl=50, window=("16:20", "17:15"), fail="end:nobody_came", must=["host"]),
})


# =====================================================================
# 28. THE CHARITY BOX
# =====================================================================
title("charity_drive", "The Charity Box", "{organiser} is collecting for the animal shelter. Somebody's counting wrong.")
L("cd_launch", ["Charity box in the kitchen! For the animal shelter. Every lira counts!", "Help the shelter! Box is in the kitchen. Be generous!"])
T("log.cd_launch", "{organiser} put a charity box in the kitchen for the animal shelter.")
start("start_charity", "charity_drive", {"organiser": "actor"},
      [actor([c_trait("self", "empathy", gt=0.65), c_time(before="13:00")], [s_trait("self", "empathy", 1.0), s_trait("self", "sociability", 0.4)])], "helping", cooldown_days=8)
scene("cd_launch", noise=0.6, allow_absent=True, conditions=[c_present("organiser")],
      effects=[say("organiser", "cd_launch"), emote("organiser", "love"), oset("kitchen.tray", True), log("log.cd_launch", 2, "help", who=["organiser"]),
               arc_next("collect", wait=(20, 60))])
L("cd_give", ["*drops a note in the box*", "For the puppies.", "Here. Don't tell anyone how much."])
T("log.cd_collect", "Coins are clinking into {organiser}'s charity box all afternoon.")
scene("cd_collect", noise=0.6, allow_absent=True, conditions=[c_present("organiser")],
      effects=[each([say("self", "cd_give", p=0.4, delay=1), rel("organiser", "self", "friendship", 3)], exclude=["organiser"], where=[c_trait("self", "empathy", gt=0.4)], stagger=0.8),
               log("log.cd_collect", 2, "help", who=["organiser"]), arc_next("count", wait=(30, 80))])
L("cd_count", ["...That's odd. I'm sure there was more in here.", "Three hundred and— wait. Where did the big note go?"])
L("cd_record", ["We raised more than last year! Thank you, everyone!", "A record! The shelter's going to cry."])
T("log.cd_record", "{organiser} counted the charity box: a record! The shelter will be thrilled.")
T("log.cd_missing", "{organiser} counted the charity box and money seems to be missing. {organiser} suspects {suspect}.")
scene("cd_count", noise=0.8, allow_absent=True, conditions=[c_present("organiser")],
      roles=[role("suspect", where=[c_present("self"), c_trait("self", "honesty", lt=0.6), c_is("self", "ahmet", neg=True)], score=[s_trait("self", "honesty", -1.0), s_rand(0.5)],
                  exclude=["organiser"], optional=True)],
      effects=[say("organiser", "cd_count")],
      outcomes=[out("record", [say("organiser", "cd_record", delay=2), emote("organiser", "cheer", delay=2), each([mood("self", 5)], where=[c_zone("self", ["kitchen"])]),
                               log("log.cd_record", 3, "help", who=["organiser"]), arc_end("record")], score=[s_const(0.8)]),
                out("missing", [expr("organiser", "angry", 5, delay=1.6), rel("organiser", "suspect", "suspicion", 25), log("log.cd_missing", 4, "conflict", who=["organiser", "suspect"]),
                                arc_next("accuse", wait=(5, 20))], score=[s_const(0.9)], when=[c_filled("suspect")])])
L("cd_accuse", ["Did you take money from the charity box, {suspect}?", "Some money's missing from the box. Anything you want to tell me?"])
L("cd_innocent", ["WHAT? No! I put money IN!", "Are you serious? From a SHELTER box?"])
L("cd_change", ["I... borrowed some change for the vending machine. I was going to put it back!", "Okay, okay — I took coins for the coffee machine. I'll pay double."])
L("cd_found_it", ["...Oh. It was stuck under the flap. Never mind. Sorry.", "Wait — the note fell inside the lining. I'm an idiot."])
T("log.cd_innocent", "{organiser} accused {suspect} of taking charity money — then found the note stuck in the box. Awkward apology.")
T("log.cd_change", "{suspect} admitted 'borrowing' coins from the charity box for the vending machine. They're paying double.")
scene("cd_accuse", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 6), say("actor", "cd_accuse", to="target")],
      outcomes=[out("innocent", [say("target", "cd_innocent", to="actor", delay=1.8), say("actor", "cd_found_it", to="target", delay=3.6), emote("actor", "sweat", delay=3.6),
                                 rel("target", "actor", "resentment", 8), rel("actor", "target", "suspicion", -25), log("log.cd_innocent", 3, "misunderstanding"),
                                 arc_end("false_alarm")], score=[s_trait("target", "honesty", 1.0), s_const(0.3)]),
                out("change", [say("target", "cd_change", to="actor", delay=1.8), emote("target", "sweat", delay=1.8), rel("actor", "target", "trust", -8),
                               rumor("stole_lunch", a="target", b="actor", juicy=0.4, knowers=["actor"]), log("log.cd_change", 3, "conflict"), arc_end("borrowed")],
                    score=[s_trait("target", "honesty", -0.8), s_const(0.5)])])
arc("charity_drive", BIG, "launch", cooldown_days=8, stages={
    "launch": stage("cd_launch", "place", actor="organiser", place="k1", wait=(3, 10), ttl=60),
    "collect": stage("cd_collect", "now", actor="organiser", ttl=120, fail="count"),
    "count": stage("cd_count", "place", actor="organiser", place="k1", ttl=120, fail="end:record"),
    "accuse": stage("cd_accuse", "visit", actor="organiser", target="suspect", ttl=80, fail="end:unspoken"),
})


# =====================================================================
# 29. THE BUDGET CUTS
# =====================================================================
title("budget_cuts", "The Budget Cuts", "HQ cut the budget. The free coffee is the first casualty.")
L("bc2_announce", ["Bad news. HQ has cut our budget. Starting today: no more free coffee.", "Team. Budget cuts. The coffee machine is now... pay-per-cup."])
L("bc2_gasp", ["WHAT?!", "No coffee?! How are we supposed to WORK?", "This is a human rights violation."])
T("log.bc2_announce", "Ahmet announced budget cuts: no more free coffee. The office reacted as if he'd cancelled oxygen.")
start("start_budget_cuts", "budget_cuts", {"boss": "actor"},
      [actor([c_is("self", "ahmet")], [s_stress("self", 0.02), s_const(1)])], "work_career", conditions=[c_chance(0.3), c_time(after="09:50", before="12:00")], cooldown_days=10)
scene("bc2_announce", noise=0.6, allow_absent=True, conditions=[c_present("boss")],
      effects=[say("boss", "bc2_announce"), sfx("gasp", delay=1.4), each([say("self", "bc2_gasp", p=0.5, delay=1.6), morale("self", -6), mood("self", -8)], exclude=["boss"],
                                                                          where=[c_near("self", "boss", 9)], stagger=0.5),
               rumor("layoffs", a="@ahmet", b="@ahmet", juicy=0.6, truth=False, knowers=[]), log("log.bc2_announce", 4, "boss")],
      roles=[role("leader", where=[c_present("self"), c_is("self", "ahmet", neg=True)], score=[s_trait("self", "sociability", 0.8), s_trait("self", "temper", 0.6),
                                                                                           s_morale("self", -0.02), s_rand(0.3)], exclude=["boss"], optional=True)],
      outcomes=[out("grumble", [arc_next("grumble", wait=(15, 40))], score=[s_const(1)], when=[c_filled("leader")]),
                out("accept", [arc_end("accepted")], score=[s_const(0.1)])])
L("bc2_grumble", ["First the coffee. Next it'll be the chairs.", "If the coffee goes, I go.", "We need to DO something."])
T("log.bc2_grumble", "The coffee-less office gathered in the kitchen to grumble. {leader} wants to do something about it.")
scene("bc2_grumble", noise=0.6,
      effects=[each([say("self", "bc2_grumble", p=0.6, delay=0.8), emote("self", "anger", delay=0.8)], where=[c_zone("self", ["kitchen"])], stagger=0.6),
               log("log.bc2_grumble", 3, "work", who=["leader"]), arc_next("deal", wait=(10, 30))])
L("bc2_propose", ["Ahmet Bey, a proposal: we run a bake sale and fund the coffee ourselves.", "What if we pay for the beans and you keep the machine running?"])
L("bc2_accept", ["...A bake sale. Fine. Bring me a börek and we'll talk.", "Hm. Creative. Approved."])
L("bc2_reject", ["No bake sales. This is a business, not a school fête.", "The budget is the budget."])
T("log.bc2_accept", "{leader} talked Ahmet into a bake sale to save the coffee. The office is cautiously optimistic.")
T("log.bc2_reject", "{leader} proposed a bake sale to save the coffee. Ahmet said no. Morale has hit the floor.")
scene("bc2_deal", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 6), say("actor", "bc2_propose", to="target")],
      outcomes=[out("accept", [say("target", "bc2_accept", to="actor", delay=1.8), favor("actor", 6), each([morale("self", 5), mood("self", 6)], exclude=["boss"]),
                               rel("target", "actor", "respect", 10), log("log.bc2_accept", 4, "work"), arc_end("bake_sale")],
                    score=[s_trait("target", "empathy", 0.8), s_rel("target", "actor", "trust", 0.02), s_const(0.3)]),
                out("reject", [say("target", "bc2_reject", to="actor", delay=1.8), each([morale("self", -4)], exclude=["boss"]), plan("actor", "job_search", "", heat=0.3),
                               log("log.bc2_reject", 4, "work"), arc_end("no_coffee")], score=[s_trait("target", "temper", 0.8), s_stress("target", 0.01)])])
arc("budget_cuts", BIG, "announce", cooldown_days=10, stages={
    "announce": stage("bc2_announce", "place", actor="boss", place="announce", wait=(2, 6), ttl=60),
    "grumble": stage("bc2_grumble", "gather", actor="leader", area="kitchen", need=3, ttl=50, fail="deal", exclude=["boss"]),
    "deal": stage("bc2_deal", "visit", actor="leader", target="boss", ttl=90, fail="end:no_coffee"),
})


# =====================================================================
# 30. THE SIDE HUSTLE
# =====================================================================
title("side_hustle", "The Side Hustle", "{seller} is running a baklava business from their desk.")
L("sh_open", ["Homemade baklava! Five lira a slice. Don't tell Ahmet.", "*opens a drawer full of baklava* Business is open."])
L("sh_buy", ["Two slices. No — three.", "Shut up and take my money.", "Is this pistachio? Give me the tray."])
T("log.sh_open", "{seller} is secretly selling homemade baklava from their desk drawer. Business is booming.")
start("start_side_hustle", "side_hustle", {"seller": "actor", "boss": "@ahmet"},
      [actor([c_trait("self", "ambition", gt=0.55), c_trait("self", "cunning", gt=0.45), c_is("self", "ahmet", neg=True)], [s_trait("self", "ambition", 0.8), s_trait("self", "cunning", 0.6)])],
      "secret_plans", conditions=[c_present("@ahmet"), c_chance(0.4)], cooldown_days=9)
scene("sh_open", noise=0.6, allow_absent=True, conditions=[c_present("seller")],
      effects=[say("seller", "sh_open"), emote("seller", "whisper"), witness([say("self", "sh_buy", p=0.6, delay=1.6), mood("self", 6), rel("self", "seller", "friendship", 4)],
                                                                            near="seller", r=6, exclude=["seller", "boss"]),
               log("log.sh_open", 3, "secret", who=["seller"]), arc_next("boom", wait=(30, 80))])
L("sh_boom", ["I'm taking orders for Friday. Trays only.", "I've hired {runner} as my delivery person."])
T("log.sh_boom", "{seller}'s baklava business is expanding. {runner} is now 'head of logistics'.")
scene("sh_boom", noise=0.6, allow_absent=True, conditions=[c_present("seller")],
      roles=[by_fn("runner", "best_of", of="seller", lim=-10, optional=True, exclude=["seller", "boss"])],
      effects=[say("seller", "sh_boom"), work("seller", -10), bond("seller", "runner", "alliance", when=[c_filled("runner")]), rumor("scheme", a="seller", b="@ahmet", juicy=0.5, knowers=[]),
               log("log.sh_boom", 3, "secret", who=["seller", "runner"]), arc_next("caught", wait=(30, 90))])
L("sh_caught", ["{seller}. Why does your desk smell like a pastry shop?", "Is that... a PRICE LIST? On company paper?"])
L("sh_boss_buys", ["...How much for a whole tray? Asking for a client.", "Fine. Two trays for the board meeting. On the company card."])
L("sh_shut", ["Close it. Today. You're paid to work, not to bake.", "This is a workplace. Shut it down."])
T("log.sh_boss_buys", "Ahmet caught {seller}'s baklava business — and became its biggest customer.")
T("log.sh_shut", "Ahmet caught {seller}'s baklava business and shut it down. The office mourns.")
scene("sh_caught", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 6), say("actor", "sh_caught", to="target"), emote("target", "sweat")],
      outcomes=[out("buys", [say("actor", "sh_boss_buys", to="target", delay=2), emote("target", "cheer", delay=2), rel("actor", "target", "friendship", 8), mood("target", 12),
                             log("log.sh_boss_buys", 4, "boss"), arc_end("supplier")], score=[s_mood("actor", 0.03), s_trait("actor", "humor", 0.8)]),
                out("shut", [say("actor", "sh_shut", to="target", delay=2), expr("target", "sad", 6, delay=2), favor("target", -8), each([mood("self", -4)], exclude=["boss"]),
                             log("log.sh_shut", 4, "boss"), arc_end("shut_down")], score=[s_trait("actor", "diligence", 0.8), s_stress("actor", 0.01), s_const(0.3)])])
arc("side_hustle", BIG, "open", cooldown_days=9, stages={
    "open": stage("sh_open", "now", actor="seller", wait=(3, 10), ttl=60),
    "boom": stage("sh_boom", "now", actor="seller", ttl=120, fail="caught"),
    "caught": stage("sh_caught", "desk", actor="boss", target="seller", ttl=150, fail="end:undetected"),
})


# =====================================================================
# 31. THE BROKEN MUG COVER-UP
# =====================================================================
title("mug_coverup", "The Broken Mug Cover-up", "{breaker} broke Ahmet's favourite mug. {friend} is helping hide it.")
L("mc_crash", ["*CRASH* ...No. No no no. Not THE mug.", "*picks up pieces of 'World's Best Boss'* I'm dead. I'm so dead."])
T("log.mc_crash", "{breaker} broke Ahmet's beloved 'World's Best Boss' mug in the kitchen.")
start("start_mug_coverup", "mug_coverup", {"breaker": "actor", "friend": "$fr", "boss": "@ahmet"},
      [actor([c_trait("self", "clumsiness", gt=0.55), c_is("self", "ahmet", neg=True)], [s_trait("self", "clumsiness", 1.0), s_rand(0.4)])], "helping",
      vars=[var("fr", "best_of", of="actor", lim=0)], conditions=[c_present("@ahmet"), c_chance(0.4)], cooldown_days=9)
scene("mc_crash", noise=0.6, allow_absent=True, conditions=[c_present("breaker")],
      effects=[sfx("slam"), fx("shake", "breaker"), say("breaker", "mc_crash", delay=0.6), expr("breaker", "surprised", 6), stress("breaker", 12),
               log("log.mc_crash", 3, "accident", who=["breaker"]), arc_next("ask", wait=(2, 10))])
L("mug_ask", ["I broke Ahmet's mug. THE mug. Help me.", "Code red. The boss mug. In pieces. What do I do?"])
L("mc_help", ["Okay. Breathe. There's an identical one in the supply room. Probably.", "Leave it to me. I know a guy who knows a mug."])
L("mc_confess_advice", ["Just tell him. He'll respect honesty. Probably.", "Tell him now, before he finds it."])
T("log.mc_help", "{friend} agreed to help {breaker} replace Ahmet's broken mug before he notices.")
T("log.mc_advice", "{friend} told {breaker} to come clean about Ahmet's mug.")
scene("mc_ask", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), emote("actor", "sweat"), say("actor", "mug_ask", to="target")],
      outcomes=[out("help", [say("target", "mc_help", to="actor", delay=1.6), bond("actor", "target", "alliance"), rel("actor", "target", "friendship", 8),
                             log("log.mc_help", 3, "help"), arc_next("swap", wait=(10, 30))], score=[s_aff("target", "actor", 0.02), s_trait("target", "cunning", 0.6)]),
                out("advice", [say("target", "mc_confess_advice", to="actor", delay=1.6), log("log.mc_advice", 2, "help"), arc_next("confess", wait=(5, 20))],
                    score=[s_trait("target", "honesty", 1.0)])])
L("mc_swap", ["*places a slightly-wrong replacement mug on Ahmet's desk* ...Perfect.", "*swaps the mug* It says 'World's Best Bass'. He won't notice."])
T("log.mc_swap", "{friend} put a replacement mug on Ahmet's desk. It says 'World's Best Bass'.")
scene("mc_swap", noise=0.6, allow_absent=True, conditions=[c_present("friend")],
      effects=[say("friend", "mc_swap"), emote("friend", "whisper"), log("log.mc_swap", 3, "secret", who=["friend", "breaker"]), arc_next("boss_check", wait=(20, 60))])
L("mc_bass", ["...'World's Best BASS'? Who swapped my mug?!", "This is not my mug. My mug had a chip on the handle."])
L("mc_fooled", ["*sips coffee happily from the wrong mug*", "Ahh. Nothing like my favourite mug."])
T("log.mc_fooled", "Ahmet is happily drinking from the 'World's Best Bass' mug. The cover-up worked.")
T("log.mc_busted", "Ahmet noticed his mug was swapped. {friend} cracked first.")
scene("mc_boss_check", noise=0.8, allow_absent=True, conditions=[c_present("boss")],
      outcomes=[out("fooled", [say("boss", "mc_fooled"), emote("boss", "ok"), rel("breaker", "friend", "trust", 10), log("log.mc_fooled", 3, "prank", who=["breaker", "friend"]),
                               arc_end("got_away")], score=[s_trait("boss", "curiosity", -1.0), s_const(0.8)]),
                out("busted", [say("boss", "mc_bass"), expr("boss", "angry", 6), favor("friend", -6), favor("breaker", -6), call("scold", target="breaker", reason="general", prio=66, delay=4),
                               log("log.mc_busted", 4, "boss", who=["breaker", "friend"]), arc_end("busted")], score=[s_trait("boss", "curiosity", 1.0), s_const(0.3)])])
L("mug_confess", ["Ahmet Bey... I broke your mug. I'm so sorry.", "I have to confess something. It's about your mug."])
L("mug_forgive", ["...That mug was a gift from my daughter. But thank you for telling me.", "Accidents happen. Thank you for being honest."])
L("mc_upset", ["MY MUG?! Do you know how long I've had that mug?!", "Twelve years. Twelve years that mug survived. Until you."])
T("log.mc_forgive", "{breaker} confessed to breaking Ahmet's mug. Ahmet forgave them — and seemed to respect it.")
T("log.mc_upset", "{breaker} confessed to breaking Ahmet's mug. Ahmet took it very, very personally.")
scene("mug_confess_scene", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 6), emote("actor", "sweat"), say("actor", "mug_confess", to="target")],
      outcomes=[out("forgive", [say("target", "mug_forgive", to="actor", delay=1.8), rel("target", "actor", "trust", 12), rel("target", "actor", "respect", 8),
                                log("log.mc_forgive", 4, "boss"), arc_end("forgiven")], score=[s_trait("target", "empathy", 1.0), s_trait("target", "forgiveness", 0.8)]),
                out("upset", [say("target", "mc_upset", to="actor", delay=1.8), expr("target", "angry", 6, delay=1.8), favor("actor", -8), mood("actor", -10),
                              log("log.mc_upset", 4, "boss"), arc_end("mourned")], score=[s_trait("target", "temper", 1.0)])])
arc("mug_coverup", BIG, "crash", cooldown_days=9, stages={
    "crash": stage("mc_crash", "place", actor="breaker", place="k2", wait=(3, 10), ttl=60),
    "ask": stage("mc_ask", "visit", actor="breaker", target="friend", ttl=60, fail="confess"),
    "swap": stage("mc_swap", "place", actor="friend", place="boss_guest", ttl=60, fail="confess"),
    "boss_check": stage("mc_boss_check", "desk", actor="boss", target="boss", ttl=200, fail="end:got_away"),
    "confess": stage("mug_confess_scene", "visit", actor="breaker", target="boss", ttl=90, fail="end:hidden"),
})


# =====================================================================
# 32. THE OFFICE CHAIR RACE
# =====================================================================
title("chair_race", "The Office Chair Race", "{racer} challenged {rival} to an office-chair race down the corridor.")
L("cr_challenge", ["You. Me. Office chairs. Corridor. Loser buys coffee for a week.", "I bet my chair is faster than yours."])
L("cr_accept", ["Oh, you're going DOWN.", "Name the time."])
T("log.cr_challenge", "{racer} challenged {rival} to an office-chair race. Bets are already being placed.")
start("start_chair_race", "chair_race", {"racer": "actor", "rival": "rv", "boss": "@ahmet"},
      [actor([c_trait("self", "humor", gt=0.55), c_mood("self", gt=10), c_is("self", "ahmet", neg=True)], [s_trait("self", "humor", 1.0), s_mood("self", 0.02)]),
       by_fn("rv", "best_of", of="actor", lim=10, exclude=["actor", "@ahmet"])], "comedy", conditions=[c_chance(0.4)], cooldown_days=8)
scene("cr_challenge", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "cr_challenge", to="target"), say("target", "cr_accept", to="actor", delay=1.6), emote("target", "cheer", delay=1.6),
               log("log.cr_challenge", 3, "prank"), arc_next("race", wait=(20, 60))])
L("cr_go", ["Three... two... ONE!", "GO GO GO!", "*rolling at terrifying speed*"])
L("cr_cheer", ["GO {racer}!", "Faster! FASTER!", "My money's on {rival}!"])
L("cr_crash", ["*CRASH* ...I'm okay! The plant is not okay.", "*spins into the water cooler*"])
T("log.cr_win", "{racer} won the office-chair race against {rival}. The crowd went wild.")
T("log.cr_crash", "The office-chair race ended with {racer} crashing into the plant. {rival} wins by default.")
scene("cr_race", noise=0.6,
      effects=[say("racer", "cr_go"), sfx("crowd", delay=1), each([say("self", "cr_cheer", p=0.5, delay=1.4), mood("self", 6)], exclude=["racer", "rival", "boss"],
                                                                   where=[c_near("self", "racer", 7)], stagger=0.4)],
      outcomes=[out("win", [emote("racer", "cheer", delay=3), rel("rival", "racer", "respect", 6), log("log.cr_win", 3, "prank", who=["racer", "rival"]), arc_next("boss", wait=(5, 20))],
                    score=[s_trait("racer", "clumsiness", -1.0), s_const(0.6)]),
                out("crash", [say("racer", "cr_crash", delay=3), sfx("thump", delay=3), fx("shake", "racer", delay=3), emote("rival", "cheer", delay=3.4),
                              log("log.cr_crash", 3, "accident", who=["racer", "rival"]), arc_next("boss", wait=(2, 10))], score=[s_trait("racer", "clumsiness", 1.0)])])
L("cr_boss_ask", ["Why are there TYRE MARKS on my corridor?", "Was someone RACING CHAIRS in my office?"])
L("cr_boss_joins", ["...Rematch. Tomorrow. I'm racing. I was regional go-kart champion in '98.", "Hm. Where's the spare chair? I want a go."])
L("cr_boss_bans", ["Chair racing is now officially banned. There will be a memo.", "Never again. Both of you. NEVER."])
T("log.cr_boss_joins", "Ahmet found out about the chair race — and demanded a rematch with himself in it.")
T("log.cr_boss_bans", "Ahmet found out about the chair race and banned it with a memo. {racer} got the blame.")
scene("cr_boss", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5.5), say("actor", "cr_boss_ask", to="target")],
      outcomes=[out("joins", [say("actor", "cr_boss_joins", to="target", delay=2), emote("target", "cheer", delay=2), rel("actor", "target", "friendship", 8),
                              log("log.cr_boss_joins", 4, "boss"), arc_end("rematch")], score=[s_trait("actor", "humor", 1.2), s_mood("actor", 0.02)]),
                out("bans", [say("actor", "cr_boss_bans", to="target", delay=2), favor("target", -6), log("log.cr_boss_bans", 4, "boss"), arc_end("banned")],
                    score=[s_trait("actor", "temper", 1.0), s_const(0.3)])])
arc("chair_race", BIG, "challenge", cooldown_days=8, stages={
    "challenge": stage("cr_challenge", "visit", actor="racer", target="rival", wait=(3, 10), ttl=60, fail="end:chickened_out"),
    "race": stage("cr_race", "gather", actor="racer", area="hall", need=2, ttl=50, fail="end:postponed", window=("12:00", "16:40"), exclude=["boss"], must=["racer", "rival"]),
    "boss": stage("cr_boss", "visit", actor="boss", target="racer", ttl=120, fail="end:got_away_with_it"),
})


# =====================================================================
# 33. THE LOTTERY POOL
# =====================================================================
title("lottery_pool", "The Lottery Pool", "{organiser} runs the office lottery pool. {dreamer} is already spending the winnings.")
L("lp2_collect", ["Lottery pool! Ten lira each. If we win, nobody comes in Monday.", "Office lottery! In or out? Don't be the one who's left out when we win."])
L("lp2_in", ["I'm in. Obviously.", "Take my money. Take my hopes."])
T("log.lp2_collect", "{organiser} collected ten lira from everyone for an office lottery ticket.")
start("start_lottery", "lottery_pool", {"organiser": "actor", "dreamer": "$dr", "boss": "@ahmet"},
      [actor([c_trait("self", "sociability", gt=0.55), c_time(before="12:00")], [s_trait("self", "sociability", 1.0), s_trait("self", "humor", 0.4)])], "gossip",
      vars=[var("dr", "low_morale", lim=60, **{"not": "actor"})], conditions=[c_present("@ahmet"), c_chance(0.4)], cooldown_days=9)
scene("lp2_collect", noise=0.6, allow_absent=True, conditions=[c_present("organiser")],
      effects=[say("organiser", "lp2_collect"), each([say("self", "lp2_in", p=0.5, delay=1.4)], exclude=["organiser"], where=[c_near("self", "organiser", 8)], stagger=0.6),
               log("log.lp2_collect", 2, "celebration", who=["organiser"]), arc_next("rumor", days=1)])
L("lp2_rumor", ["Did you hear? We WON. The lottery. I heard {organiser} on the phone!", "We're RICH! {organiser} was screaming at their phone!"])
L("lp2_dreamer", ["That's it. I'm telling Ahmet what I REALLY think of his memos.", "I'm buying a boat. A big one. Bye, spreadsheets."])
T("log.lp2_rumor", "A rumour spread that the office lottery ticket WON. {dreamer} is already acting like a millionaire.")
scene("lp2_rumor", noise=0.6, allow_absent=True, conditions=[c_present("dreamer")],
      effects=[say("dreamer", "lp2_rumor"), emote("dreamer", "cheer"), say("dreamer", "lp2_dreamer", delay=2.4), mood("dreamer", 25), work("dreamer", -10),
               rumor("raise", a="dreamer", b="organiser", juicy=0.8, truth=False, knowers=["dreamer"], origin="dreamer"),
               witness([learn("self", "$rumor", frm="dreamer"), emote("self", "exclaim", delay=2)], near="dreamer", r=6, exclude=["dreamer"]),
               log("log.lp2_rumor", 4, "rumor", who=["dreamer", "organiser"]), arc_next("truth", wait=(20, 60))])
L("lp2_truth", ["Okay, everyone. We won. Forty lira. Total. Four lira each.", "Good news: we won! Bad news: it's enough for one simit each."])
L("lp2_dreamer_crash", ["...Four lira. I told Ahmet his tie is ugly. FOR FOUR LIRA.", "I already quit my gym. And insulted the boss. For a simit."])
T("log.lp2_truth", "{organiser} revealed the real lottery win: forty lira. {dreamer} had already told Ahmet exactly what they think of him.")
scene("lp2_truth", noise=0.6, allow_absent=True, conditions=[c_present("organiser")],
      effects=[say("organiser", "lp2_truth"), each([say("self", "gen_laugh", p=0.4, delay=1.6)], exclude=["organiser", "dreamer"], where=[c_near("self", "organiser", 8)]),
               say("dreamer", "lp2_dreamer_crash", delay=3, when=[c_present("dreamer")]), expr("dreamer", "sad", 8, delay=3), mood("dreamer", -25),
               debunk("$rumor", who=["boss"], by="organiser"), favor("dreamer", -6), rel("boss", "dreamer", "trust", -6), log("log.lp2_truth", 4, "celebration", who=["dreamer", "organiser"]),
               arc_end("four_lira")])
arc("lottery_pool", BIG, "collect", cooldown_days=9, stages={
    "collect": stage("lp2_collect", "now", actor="organiser", wait=(3, 10), ttl=60),
    "rumor": stage("lp2_rumor", "now", actor="dreamer", ttl=120, fail="truth"),
    "truth": stage("lp2_truth", "place", actor="organiser", place="announce", ttl=120, fail="end:forgotten"),
})


# =====================================================================
# 34. FORCED PARTNERS
# =====================================================================
title("forced_partners", "Forced Partners", "Ahmet has paired {a} and {b} on a project. They can't stand each other.")
L("fp_assign", ["{a}, {b}: the quarterly report is yours. Together. By tomorrow.", "New project. {a} and {b}. Make it work."])
L("fp_groan", ["...Together?", "With HIM? With HER?", "Can I just do it alone? Twice?"])
T("log.fp_assign", "Ahmet paired {a} and {b} — sworn rivals — on the quarterly report.")
start("start_forced_partners", "forced_partners", {"boss": "actor", "a": "$a", "b": "$b"},
      [actor([c_is("self", "ahmet")], [s_const(1)])], "work_career", vars=[var("a", "rival_pair", lim=30)], conditions=[c_chance(0.5)], cooldown_days=8)
scene("fp_assign", noise=0.6, allow_absent=True, conditions=[c_present("boss"), c_present("a"), c_present("b")],
      effects=[say("boss", "fp_assign"), say("a", "fp_groan", delay=1.6), say("b", "fp_groan", delay=2.6), log("log.fp_assign", 3, "work", who=["a", "b"]),
               arc_next("work", wait=(15, 40))])
L("fp_click", ["...Your chart is actually good.", "Okay. You do the numbers, I do the words. Deal?"])
L("fp_clash", ["That's not how you format a table!", "Stop changing MY paragraphs!"])
T("log.fp_click", "{a} and {b} worked on the report together in the archive — and, against all odds, it went well.")
T("log.fp_clash", "{a} and {b} worked on the report together in the archive. There was shouting about fonts.")
scene("fp_work", noise=0.9,
      effects=[hold(["a", "b"], 6), emote("a", "question")],
      outcomes=[out("click", [say("a", "fp_click", to="b", delay=1.4), say("b", "fp_click", to="a", delay=3), rel("a", "b", "rivalry", -12, both=True), rel("a", "b", "respect", 10, both=True),
                              work("a", 12), work("b", 12), log("log.fp_click", 3, "work"), arc_next("deliver", wait=(20, 60))],
                    score=[s_trait("a", "empathy", 0.6), s_trait("b", "empathy", 0.6), s_const(0.2)]),
                out("clash", [say("a", "fp_clash", to="b", delay=1.4), say("b", "fp_clash", to="a", delay=3), sfx("argue", delay=1.4), rel("a", "b", "resentment", 10, both=True),
                              stat("arguments"), log("log.fp_clash", 3, "conflict"), arc_next("deliver", wait=(20, 60))],
                    score=[s_trait("a", "temper", 0.8), s_trait("b", "temper", 0.8)])])
L("fp_present", ["Here's the report. I did most of it.", "Our report. Mine, mostly."])
L("fp_credit_fight", ["MOST of it?! I wrote every number in there!", "Excuse me?! Page three to nine are MINE."])
L("fp_boss_good", ["This is excellent. Both of you. See? Teamwork.", "Good work. Both of you. I knew it."])
T("log.fp_credit", "{a} handed in the joint report and claimed most of the credit. {b} exploded.")
T("log.fp_good", "{a} and {b} handed in the joint report. Ahmet loved it and praised them both.")
scene("fp_deliver", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "fp_present", to="target")],
      outcomes=[out("credit", [say("b", "fp_credit_fight", delay=1.8, when=[c_near("b", "a", 6)]), rel("b", "a", "resentment", 15), rumor("credit_steal", a="a", b="b", juicy=0.7, knowers=["b"]),
                               favor("a", 4), log("log.fp_credit", 4, "conflict", who=["a", "b"]), arc_end("credit_fight")],
                    score=[s_trait("actor", "cunning", 1.0), s_rel("actor", "b", "rivalry", 0.02)]),
                out("good", [say("target", "fp_boss_good", to="actor", delay=1.8), favor("a", 6), favor("b", 6), rel("a", "b", "friendship", 6, both=True),
                             log("log.fp_good", 3, "work", who=["a", "b"]), arc_end("teamwork")], score=[s_trait("actor", "honesty", 1.0), s_rel("actor", "b", "respect", 0.02)])])
arc("forced_partners", BIG, "assign", cooldown_days=8, stages={
    "assign": stage("fp_assign", "now", actor="boss", wait=(3, 12), ttl=80),
    "work": stage("fp_work", "meet", actor="a", target="b", area="archive", ttl=90, fail="deliver"),
    "deliver": stage("fp_deliver", "visit", actor="a", target="boss", ttl=120, fail="end:missed_deadline"),
})


# =====================================================================
# 35. THE HQ INSPECTION
# =====================================================================
title("hq_inspection", "The HQ Inspection", "HQ is inspecting the office tomorrow. {slob}'s desk is a disaster.")
L("hq_warn", ["Listen up! HQ inspection TOMORROW. I want this office SPOTLESS.", "Tomorrow, an inspector from HQ is coming. Clean. Everything."])
L("hq_groan", ["Spotless? Have you SEEN {slob}'s desk?", "We'll need a bulldozer for {slob}'s corner."])
T("log.hq_warn", "Ahmet announced an HQ inspection for tomorrow. All eyes turned to {slob}'s desk.")
start("start_hq_inspection", "hq_inspection", {"boss": "actor", "slob": "slob"},
      [actor([c_is("self", "ahmet"), c_time(after="10:00", before="15:00")], [s_const(1)]),
       role("slob", where=[c_present("self"), c_is("self", "ahmet", neg=True)], score=[s_trait("self", "diligence", -1.0), s_trait("self", "clumsiness", 0.5), s_rand(0.2)])],
      "work_career", conditions=[c_chance(0.3)], cooldown_days=10)
scene("hq_warn", noise=0.6, allow_absent=True, conditions=[c_present("boss")],
      effects=[say("boss", "hq_warn"), each([stress("self", 6)], exclude=["boss"]), say("$teaser", "hq_groan", delay=2, when=[c_filled("$teaser")]),
               log("log.hq_warn", 3, "boss", who=["slob"]), arc_next("cleanup", days=1)],
      vars=[var("teaser", "best_of", of="slob", lim=-50, optional=True)])
L("hq_clean", ["*scrubbing the keyboard with a toothbrush*", "Is this... a sandwich from MARCH?", "*shoves everything into a drawer*"])
T("log.hq_clean", "Inspection day. Everyone's cleaning. {slob} is shoving things into drawers at alarming speed.")
scene("hq_cleanup", noise=0.6, allow_absent=True, conditions=[c_present("slob")],
      effects=[say("slob", "hq_clean"), emote("slob", "sweat"), each([say("self", "hq_clean", p=0.3, delay=1.4)], exclude=["slob", "boss"], stagger=0.8),
               log("log.hq_clean", 3, "work", who=["slob"]), arc_next("inspect", wait=(30, 90))])
L("hq_open_drawer", ["And what's in THIS drawer, {slob}?", "Open the drawer, {slob}. The inspector is watching."])
L("hq_drawer_ok", ["...Neatly labelled folders. Huh. Well done.", "Impressive. I take back what I said about your desk."])
L("hq_avalanche", ["*an avalanche of crisp packets and old memos pours out*", "*four months of receipts slide onto the inspector's shoes*"])
T("log.hq_pass", "During the HQ inspection, Ahmet opened {slob}'s drawer. It was immaculate. Nobody can explain it.")
T("log.hq_fail", "During the HQ inspection, Ahmet opened {slob}'s drawer. An avalanche of rubbish hit the inspector's shoes.")
scene("hq_inspect", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 6), say("actor", "hq_open_drawer", to="target"), emote("target", "sweat")],
      outcomes=[out("pass", [say("actor", "hq_drawer_ok", to="target", delay=2), favor("target", 8), rel("actor", "target", "respect", 10), log("log.hq_pass", 4, "boss"),
                             arc_next("verdict", wait=(15, 45))], score=[s_trait("target", "diligence", 1.0), s_const(0.2)]),
                out("fail", [say("target", "hq_avalanche", delay=2), sfx("papers", delay=2), expr("actor", "angry", 8, delay=2), favor("target", -12), stress("target", 12),
                             log("log.hq_fail", 4, "boss"), arc_next("verdict", wait=(15, 45))], score=[s_trait("target", "diligence", -1.0), s_const(0.4)])])
L("hq_result_good", ["The inspector's report is in: 'Exemplary office.' Well done, everyone!", "We PASSED. Pizza on me. Well, on the company."])
L("hq_result_bad", ["The inspector's report says 'Needs improvement'. One drawer cost us everything.", "We failed the inspection. I'm not naming names. {slob}."])
T("log.hq_good", "The HQ inspector's verdict: 'Exemplary office.' Ahmet ordered pizza.")
T("log.hq_bad", "The HQ inspector's verdict: 'Needs improvement.' Ahmet blamed {slob} in front of everyone.")
scene("hq_verdict", noise=0.6, allow_absent=True, conditions=[c_present("boss")],
      outcomes=[out("good", [say("boss", "hq_result_good"), each([mood("self", 8), morale("self", 4), emote("self", "cheer", delay=1.4)], exclude=["boss"]),
                             log("log.hq_good", 4, "celebration"), arc_end("passed")], score=[s_const(1)], when=[c_var("last_outcome", eq="pass")]),
                out("bad", [say("boss", "hq_result_bad"), expr("boss", "angry", 6), each([morale("self", -3), rel("self", "slob", "resentment", 6)], exclude=["boss", "slob"]),
                            mood("slob", -16), log("log.hq_bad", 4, "boss", who=["slob"]), arc_end("failed")], score=[s_const(0.5)])])
arc("hq_inspection", BIG, "warn", cooldown_days=10, stages={
    "warn": stage("hq_warn", "place", actor="boss", place="announce", wait=(2, 8), ttl=60),
    "cleanup": stage("hq_cleanup", "now", actor="slob", ttl=90, window=("09:40", "11:00"), fail="inspect"),
    "inspect": stage("hq_inspect", "desk", actor="boss", target="slob", ttl=120, fail="verdict"),
    "verdict": stage("hq_verdict", "place", actor="boss", place="announce", ttl=120, fail="end:no_verdict"),
})


TEST_CASTS = {
    "breakup": {"a": "mert", "b": "ceren"},
    "office_pet": {"smuggler": "ceren", "boss": "ahmet", "accomplice": "ece"},
    "prank_war": {"p1": "mert", "p2": "burak", "boss": "ahmet"},
    "noise_war": {"quiet": "zeynep", "loud": "mert"},
    "pitch_battle": {"a": "selin", "b": "deniz", "boss": "ahmet"},
    "karaoke_night": {"host": "mert", "shy": "zeynep"},
    "charity_drive": {"organiser": "ceren"},
    "budget_cuts": {"boss": "ahmet"},
    "side_hustle": {"seller": "deniz", "boss": "ahmet"},
    "mug_coverup": {"breaker": "ece", "friend": "ceren", "boss": "ahmet"},
    "chair_race": {"racer": "mert", "rival": "burak", "boss": "ahmet"},
    "lottery_pool": {"organiser": "ceren", "dreamer": "burak", "boss": "ahmet"},
    "forced_partners": {"boss": "ahmet", "a": "selin", "b": "deniz"},
    "hq_inspection": {"boss": "ahmet", "slob": "burak"},
}
for _a in _sh.A:
    if _a["id"] in TEST_CASTS:
        _a["test"] = TEST_CASTS[_a["id"]]
