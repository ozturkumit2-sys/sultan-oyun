# Interventions — E. Career, promotion & pay (Ahmet's folders, HR cabinet, cork board, boss's desk)
from iv_common import *  # noqa: F401,F403

HR = dict(obj="hr_cabinet", cat="E")
PROMO = dict(obj="promo_file", cat="E")
BOARD_N = dict(obj="noticeboard", cat="E")
NOT_BOSS_PICK = [c_is("self", "ahmet", neg=True)]

# --- E02 put someone on top of the promotion shortlist ---------------------------------
L("shortlist_joy", ["I'm on the shortlist?! TOP of the shortlist?!", "Me! First name on the promotion list!"], ece=["Is this real? Pinch me. No, don't."])
L("shortlist_brag", ["Guess whose name is first on the promotion shortlist?", "Don't tell anyone... but I'm top of the shortlist."])
L("shortlist_boss_no", ["What shortlist? There IS no shortlist yet.", "Whoever told you that was lying. Back to work."])
S_("log.shortlist_joy", "{target} saw a promotion shortlist with their own name on top. They're over the moon.")
S_("log.shortlist_burst", "{target} bragged about the promotion shortlist — Ahmet overheard: there is no shortlist. Ouch.")
S_("mem.shortlist_humiliated", "I bragged about a promotion that doesn't exist. In front of Ahmet.")
scene("iv_shortlist_find", allow_absent=True, conditions=[c_present("target")],
      effects=[expr("target", "happy", 6), emote("target", "cheer"), say("target", "shortlist_joy"), mood("target", 18), morale("target", 6),
               learn("target", "$fact", c=0.9), log("log.shortlist_joy", 3, "promotion", who=["target"]), chain("iv_shortlist_brag", delay=8)])
scene("iv_shortlist_brag", allow_absent=True, conditions=[c_present("target")],
      vars=[var("friend", "best_of", of="target", lim=-50)],
      effects=[visit("target", "$friend", "iv_shortlist_tell", prio=56, ttl=50, when=[c_present("$friend")]), chain("iv_shortlist_burst", delay=30)])
scene("iv_shortlist_tell", conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4), emote("actor", "whisper"), say("actor", "shortlist_brag", to="target"), learn("target", "$fact", frm="actor"),
               rel("target", "actor", "rivalry", 6, when=[c_trait("target", "ambition", gt=0.6)])])
scene("iv_shortlist_burst", allow_absent=True, conditions=[c_present("target"), c_present("@ahmet")],
      effects=[visit("@ahmet", "target", "iv_shortlist_burst_scene", prio=62, ttl=50)])
scene("iv_shortlist_burst_scene", conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "shortlist_boss_no", to="target"), expr("target", "sad", 6, delay=1.6), mood("target", -20), morale("target", -8),
               debunk("$fact", who=["target"], by="actor"), mem("target", "actor", "humiliated", -0.6, 0.9, "mem.shortlist_humiliated", 3),
               witness([rel("self", "target", "respect", -3)], r=5), log("log.shortlist_burst", 3, "promotion")])
iv("E02", "shortlist", title="Put someone at the top of the promotion shortlist", desc="A shortlist that doesn't exist yet — with their name first.",
   log="The ghost drafted a promotion shortlist with {target} at the top.", **HR, needs="person", icon="star", pick=NOT_BOSS_PICK + [c_present("self")],
   state=[rumor("shortlisted", a="target", b="target", juicy=0.7, truth=False, knowers=[], key="fact"), oset("hr.shortlist", "%target")],
   react=[chain("iv_shortlist_find", delay=3)])

# --- E03 rewrite someone's performance report ----------------------------------------------
L("perf_boss_good", ["{actor}! Your report says you've doubled output. Impressive!", "I've just read your performance report, {actor}. Exemplary."])
L("perf_boss_bad", ["{actor}. Your performance report is... troubling.", "We need to talk about your numbers, {actor}. They're terrible."])
L("perf_happy", ["Oh! Thank you! I... didn't know it was that good.", "Wow. I'll take it!"])
L("perf_hurt", ["Terrible? I've been working weekends!", "That's not true! Those can't be my numbers!"])
L("perf_unfair", ["{actor} got a glowing review? For WHAT?", "Unbelievable. {actor} of all people."])
S_("log.perf_good", "Someone rewrote {actor}'s performance report to sparkle. Ahmet praised them; colleagues smell something off.")
S_("log.perf_bad", "Someone rewrote {actor}'s performance report into a disaster. Ahmet gave them a grim talk.")
scene("iv_perf_talk", noise=0.5, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5)],
      outcomes=[out("good", [say("target", "perf_boss_good", to="actor"), say("actor", "perf_happy", to="target", delay=1.6), emote("actor", "cheer", delay=1.8),
                             morale("actor", 8), mood("actor", 12), each([say("self", "perf_unfair", p=0.4, delay=3), rel("self", "actor", "rivalry", 6)],
                             exclude=["actor", "target"], where=[c_trait("self", "ambition", gt=0.6)]), log("log.perf_good", 3, "promotion")],
                    score=[s_const(5)], when=[c_var("choice", eq="glowing")]),
                out("bad", [say("target", "perf_boss_bad", to="actor"), say("actor", "perf_hurt", to="target", delay=1.6), expr("actor", "sad", 6, delay=1.6),
                            morale("actor", -10), rel("actor", "target", "resentment", 12), plan("actor", "prove_self", "", heat=1.0),
                            mem("actor", "target", "scolded", -0.6, 0.9, "mem.review_bad", 3), log("log.perf_bad", 3, "promotion")],
                    score=[s_const(5)], when=[c_var("choice", eq="terrible")])])
scene("iv_perf_read", allow_absent=True, conditions=[c_present("actor"), c_present("target")],
      effects=[emote("actor", "question"), summon("target", "iv_perf_talk", delay=1)])
iv("E03", "perf_report", title="Rewrite someone's performance report", desc="Pick whose report, then make it glow — or make it a disaster. Ahmet reads these at his desk.",
   log="The ghost rewrote {target}'s performance report.", **HR, needs="person", icon="file", pick=NOT_BOSS_PICK,
   choices=[choice("glowing", "Make it glow"), choice("terrible", "Make it a disaster")],
   conds=[r_present("@ahmet"), r_time(before="15:45")],
   state=[favor("target", 12, when=[c_var("choice", eq="glowing")]), favor("target", -12, when=[c_var("choice", eq="terrible")]), oset("hr.perf", "%target")],
   react=[trap("iv_perf_read", place="desk_ahmet", who="@ahmet", key="perf", after=4)])

# --- E04 pin "raise budget this year: 0" -----------------------------------------------------------
L("zero_read", ["'Raise budget this year: ZERO'?!", "Zero raises. For anyone. This year.", "So that's it. No raises. Great."], zeynep=["Zero? That's not what the budget says..."])
L("zero_grumble", ["Why do we even bother?", "I'm updating my CV tonight.", "Zero. After the year we've had."])
L("zero_zeynep", ["Ahmet Bey, the raise budget isn't zero. Who pinned that?", "Someone's spreading fake budget numbers. It's not zero."])
L("zero_boss", ["ZERO? I never said zero! Take that down!", "That's not my number! Who wrote this?"])
S_("log.zero", "A note on the cork board says the raise budget this year is zero. The office mood just crashed.")
S_("log.zero_fixed", "Zeynep told Ahmet the 'zero raise budget' note was fake. Ahmet tore it down — but the damage is done.")
scene("iv_zero_read", allow_absent=True,
      effects=[each([say("self", "zero_read", p=0.4, delay=1.0), mood("self", -8), morale("self", -4)], exclude=["@ahmet"], stagger=0.5),
               each([say("self", "zero_grumble", p=0.5, delay=3.0), plan("self", "job_search", "", heat=0.5)], exclude=["@ahmet"],
                    where=[c_any(c_goal("self", "get_raise"), c_morale("self", lt=45))], stagger=0.7),
               log("log.zero", 4, "promotion"), chain("iv_zero_fix", delay=30)])
scene("iv_zero_fix", allow_absent=True, conditions=[c_present("@zeynep"), c_present("@ahmet")],
      effects=[visit("@zeynep", "@ahmet", "iv_zero_fix_scene", prio=58, ttl=50)])
scene("iv_zero_fix_scene", conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "zero_zeynep", to="target"), say("target", "zero_boss", to="actor", delay=1.6), expr("target", "angry", 5, delay=1.6),
               unpin("zero"), each([morale("self", 2)], exclude=["target"]), rel("target", "actor", "trust", 6), log("log.zero_fixed", 3, "boss")])
iv("E04", "zero_raise", title="Pin 'Raise budget this year: 0'", desc="A small note on the cork board. A big drop in morale.",
   log="The ghost pinned 'Raise budget this year: 0' on the cork board.", **BOARD_N, icon="pin",
   state=[pin("zero", about="@ahmet")], react=[chain("iv_zero_read", delay=4)], reuse={"cool": 900, "day": 1, "per": "global"})

# --- E05 deliver a raise letter to the wrong person ----------------------------------------------------
L("raiseletter_joy", ["A RAISE?! For ME?!", "'Your salary increase has been approved'... YES!"], burak=["...Huh. Maybe I'll stay after all."])
L("raiseletter_zeynep", ["That letter wasn't for you, {target}. It's {rich}'s.", "Sorry, {target} — payroll mix-up. That raise is {rich}'s."])
L("raiseletter_crushed", ["...Of course it is.", "Right. Of course. Never mind."])
S_("log.raiseletter", "A raise letter meant for {rich} landed on {target}'s desk. {target} celebrated — until Zeynep corrected it.")
scene("iv_raiseletter", allow_absent=True, conditions=[c_present("target")],
      effects=[expr("target", "happy", 6), emote("target", "cheer"), say("target", "raiseletter_joy"), mood("target", 18), morale("target", 6),
               rumor("raise", a="target", b="target", juicy=0.6, truth=False, knowers=[], key="fact"), witness([learn("self", "$fact")], near="target", r=5),
               chain("iv_raiseletter_fix", delay=25)])
scene("iv_raiseletter_fix", allow_absent=True, conditions=[c_present("@zeynep"), c_present("target")],
      effects=[visit("@zeynep", "target", "iv_raiseletter_scene", prio=60, ttl=50)])
scene("iv_raiseletter_scene", conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "raiseletter_zeynep", to="target"), say("target", "raiseletter_crushed", to="actor", delay=1.6),
               expr("target", "sad", 6, delay=1.6), mood("target", -22), morale("target", -8), rel("target", "rich", "resentment", 14), rel("target", "rich", "rivalry", 10),
               debunk("$fact", who=["target"], by="actor"), rumor("raise", a="rich", b="rich", juicy=0.6, knowers=["actor", "target"]),
               mood("rich", 10), log("log.raiseletter", 4, "promotion", who=["target", "rich"])])
iv("E05", "raise_letter", title="Deliver someone's raise letter to the wrong person", desc="The letter's for Ahmet's favourite. Pick who opens it instead.",
   log="The ghost put a raise confirmation letter on {target}'s desk. It wasn't meant for them.", **HR, needs="person", icon="email",
   pick=NOT_BOSS_PICK + [c_present("self")], conds=[r_present("@zeynep")],
   state=[pick_role("rich", "boss_fav", **{"not": "target"}), oset("hr.raise_letter", "%target")], react=[chain("iv_raiseletter", delay=3)])

# --- E06 make a secret job application visible to Ahmet ----------------------------------------------
L("app_boss_read", ["A job application? From {applicant}? To a COMPETITOR?", "So. {applicant} wants to leave."])
L("app_confront", ["{target}. I found your job application. Care to explain?", "Planning to leave us, {target}?"])
L("app_counter", ["...If it's about money, let's talk. I don't want to lose you.", "What would it take for you to stay?"])
L("app_cold", ["Fine. If you want to go, go. But don't expect a reference.", "Disloyalty. I'll remember this."])
L("app_admit", ["...Yes. I've been looking. I'm not happy here.", "I won't lie to you. I applied."])
S_("log.app_found", "{applicant}'s secret job application turned up on Ahmet's desk.")
S_("log.app_counter", "Ahmet confronted {target} about the job application — then made a counter-offer to keep them.")
S_("log.app_cold", "Ahmet confronted {target} about the job application. It went cold and ugly.")
scene("iv_app_found", allow_absent=True, conditions=[c_present("actor"), c_present("applicant")],
      effects=[expr("actor", "surprised", 5), say("actor", "app_boss_read"), learn("actor", "$fact", c=1.0), reveal("$fact"),
               log("log.app_found", 4, "secret", who=["applicant"]), visit("actor", "applicant", "iv_app_scene", prio=70, ttl=60, delay=2)])
scene("iv_app_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 6), say("actor", "app_confront", to="target"), say("target", "app_admit", to="actor", delay=1.8), emote("target", "sweat", delay=1.8)],
      outcomes=[out("counter", [say("actor", "app_counter", to="target", delay=3.6), favor("target", 5), morale("target", 8), plan("target", "job_search", "", v=False),
                                log("log.app_counter", 4, "boss")], score=[s_rel("actor", "target", "respect", 0.03), s_trait("actor", "cunning", 0.5)]),
                out("cold", [say("actor", "app_cold", to="target", delay=3.6), expr("actor", "angry", 6, delay=3.6), favor("target", -12), morale("target", -8),
                             rel("actor", "target", "trust", -20), plan("target", "job_search", "", heat=1.5), log("log.app_cold", 4, "boss")],
                    score=[s_trait("actor", "temper", 1.0), s_rel("actor", "target", "trust", -0.01)])])
iv("E06", "expose_application", title="Put a secret job application on Ahmet's desk", desc="Someone's been applying elsewhere. Make sure Ahmet sees it.",
   log="The ghost left {applicant}'s job application on Ahmet's desk.", obj="promo_file", cat="E", icon="newspaper",
   vars=[var("applicant", "job_seeker", role=True, why="why.no_seeker")], conds=[r_present("@ahmet")],
   state=[rumor("job_hunting", a="applicant", b="@ahmet", juicy=0.85, knowers=["applicant"], key="fact"), oset("hr.application", "%applicant")],
   react=[trap("iv_app_found", place="desk_ahmet", who="@ahmet", key="application", after=2)], reuse={"cool": 600, "day": 1})
S_("why.no_seeker", "Nobody is secretly job hunting right now.")

# --- E07 announce the promotion early ------------------------------------------------------------------
L("early_promo_go", ["Actually — why wait? Everyone! Gather round!", "I've decided. Announcement time. Now."])
L("early_promo_miss", ["Wait, the promotion was announced? I was in the kitchen!", "They announced it WITHOUT me?"])
S_("log.early_promo", "Ahmet suddenly announced the promotion hours early. Not everyone was around to hear it.")
scene("iv_early_promo", allow_absent=True, conditions=[c_present("@ahmet")],
      effects=[say("@ahmet", "early_promo_go"), act("@ahmet", "announce", place="announce", dur=6), log("log.early_promo", 3, "promotion")])
iv("E07", "early_announcement", title="Move the promotion announcement forward", desc="Today's promotion gets announced right now — ready or not.",
   log="The ghost moved Ahmet's promotion announcement to right now.", **PROMO, icon="star",
   conds=[why({"c": "picks", "fn": "promo_day"}, "no_promo", "There's no promotion announcement today."), why(c_dayflag("promotion_done", neg=True), "promo_done", "The promotion was already announced."),
          r_present("@ahmet"), r_time(before="16:00"), why(c_busy_meeting("@ahmet"), "boss_busy", "Ahmet is in a meeting.")],
   state=[flag("promo_early", True, day=True)], react=[chain("iv_early_promo", delay=2)], test={"day": 2, "at": "11:00"},
   watch=["promotion"])

# --- E08 put someone on top of the sales leaderboard ------------------------------------------------
L("leader_see", ["{target} is number one on the sales board? Since when?", "Wait, {target} out-sold MERT?"], mert=["Number TWO? Me? Behind {target}?!"])
L("leader_boss", ["{target}! Top of the sales board! Well done!", "Look at that. {target}, our new sales champion."])
L("leader_mert", ["Those are MY numbers! I closed those deals!", "That's a mistake. I'm number one. I'm always number one."])
S_("log.leader", "The sales leaderboard now shows {target} in first place. Mert is fuming — those were his deals.")
scene("iv_leader_seen", allow_absent=True, conditions=[c_present("@mert")],
      effects=[say("@mert", "leader_mert"), expr("@mert", "angry", 6), emote("@mert", "anger"), rel("@mert", "target", "rivalry", 18), rel("@mert", "target", "suspicion", 15),
               morale("@mert", -5), favor("target", 4), say("@ahmet", "leader_boss", delay=2, when=[c_present("@ahmet")]), log("log.leader", 3, "promotion", who=["target", "@mert"]),
               visit("@mert", "target", "ivm_accuse", prio=60, ttl=50, delay=4, when=[c_present("target"), c_trait("@mert", "temper", gt=0.2)])])
iv("E08", "sales_board", title="Rewrite the sales leaderboard", desc="Put someone else in first place. Mert checks it every day.",
   log="The ghost put {target} at the top of the sales leaderboard.", **BOARD_N, needs="person", icon="star",
   pick=[c_is("self", "mert", neg=True), c_is("self", "ahmet", neg=True)], conds=[r_present("@mert")],
   state=[pin("sales", about="target")], react=[chain("iv_leader_seen", delay=8)])

# --- E09 postpone someone's performance review indefinitely ---------------------------------------------
L("postpone_read", ["My review is postponed... 'indefinitely'?", "'Review postponed — no new date.' What does THAT mean?"])
L("postpone_ask", ["Ahmet Bey, why was my review postponed indefinitely?", "Is there a reason my review keeps being pushed?"])
L("postpone_boss", ["Postponed? I didn't postpone anything. ...Did I?", "Your review? Hm. Next month. Probably."])
S_("log.postpone", "{target}'s performance review was postponed 'indefinitely'. {target} is reading a lot into it.")
scene("iv_postpone_read", allow_absent=True, conditions=[c_present("target")],
      effects=[expr("target", "sad", 5), say("target", "postpone_read"), stress("target", 10), morale("target", -5), log("log.postpone", 3, "promotion", who=["target"])],
      outcomes=[out("ask", [visit("target", "@ahmet", "iv_postpone_scene", prio=58, ttl=60, delay=3)], score=[s_trait("target", "temper", 0.6), s_trait("target", "ambition", 0.6)],
                    when=[c_present("@ahmet")]),
                out("brood", [plan("target", "job_search", "", heat=0.6), mood("target", -6)], score=[s_trait("target", "sociability", -0.5), s_const(0.4)])])
scene("iv_postpone_scene", conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "postpone_ask", to="target"), say("target", "postpone_boss", to="actor", delay=1.6),
               rel("actor", "target", "resentment", 8), plan("actor", "prove_self", "", heat=0.8)])
iv("E09", "postpone_review", title="Postpone someone's review — indefinitely", desc="No new date. Just 'postponed'. They'll wonder why.",
   log="The ghost postponed {target}'s performance review indefinitely.", **HR, needs="person", icon="calendar", pick=NOT_BOSS_PICK + [c_present("self")],
   state=[oset("hr.postponed", "%target")], react=[chain("iv_postpone_read", delay=3)])

# --- E10 change the name on the Employee of the Month certificate ---------------------------------------
L("eotm_joy", ["Employee of the Month? ME?", "My name! On the certificate! On the board!"])
L("eotm_rival", ["{target}? Employee of the Month? Seriously?", "Who chose {target}?!"])
L("eotm_boss_keep", ["...Well. It's printed now. Congratulations, {target}.", "Hm. Fine. You've earned... something."])
L("eotm_boss_fix", ["That certificate is wrong. It should say {rich}.", "Correction: Employee of the Month is {rich}. Not {target}."])
S_("log.eotm_keep", "The Employee of the Month certificate says {target}. Ahmet didn't pick them — but decided to let it stand.")
S_("log.eotm_fix", "The Employee of the Month certificate said {target}. Ahmet publicly corrected it to {rich}. Brutal.")
scene("iv_eotm", noise=0.8, allow_absent=True, conditions=[c_present("target")],
      effects=[emote("target", "cheer"), say("target", "eotm_joy"), mood("target", 14), say("rich", "eotm_rival", delay=2, when=[c_present("rich")]),
               rel("rich", "target", "rivalry", 10)],
      outcomes=[out("keep", [say("@ahmet", "eotm_boss_keep", delay=4, when=[c_present("@ahmet")]), morale("target", 6), favor("target", 4), log("log.eotm_keep", 3, "reward")],
                    score=[s_mood("@ahmet", 0.02), s_rel("@ahmet", "target", "trust", 0.02), s_const(0.3)]),
                out("fix", [say("@ahmet", "eotm_boss_fix", delay=4), unpin("eotm"), pin("eotm", about="rich"), mood("target", -20), morale("target", -6),
                            mem("target", "@ahmet", "humiliated", -0.6, 0.9, "mem.shortlist_humiliated", 3), log("log.eotm_fix", 4, "reward")],
                    score=[s_trait("@ahmet", "temper", 1.0)], when=[c_present("@ahmet")])])
iv("E10", "eotm_certificate", title="Change the name on 'Employee of the Month'", desc="The certificate on the cork board will show whoever you pick.",
   log="The ghost changed the Employee of the Month certificate to {target}.", **BOARD_N, needs="person", icon="star", pick=NOT_BOSS_PICK + [c_present("self")],
   state=[pick_role("rich", "boss_fav", **{"not": "target"}), unpin("eotm"), pin("eotm", about="target")], react=[chain("iv_eotm", delay=5)])

# --- E11 deliver Ahmet's thank-you note to the wrong person --------------------------------------------
L("thanks_note_read", ["'Thank you for your outstanding effort — Ahmet.' For ME?", "A handwritten thank-you from Ahmet! I'm framing this."])
L("thanks_note_thank", ["Ahmet Bey, thank you for the lovely note!", "Your note made my day, Ahmet Bey."])
L("thanks_note_boss", ["...Note? That note was for {rich}.", "Ah. That one was meant for {rich}, actually."])
L("thanks_unseen", ["So I fix everything and the thank-you goes to {target}. Great.", "Nice. My thank-you note, someone else's desk."])
S_("log.thanks_note", "Ahmet's thank-you note to {rich} ended up with {target}. {target} thanked Ahmet for it. Awkward for everyone.")
scene("iv_thanks_note", allow_absent=True, conditions=[c_present("target")],
      effects=[expr("target", "happy", 5), say("target", "thanks_note_read"), mood("target", 10), rel("target", "@ahmet", "friendship", 6),
               visit("target", "@ahmet", "iv_thanks_note_scene", prio=56, ttl=60, delay=4, when=[c_present("@ahmet")])])
scene("iv_thanks_note_scene", noise=0.6, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "thanks_note_thank", to="target"), say("target", "thanks_note_boss", to="actor", delay=1.6),
               expr("actor", "sad", 5, delay=1.6), mood("actor", -10), say("rich", "thanks_unseen", delay=4, when=[c_present("rich")]),
               rel("rich", "@ahmet", "resentment", 8), rel("rich", "actor", "rivalry", 4), log("log.thanks_note", 3, "misunderstanding", who=["actor", "rich"])])
iv("E11", "thank_wrong", title="Deliver Ahmet's thank-you note to the wrong person", desc="It was meant for his favourite. Pick who opens it.",
   log="The ghost moved Ahmet's thank-you note onto {target}'s desk.", **PROMO, needs="person", icon="email", pick=NOT_BOSS_PICK + [c_present("self")],
   state=[pick_role("rich", "boss_fav", **{"not": "target"}), oset("hr.thanks_note", "%target")], react=[chain("iv_thanks_note", delay=3)])

# --- E12 pin Ahmet's private notes about everyone ----------------------------------------------------------
L("notes_good", ["Ahmet wrote 'reliable, future leader' about me!", "He thinks I'm 'excellent'! In writing!"])
L("notes_bad", ["'Needs constant supervision'?! That's what he thinks of me?", "Ahmet's note on me: 'disappointing'. Wow."])
L("notes_boss", ["WHO PINNED MY PRIVATE NOTES ON THE BOARD?!", "Those were PRIVATE!"])
S_("log.notes", "Ahmet's private notes about every employee appeared on the cork board. Everyone read what he thinks of them.")
scene("iv_notes_pinned", allow_absent=True,
      effects=[each([say("self", "notes_good", p=0.5, delay=1.0), mood("self", 10), morale("self", 4)], exclude=["@ahmet"], where=[{"c": "picks", "fn": "favored", "of": "self"}], stagger=0.6),
               each([say("self", "notes_bad", p=0.5, delay=1.0), expr("self", "sad", 5), mood("self", -12), morale("self", -6), rel("self", "@ahmet", "resentment", 12)],
                    exclude=["@ahmet"], where=[{"c": "picks", "fn": "disfavored", "of": "self"}], stagger=0.6),
               say("@ahmet", "notes_boss", delay=5, when=[c_present("@ahmet")]), expr("@ahmet", "angry", 6, delay=5), stress("@ahmet", 14),
               rel("@ahmet", "@ceren", "trust", -6), oset("notice.notes_read", True), log("log.notes", 4, "boss")])
iv("E12", "pin_boss_notes", title="Pin Ahmet's private notes about everyone", desc="What he really thinks of each employee. On the cork board.",
   log="The ghost pinned Ahmet's private notes about the staff on the cork board.", **BOARD_N, icon="pin",
   state=[pin("notes", about="@ahmet")], react=[chain("iv_notes_pinned", delay=4)], reuse={"cool": 900, "day": 1, "per": "global"})

# --- E13 leave a headhunter's card on someone's desk ---------------------------------------------------------
L("card_find", ["A headhunter's card? 'Call me — we pay double'?", "'Senior role, double salary. Call me.' On my desk?"])
L("card_show_boss", ["Ahmet Bey — a headhunter's been courting me. Just so you know.", "Someone offered me double. I'd rather stay... at the right price."])
L("card_boss_raise", ["...Fine. Let's talk about your salary.", "Don't call them. We'll sort something out."])
L("card_boss_call_bluff", ["Then go. Nobody's irreplaceable.", "Call them, then."])
S_("log.card_leverage", "{actor} found a headhunter's card and used it as leverage with Ahmet. It worked.")
S_("log.card_bluff", "{actor} waved a headhunter's card at Ahmet. Ahmet called the bluff.")
S_("log.card_tempt", "{actor} found a headhunter's business card on their desk — and kept it.")
scene("iv_card_found", noise=0.8,
      effects=[expr("actor", "surprised", 4), say("actor", "card_find"), emote("actor", "idea")],
      outcomes=[out("leverage", [visit("actor", "@ahmet", "iv_card_boss", prio=58, ttl=60, delay=3)], score=[s_trait("actor", "cunning", 1.0), s_trait("actor", "ambition", 0.6)],
                    when=[c_present("@ahmet")]),
                out("tempt", [plan("actor", "job_search", "", heat=1.0), log("log.card_tempt", 2, "drama")], score=[s_morale("actor", -0.03), s_goal("actor", "find_new_job", 1.5), s_const(0.3)])])
scene("iv_card_boss", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "card_show_boss", to="target")],
      outcomes=[out("raise", [say("target", "card_boss_raise", to="actor", delay=1.6), favor("actor", 5), morale("actor", 8), log("log.card_leverage", 3, "reward")],
                    score=[s_rel("target", "actor", "respect", 0.03), s_const(0.2)]),
                out("bluff", [say("target", "card_boss_call_bluff", to="actor", delay=1.6), morale("actor", -8), rel("actor", "target", "resentment", 10),
                              plan("actor", "job_search", "", heat=1.0), log("log.card_bluff", 3, "boss")], score=[s_trait("target", "temper", 0.8), s_const(0.3)])])
iv("E13", "headhunter_card", title="Leave a headhunter's card on their desk", desc="'Senior role. Double salary. Call me.'",
   log="The ghost left a headhunter's business card on {owner}'s desk.", obj="ws", tab="papers", cat="E", icon="email",
   owners=["selin", "mert", "zeynep", "burak", "ece", "deniz", "ceren"], state=[oset("ws.{owner}.card")], react=[desk_trap("iv_card_found", "card_{owner}")])

# --- E14 enrol someone in an anger-management course ----------------------------------------------------------
L("course_read", ["'Mandatory anger management course'?! For ME?!", "Who signed me up for ANGER MANAGEMENT?!"])
L("course_laugh", ["Ha! Anger management!", "Somebody's going to be very calm next week!"], mert=["Namaste, my friend."])
L("course_calm", ["...Fine. Maybe I'll go. Could be useful.", "Okay. Deep breaths. I'm calm. I'm CALM."])
S_("log.course_rage", "{target} was enrolled in a mandatory anger-management course. {target} responded by... getting very angry.")
S_("log.course_calm", "{target} was enrolled in an anger-management course — and took it surprisingly well.")
scene("iv_course", noise=0.6, allow_absent=True, conditions=[c_present("target")],
      effects=[expr("target", "surprised", 4), say("target", "course_read"), witness([say("self", "course_laugh", p=0.5, delay=2), rel("self", "target", "respect", -2)], near="target", r=5)],
      outcomes=[out("rage", [emote("target", "anger", delay=1.6), expr("target", "angry", 6, delay=1.6), sfx("thump", delay=1.6), stress("target", 12),
                             mood("target", -8),
                             log("log.course_rage", 3, "prank", who=["target"])], score=[s_trait("target", "temper", 1.4)]),
                out("calm", [say("target", "course_calm", delay=1.6), mood("target", -2), log("log.course_calm", 2, "prank", who=["target"])],
                    score=[s_trait("target", "forgiveness", 0.8), s_trait("target", "humor", 0.6)])])
iv("E14", "anger_course", title="Enrol someone in an anger-management course", desc="A very official, very public memo.",
   log="The ghost enrolled {target} in a mandatory anger-management course.", **HR, needs="person", icon="papers", pick=[c_present("self")],
   state=[oset("hr.course", "%target")], react=[chain("iv_course", delay=4)])

# --- E15 change someone's job title to "Intern" -----------------------------------------------------------------
L("intern_read", ["Payroll says my title is... 'INTERN'?!", "'Welcome to the team, intern!' I've been here five years!"])
L("intern_ask", ["Ahmet Bey, why am I listed as an INTERN?", "Have I been demoted? To intern?!"])
L("intern_boss", ["Intern? Nonsense. HR glitch. Probably.", "You're not an intern. Calm down."])
L("intern_ece", ["Welcome to the club!", "Interns unite!"])
S_("log.intern", "{target}'s official job title changed to 'Intern' overnight. Ece is delighted. {target} is not.")
scene("iv_intern", allow_absent=True, conditions=[c_present("target")],
      effects=[expr("target", "surprised", 5), emote("target", "exclaim"), say("target", "intern_read"), stress("target", 10), morale("target", -4),
               say("@ece", "intern_ece", delay=2.5, when=[c_near("@ece", "target", 6), c_is("target", "ece", neg=True)]),
               log("log.intern", 3, "promotion", who=["target"]), visit("target", "@ahmet", "iv_intern_scene", prio=60, ttl=50, delay=3, when=[c_present("@ahmet")])])
scene("iv_intern_scene", conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "intern_ask", to="target"), say("target", "intern_boss", to="actor", delay=1.6),
               rel("target", "actor", "respect", -3), mood("actor", 4)])
iv("E15", "title_intern", title="Change someone's job title to 'Intern'", desc="In the HR system. Payroll will send a welcome email.",
   log="The ghost changed {target}'s job title to 'Intern'.", **HR, needs="person", icon="file", pick=NOT_BOSS_PICK + [c_is("self", "ece", neg=True), c_present("self")],
   state=[oset("hr.intern", "%target")], react=[chain("iv_intern", delay=4)])

# --- E16 draft a transfer request to the branch office -----------------------------------------------------------
L("transfer_read", ["'Transfer request: to the Erzurum branch'?! I never asked for that!", "They're sending me to ERZURUM?"])
L("transfer_ask", ["Ahmet Bey, are you trying to get rid of me?", "Is this transfer request your idea?"])
L("transfer_boss_no", ["Transfer? You? Who would do your job?", "I'd never send you away. Sit down."])
L("transfer_boss_hmm", ["...Erzurum is lovely this time of year.", "Hm. Not my idea. But not a bad one."])
S_("log.transfer_ok", "{actor} found a transfer request to a far-away branch. Ahmet swore he'd never send them away. {actor} feels valued.")
S_("log.transfer_hmm", "{actor} found a transfer request to a far-away branch. Ahmet didn't exactly deny it.")
scene("iv_transfer", allow_absent=True, conditions=[c_present("target")],
      effects=[expr("target", "surprised", 5), say("target", "transfer_read"), stress("target", 12), visit("target", "@ahmet", "iv_transfer_scene", prio=60, ttl=50, delay=3,
               when=[c_present("@ahmet")])])
scene("iv_transfer_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "transfer_ask", to="target")],
      outcomes=[out("valued", [say("target", "transfer_boss_no", to="actor", delay=1.6), morale("actor", 8), mood("actor", 10), rel("actor", "target", "trust", 8),
                               log("log.transfer_ok", 3, "boss")], score=[{"s": "favor", "who": "actor", "w": 0.05}]),
                out("hmm", [say("target", "transfer_boss_hmm", to="actor", delay=1.6), morale("actor", -10), rel("actor", "target", "resentment", 12),
                            plan("actor", "job_search", "", heat=0.8), log("log.transfer_hmm", 3, "boss")], score=[s_const(2.5), s_trait("target", "humor", 0.5)])])
iv("E16", "transfer_request", title="Draft a transfer request for someone", desc="To a branch office very, very far away.",
   log="The ghost drafted a transfer request sending {target} to a far-away branch.", **HR, needs="person", icon="papers", pick=NOT_BOSS_PICK + [c_present("self")],
   state=[oset("hr.transfer", "%target")], react=[chain("iv_transfer", delay=4)])

# --- E17 pin fake promotion criteria ---------------------------------------------------------------------------
L("criteria_read_cake", ["'Promotion criteria: bring cake on Fridays'? ...It's Friday-ish.", "Cake gets you promoted? I can do cake."])
L("criteria_read_laugh", ["'Must laugh at Ahmet's jokes'? Noted.", "Laugh at his jokes. Okay. I can fake that."])
L("criteria_laugh_boss", ["HAHAHA! Ahmet Bey, that's hilarious!", "Ha! Oh, Ahmet Bey, you kill me."])
L("criteria_boss", ["...I didn't say anything funny.", "Why is everyone laughing at everything I say today?"])
S_("log.criteria_cake", "Fake 'promotion criteria' on the cork board say: bring cake. {climber} is already bringing cake.")
S_("log.criteria_laugh", "Fake 'promotion criteria' say: laugh at Ahmet's jokes. {climber} is laughing at EVERYTHING Ahmet says.")
scene("iv_criteria", noise=0.8, allow_absent=True,
      roles=[role("climber", where=[c_avail("self"), c_is("self", "ahmet", neg=True)], score=[s_trait("self", "ambition", 1.2), s_trait("self", "cunning", 0.5)], exclude=[])],
      outcomes=[out("cake", [say("climber", "criteria_read_cake"), go_place("climber", "k4", "iv_criteria_cake", prio=56, ttl=40, dur=3),
                             log("log.criteria_cake", 2, "promotion", who=["climber"])], score=[s_const(5)], when=[c_var("choice", eq="cake")]),
                out("laugh", [say("climber", "criteria_read_laugh"), visit("climber", "@ahmet", "iv_criteria_laugh", prio=56, ttl=50, delay=2),
                              log("log.criteria_laugh", 2, "promotion", who=["climber"])], score=[s_const(5)], when=[c_var("choice", eq="laugh"), c_present("@ahmet")])])
L("criteria_cake_offer", ["Cake! For everyone! No reason!", "I brought cake. Just because. Totally unrelated to anything."])
scene("iv_criteria_cake", allow_absent=True, conditions=[c_present("actor")],
      effects=[say("actor", "criteria_cake_offer"), oset("kitchen.tray", True), each([mood("self", 4), rel("self", "actor", "friendship", 3)], exclude=["actor"], where=[c_near("self", "actor", 6)]),
               favor("actor", 2)])
scene("iv_criteria_laugh", conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4), say("actor", "criteria_laugh_boss", to="target"), say("target", "criteria_boss", to="actor", delay=1.6), emote("target", "question", delay=1.6),
               favor("actor", 1), rel("target", "actor", "respect", -2), witness([say("self", "eye_roll", p=0.5, delay=2.5), rel("self", "actor", "respect", -4)], near="actor", r=5)])
iv("E17", "promo_criteria", title="Pin fake 'promotion criteria'", desc="The ambitious will follow them to the letter.",
   log="The ghost pinned fake promotion criteria on the cork board.", **BOARD_N, needs="choice", icon="pin",
   choices=[choice("cake", "'Bring cake on Fridays'"), choice("laugh", "'Laugh at Ahmet's jokes'")],
   state=[pin("criteria", about="@ahmet"), oset("notice.criteria", "$choice")], react=[chain("iv_criteria", delay=6)])

# --- E18 leave a glowing reference letter from Ahmet for someone ---------------------------------------------
L("reference_read", ["A reference letter? From Ahmet? 'Highly recommended for positions elsewhere'...", "Ahmet wrote me a reference. For OTHER jobs. Is that a hint?"])
L("reference_hurt", ["He wants me gone. That's what this means.", "'Elsewhere.' Got it."])
L("reference_use", ["...Well. Might as well use it.", "A glowing reference? I'll put it to work."])
S_("log.reference_hurt", "{target} found a reference letter from Ahmet recommending them 'for positions elsewhere'. They took it as a hint.")
S_("log.reference_use", "{target} found a glowing reference letter from Ahmet — and started applying for other jobs with it.")
scene("iv_reference", noise=0.8, allow_absent=True, conditions=[c_present("target")],
      effects=[expr("target", "surprised", 4), say("target", "reference_read")],
      outcomes=[out("hurt", [say("target", "reference_hurt", delay=1.6), expr("target", "sad", 6, delay=1.6), morale("target", -10), rel("target", "@ahmet", "resentment", 14),
                             log("log.reference_hurt", 3, "drama", who=["target"])], score=[s_trait("target", "empathy", 0.6), s_morale("target", 0.01)]),
                out("use", [say("target", "reference_use", delay=1.6), plan("target", "job_search", "", heat=1.5), log("log.reference_use", 3, "drama", who=["target"])],
                    score=[s_goal("target", "find_new_job", 2.0), s_trait("target", "ambition", 0.6), s_morale("target", -0.02)])])
iv("E18", "reference_letter", title="Leave a glowing reference letter for someone", desc="From Ahmet. 'Highly recommended — for positions elsewhere.'",
   log="The ghost left {target} a reference letter 'from Ahmet'.", **PROMO, needs="person", icon="email", pick=NOT_BOSS_PICK + [c_present("self")],
   state=[oset("hr.reference", "%target")], react=[chain("iv_reference", delay=4)])

# --- E19 add someone to the weekend overtime list -------------------------------------------------------------
L("overtime_read", ["I'm on the WEEKEND overtime list?! It's my sister's wedding!", "Weekend shift? Me? Who decided that?!"])
L("overtime_blame", ["{suspect} makes these lists. I KNOW it.", "This is {suspect}'s doing."])
S_("log.overtime", "{target} discovered they'd been put on the weekend overtime list. {target} is not taking it quietly.")
scene("iv_overtime", noise=0.8, allow_absent=True, conditions=[c_present("target")],
      vars=[var("suspect", "suspect", of="target", optional=True)],
      effects=[expr("target", "angry", 6), say("target", "overtime_read"), stress("target", 14), morale("target", -6), log("log.overtime", 3, "work", who=["target"])],
      outcomes=[out("blame", [say("target", "overtime_blame", delay=1.6), rel("target", "$suspect", "suspicion", 15), rel("target", "$suspect", "resentment", 8),
                              visit("target", "$suspect", "ivm_accuse", prio=60, ttl=50, delay=3, when=[c_present("$suspect")])],
                    score=[s_trait("target", "temper", 1.0)], when=[c_filled("$suspect")]),
                out("boss", [visit("target", "@ahmet", "iv_overtime_boss", prio=58, ttl=50, delay=3)], score=[s_trait("target", "honesty", 0.8)], when=[c_present("@ahmet")])])
L("overtime_plead", ["Ahmet Bey, I can't work this weekend. Please.", "There must be a mistake with the overtime list."])
L("overtime_boss_yes", ["If you're on the list, you're on the list.", "Rules are rules."])
scene("iv_overtime_boss", conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "overtime_plead", to="target"), say("target", "overtime_boss_yes", to="actor", delay=1.6),
               rel("actor", "target", "resentment", 10), morale("actor", -4)])
iv("E19", "overtime_list", title="Add someone to the weekend overtime list", desc="Pinned up for everyone to see.",
   log="The ghost added {target} to the weekend overtime list.", **BOARD_N, needs="person", icon="calendar", pick=NOT_BOSS_PICK + [c_present("self")],
   state=[pin("overtime", about="target")], react=[chain("iv_overtime", delay=5)])

# --- E20 change the nameplate on the manager's office ----------------------------------------------------------
L("plate_bring", ["Here's the paperwork you wanted, boss... uh, {target}?", "{target}, the sign says you're the manager now. Sign this?"])
L("plate_power", ["Put it on the pile. I'll get to it. Maybe.", "Yes, yes. Leave it with me."], deniz=["Excellent. Put it on MY desk."])
L("plate_panic", ["I'm not the manager! The sign is wrong!", "Don't give me that! I don't want it!"])
L("plate_boss", ["WHY does my door say '{target} — Manager'?!", "Who changed my nameplate?!"])
S_("log.plate_power", "The manager's nameplate now says '{target}'. People started bringing {target} their paperwork — and {target} enjoyed it.")
S_("log.plate_panic", "The manager's nameplate now says '{target}'. {target} spent the morning refusing other people's paperwork.")
ev(id="iv_plate", trigger="", priority=56, allow_absent=True,
   roles=[role("visitor", where=[c_avail("self"), c_not(c_same("self", "target")), c_is("self", "ahmet", neg=True)], score=[s_trait("self", "diligence", 0.6), s_rand(0.6)],
               exclude=["target"])],
   conditions=[c_present("target")], effects=[visit("visitor", "target", "iv_plate_scene", prio=56, ttl=50)])
scene("iv_plate_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "plate_bring", to="target"), say("@ahmet", "plate_boss", delay=4, when=[c_present("@ahmet")])],
      outcomes=[out("power", [say("target", "plate_power", to="actor", delay=1.6), favor("target", -3), rel("@ahmet", "target", "rivalry", 8), rel("actor", "target", "respect", -2),
                              log("log.plate_power", 3, "boss")], score=[s_trait("target", "ambition", 1.0), s_trait("target", "cunning", 0.6)]),
                out("panic", [say("target", "plate_panic", to="actor", delay=1.6), emote("target", "sweat", delay=1.6), log("log.plate_panic", 2, "boss")],
                    score=[s_trait("target", "empathy", 0.6), s_const(0.5)])])
iv("E20", "nameplate", title="Change the name on the manager's door", desc="'Manager: (someone)'. People will bring them Ahmet's paperwork.",
   log="The ghost changed the manager's nameplate to '{target}'.", **PROMO, needs="person", icon="home", pick=NOT_BOSS_PICK + [c_present("self")],
   state=[oset("hr.nameplate", "%target")], react=[chain("iv_plate", delay=4), chain("iv_plate", delay=22)])
