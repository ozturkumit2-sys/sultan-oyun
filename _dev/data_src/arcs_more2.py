# More story arcs (part 2): stories that hidden combinations (category J) set off.
# They can't start on their own — the player has to line up the ingredients.
from story_helpers import *  # noqa: F401,F403
from story_helpers import arc, stage
import story_helpers as _sh
from iv_helpers import S_, L, oset, unpin  # noqa: F811  (guarded: never overwrite existing text)
from arcs_more1 import title, T, BIG


# =====================================================================
# 13. THE COFFEE DATE MIX-UP (J02: wrong love note + fake 1:1 invite)
# =====================================================================
title("coffee_date_mixup", "The Coffee Date Mix-up", "{reader} thinks {sender} asked them out. {sender} has no idea.")
L("cdm_hopeful", ["I got your note. And the invite. I... feel the same way.", "So. The note. The candle-lit coffee. I'm in."])
L("cdm_what", ["...Note? What note?", "Wait — what candle?", "I'm sorry, the WHAT?"])
L("cdm_along", ["...Right. Yes. The note. Shall we get that coffee?", "Ha. Yes. That note. Totally me."])
L("cdm_truth", ["I didn't write any note. Somebody's messing with us.", "I... think there's been a mistake. I never sent that."])
L("cdm_mortified", ["Oh no. Oh no no no.", "I'm going to go and disappear now."])
T("log.cdm_along", "{reader} turned up for a 'date' with {sender}. {sender} had no idea — but played along. The kitchen saw everything.")
T("log.cdm_truth", "{reader} turned up for a 'date' with {sender}. {sender} told the truth: there was no note. {reader} wanted the floor to swallow them.")
T("mem.cdm_mortified", "I turned up for a date that didn't exist.")
scene("cdm_date", noise=0.8, conditions=[c_present("sender"), c_present("reader")],
      effects=[hold(["sender", "reader"], 7), say("reader", "cdm_hopeful", to="sender"), emote("reader", "love"), say("sender", "cdm_what", to="reader", delay=1.8),
               emote("sender", "question", delay=1.8)],
      outcomes=[out("along", [say("sender", "cdm_along", to="reader", delay=3.6), rel("reader", "sender", "romance", 12), rel("sender", "reader", "romance", 6),
                              rumor("couple", a="sender", b="reader", juicy=0.7, truth=False, knowers=[]), witness([learn("self", "$rumor")], near="reader", r=5, exclude=["sender", "reader"]),
                              log("log.cdm_along", 4, "romance", who=["sender", "reader"]), arc_next("second", days=1)],
                    score=[s_trait("sender", "empathy", 0.8), s_aff("sender", "reader", 0.02), s_rel("sender", "reader", "romance", 0.02)]),
                out("truth", [say("sender", "cdm_truth", to="reader", delay=3.6), expr("reader", "sad", 8, delay=3.6), say("reader", "cdm_mortified", delay=5.2), mood("reader", -16),
                              mem("reader", "sender", "humiliated", -0.4, 0.8, "mem.cdm_mortified", 3), log("log.cdm_truth", 4, "romance", who=["sender", "reader"]),
                              arc_next("fallout", wait=(10, 40))], score=[s_trait("sender", "honesty", 1.0), s_const(0.2)])])
L("cdm_second_ask", ["So... about yesterday. Want to try a real coffee? On purpose this time?", "Lunch? A real one. No mysterious notes."])
L("cdm_spark", ["...I'd really like that.", "Honestly? Yesterday was the best mistake ever."])
L("cdm_fizzle", ["Let's just... be friends? Yesterday was a lot.", "I think we both know it was a mix-up."])
T("log.cdm_spark", "{sender} and {reader}'s 'mix-up' date turned into a second, real one. Something is actually happening there.")
T("log.cdm_fizzle", "{sender} and {reader} agreed their date was a mix-up. Friends. Probably.")
scene("cdm_second", noise=0.8, conditions=[c_present("sender"), c_present("reader")],
      effects=[hold(["sender", "reader"], 6), say("sender", "cdm_second_ask", to="reader")],
      outcomes=[out("spark", [say("reader", "cdm_spark", to="sender", delay=1.8), emote("reader", "love", delay=1.8), emote("sender", "love", delay=2.4),
                              rel("sender", "reader", "romance", 15, both=True), log("log.cdm_spark", 4, "romance", who=["sender", "reader"]), arc_next("jealous", wait=(20, 60))],
                    score=[s_rel("reader", "sender", "romance", 0.03), s_rel("sender", "reader", "romance", 0.03), s_const(0.6)]),
                out("fizzle", [say("reader", "cdm_fizzle", to="sender", delay=1.8), rel("sender", "reader", "friendship", 8, both=True), log("log.cdm_fizzle", 3, "friendship"),
                               arc_next("jealous", wait=(20, 60))], score=[s_const(1.2)])])
L("cdm_jealous", ["So. You and {reader}. Everyone's talking about it.", "I heard you're dating {reader} now. Congratulations, I guess."])
L("cdm_confess_crush", ["It's a mix-up! It's YOU I like. It's always been you.", "No — wait. I never wrote that note. The person I like is you."])
L("cdm_clear", ["Dating? No! It was a mix-up. We're just friends.", "Oh, THAT. Fake note, fake date. Nothing happened."])
T("log.cdm_clear", "{crush} asked {sender} about the 'date' with {reader}. Just a mix-up, {sender} explained. {crush} looked... relieved.")
L("cdm_shrug", ["...Yeah. I guess I am.", "It just sort of happened."])
T("log.cdm_true", "{crush} confronted {sender} about {reader}. {sender} blurted out the truth: it's {crush} they like. {reader} found out last.")
T("log.cdm_tangled", "{crush} confronted {sender} about dating {reader}. {sender} didn't deny it. {crush} walked away hurt.")
scene("cdm_jealous", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 6), expr("actor", "sad", 5), say("actor", "cdm_jealous", to="target")],
      outcomes=[out("truth", [say("target", "cdm_confess_crush", to="actor", delay=1.8), emote("actor", "love", delay=1.8), bond("target", "actor", "romance"),
                              rel("actor", "target", "romance", 12), mood("reader", -18), rel("reader", "sender", "resentment", 15), plan("reader", "revenge", "crush", heat=0.5),
                              log("log.cdm_true", 5, "romance", who=["sender", "crush", "reader"]), arc_end("true_love")],
                    score=[s_rel("target", "actor", "romance", 0.04), s_trait("target", "honesty", 0.5)]),
                out("couple", [say("target", "cdm_shrug", to="actor", delay=1.8), mood("actor", -14), bond("sender", "reader", "romance"), rel("actor", "target", "romance", -12), storm("actor", delay=3),
                               log("log.cdm_tangled", 4, "romance", who=["sender", "crush", "reader"]), arc_end("new_couple")], score=[s_rel("target", "reader", "romance", 0.04)],
                    when=[c_var("last_outcome", eq="spark")]),
                out("clear", [say("target", "cdm_clear", to="actor", delay=1.8), emote("actor", "ok", delay=1.8), rel("actor", "target", "trust", 6),
                              log("log.cdm_clear", 3, "romance", who=["sender", "crush"]), arc_end("cleared_up")], score=[s_const(1.0)], when=[c_var("last_outcome", eq="fizzle")])])
L("cdm_vent", ["I showed up for a DATE. With candles. In the KITCHEN.", "Someone set me up. And I fell for it. Literally."])
L("cdm_laugh_it_off", ["...You know what? It's actually hilarious.", "Okay. One day this will be funny. Maybe today."])
L("cdm_hurt", ["I'm never trusting a note again.", "I'm not talking to anyone for a week."])
T("log.cdm_laughed", "{reader} decided the fake date was funny. {reader} and {sender} now have an inside joke.")
T("log.cdm_hurt", "{reader} is still hurt by the fake date and is avoiding {sender}.")
scene("cdm_fallout", noise=0.8, allow_absent=True, conditions=[c_present("reader")],
      effects=[say("reader", "cdm_vent"), emote("reader", "cloud")],
      outcomes=[out("laugh", [say("reader", "cdm_laugh_it_off", delay=2), rel("reader", "sender", "friendship", 10), rel("sender", "reader", "friendship", 6),
                              log("log.cdm_laughed", 3, "friendship", who=["reader", "sender"]), arc_end("laughed_off")], score=[s_trait("reader", "humor", 1.2)]),
                out("hurt", [say("reader", "cdm_hurt", delay=2), expr("reader", "sad", 6, delay=2), rel("reader", "sender", "resentment", 8), morale("reader", -5),
                             log("log.cdm_hurt", 3, "romance", who=["reader"]), arc_end("awkward")], score=[s_trait("reader", "temper", 0.8), s_const(0.3)])])
arc("coffee_date_mixup", BIG, "date", cooldown_days=4, stages={
    "date": stage("cdm_date", "meet", actor="sender", target="reader", area="kitchen", wait=(2, 6), ttl=60, fail="end:stood_up"),
    "second": stage("cdm_second", "meet", actor="sender", target="reader", area="lounge", ttl=90, window=("11:30", "15:30"), fail="end:fizzled"),
    "jealous": stage("cdm_jealous", "visit", actor="crush", target="sender", ttl=80, fail="end:new_couple"),
    "fallout": stage("cdm_fallout", "now", actor="reader", ttl=80, fail="end:awkward"),
})


# =====================================================================
# 14. THE LEAK (J07: shared private folder + confidential document)
# =====================================================================
title("leak_scandal", "The Leak", "A confidential document turned up in {leaker}'s shared folder.")
L("lk_found", ["Wait. Why is the confidential list in {leaker}'s shared folder?!", "Everyone can see this. And it's in {leaker}'s folder."])
T("log.lk_found", "{finder} found the confidential document sitting in {leaker}'s shared folder. Word reached Ahmet within minutes.")
scene("lk_found", noise=0.6, allow_absent=True, conditions=[c_present("finder")],
      effects=[say("finder", "lk_found"), emote("finder", "exclaim"),
               rumor("scheme", a="leaker", b="@ahmet", juicy=0.8, truth=False, knowers=["finder"], origin="finder"),
               learn("@ahmet", "$rumor", frm="finder", c=0.8), log("log.lk_found", 4, "secret", who=["finder", "leaker"]), arc_next("summon", wait=(5, 20))])
L("lk_accuse", ["The confidential file. In YOUR shared folder. Explain.", "{leaker}. Did you leak the confidential list?"])
L("lk_deny", ["I've never seen that file in my life!", "I didn't put it there! Someone's framing me!"])
L("lk_panic", ["I— I can explain— no I can't.", "...Can we talk about this later?"])
T("log.lk_deny", "Ahmet confronted {leaker} about the leak. {leaker} swore they'd never seen the file.")
T("log.lk_panic", "Ahmet confronted {leaker} about the leak. {leaker} panicked — which looked very guilty.")
scene("lk_summon", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 6), expr("actor", "angry", 6), say("actor", "lk_accuse", to="target")],
      outcomes=[out("deny", [say("target", "lk_deny", to="actor", delay=1.8), log("log.lk_deny", 3, "boss"), arc_next("investigate", wait=(10, 30))],
                    score=[s_trait("target", "honesty", 1.0), s_trait("target", "temper", 0.4)]),
                out("panic", [say("target", "lk_panic", to="actor", delay=1.8), emote("target", "sweat", delay=1.8), favor("target", -14), rel("actor", "target", "trust", -18),
                              stress("target", 14), log("log.lk_panic", 4, "boss"), arc_next("investigate", wait=(20, 50))],
                    score=[s_stress("target", 0.02), s_trait("target", "honesty", -0.4), s_const(0.3)])])
L("lk_logs", ["Let's see who opened this file... huh. The account says 'GHOST'.", "Access log, access log... that's odd. Nobody touched it. It just... moved."])
L("lk_logs_unclear", ["The logs are a mess. Could've been anyone.", "No idea. The server's been acting weird all week."])
T("log.lk_ghost", "{it} checked the server logs: nobody moved the confidential file. {leaker} is cleared — and the office is a little more spooked.")
T("log.lk_unclear", "{it} checked the server logs. Inconclusive. {leaker} stays under a cloud of suspicion.")
scene("lk_investigate", noise=0.6, allow_absent=True, conditions=[c_present("it")],
      effects=[emote("it", "question"), say("it", "lk_logs", delay=1.5)],
      outcomes=[out("clear", [debunk("$rumor", who=["@ahmet"], by="it"), call("ghost_theory"), log("log.lk_ghost", 4, "ghost", who=["it", "leaker"]), arc_next("apology", wait=(5, 25))],
                    score=[s_trait("it", "diligence", 1.0), s_const(0.3)]),
                out("unclear", [say("it", "lk_logs_unclear", delay=3), rel("@ahmet", "leaker", "suspicion", 15), log("log.lk_unclear", 3, "secret", who=["leaker"]),
                                arc_end("under_a_cloud")], score=[s_trait("it", "diligence", -0.6), s_const(0.5)])])
L("lk_sorry", ["I owe you an apology, {leaker}. I jumped to conclusions.", "The logs cleared you. I'm sorry. Genuinely."])
L("lk_grudging", ["...Cleared. Fine. But I'm watching that folder.", "Hm. Just... lock your folders, will you?"])
L("lk_accept", ["Thank you. That means a lot.", "Apology accepted. I think."])
T("log.lk_sorry", "Ahmet apologised to {leaker} for the leak accusation. Rare. Witnessed.")
T("log.lk_grudging", "Ahmet grudgingly admitted {leaker} was innocent. No actual apology.")
scene("lk_apology", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5)],
      outcomes=[out("sorry", [say("actor", "lk_sorry", to="target"), say("target", "lk_accept", to="actor", delay=1.8), favor("target", 8), rel("target", "actor", "respect", 8),
                              rel("actor", "target", "trust", 12), log("log.lk_sorry", 4, "boss"), arc_end("cleared")], score=[s_trait("actor", "empathy", 1.0), s_trait("actor", "honesty", 0.6)]),
                out("grudging", [say("actor", "lk_grudging", to="target"), rel("target", "actor", "resentment", 8), log("log.lk_grudging", 3, "boss"), arc_end("cleared_grudgingly")],
                    score=[s_trait("actor", "temper", 0.8), s_const(0.3)])])
arc("leak_scandal", BIG, "found", cooldown_days=5, stages={
    "found": stage("lk_found", "now", actor="finder", wait=(2, 8), ttl=60),
    "summon": stage("lk_summon", "visit", actor="boss", target="leaker", ttl=80, fail="investigate"),
    "investigate": stage("lk_investigate", "place", actor="it", place="server", ttl=90, fail="end:under_a_cloud"),
    "apology": stage("lk_apology", "visit", actor="boss", target="leaker", ttl=90, fail="end:never_apologised"),
})


# =====================================================================
# 15. THE LOYALTY TEST (J10: transfer request + reference letter for the same person)
# =====================================================================
title("loyalty_test", "The Loyalty Test", "Ahmet is convinced {target} wants to leave — so he's testing them.")
L("lt2_mutter", ["A transfer request AND a reference letter? For {target}? Hmm.", "So {target} wants out, do they? We'll see about that."])
T("log.lt2_mutter", "Ahmet found a transfer request and a glowing reference letter for {target} — and decided to test {target}'s loyalty.")
scene("lt2_suspect", noise=0.6, allow_absent=True, conditions=[c_present("boss")],
      effects=[expr("boss", "angry", 4), say("boss", "lt2_mutter"), emote("boss", "question"), rel("boss", "target", "suspicion", 20),
               log("log.lt2_mutter", 3, "boss", who=["target"]), arc_next("test", wait=(10, 30))])
L("lt2_offer", ["There's an opening at our far-east branch. Very far. Interested?", "I could recommend you for a transfer. Tomorrow. Say the word."])
L("lt2_refuse", ["Transfer? No! I'm happy here!", "Why would I want to leave? I like it here. Mostly."])
L("lt2_tempted", ["...How far east, exactly?", "Hm. Can I think about it?"])
T("log.lt2_refuse", "Ahmet offered {target} a far-away transfer as a loyalty test. {target} refused on the spot. Ahmet looked relieved.")
T("log.lt2_tempted", "Ahmet offered {target} a far-away transfer as a test. {target} said they'd think about it. Ahmet did not like that.")
scene("lt2_test", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 6), say("actor", "lt2_offer", to="target")],
      outcomes=[out("refuse", [say("target", "lt2_refuse", to="actor", delay=1.8), favor("target", 10), rel("actor", "target", "trust", 12), rel("actor", "target", "suspicion", -20),
                               log("log.lt2_refuse", 3, "boss"), arc_next("reward", wait=(20, 60))], score=[s_morale("target", 0.03), s_rel("target", "actor", "respect", 0.02)]),
                out("tempted", [say("target", "lt2_tempted", to="actor", delay=1.8), favor("target", -10), rel("actor", "target", "trust", -12),
                                log("log.lt2_tempted", 4, "boss"), arc_next("friend_talk", wait=(10, 40))], score=[s_morale("target", -0.04), s_const(1.6)])])
L("lt2_praise", ["Everyone: {target} turned down a transfer to stay with us. THAT is loyalty.", "A round of applause for {target}. Loyal to the bone."])
L("lt2_cringe", ["...Please stop.", "Oh no. Everyone's looking at me."])
T("log.lt2_praise", "Ahmet publicly praised {target}'s 'loyalty'. {target} had no idea they'd been tested.")
scene("lt2_reward", noise=0.6, allow_absent=True, conditions=[c_present("boss")],
      effects=[say("boss", "lt2_praise"), say("target", "lt2_cringe", delay=2, when=[c_present("target")]), emote("target", "sweat", delay=2), favor("target", 6),
               each([rel("self", "target", "rivalry", 5)], exclude=["boss", "target"], where=[c_trait("self", "ambition", gt=0.6)]),
               log("log.lt2_praise", 4, "boss", who=["target"]), arc_end("loyal")])
L("lt2_friend", ["Ahmet says you might transfer?! Are you LEAVING?", "Tell me you're not moving to the far-east branch."])
L("lt2_staying", ["No! I was just being polite! I'm staying.", "Relax. I'm not going anywhere."])
L("lt2_thinking", ["...Maybe. Honestly, I'm tired.", "I don't know anymore."])
T("log.lt2_staying", "{friend} begged {target} not to transfer. {target} promised to stay.")
T("log.lt2_thinking", "{friend} asked {target} if they're leaving. {target} didn't say no. A job search has quietly begun.")
scene("lt2_friend", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), expr("actor", "sad", 4), say("actor", "lt2_friend", to="target")],
      outcomes=[out("stay", [say("target", "lt2_staying", to="actor", delay=1.8), rel("actor", "target", "friendship", 6, both=True), log("log.lt2_staying", 3, "friendship"),
                             arc_end("stayed")], score=[s_morale("target", 0.03), s_aff("target", "actor", 0.02)]),
                out("leave", [say("target", "lt2_thinking", to="actor", delay=1.8), plan("target", "job_search", "", heat=0.8), mood("actor", -8),
                              rumor("job_hunting", a="target", b="@ahmet", juicy=0.7, knowers=["friend"]), log("log.lt2_thinking", 4, "job"), arc_end("drifting_away")],
                    score=[s_morale("target", -0.04), s_const(1.4)])])
arc("loyalty_test", BIG, "suspect", cooldown_days=6, stages={
    "suspect": stage("lt2_suspect", "now", actor="boss", wait=(2, 8), ttl=60),
    "test": stage("lt2_test", "visit", actor="boss", target="target", ttl=90, fail="end:forgotten"),
    "reward": stage("lt2_reward", "place", actor="boss", place="announce", ttl=120, fail="end:loyal"),
    "friend_talk": stage("lt2_friend", "visit", actor="friend", target="target", ttl=90, fail="end:drifting_away"),
})


# =====================================================================
# 16. THE ACCIDENTAL DOUBLE DATE (J11: doctored couple photo + redirected lunch invitation)
# =====================================================================
title("double_date", "The Accidental Double Date", "{a} and {b} (the 'couple' from the photo) ended up at lunch with {c} and {d}.")
L("dd_sit", ["So... this is cosy.", "Is this a double date? Nobody told me this was a double date.", "Who invited whom, exactly?"])
L("dd_fun", ["Okay, this is actually the best lunch I've had all year.", "We should do this every week!"])
L("dd_awkward", ["*chews very loudly in silence*", "...Nice weather.", "So. The photo on the board, huh."])
T("log.dd_fun", "A redirected lunch invite turned into a double date with {a} and {b}, the 'couple' from the board photo. It was, somehow, great.")
T("log.dd_awkward", "A redirected lunch invite turned into a double date with {a} and {b}, the 'couple' from the photo. Nobody knew where to look.")
scene("dd_lunch", noise=0.6,
      effects=[each([say("self", "dd_sit", p=0.6, delay=0.8)], where=[c_zone("self", ["lounge"])], stagger=0.8)],
      outcomes=[out("fun", [each([say("self", "dd_fun", p=0.5, delay=2), mood("self", 10), emote("self", "cheer", delay=2)], where=[c_zone("self", ["lounge"])], stagger=0.6),
                            rel("a", "b", "friendship", 8, both=True), rel("c", "d", "friendship", 8, both=True), log("log.dd_fun", 4, "romance", who=["a", "b", "c", "d"]),
                            arc_next("photo_talk", wait=(20, 60))], score=[s_trait("a", "humor", 0.6), s_trait("c", "sociability", 0.6), s_trait("d", "sociability", 0.4)]),
                out("awkward", [each([say("self", "dd_awkward", p=0.5, delay=2), emote("self", "sweat", delay=2)], where=[c_zone("self", ["lounge"])], stagger=0.6),
                                log("log.dd_awkward", 4, "romance", who=["a", "b", "c", "d"]), arc_next("photo_talk", wait=(20, 60))], score=[s_const(0.8)])])
L("dd_talk", ["About that photo. You know it's fake, right?", "So everyone thinks we're a couple now."])
L("dd_maybe", ["...Would it be so bad if it wasn't fake?", "I mean... we could make it less fake."])
L("dd_fake", ["Completely fake. I'm finding whoever did it.", "Fake. Obviously. Right? Right."])
T("log.dd_maybe", "{a} and {b} talked about the fake couple photo — and decided they don't mind if it's not that fake.")
T("log.dd_fake", "{a} and {b} agreed the couple photo was fake. Now they want to know who made it.")
scene("dd_photo_talk", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "dd_talk", to="target")],
      outcomes=[out("maybe", [say("target", "dd_maybe", to="actor", delay=1.8), emote("target", "love", delay=1.8), rel("actor", "target", "romance", 14, both=True),
                              log("log.dd_maybe", 4, "romance"), arc_next("verdict", days=1)], score=[s_rel("target", "actor", "romance", 0.04), s_aff("target", "actor", 0.01)]),
                out("fake", [say("target", "dd_fake", to="actor", delay=1.8), plan("actor", "expose", "", heat=0.4), log("log.dd_fake", 3, "romance"), arc_end("just_friends")],
                    score=[s_const(1.0)])])
L("dd_official", ["So. Lunch again? Just us this time?", "I'm taking the photo down. We'll take a real one."])
L("dd_yes", ["Yes. Just us.", "Deal. A real one."])
T("log.dd_official", "{a} and {b} took the fake couple photo down — and went to lunch together. Just the two of them.")
scene("dd_verdict", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "dd_official", to="target"), say("target", "dd_yes", to="actor", delay=1.8), emote("actor", "love", delay=1.8),
               bond("actor", "target", "romance"), unpin("couple"), log("log.dd_official", 5, "romance"), arc_end("real_couple")])
arc("double_date", BIG, "lunch", cooldown_days=5, stages={
    "lunch": stage("dd_lunch", "gather", actor="c", area="lounge", need=3, ttl=60, window=("11:40", "14:30"), fail="end:no_lunch", who=["a", "b", "c", "d"], must=["c"]),
    "photo_talk": stage("dd_photo_talk", "visit", actor="a", target="b", ttl=90, fail="end:just_friends"),
    "verdict": stage("dd_verdict", "visit", actor="a", target="b", ttl=120, fail="end:never_asked"),
})


# =====================================================================
# 17. THE SPEAKERPHONE CONFESSION (J12: speaker mode + "we need to talk" text)
# =====================================================================
title("speaker_confession", "The Speakerphone Confession", "{owner}'s most private phone call is about to go very public.")
L("spc_ring", ["*ring ring* — on SPEAKER — 'You said we need to talk?'", "*phone on speaker* '{owner}? You wanted to talk?'"])
L("spc_blurt", ["I— um— I've liked you for ages, okay?! There. I said it.", "I like you! A lot! ...Why is everyone looking at me?"])
L("spc_hangup", ["*panicked hang-up* ...Wrong number! Ha! Ha.", "*slams the phone down* That was... a client."])
T("log.spc_blurt", "{crush} called {owner} back — on speakerphone. Half the office heard {owner} confess their feelings for {crush}.")
T("log.spc_hangup", "{crush} called {owner} back on speakerphone. {owner} panicked and hung up. Everyone heard enough to guess.")
scene("spc_call", noise=0.6, allow_absent=True, conditions=[c_present("owner")],
      effects=[sfx("phone"), act("owner", "phone", dur=6), say("owner", "spc_ring", delay=1)],
      outcomes=[out("blurt", [say("owner", "spc_blurt", delay=3), expr("owner", "surprised", 6, delay=3), emote("owner", "love", delay=3),
                              rumor("crush", a="owner", b="crush", juicy=0.8, knowers=[]), witness([learn("self", "$rumor", c=0.95), emote("self", "exclaim", delay=3.6)], near="owner", r=6, exclude=["owner", "crush"]),
                              learn("crush", "$rumor", c=1.0), log("log.spc_blurt", 5, "romance", who=["owner", "crush"]), arc_next("tease", wait=(5, 20))],
                    score=[s_trait("owner", "honesty", 1.0), s_rel("owner", "crush", "romance", 0.02)]),
                out("hangup", [say("owner", "spc_hangup", delay=3), emote("owner", "sweat", delay=3), rumor("crush", a="owner", b="crush", juicy=0.6, knowers=[]),
                               witness([learn("self", "$rumor", c=0.6)], near="owner", r=6, exclude=["owner", "crush"]), log("log.spc_hangup", 4, "romance", who=["owner", "crush"]),
                               arc_next("tease", wait=(5, 20))], score=[s_trait("owner", "cunning", 0.8), s_const(0.4)])])
L("spc_tease", ["Ooooh, {owner}! 'I've liked you for ages'!", "Heard your phone call, {owner}. Very romantic.", "*makes kissing noises at {owner}*"])
L("spc_tease_back", ["Laugh it up. I hope your phone's on speaker next.", "...I'm moving desks. To Antarctica."])
T("log.spc_tease", "{teaser} won't stop teasing {owner} about the speakerphone confession.")
scene("spc_tease", noise=0.8, allow_absent=True, conditions=[c_present("owner")],
      roles=[role("teaser", where=[c_present("self"), c_is("self", "ahmet", neg=True)], score=[s_trait("self", "humor", 1.0), s_trait("self", "gossip", 0.6), s_rand(0.3)],
                  exclude=["owner", "crush"], optional=True)],
      effects=[say("teaser", "spc_tease", to="owner", when=[c_filled("teaser")]), say("owner", "spc_tease_back", delay=1.8), expr("owner", "angry", 4, delay=1.8), stress("owner", 8),
               log("log.spc_tease", 3, "gossip", who=["teaser", "owner"]), arc_next("face", wait=(15, 45))])
L("spc_face", ["So... that phone call.", "I heard what you said. On the phone. Everybody did."])
L("spc_mutual", ["...I like you too. Speakerphone and all.", "For the record? Same."])
L("spc_no", ["You're sweet. But I don't feel that way. I'm sorry.", "I'm flattered. Really. But no."])
L("spc_friends", ["Let's pretend it never happened and get a coffee?", "Okay, that was the most embarrassing thing I've ever witnessed. Coffee?"])
T("log.spc_mutual", "{crush} told {owner} the feeling is mutual. The speakerphone did them a favour.")
T("log.spc_no", "{crush} gently turned {owner} down after the speakerphone confession.")
T("log.spc_friends", "{crush} and {owner} laughed off the speakerphone confession over coffee.")
scene("spc_face", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 6), say("actor", "spc_face", to="target"), emote("target", "sweat")],
      outcomes=[out("mutual", [say("actor", "spc_mutual", to="target", delay=1.8), emote("target", "love", delay=1.8), bond("actor", "target", "romance"),
                               rel("actor", "target", "romance", 15, both=True), log("log.spc_mutual", 5, "romance"), arc_end("together")],
                    score=[s_rel("actor", "target", "romance", 0.05), s_aff("actor", "target", 0.01)]),
                out("no", [say("actor", "spc_no", to="target", delay=1.8), expr("target", "sad", 8, delay=1.8), mood("target", -18), rel("target", "actor", "romance", -15),
                           log("log.spc_no", 4, "romance"), arc_end("rejected")], score=[s_const(1.0)]),
                out("friends", [say("actor", "spc_friends", to="target", delay=1.8), rel("actor", "target", "friendship", 10, both=True), log("log.spc_friends", 3, "friendship"),
                                arc_end("friends")], score=[s_trait("actor", "humor", 1.0)])])
arc("speaker_confession", BIG, "call", cooldown_days=5, stages={
    "call": stage("spc_call", "now", actor="owner", wait=(2, 6), ttl=60),
    "tease": stage("spc_tease", "now", actor="owner", ttl=90, fail="face"),
    "face": stage("spc_face", "visit", actor="crush", target="owner", ttl=120, fail="end:avoided"),
})


# =====================================================================
# 18. THE CLIENT MELTDOWN (J13: client visit + broken projector)
# =====================================================================
title("client_meltdown", "The Client Meltdown", "The client is on the way. The projector is dead. {presenter} is up.")
L("cm_panic", ["The CLIENT is coming and the projector is DEAD?!", "Who broke the projector? TODAY of all days?!"])
T("log.cm_panic", "Ahmet discovered the projector is dead — an hour before the 'important client'. {presenter} is presenting. Panic.")
scene("cm_panic", noise=0.6, allow_absent=True, conditions=[c_present("boss")],
      effects=[expr("boss", "angry", 6), say("boss", "cm_panic"), sfx("gasp"), stress("presenter", 15), stress("boss", 10),
               log("log.cm_panic", 4, "meeting", who=["presenter"]), arc_next("fix", wait=(2, 8))])
L("cm_fixing", ["Hold on... I've got a spare cable... somewhere.", "Okay projector. It's you and me."])
L("cm_fixed", ["AND... we have light! You're welcome.", "Fixed. Don't touch it. Don't breathe on it."])
L("cm_dead", ["It's dead, Jim. Completely dead.", "Nope. It smells like burning. That's never good."])
T("log.cm_fixed", "{it} brought the projector back from the dead with minutes to spare.")
T("log.cm_dead", "{it} declared the projector officially dead. {presenter} will have to improvise.")
scene("cm_fix", noise=0.8, allow_absent=True, conditions=[c_present("it")],
      effects=[say("it", "cm_fixing"), emote("it", "sweat")],
      outcomes=[out("fixed", [say("it", "cm_fixed", delay=3), emote("it", "ok", delay=3), oset("projector.broken", False), rel("presenter", "it", "friendship", 8),
                              log("log.cm_fixed", 3, "help", who=["it"]), arc_next("pitch", wait=(10, 30))], score=[s_trait("it", "diligence", 1.0), s_const(0.3)]),
                out("dead", [say("it", "cm_dead", delay=3), log("log.cm_dead", 3, "malfunction", who=["it", "presenter"]), arc_next("improv", wait=(10, 30))], score=[s_const(0.8)])])
L("cm_present", ["And as you can see on slide four...", "Our numbers this quarter speak for themselves."])
L("cm_client_happy", ["The client signed! On the spot!", "They loved it. We got the contract!"])
L("cm_client_meh", ["...The client said they'll 'think about it'.", "They left early. That's bad, right? That's bad."])
T("log.cm_won", "{presenter} nailed the client presentation. The client signed. Ahmet is beaming.")
T("log.cm_lost", "{presenter}'s client presentation fell flat. The client left 'to think about it'.")
scene("cm_pitch", noise=0.6,
      effects=[say("presenter", "cm_present"), emote("presenter", "idea")],
      outcomes=[out("won", [say("boss", "cm_client_happy", delay=3), each([emote("self", "cheer", delay=3), mood("self", 8)], where=[c_zone("self", ["meeting"])]),
                            favor("presenter", 14), morale("presenter", 8), log("log.cm_won", 4, "work", who=["presenter"]), arc_end("won_client")],
                    score=[s_trait("presenter", "diligence", 1.0), s_mood("presenter", 0.02)]),
                out("lost", [say("boss", "cm_client_meh", delay=3), expr("boss", "sad", 5, delay=3), favor("presenter", -6), log("log.cm_lost", 4, "work", who=["presenter"]),
                             arc_end("lost_client")], score=[s_stress("presenter", 0.02), s_const(0.3)])])
L("cm_improv", ["No projector? No problem. *grabs a marker* Picture this...", "Forget the slides. Let me draw you the future. *draws a very wobbly graph*"])
L("cm_legend", ["The client bought the WHOLE thing. Because of a stick-figure drawing.", "They said it was 'refreshingly human'. We got it!"])
L("cm_disaster", ["The client asked if the drawing was of a horse. It was our sales graph.", "...They left. With their coats. Quickly."])
T("log.cm_legend", "With no projector, {presenter} improvised with a marker and stick figures — and won the client. Office legend.")
T("log.cm_disaster", "With no projector, {presenter} tried to improvise with a marker. The client thought the sales graph was a horse.")
scene("cm_improv", noise=0.6,
      effects=[say("presenter", "cm_improv"), emote("presenter", "idea")],
      outcomes=[out("legend", [say("boss", "cm_legend", delay=3), each([emote("self", "cheer", delay=3)], where=[c_zone("self", ["meeting"])]), favor("presenter", 18),
                               rel("boss", "presenter", "respect", 15), mem("presenter", "boss", "praised", 0.7, 0.9, "mem.praised", 3), log("log.cm_legend", 5, "work", who=["presenter"]),
                               arc_end("improv_hero")], score=[s_trait("presenter", "humor", 1.0), s_trait("presenter", "sociability", 0.6)]),
                out("disaster", [say("boss", "cm_disaster", delay=3), expr("boss", "angry", 6, delay=3), favor("presenter", -10), stress("presenter", 12),
                                 call("scold", target="presenter", reason="general", prio=66, delay=6), log("log.cm_disaster", 4, "boss", who=["presenter"]), arc_end("disaster")],
                    score=[s_stress("presenter", 0.02), s_const(0.5)])])
arc("client_meltdown", BIG, "panic", cooldown_days=6, stages={
    "panic": stage("cm_panic", "now", actor="boss", wait=(1, 4), ttl=60),
    "fix": stage("cm_fix", "place", actor="it", place="m2", ttl=60, fail="improv"),
    "pitch": stage("cm_pitch", "gather", actor="presenter", area="meeting", need=2, ttl=60, fail="end:client_left", who=["presenter", "boss", "it"], must=["presenter"]),
    "improv": stage("cm_improv", "gather", actor="presenter", area="meeting", need=2, ttl=60, fail="end:client_left", who=["presenter", "boss"], must=["presenter"]),
})


# =====================================================================
# 19. THE GREAT EVACUATION (J14: fire alarm + jammed front door)
# =====================================================================
title("evacuation", "The Great Evacuation", "Fire alarm. Front door jammed. Everyone is stuck at reception.")
L("ev_stuck", ["THE DOOR WON'T OPEN!", "We're TRAPPED!", "Why is the door locked during a FIRE ALARM?!"])
L("ev_panic", ["We're all going to— okay I'm calm. I'm calm. I'M NOT CALM.", "Is this how it ends? At reception?"])
L("ev_lead", ["Everyone! Calm down! Fire exit's by the archive. Follow me.", "Listen to me. Nobody panic. There's another way out."])
T("log.ev_hero", "Everyone got stuck at the jammed front door during the fire alarm. {hero} kept calm and took charge.")
T("log.ev_chaos", "Everyone got stuck at the jammed front door during the fire alarm. Total chaos. {panicker} screamed the loudest.")
scene("ev_stuck", noise=0.6,
      effects=[each([say("self", "ev_stuck", p=0.5, delay=0.6), stress("self", 10), emote("self", "exclaim")], where=[c_zone("self", ["reception"])], stagger=0.4),
               say("panicker", "ev_panic", delay=2, when=[c_present("panicker")]), emote("panicker", "sweat", delay=2)],
      outcomes=[out("hero", [say("hero", "ev_lead", delay=3.6), emote("hero", "idea", delay=3.6), log("log.ev_hero", 4, "drama", who=["hero"]), arc_next("break_out", wait=(1, 4))],
                    score=[s_trait("hero", "diligence", 0.8), s_trait("hero", "empathy", 0.6), s_stress("hero", -0.01)]),
                out("chaos", [each([stress("self", 6)], where=[c_zone("self", ["reception"])]), log("log.ev_chaos", 4, "drama", who=["panicker"]), arc_next("blame", wait=(10, 30))],
                    score=[s_stress("panicker", 0.02), s_const(0.3)])])
L("ev_unjam", ["*shoulder-barges the door* ...It's open! Everyone out— oh, the alarm stopped.", "Got it! The latch was jammed. Out, everyone. Calmly."])
T("log.ev_unjam", "{hero} unjammed the front door. Everyone filed out — just as the alarm stopped. Applause anyway.")
scene("ev_break_out", noise=0.6, allow_absent=True, conditions=[c_present("hero")],
      effects=[sfx("thump"), fx("shake", "hero"), say("hero", "ev_unjam", delay=1), oset("front_door.jammed", False),
               each([rel("self", "hero", "respect", 10), stress("self", -6)], exclude=["hero"], where=[c_zone("self", ["reception"])]),
               log("log.ev_unjam", 4, "help", who=["hero"]), arc_next("debrief", wait=(15, 40))])
L("ev_who", ["WHO jammed the front door? That's a SAFETY issue!", "Someone jammed that door. I want a name."])
L("ev_scapegoat", ["{scapegoat}, you were the last one by the door. Explain.", "It was you, wasn't it, {scapegoat}?"])
L("ev_not_me", ["Me?! I was trying to GET OUT like everyone else!", "I didn't touch it! I swear!"])
T("log.ev_scapegoat", "Ahmet blamed {scapegoat} for the jammed front door. {scapegoat} had nothing to do with it.")
scene("ev_blame", noise=0.6, allow_absent=True, conditions=[c_present("boss")],
      roles=[role("scapegoat", where=[c_present("self"), c_is("self", "ahmet", neg=True)], score=[s_rel("@ahmet", "self", "trust", -0.02), s_rand(0.8)], exclude=["boss"])],
      effects=[expr("boss", "angry", 6), say("boss", "ev_who"), say("boss", "ev_scapegoat", delay=2), say("scapegoat", "ev_not_me", delay=3.8), favor("scapegoat", -8),
               rel("scapegoat", "boss", "resentment", 12), mem("scapegoat", "boss", "falsely_accused", -0.7, 0.9, "mem.falsely_accused", 3), stat("blames"),
               log("log.ev_scapegoat", 4, "blame", who=["scapegoat"]), arc_end("scapegoat")])
L("ev_praise", ["Today, {hero} kept everyone safe. That's leadership.", "Let's hear it for {hero}. Cool head in a crisis."])
T("log.ev_praise", "Ahmet praised {hero} in front of everyone for handling the evacuation.")
scene("ev_debrief", noise=0.6, allow_absent=True, conditions=[c_present("boss")],
      effects=[say("boss", "ev_praise"), emote("hero", "cheer", delay=1.6), favor("hero", 12), morale("hero", 6), stat("praises"), log("log.ev_praise", 4, "boss", who=["hero"]),
               arc_end("hero")])
arc("evacuation", BIG, "stuck", cooldown_days=6, stages={
    "stuck": stage("ev_stuck", "gather", actor="hero", area="reception", need=3, ttl=40, fail="blame"),
    "break_out": stage("ev_break_out", "place", actor="hero", place="hr1", ttl=40, fail="blame"),
    "blame": stage("ev_blame", "now", actor="boss", ttl=120, fail="end:forgotten"),
    "debrief": stage("ev_debrief", "place", actor="boss", place="announce", ttl=120, fail="end:hero"),
})


# =====================================================================
# 20. THE FRIDGE WAR (J15: emptied fridge + passive-aggressive note signed by someone)
# =====================================================================
title("fridge_war", "The Fridge War", "{victim} thinks {signer} threw out everyone's lunch.")
L("fw_outrage", ["My lunch is GONE and there's a note signed {signer}?!", "'Stop stealing my yoghurt — {signer}'?! You threw out EVERYTHING?!"])
T("log.fw_outrage", "{victim} found the fridge empty and a note 'signed' by {signer}. {victim} is convinced {signer} binned everyone's lunch.")
scene("fw_outrage", noise=0.6, allow_absent=True, conditions=[c_present("victim")],
      effects=[expr("victim", "angry", 7), emote("victim", "anger"), say("victim", "fw_outrage"), mood("victim", -12), rel("victim", "signer", "resentment", 15),
               rumor("prank", a="signer", b="victim", juicy=0.6, truth=False, knowers=["victim"], origin="victim"),
               witness([learn("self", "$rumor", frm="victim")], near="victim", r=5, exclude=["victim", "signer"]),
               log("log.fw_outrage", 3, "conflict", who=["victim", "signer"]), arc_next("counter", wait=(5, 20))])
L("fw_counter", ["*writes a VERY long counter-note in capital letters*", "'DEAR {signer}: SOME OF US HAVE FEELINGS. AND LUNCHES.' *sticks it on the fridge*"])
T("log.fw_counter", "{victim} stuck a furious counter-note on the fridge, addressed to {signer}. The fridge war has begun.")
scene("fw_counter", noise=0.6, allow_absent=True, conditions=[c_present("victim")],
      effects=[say("victim", "fw_counter"), emote("victim", "anger"), oset("fridge.note2", "%victim"), log("log.fw_counter", 3, "conflict", who=["victim"]), arc_next("confront", wait=(10, 40))])
L("fw_accuse", ["You threw out my lunch. And then you LECTURED me about yoghurt?", "Explain the note, {signer}."])
L("fw_innocent", ["I didn't write that note! I don't even eat yoghurt!", "That's not my handwriting! Someone's setting us up!"])
L("fw_snap", ["Maybe if people labelled their food, it wouldn't get thrown out!", "Oh, so now I'm the fridge police? Fine. I'm the fridge police."])
T("log.fw_ghost", "{victim} confronted {signer} over the fridge note. {signer} proved it wasn't their handwriting. They now both suspect a third party.")
T("log.fw_feud", "{victim} confronted {signer} over the fridge note. {signer} snapped back. The kitchen is now a war zone.")
scene("fw_confront", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 6), expr("actor", "angry", 5), say("actor", "fw_accuse", to="target")],
      outcomes=[out("innocent", [say("target", "fw_innocent", to="actor", delay=1.8), rel("actor", "target", "resentment", -12), rel("actor", "target", "friendship", 5),
                                 call("ghost_theory"), log("log.fw_ghost", 3, "ghost"), arc_end("ghost_blamed")],
                    score=[s_trait("target", "honesty", 1.0), s_trait("target", "empathy", 0.5)]),
                out("snap", [say("target", "fw_snap", to="actor", delay=1.8), expr("target", "angry", 5, delay=1.8), sfx("argue", delay=1.8), bond("actor", "target", "feud"), storm("actor", delay=3.2),
                             stat("arguments"), log("log.fw_feud", 4, "conflict"), arc_end("feud")], score=[s_trait("target", "temper", 1.0), s_const(0.3)])])
arc("fridge_war", BIG, "outrage", cooldown_days=5, stages={
    "outrage": stage("fw_outrage", "now", actor="victim", wait=(2, 8), ttl=60),
    "counter": stage("fw_counter", "place", actor="victim", place="fridge", ttl=60, fail="confront"),
    "confront": stage("fw_confront", "visit", actor="victim", target="signer", ttl=90, fail="end:cold_war"),
})


# =====================================================================
# 21. THE FAREWELL THAT WASN'T (J16: "I quit" auto-reply + resignation draft on show)
# =====================================================================
title("farewell_mixup", "The Farewell That Wasn't", "Everyone thinks {leaver} is quitting. {leaver} isn't. Probably.")
L("fm_news", ["Did you hear? {leaver} is QUITTING. I saw the letter!", "{leaver}'s leaving! The auto-reply says 'I quit'!"])
T("log.fm_news", "{organiser} told everyone that {leaver} is quitting — the resignation letter and the 'I quit' auto-reply were proof enough.")
scene("fm_news", noise=0.6, allow_absent=True, conditions=[c_present("organiser")],
      effects=[emote("organiser", "whisper"), say("organiser", "fm_news"), rumor("resigning", a="leaver", b="organiser", juicy=0.8, truth=False, knowers=["organiser"], origin="organiser"),
               each([learn("self", "$rumor", frm="organiser", c=0.8)], exclude=["organiser", "leaver"], where=[c_near("self", "organiser", 7)]),
               log("log.fm_news", 4, "job", who=["organiser", "leaver"]), arc_next("collection", wait=(10, 30))])
L("fm_collect", ["We're collecting for {leaver}'s farewell gift. Chip in?", "Sign the card! For {leaver}! Don't let them see!"])
L("fm_chip_in", ["Of course. I'll miss {leaver}.", "Here. Get something nice.", "I can't believe they're leaving."])
T("log.fm_collect", "{organiser} is secretly collecting money for {leaver}'s farewell gift. Everyone signed the card.")
scene("fm_collection", noise=0.6, allow_absent=True, conditions=[c_present("organiser")],
      effects=[say("organiser", "fm_collect"), each([say("self", "fm_chip_in", p=0.5, delay=1.4), rel("self", "leaver", "friendship", 3)], exclude=["organiser", "leaver"],
                                                     where=[c_near("self", "organiser", 7)], stagger=0.6),
               log("log.fm_collect", 3, "celebration", who=["organiser"]), arc_next("counter", wait=(15, 40))])
L("fm_offer", ["Don't go, {leaver}. Whatever they're offering — I'll match it.", "{leaver}. Before you leave... what would it take to keep you?"])
L("fm_confused", ["...Leave? I'm not leaving. Who said I'm leaving?", "Wait. What offer? I'm not going anywhere!"])
L("fm_cunning", ["...Well. A raise would be a good start.", "Hm. A bigger desk. And a raise. Then we'll talk."])
T("log.fm_confused", "Ahmet begged {leaver} not to quit. {leaver} had no idea what he was talking about.")
T("log.fm_cunning", "Ahmet begged {leaver} not to quit. {leaver} didn't correct him — and negotiated a raise.")
scene("fm_counter", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 6), say("actor", "fm_offer", to="target")],
      outcomes=[out("confused", [say("target", "fm_confused", to="actor", delay=1.8), emote("target", "question", delay=1.8), setv("played", "no"), rel("actor", "target", "trust", 6),
                                 log("log.fm_confused", 4, "boss"), arc_next("party", wait=(15, 40))], score=[s_trait("target", "honesty", 1.0)]),
                out("cunning", [say("target", "fm_cunning", to="actor", delay=1.8), emote("target", "idea", delay=1.8), setv("played", "yes"), favor("target", 8), morale("target", 12),
                                log("log.fm_cunning", 4, "boss"), arc_next("party", wait=(15, 40))], score=[s_trait("target", "cunning", 1.2), s_trait("target", "ambition", 0.5)])])
L("fm_surprise", ["SURPRISE! We'll miss you, {leaver}!", "Farewell, {leaver}! *pops a party popper*"])
L("fm_not_leaving", ["I'M NOT LEAVING! But... thank you? Is there cake?", "...I'm not quitting. But I'm keeping the card."])
L("fm_staying_raise", ["Thanks, everyone! ...Small update: I'm staying. With a raise.", "Oh! About that. I'm staying. Ahmet made me an offer."])
L("fm_outrage", ["We paid for a GIFT!", "You KNEW and you let us collect?!"])
T("log.fm_not_leaving", "The office threw {leaver} a surprise farewell party. {leaver} isn't leaving. They kept the cake anyway.")
T("log.fm_played", "The office threw {leaver} a farewell party — and {leaver} announced they're staying, with a fresh raise. People want their gift money back.")
scene("fm_party", noise=0.6,
      effects=[say("organiser", "fm_surprise"), sfx("pop"), each([emote("self", "cheer"), mood("self", 6)], where=[c_zone("self", ["kitchen"])], stagger=0.3)],
      outcomes=[out("honest", [say("leaver", "fm_not_leaving", delay=2.4), emote("leaver", "sweat", delay=2.4), each([say("self", "gen_laugh", p=0.4, delay=3.6)], exclude=["leaver"],
                                                                                                                where=[c_zone("self", ["kitchen"])]),
                               each([debunk("$rumor", who=["self"], by="leaver")], exclude=["leaver"], where=[c_zone("self", ["kitchen"])]), log("log.fm_not_leaving", 4, "celebration", who=["leaver"]), arc_end("not_leaving")],
                    score=[s_const(1)], when=[c_var("played", eq="no")]),
                out("played", [say("leaver", "fm_staying_raise", delay=2.4), each([say("self", "fm_outrage", p=0.5, delay=3.8), rel("self", "leaver", "resentment", 8)], exclude=["leaver", "boss"],
                                                                                     where=[c_zone("self", ["kitchen"])]),
                               each([debunk("$rumor", who=["self"], by="leaver")], exclude=["leaver"], where=[c_zone("self", ["kitchen"])]), log("log.fm_played", 5, "drama", who=["leaver"]), arc_end("played_it")], score=[s_const(1)],
                    when=[c_var("played", eq="yes")]),
                out("plain", [say("leaver", "fm_not_leaving", delay=2.4), log("log.fm_not_leaving", 4, "celebration", who=["leaver"]), arc_end("not_leaving")], score=[s_const(0.1)])])
L("gen_laugh", ["HAHAHA!", "Oh, that's priceless.", "*wheezes*", "I can't breathe!"])
arc("farewell_mixup", BIG, "news", cooldown_days=6, stages={
    "news": stage("fm_news", "now", actor="organiser", wait=(2, 8), ttl=60),
    "collection": stage("fm_collection", "now", actor="organiser", ttl=90, fail="counter"),
    "counter": stage("fm_counter", "visit", actor="boss", target="leaver", ttl=120, fail="party"),
    "party": stage("fm_party", "gather", actor="organiser", area="kitchen", need=3, ttl=60, window=("10:00", "17:00"), fail="end:fizzled", must=["organiser", "leaver"]),
})


TEST_CASTS = {
    "coffee_date_mixup": {"sender": "mert", "reader": "ece", "crush": "ceren"},
    "leak_scandal": {"leaker": "deniz", "finder": "zeynep", "boss": "ahmet", "it": "burak"},
    "loyalty_test": {"target": "selin", "boss": "ahmet", "friend": "zeynep"},
    "double_date": {"a": "mert", "b": "ceren", "c": "selin", "d": "burak"},
    "speaker_confession": {"owner": "mert", "crush": "ceren"},
    "client_meltdown": {"presenter": "selin", "boss": "ahmet", "it": "burak"},
    "evacuation": {"hero": "selin", "panicker": "ece", "boss": "ahmet"},
    "fridge_war": {"victim": "burak", "signer": "deniz"},
    "farewell_mixup": {"leaver": "burak", "organiser": "ceren", "boss": "ahmet"},
}
for _a in _sh.A:
    if _a["id"] in TEST_CASTS:
        _a["test"] = TEST_CASTS[_a["id"]]
