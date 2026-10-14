# More things people do on their own (initiatives). Each one is picked by the
# StoryDirector from who is free, their traits, relationships, memories and plans;
# each makes someone walk somewhere, say something and leave a trace (relations,
# memories, rumours, plans). Every initiative carries a "domain" for the reports.
from story_helpers import *  # noqa: F401,F403
from story_helpers import initiative, scene
from iv_helpers import S_, L, oset, trap  # noqa: F811  (guarded: never overwrite existing text)

NB = [c_is("self", "ahmet", neg=True)]


# ======================================================================= SOCIALISING
# --- lunch crew: someone rounds up their friends for lunch together
L("na_lunch_round", ["Lunch? Kitchen table, five minutes.", "Who's hungry? Kitchen table. Now."])
L("na_lunch_chat", ["So then the waiter says—", "Did anyone watch the match?", "Pass the ayran, please."])
S_("log.na_lunch_crew", "{actor}, {target} and {friend} had lunch together at the kitchen table. A little clique is forming.")
S_("log.na_lunch_pair", "{actor} and {target} had lunch together at the kitchen table.")
initiative("na_lunch_crew", "small", domain="socializing", cooldown_days=1,
    roles=[actor([c_time(after="11:50", before="13:00"), c_trait("self", "sociability", gt=0.5)], [s_trait("self", "sociability", 1.0), s_rand(0.4)]),
           by_fn("target", "best_of", of="actor", lim=15),
           by_fn("friend", "best_of", of="target", lim=0, exclude=["actor", "target"], optional=True)],
    effects=[say("actor", "na_lunch_round", to="target"), emote("actor", "wave"),
             meetup("na_lunch_scene", who=("actor", "target", "friend"), area="kitchen", roles={"friend": "friend"}, ttl=40, need=2)])
scene("na_lunch_scene", noise=0.4,
    effects=[hold(["actor", "target"], 8), each([say("self", "na_lunch_chat", p=0.6, delay=1.0), mood("self", 6)],
                                                where=[c_zone("self", ["kitchen"]), c_any(c_same("self", "actor"), c_same("self", "target"), c_same("self", "friend"))], stagger=1.2),
             rel("actor", "target", "friendship", 5, both=True), rel("actor", "friend", "friendship", 4, both=True, when=[c_filled("friend")]),
             log("log.na_lunch_crew", 1, "friendship", who=["actor", "target"], when=[c_filled("friend"), c_zone("friend", ["kitchen"])]),
             log("log.na_lunch_pair", 1, "friendship", who=["actor", "target"], when=[c_any(c_not(c_filled("friend")), c_zone("friend", ["kitchen"], neg=True))])])

# --- weekend story at the coffee machine
L("na_weekend", ["So this weekend I accidentally joined a marathon.", "Long story short: I'm banned from that IKEA.", "My cat learned to open the fridge. We have a problem."])
L("na_weekend_laugh", ["HAHA! No way!", "Stop it. You did NOT.", "That's the best thing I've heard all week."])
L("na_weekend_bored", ["...Fascinating.", "Mm-hm. Mm-hm. Anyway—", "*nods politely, checks phone*"])
S_("log.na_weekend_hit", "{actor}'s weekend story had {target} in tears of laughter by the coffee machine.")
S_("log.na_weekend_flop", "{actor} told {target} a very long weekend story. {target} survived it.")
initiative("na_weekend_story", "small", domain="socializing", cooldown=180, max_day=2,
    roles=[actor([c_time(before="11:30"), c_trait("self", "humor", gt=0.4)], [s_trait("self", "humor", 0.8), s_trait("self", "sociability", 0.6)]),
           role("target", where=[c_avail("self")], score=[s_aff("actor", "self", 0.02), s_rand(0.5)])],
    effects=[meetup("na_weekend_scene", area="kitchen", ttl=30)])
scene("na_weekend_scene", noise=0.6,
    effects=[hold(["actor", "target"], 5), say("actor", "na_weekend", to="target")],
    outcomes=[out("hit", [say("target", "na_weekend_laugh", to="actor", delay=1.8), emote("target", "cheer", delay=1.8), rel("target", "actor", "friendship", 6), mood("target", 6),
                          log("log.na_weekend_hit", 1, "friendship")], score=[s_trait("actor", "humor", 1.2), s_trait("target", "humor", 0.6)]),
              out("flop", [say("target", "na_weekend_bored", to="actor", delay=1.8), rel("target", "actor", "respect", -2), log("log.na_weekend_flop", 1, "friendship")],
                  score=[s_const(0.6)])])

# --- phone photos
L("na_photo_show", ["Look! Look at this face! *shows a phone full of cat photos*", "Okay, one more photo. Just one. *shows forty*"])
L("na_photo_aww", ["Awwww! I need one!", "That's the cutest thing I've ever seen."])
S_("log.na_photos", "{actor} showed {target} approximately three hundred pet photos. {target} loved every one.")
initiative("na_photo_share", "small", domain="socializing", cooldown=200, max_day=1,
    roles=[actor([c_mood("self", gt=10)], [s_trait("self", "sociability", 0.8), s_mood("self", 0.02)]), by_fn("target", "best_of", of="actor", lim=10)],
    effects=[visit("actor", "target", "na_photo_scene", prio=50, ttl=30)])
scene("na_photo_scene", noise=0.4, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), act("actor", "phone", dur=4), say("actor", "na_photo_show", to="target"), say("target", "na_photo_aww", to="actor", delay=1.6),
             emote("target", "love", delay=1.6), rel("target", "actor", "friendship", 4), stress("target", -4), log("log.na_photos", 1, "friendship")])


# ======================================================================= RIVALRY
# --- one-upmanship
L("na_brag", ["Closed three deals before lunch. Just saying.", "Ahmet called my report 'flawless'. His word."])
L("na_counter", ["Three? Cute. I did four. Yesterday.", "Funny, he called mine 'exemplary'. That's better than flawless."])
S_("log.na_oneup", "{actor} and {target} had a loud contest about who works harder. Nobody won. Everyone heard.")
initiative("na_one_upmanship", "small", domain="rivalry", cooldown_days=1,
    roles=[actor([c_trait("self", "ambition", gt=0.55)], [s_trait("self", "ambition", 1.0)]), by_fn("target", "rival_of", of="actor", lim=12, where=[c_avail("self")])],
    effects=[visit("actor", "target", "na_oneup_scene", prio=52, ttl=30)])
scene("na_oneup_scene", noise=0.6, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), expr("actor", "happy", 3), say("actor", "na_brag", to="target"), say("target", "na_counter", to="actor", delay=1.8),
             expr("target", "angry", 3, delay=1.8), rel("actor", "target", "rivalry", 6, both=True), witness([emote("self", "sweat", delay=2)], near="actor", r=4.5),
             log("log.na_oneup", 2, "rivalry")])

# --- telling the boss about a rival's mistake (high rivalry)
L("na_snitch", ["Ahmet Bey, I don't like to say this, but {rival}'s report went out with errors.", "Small thing — {rival} missed the deadline again. Thought you should know."])
L("na_snitch_boss", ["Hm. Thank you. I'll look into it.", "Is that so? Interesting."])
L("na_snitch_caught", ["Did you just tell Ahmet about my report?!", "I heard that. Thanks a lot, {actor}."])
S_("log.na_snitch", "{actor} told Ahmet about {rival}'s mistake. Rivalry has a new weapon.")
S_("log.na_snitch_caught", "{rival} overheard {actor} reporting their mistake to Ahmet. That will not be forgotten.")
S_("mem.na_snitched", "{actor} ran to Ahmet about my mistake.")
initiative("na_report_rival", "medium", domain="rivalry", cooldown_days=2,
    roles=[actor([c_trait("self", "honesty", lt=0.75)] + NB, [s_trait("self", "ambition", 0.8), s_trait("self", "cunning", 0.6)]),
           by_fn("target", "rival_of", of="actor", lim=35)],
    conditions=[c_present("@ahmet"), c_rel("actor", "target", "rivalry", gt=35)],
    effects=[visit("actor", "@ahmet", "na_snitch_scene", prio=55, ttl=40, roles={"rival": "target"})])
scene("na_snitch_scene", noise=0.6, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), emote("actor", "whisper"), say("actor", "na_snitch", to="target"), say("target", "na_snitch_boss", to="actor", delay=1.8),
             favor("rival", -6), rel("target", "rival", "trust", -6), log("log.na_snitch", 2, "rivalry", who=["actor", "rival"])],
    outcomes=[out("caught", [say("rival", "na_snitch_caught", to="actor", delay=3.2), expr("rival", "angry", 6, delay=3.2), rel("rival", "actor", "resentment", 18),
                             rel("rival", "actor", "trust", -15), mem("rival", "actor", "snitched", -0.6, 0.9, "mem.na_snitched", 3), storm("rival", delay=4.5),
                             log("log.na_snitch_caught", 3, "conflict", who=["rival", "actor"])],
                  score=[s_const(5)], when=[c_near("rival", "actor", 6)]),
              out("unseen", [], score=[s_const(1)])])

# --- desk territory
L("na_territory", ["Is that YOUR stapler on MY side of the desk?", "Your plant is invading my keyboard."])
L("na_territory_back", ["Your side? Since when is there a side?", "The plant goes where the light is."])
S_("log.na_territory", "{actor} and {target} had a border dispute over a stapler.")
initiative("na_desk_territory", "small", domain="rivalry", cooldown_days=2,
    roles=[actor([c_stress("self", gt=25)] + NB, [s_stress("self", 0.02), s_trait("self", "temper", 0.6)]), by_fn("target", "worst_of", of="actor", lim=15, where=NB)],
    effects=[visit("actor", "target", "na_territory_scene", prio=50, ttl=30)])
scene("na_territory_scene", noise=0.6, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 4), expr("actor", "angry", 3), say("actor", "na_territory", to="target"), say("target", "na_territory_back", to="actor", delay=1.6),
             rel("actor", "target", "resentment", 4, both=True), log("log.na_territory", 1, "conflict")])


# ======================================================================= WORK & CAREER
# --- asking for a promotion directly
L("na_promo_ask", ["Ahmet Bey, I think I'm ready for the team lead role.", "I'd like to be considered for the promotion. Seriously considered."])
L("na_promo_maybe", ["...Keep doing what you're doing. We'll see at the next review.", "I've noticed your work. Give me a few weeks."])
L("na_promo_no", ["Not yet. You're not there yet.", "Ready? Let's talk again next year."])
S_("log.na_promo_maybe", "{actor} asked Ahmet straight out for a promotion. Ahmet didn't say no.")
S_("log.na_promo_no", "{actor} asked Ahmet straight out for a promotion. 'Not yet.'")
S_("mem.na_promo_no", "Ahmet turned down my request for a promotion.")
initiative("na_ask_promotion", "medium", domain="work_career", cooldown_days=3,
    roles=[actor([c_trait("self", "ambition", gt=0.7)] + NB, [s_trait("self", "ambition", 1.0), s_morale("self", 0.01)])],
    conditions=[c_present("@ahmet"), c_time(after="10:00", before="16:00")],
    effects=[visit("actor", "@ahmet", "na_promo_scene", prio=58, ttl=45)])
scene("na_promo_scene", noise=0.8, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 6), say("actor", "na_promo_ask", to="target")],
    outcomes=[out("maybe", [say("target", "na_promo_maybe", to="actor", delay=1.8), emote("actor", "cheer", delay=2.4), favor("actor", 4), morale("actor", 6),
                            plan("actor", "prove_self", "", heat=0.6), log("log.na_promo_maybe", 2, "promotion")],
                  score=[{"s": "favor", "who": "actor", "w": 0.04}, s_rel("target", "actor", "respect", 0.02)]),
              out("no", [say("target", "na_promo_no", to="actor", delay=1.8), expr("actor", "sad", 5, delay=1.8), morale("actor", -8), rel("actor", "target", "resentment", 6),
                         mem("actor", "target", "promo_denied", -0.5, 0.9, "mem.na_promo_no", 2), log("log.na_promo_no", 2, "promotion")], score=[s_const(1.2)])])

# --- volunteering for extra work
L("na_volunteer", ["I can take the Henderson file. I've got time.", "Need someone for the weekend report? I'll do it."])
L("na_volunteer_thanks", ["See? THAT's the attitude I want.", "Excellent. Thank you."])
S_("log.na_volunteer", "{actor} volunteered for extra work in front of Ahmet. A few colleagues rolled their eyes.")
initiative("na_volunteer", "small", domain="work_career", cooldown_days=2,
    roles=[actor([c_trait("self", "diligence", gt=0.65)] + NB, [s_trait("self", "diligence", 1.0), s_trait("self", "ambition", 0.5)])],
    conditions=[c_present("@ahmet")],
    effects=[visit("actor", "@ahmet", "na_volunteer_scene", prio=52, ttl=40)])
scene("na_volunteer_scene", noise=0.4, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 4), say("actor", "na_volunteer", to="target"), say("target", "na_volunteer_thanks", to="actor", delay=1.6), favor("actor", 5),
             work("actor", -6), stress("actor", 6), each([rel("self", "actor", "rivalry", 3)], exclude=["actor", "target"], where=[c_trait("self", "ambition", gt=0.6)]),
             log("log.na_volunteer", 1, "work")])

# --- teaching a shortcut
L("na_teach", ["Ctrl+Shift+L. Trust me. It filters everything.", "You do that by hand?! Let me show you something."])
L("na_teach_wow", ["...That just saved me two hours a week.", "WHAT. Where has this been all my life?"])
S_("log.na_teach", "{actor} showed {target} a spreadsheet shortcut. {target} looked at {actor} like a wizard.")
initiative("na_skill_share", "small", domain="helping", cooldown_days=1,
    roles=[actor([c_trait("self", "empathy", gt=0.45), c_trait("self", "diligence", gt=0.5)], [s_trait("self", "empathy", 0.8), s_trait("self", "diligence", 0.5)]),
           role("target", where=[c_avail("self"), c_stress("self", gt=20)] + NB, score=[s_stress("self", 0.02), s_aff("actor", "self", 0.01)])],
    effects=[go_desk("actor", "target", "na_teach_scene", prio=50, ttl=30)])
scene("na_teach_scene", noise=0.4, conditions=[c_present("target")],
    effects=[hold(["actor", "target"], 5), say("actor", "na_teach", to="target"), say("target", "na_teach_wow", to="actor", delay=1.8), emote("target", "idea", delay=1.8),
             work("target", 6), stress("target", -6), rel("target", "actor", "respect", 8), rel("target", "actor", "friendship", 4), stat("helps"),
             log("log.na_teach", 1, "help")])


# ======================================================================= FRIENDSHIP
# --- checking in on a stressed colleague
L("na_checkin", ["Hey. You okay? You look like you need a break.", "Rough day? Come get a tea with me."])
L("na_checkin_open", ["...Honestly? Not great. Thanks for asking.", "It's been a week. Tea sounds perfect."])
L("na_checkin_closed", ["I'm fine. Really. Just busy.", "Thanks, but I'm okay."])
S_("log.na_checkin", "{actor} noticed {target} was struggling and took them for a tea. {target} looked lighter afterwards.")
S_("mem.na_checkin", "{actor} checked on me when I was having a hard day.")
initiative("na_check_in", "small", domain="friendship", cooldown_days=1,
    roles=[actor([c_trait("self", "empathy", gt=0.6)], [s_trait("self", "empathy", 1.0)]),
           role("target", where=[c_avail("self"), c_stress("self", gt=30)], score=[s_stress("self", 0.03), s_aff("actor", "self", 0.01)])],
    effects=[visit("actor", "target", "na_checkin_scene", prio=54, ttl=35)])
scene("na_checkin_scene", noise=0.6, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), say("actor", "na_checkin", to="target")],
    outcomes=[out("open", [say("target", "na_checkin_open", to="actor", delay=1.8), stress("target", -14), mood("target", 8), rel("target", "actor", "friendship", 10),
                           rel("target", "actor", "trust", 8), mem("target", "actor", "supported", 0.6, 0.8, "mem.na_checkin", 2), log("log.na_checkin", 2, "friendship"),
                           meetup("na_tea_scene", area="kitchen", ttl=30, delay=2)], score=[s_aff("target", "actor", 0.03), s_trait("target", "sociability", 0.4)]),
              out("closed", [say("target", "na_checkin_closed", to="actor", delay=1.8), rel("target", "actor", "friendship", 2)], score=[s_trait("target", "temper", 0.6), s_const(0.3)])])
L("na_tea", ["*sips tea quietly*", "...This helps. Thanks.", "Same time tomorrow?"])
scene("na_tea_scene", noise=0.3, effects=[hold(["actor", "target"], 6), act("actor", "coffee", dur=5), act("target", "coffee", dur=5), say("target", "na_tea", delay=2),
                                          emote("target", "ok", delay=2)])

# --- a sincere compliment
L("na_compliment", ["Your presentation yesterday? Really good. I meant to say.", "I don't say it enough: you're great at this."])
L("na_compliment_thx", ["Oh! Thank you. That made my day.", "...Wow. Thanks. Really."])
S_("log.na_compliment", "{actor} paid {target} a genuine compliment. {target} is still smiling.")
initiative("na_compliment", "small", domain="friendship", cooldown=240, max_day=2,
    roles=[actor([c_trait("self", "empathy", gt=0.5), c_mood("self", gt=0)], [s_trait("self", "empathy", 0.8), s_mood("self", 0.02)]),
           by_fn("target", "best_of", of="actor", lim=5)],
    effects=[visit("actor", "target", "na_compliment_scene", prio=50, ttl=30)])
scene("na_compliment_scene", noise=0.3, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 4), say("actor", "na_compliment", to="target"), say("target", "na_compliment_thx", to="actor", delay=1.6),
             expr("target", "happy", 5, delay=1.6), mood("target", 10), rel("target", "actor", "friendship", 6), rel("target", "actor", "respect", 4),
             rel("target", "actor", "romance", 4, when=[c_rel("target", "actor", "romance", gt=25)]), log("log.na_compliment", 1, "friendship")])


# ======================================================================= ROMANCE
# --- an excuse to visit the crush's desk
L("na_excuse", ["Do you have a... stapler? I seem to have lost all of mine.", "Hey! Is this pen yours? No? ...Nice desk, by the way."])
L("na_excuse_smile", ["*smiles* Here. Keep it.", "Ha. Sure. Come by any time."])
L("na_excuse_oblivious", ["Stapler's in the supply room.", "Nope. Not my pen."])
S_("log.na_excuse_hit", "{actor} invented a reason to visit {target}'s desk. {target} smiled. Progress.")
S_("log.na_excuse_miss", "{actor} invented a reason to visit {target}'s desk. {target} didn't notice a thing.")
initiative("na_desk_excuse", "small", domain="romance", cooldown=200, max_day=1,
    roles=[actor([{"c": "picks", "fn": "crush_of", "of": "self"}], [s_trait("self", "sociability", -0.3), s_const(0.5)]), by_fn("target", "crush_of", of="actor")],
    conditions=[c_rel("actor", "target", "romance", gt=30), c_bond("actor", "target", "romance", neg=True)],
    effects=[go_desk("actor", "target", "na_excuse_scene", prio=50, ttl=30)])
scene("na_excuse_scene", noise=0.6, conditions=[c_present("target"), c_near("target", "actor", 4)],
    effects=[hold(["actor", "target"], 4), emote("actor", "sweat"), say("actor", "na_excuse", to="target")],
    outcomes=[out("hit", [say("target", "na_excuse_smile", to="actor", delay=1.6), emote("actor", "love", delay=1.8), rel("target", "actor", "romance", 6),
                          log("log.na_excuse_hit", 1, "romance")], score=[s_rel("target", "actor", "romance", 0.03)]),
              out("miss", [say("target", "na_excuse_oblivious", to="actor", delay=1.6), expr("actor", "sad", 3, delay=1.8), log("log.na_excuse_miss", 1, "romance")],
                  score=[s_const(0.8)])])

# --- a flower on the desk
L("na_flower_leave", ["*leaves a single flower on {target}'s keyboard*", "*places a tiny flower in {target}'s pen pot and walks off fast*"])
L("na_flower_find", ["...A flower? Who left this?", "Somebody left me a flower!"])
S_("log.na_flower", "Someone left a flower on {actor}'s desk. {actor} has no idea it was {giver}.")
initiative("na_flower", "small", domain="romance", cooldown_days=2,
    roles=[actor([{"c": "picks", "fn": "crush_of", "of": "self"}, c_time(before="11:00")], [s_trait("self", "empathy", 0.6), s_rand(0.4)]),
           by_fn("target", "crush_of", of="actor", avail=False)],
    conditions=[c_rel("actor", "target", "romance", gt=35)],
    effects=[go_desk("actor", "target", "na_flower_scene", prio=50, ttl=40)])
scene("na_flower_scene", allow_absent=True, conditions=[c_present("actor")],
    effects=[say("actor", "na_flower_leave"), emote("actor", "love"), oset("ws.{target}.flower", "%actor"),
             trap("na_flower_found", place="desk_{target}", who="target", key="flower_{target}", days=1, roles={"giver": "actor"})])
scene("na_flower_found", allow_absent=True, conditions=[c_present("actor")],
    effects=[say("actor", "na_flower_find"), emote("actor", "love"), mood("actor", 8), rel("actor", "giver", "romance", 3),
             rumor("crush", a="giver", b="actor", juicy=0.5, truth=True, knowers=[], when=[c_chance(0.3)]),
             log("log.na_flower", 2, "romance", who=["actor"])])


# ======================================================================= ARGUMENTS
# --- the dirty mug dispute
L("na_mugs", ["Whose mugs are these? They've been in the sink since MONDAY.", "Somebody here thinks the sink is a museum."])
L("na_mugs_accuse", ["{target}, are these yours? They have your lipstick. Or coffee. Or both.", "{target}. The mugs. Explain."])
L("na_mugs_own", ["...Okay, two of them are mine. I'll wash them.", "Sorry! I'll do them now."])
L("na_mugs_deny", ["Not mine! I have ONE mug and it's on my desk!", "Why is it always me?!"])
S_("log.na_mugs_own", "{actor} confronted {target} about the mugs in the sink. {target} washed them. Peace in the kitchen.")
S_("log.na_mugs_deny", "{actor} accused {target} of leaving mugs in the sink. {target} denied it — loudly.")
initiative("na_mug_dispute", "small", domain="arguments", cooldown_days=2,
    roles=[actor([c_trait("self", "diligence", gt=0.55), c_stress("self", gt=20)], [s_trait("self", "diligence", 0.8), s_stress("self", 0.02)]),
           role("target", where=[c_avail("self")] + NB, score=[s_trait("self", "diligence", -1.0), s_aff("actor", "self", -0.01), s_rand(0.4)])],
    effects=[go_place("actor", "k2", "na_mugs_start", prio=50, ttl=30, roles={"target": "target"})])
scene("na_mugs_start", allow_absent=True, conditions=[c_present("actor")],
    effects=[say("actor", "na_mugs"), emote("actor", "anger"), visit("actor", "target", "na_mugs_scene", prio=54, ttl=30, delay=2)])
scene("na_mugs_scene", noise=0.8, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), say("actor", "na_mugs_accuse", to="target")],
    outcomes=[out("own", [say("target", "na_mugs_own", to="actor", delay=1.6), emote("target", "sweat", delay=1.6), rel("actor", "target", "respect", 2),
                          log("log.na_mugs_own", 1, "conflict")], score=[s_trait("target", "honesty", 0.8), s_trait("target", "empathy", 0.4)]),
              out("deny", [say("target", "na_mugs_deny", to="actor", delay=1.6), expr("target", "angry", 4, delay=1.6), rel("target", "actor", "resentment", 6), storm("target", delay=2.8),
                           stat("arguments"), log("log.na_mugs_deny", 2, "conflict")], score=[s_trait("target", "temper", 0.8), s_const(0.3)])])

# --- interrupted one time too many
L("na_interrupt", ["—and ANOTHER thing about the budget—", "Sorry, can I just jump in here—"])
L("na_snap", ["Can I FINISH a sentence? Once? Today?", "I was TALKING."])
S_("log.na_snap", "{target} snapped at {actor} for interrupting. Again.")
initiative("na_interrupted", "small", domain="arguments", cooldown_days=1,
    roles=[actor([c_trait("self", "sociability", gt=0.6)], [s_trait("self", "sociability", 0.8), s_trait("self", "empathy", -0.5)]),
           role("target", where=[c_avail("self"), c_stress("self", gt=30)], score=[s_trait("self", "temper", 1.0), s_stress("self", 0.02)])],
    effects=[visit("actor", "target", "na_interrupt_scene", prio=48, ttl=30)])
scene("na_interrupt_scene", noise=0.6, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 4), say("actor", "na_interrupt", to="target"), expr("target", "angry", 5, delay=1.4), say("target", "na_snap", to="actor", delay=1.4),
             emote("actor", "sweat", delay=2.6), rel("target", "actor", "resentment", 5), rel("actor", "target", "respect", 3), log("log.na_snap", 1, "conflict")])


# ======================================================================= GOSSIP
# --- spreading an unverified (false) rumour
L("na_false_tell", ["I heard {victim} is being 'reviewed'. You didn't hear it from me.", "Between us? {victim} might not be here much longer."])
L("na_false_react", ["No! Really?", "Wait, seriously? Since when?"])
S_("log.na_false_rumor", "{actor} told {target} that {victim} is about to be fired. There's no truth in it at all.")
initiative("na_false_rumor", "medium", domain="gossip", cooldown_days=2,
    roles=[actor([c_trait("self", "gossip", gt=0.6), c_trait("self", "honesty", lt=0.7)], [s_trait("self", "gossip", 1.0), s_trait("self", "cunning", 0.6)]),
           by_fn("victim", "worst_of", of="actor", lim=20, avail=False, exclude=["actor", "@ahmet"]),
           role("target", where=[c_avail("self")], score=[s_trait("self", "gossip", 0.8), s_aff("actor", "self", 0.01)], exclude=["actor", "victim"])],
    effects=[meetup("na_false_scene", area="kitchen", roles={"victim": "victim"}, ttl=35)])
scene("na_false_scene", noise=0.6,
    effects=[hold(["actor", "target"], 5), emote("actor", "whisper"), say("actor", "na_false_tell", to="target"), say("target", "na_false_react", to="actor", delay=1.8),
             rumor("getting_fired", a="victim", b="actor", juicy=0.8, truth=False, knowers=["actor", "target"]), stat("rumors"), log("log.na_false_rumor", 2, "rumor", who=["actor", "victim"])])

# --- a little gossip huddle
L("na_huddle", ["Psst. Over here. You'll want to hear this.", "Okay, gather round. Quietly."])
L("na_huddle_react", ["NO.", "Shut UP.", "I KNEW it!", "*gasps*"])
S_("log.na_huddle", "A gossip huddle formed in the kitchen around {actor}. Whatever {actor} said, three people now know it.")
initiative("na_gossip_huddle", "medium", domain="gossip", cooldown_days=1,
    roles=[actor([c_trait("self", "gossip", gt=0.65)], [s_trait("self", "gossip", 1.2)]), by_fn("target", "gossip_target")],
    vars=[var("gossip", "gossip_fact")],
    effects=[say("actor", "na_huddle"), emote("actor", "whisper"), meetup("na_huddle_scene", area="kitchen", ttl=35)])
scene("na_huddle_scene", noise=0.6,
    roles=[role("third", where=[c_zone("self", ["kitchen"]), c_trait("self", "gossip", gt=0.3)], score=[s_trait("self", "gossip", 1.0)], optional=True)],
    effects=[hold(["actor", "target"], 6), emote("actor", "whisper"),
             each([learn("self", "$gossip", frm="actor"), say("self", "na_huddle_react", p=0.6, delay=1.6), emote("self", "exclaim", delay=1.6)],
                  exclude=["actor"], where=[c_zone("self", ["kitchen"])], stagger=0.5),
             stat("rumors"), log("log.na_huddle", 2, "rumor", who=["actor"])])


# ======================================================================= HELPING
# --- covering for a late colleague
L("na_where_is", ["Where's {late}? It's nearly ten.", "Has anyone seen {late} this morning?"])
L("na_cover", ["{late}'s at a client meeting. Back soon.", "Oh, {late} called — dentist. Totally normal."])
S_("log.na_cover", "{actor} covered for {late} when Ahmet asked where they were. {late} owes {actor} one.")
S_("mem.na_cover", "{actor} covered for me with Ahmet.")
initiative("na_cover_late", "small", domain="helping", cooldown_days=2,
    roles=[actor([c_trait("self", "empathy", gt=0.55)] + NB, [s_trait("self", "empathy", 1.0)]),
           role("late", where=[{"c": "present", "who": "self", "not": True}] + NB, pool="all", avail=False,
                score=[s_aff("actor", "self", 0.02), s_rand(0.3)], exclude=["actor"])],
    conditions=[c_time(after="09:12", before="11:30"), c_present("@ahmet"), c_avail("@ahmet")], allow_absent=True,
    effects=[visit("@ahmet", "actor", "na_cover_scene", prio=52, ttl=30, roles={"late": "late"})])
scene("na_cover_scene", noise=0.4, allow_absent=True, conditions=[c_avail("target"), c_present("actor")],
    effects=[hold(["actor", "target"], 4), say("actor", "na_where_is", to="target"), say("target", "na_cover", to="actor", delay=1.6), emote("target", "sweat", delay=1.6),
             rel("late", "target", "trust", 10), rel("late", "target", "friendship", 6), mem("late", "target", "covered", 0.6, 0.8, "mem.na_cover", 2),
             log("log.na_cover", 2, "help", who=["target", "late"])])

# --- sharing lunch
L("na_share", ["Forgot your lunch? Here, have half. I always make too much.", "I've got two börek. That's one too many. Take it."])
L("na_share_thx", ["You're a lifesaver.", "Seriously? Thank you!"])
S_("log.na_share", "{actor} shared their lunch with {target}. It's the little things.")
initiative("na_share_lunch", "small", domain="helping", cooldown_days=1,
    roles=[actor([c_time(after="12:00", before="13:10"), c_trait("self", "empathy", gt=0.5)], [s_trait("self", "empathy", 1.0)]),
           role("target", where=[c_avail("self"), c_mood("self", lt=30)], score=[s_mood("self", -0.02), s_aff("actor", "self", 0.01)])],
    effects=[meetup("na_share_scene", area="kitchen", ttl=30)])
scene("na_share_scene", noise=0.3,
    effects=[hold(["actor", "target"], 5), say("actor", "na_share", to="target"), say("target", "na_share_thx", to="actor", delay=1.6), emote("target", "love", delay=1.6),
             mood("target", 12), rel("target", "actor", "friendship", 8), stat("helps"), log("log.na_share", 1, "help")])


# ======================================================================= SECRET PLANS
# --- booking a secret job interview
L("na_interview_call", ["*whispering* Yes, Thursday at 3 works. ...No, my boss doesn't know.", "*on the phone, very quietly* I'll be there. I'll say it's the dentist."])
L("na_interview_alibi", ["Ahmet Bey, I have a dentist appointment on Thursday afternoon.", "Can I leave early Thursday? Dentist."])
L("na_interview_ok", ["Again? Your teeth must be in a terrible state.", "Fine. Fine."])
S_("log.na_interview", "{actor} secretly booked a job interview — and told Ahmet it's 'the dentist'.")
initiative("na_job_interview", "medium", domain="secret_plans", cooldown_days=3,
    roles=[actor([c_any(c_plan("self", "job_search"), c_morale("self", lt=40))] + NB, [s_morale("self", -0.03), s_plan("self", "job_search", 1.0)])],
    conditions=[c_present("@ahmet")],
    effects=[go_place("actor", "phone1", "na_interview_scene", prio=54, ttl=35, dur=5)])
scene("na_interview_scene", allow_absent=True, conditions=[c_present("actor")],
    roles=[role("ear", where=[c_avail("self")], score=[s_trait("self", "curiosity", 1.0)], near="actor", r=4, optional=True)],
    effects=[act("actor", "phone", dur=5), say("actor", "na_interview_call"), plan("actor", "job_search", "", heat=0.9),
             rumor("interview", a="actor", b="@ahmet", juicy=0.8, knowers=["actor"]), learn("ear", "$rumor", c=0.7, when=[c_filled("ear")]),
             emote("ear", "exclaim", when=[c_filled("ear")]), visit("actor", "@ahmet", "na_alibi_scene", prio=52, ttl=40, delay=6),
             log("log.na_interview", 3, "job", who=["actor"])])
scene("na_alibi_scene", noise=0.4, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 4), say("actor", "na_interview_alibi", to="target"), say("target", "na_interview_ok", to="actor", delay=1.6),
             rel("target", "actor", "suspicion", 8)])

# --- eavesdropping on the boss
L("na_eaves", ["*pretends to read the fire safety poster very carefully*", "*suddenly very interested in the boss's office plant*"])
S_("log.na_eaves", "{actor} hung around outside Ahmet's office pretending to read a poster — and overheard something.")
initiative("na_eavesdrop", "small", domain="secret_plans", cooldown_days=1,
    roles=[actor([c_trait("self", "curiosity", gt=0.6)] + NB, [s_trait("self", "curiosity", 1.0), s_trait("self", "gossip", 0.5)])],
    vars=[var("fact", "any_secret", knower="@ahmet", **{"not": "actor"})],
    conditions=[c_present("@ahmet")],
    effects=[go_place("actor", "boss_guest", "na_eaves_scene", prio=50, ttl=30, dur=5)])
scene("na_eaves_scene", allow_absent=True, conditions=[c_present("actor")],
    effects=[say("actor", "na_eaves"), emote("actor", "question"), learn("actor", "$fact", c=0.6), emote("actor", "exclaim", delay=2),
             rel("@ahmet", "actor", "suspicion", 4), log("log.na_eaves", 2, "secret", who=["actor"])])

# --- peeking at papers on an empty desk
L("na_snoop", ["*glances at the papers on {target}'s empty desk* ...Oh. OH.", "Just... straightening {target}'s papers. Hm. Interesting."])
S_("log.na_snoop", "{actor} snooped through the papers on {target}'s empty desk — and found something.")
initiative("na_snoop_desk", "small", domain="secret_plans", cooldown_days=2,
    roles=[actor([c_trait("self", "curiosity", gt=0.55), c_trait("self", "honesty", lt=0.75)], [s_trait("self", "curiosity", 1.0), s_trait("self", "honesty", -0.5)]),
           role("target", where=[{"c": "zone", "who": "self", "in": ["workspace"], "not": True}] + NB, score=[s_aff("actor", "self", -0.01), s_rand(0.5)], avail=False)],
    vars=[var("fact", "secret_about", knower="target", about="target")],
    effects=[go_desk("actor", "target", "na_snoop_scene", prio=48, ttl=25)])
scene("na_snoop_scene", allow_absent=True, conditions=[c_present("actor"), {"c": "near", "a": "target", "b": "actor", "lt": 4, "not": True}],
    effects=[say("actor", "na_snoop"), emote("actor", "exclaim"), learn("actor", "$fact", c=0.8), rel("actor", "target", "suspicion", 6),
             log("log.na_snoop", 2, "secret", who=["actor", "target"])])


# ======================================================================= COMEDY
# --- talking to the office plant
L("na_plant", ["You're doing great, Fikret. Grow, buddy. Grow.", "*whispering to the plant* Don't tell Ahmet, but you're my favourite colleague."])
L("na_plant_seen", ["...Are you talking to the plant?", "Did the plant answer?"])
S_("log.na_plant", "{actor} was caught having a heartfelt conversation with the office plant.")
initiative("na_plant_talk", "small", domain="comedy", cooldown_days=2,
    roles=[actor([c_trait("self", "humor", gt=0.4)], [s_trait("self", "humor", 0.6), s_stress("self", 0.02), s_rand(0.4)])],
    effects=[go_place("actor", "plant", "na_plant_scene", prio=46, ttl=25, dur=4)])
scene("na_plant_scene", allow_absent=True, conditions=[c_present("actor")],
    roles=[role("seer", where=[c_avail("self")], score=[s_trait("self", "humor", 1.0)], near="actor", r=5, optional=True)],
    effects=[say("actor", "na_plant"), emote("actor", "love"), stress("actor", -6), say("seer", "na_plant_seen", delay=2, when=[c_filled("seer")]),
             emote("actor", "sweat", delay=2.4, when=[c_filled("seer")]), oset("plant.talked", True), log("log.na_plant", 1, "accident", who=["actor"])])

# --- the fish in the microwave
L("na_fish", ["*microwaves leftover fish* What? It's lunch.", "Fish curry. Reheated. Don't judge me."])
L("na_fish_smell", ["WHAT is that SMELL?!", "Who microwaved FISH?!", "I can taste it. I can TASTE the smell."])
S_("log.na_fish", "{actor} microwaved fish. The whole office now knows.")
initiative("na_fish_lunch", "small", domain="comedy", cooldown_days=3,
    roles=[actor([c_time(after="12:00", before="13:30"), c_trait("self", "empathy", lt=0.6)], [s_trait("self", "empathy", -0.8), s_rand(0.5)])],
    conditions=[{"c": "ostate", "path": "microwave.broken", "not": True}],
    effects=[go_place("actor", "micro", "na_fish_scene", prio=50, ttl=25, dur=4)])
scene("na_fish_scene", allow_absent=True, conditions=[c_present("actor")],
    effects=[say("actor", "na_fish"), sfx("pop", delay=1), each([say("self", "na_fish_smell", p=0.5, delay=2), mood("self", -4), rel("self", "actor", "friendship", -2)],
                                                                  exclude=["actor"], where=[c_near("self", "actor", 9)], stagger=0.6),
             log("log.na_fish", 1, "accident", who=["actor"])])

# --- dozing off at the desk
L("na_doze", ["*head slowly sinks onto the keyboard* zzz...", "*snores very softly behind the monitor*"])
L("na_doze_prank", ["*very quietly places a sticky note on their forehead*", "*takes a photo* For the newsletter."])
L("na_doze_boss", ["Good MORNING, {actor}. Comfortable?", "Am I paying you to sleep?"])
S_("log.na_doze_prank", "{actor} fell asleep at their desk. {prankster} stuck a note on their forehead. It said 'out of office'.")
S_("log.na_doze_boss", "{actor} fell asleep at their desk — and Ahmet found them.")
initiative("na_doze", "small", domain="comedy", cooldown_days=2,
    roles=[actor([c_time(after="13:30", before="16:00"), c_act("self", ["work"])], [s_stress("self", 0.02), s_trait("self", "diligence", -0.8), s_rand(0.3)])],
    effects=[expr("actor", "sad", 3), chain("na_doze_scene", delay=1)])
scene("na_doze_scene", allow_absent=True, conditions=[c_present("actor")],
    roles=[role("prankster", where=[c_avail("self"), c_trait("self", "humor", gt=0.5)] + NB, score=[s_trait("self", "humor", 1.0)], near="actor", r=7, optional=True)],
    effects=[say("actor", "na_doze"), emote("actor", "cloud")],
    outcomes=[out("prank", [say("prankster", "na_doze_prank", delay=2), emote("prankster", "cheer", delay=2), rel("actor", "prankster", "friendship", 2),
                            log("log.na_doze_prank", 2, "prank", who=["actor", "prankster"])], score=[s_const(1)], when=[c_filled("prankster")]),
              out("boss", [visit("@ahmet", "actor", "na_doze_boss_scene", prio=56, ttl=25, delay=2)], score=[s_const(0.6)], when=[c_present("@ahmet")]),
              out("nap", [stress("actor", -10)], score=[s_const(0.2)])])
scene("na_doze_boss_scene", noise=0.4, conditions=[c_present("target")],
    effects=[hold(["actor", "target"], 4), say("actor", "na_doze_boss", to="target"), expr("target", "surprised", 4, delay=1), favor("target", -4),
             log("log.na_doze_boss", 2, "boss", who=["target"])])
