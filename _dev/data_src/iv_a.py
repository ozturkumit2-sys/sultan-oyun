# Interventions: the 13 originals (legacy code path) + A. Computers & digital systems
from iv_common import *  # noqa: F401,F403

# =====================================================================
# The original 13 — same behaviour as before, now listed in the database
# =====================================================================
iv("G01", "break_coffee", "G", "coffee_machine", "", "", legacy="break_coffee", icon="coffee", reuse={"cool": 60},
   watch=["coffee_broken", "help_request", "fix_done", "accusation"])
iv("G02", "fix_coffee", "G", "coffee_machine", "", "", legacy="fix_coffee", icon="coffee", reuse={"cool": 30}, test={"setup": [{"e": "obj", "obj": "coffee", "key": "broken", "v": True}]},
   watch=["coffee_ghost", "thank_wrong_person"])
iv("H01", "break_printer", "H", "printer", "", "", legacy="break_printer", icon="printer", reuse={"cool": 60},
   watch=["printer_broken", "help_request", "fix_done"])
iv("C01", "move_meeting", "C", "meeting_board", "", "", legacy="move_meeting", icon="board", reuse={"cool": 30},
   watch=["board_noticed", "board_changed", "meeting_late", "meeting_wait_timeout", "meeting_absent"])
iv("H02", "set_temp", "H", "ac", "", "", legacy="set_temp", icon="thermo", reuse={"cool": 15},
   watch=["temp_changed", "thermo_complaint", "thermostat_war", "thermo_argument"])
iv("H03", "lights_off", "H", "lights", "", "", legacy="lights_off", icon="bulb", reuse={"cool": 45},
   watch=["lights_off_panic", "dark_bonding", "dark_scheme", "ece_spill", "lights_restored"])
iv("H04", "lights_on", "H", "lights", "", "", legacy="lights_on", icon="bulb", reuse={"cool": 10}, test={"setup": [{"e": "obj", "obj": "lights", "key": "on", "v": False}]}, watch=["lights_on_ghost"])
iv("E01", "edit_promo", "E", "promo_file", "", "", legacy="edit_promo", icon="file", reuse={"cool": 60},
   watch=["promo_reviewed", "promotion"])
iv("B01", "email_all", "B", "ws", "", "", legacy="email_all", tab="mail", icon="email", reuse={"cool": 90}, watch=["email_all_scene"])
iv("B02", "email_redirect", "B", "ws", "", "", legacy="email_redirect", tab="mail", icon="redirect", reuse={"cool": 90}, watch=["email_redirect_scene"])
iv("D01", "shuffle_files", "D", "ws", "", "", legacy="shuffle_files", tab="papers", icon="papers", reuse={"cool": 60},
   watch=["desk_messed", "accusation"])
iv("A01", "fake_notif", "A", "ws", "", "", legacy="fake_notif", tab="pc", icon="phone", reuse={"cool": 30},
   watch=["notif_boss", "notif_food", "notif_cancel", "notif_admirer"])
iv("H05", "move_item", "H", "item", "", "", legacy="move_item", icon="item", reuse={"cool": 5},
   watch=["item_missing", "item_found", "foreign_item", "item_returned"])


# =====================================================================
# A. COMPUTERS & DIGITAL SYSTEMS (desk -> Computer tab)
# =====================================================================
PC = dict(obj="ws", tab="pc", cat="A")
SUSPECT_DESK = [var("suspect", "suspect", desk=True, optional=True)]

# --- A02 lock their computer --------------------------------------------
L("lockpc_react", ["Wrong password?! I've had the same password for six years!", "Why won't it let me in?!", "LOCKED OUT. Of my own computer."],
  ahmet=["What is this? 'Account locked'? I AM the account!"], burak=["Someone locked ME out? That's... impressive."], ece=["Is it 'Password1'? 'Password2'? Help!"])
L("lockpc_reset", ["Fine. I'll reset it myself.", "Security question... 'name of first pet'... got it."], burak=["Give me thirty seconds. ...Twenty."])
S_("log.lockpc", "{actor} got locked out of their own computer. Work: zero.")
S_("log.lockpc_reset", "{actor} reset their own password, grumbling the whole time.")
scene("iv_lockpc_found", vars=SUSPECT_DESK,
      effects=[expr("actor", "surprised", 4), emote("actor", "exclaim"), say("actor", "lockpc_react"), stress("actor", 8),
               oset("ws.{owner}.locked", False, delay=28), log("log.lockpc", 2, "prank")],
      outcomes=[O_it("ws.{owner}.locked"),
                out("reset", [say("actor", "lockpc_reset", delay=1.5), oset("ws.{owner}.locked", False, delay=9), mood("actor", -4),
                              log("log.lockpc_reset", 1, "work")], score=[s_is("actor", "burak", 3), s_trait("actor", "diligence", 0.5), s_const(0.2)]),
                O_blame(), O_ghost()])
iv("A02", "lock_pc", title="Lock their computer", desc="Reset the password. They'll find out when they sit down.",
   log="The ghost locked {owner}'s computer.", **PC, icon="lock",
   conds=[why(c_os("ws.{owner}.locked", neg=True), "already_locked", "It's already locked.")],
   state=[oset("ws.{owner}.locked")], react=[desk_trap("iv_lockpc_found", "lockpc_{owner}")],
   watch=["iv_lockpc_found", "ivm_it_fix", "ivm_accuse"], reuse={"cool": 90, "day": 1})

# --- A03 move their file into the wrong folder (Ahmet's!) --------------------
L("misfile_react", ["Where's my file? It was RIGHT HERE.", "My folder's empty. Why is my folder empty?!", "No no no, where did it go?"],
  selin=["My entire proposal. Gone. From MY folder."], mert=["File? What file? ...Oh no, THAT file."])
L("misfile_boss", ["Why is {owner}'s file sitting in MY private folder?", "What is {owner}'s work doing in my folder?"])
S_("log.misfile", "{actor} lost a file from their folder. It's now sitting in Ahmet's private folder.")
S_("log.misfile_boss", "Ahmet found {owner}'s file in his private folder and wants to know how it got there.")
what("boss_folder", "your file turning up in my private folder")
scene("iv_misfile_found", vars=SUSPECT_DESK,
      effects=[expr("actor", "surprised", 4), say("actor", "misfile_react"), work("actor", -10), stress("actor", 6), log("log.misfile", 2, "prank")],
      outcomes=[O_it("ws.{owner}.misfiled"), O_blame(), O_shrug()])
scene("iv_misfile_boss", allow_absent=True, conditions=[c_present("actor"), c_present("owner")],
      effects=[emote("actor", "question"), say("actor", "misfile_boss"), rel("actor", "owner", "suspicion", 15), setv("what", "boss_folder"),
               summon("owner", "ivm_boss_talk", delay=2), log("log.misfile_boss", 2, "boss", who=["actor", "owner"])])
iv("A03", "misfile", title="Move their file into the wrong folder", desc="Straight into Ahmet's private folder.",
   log="The ghost moved {owner}'s file into Ahmet's private folder.", **PC, icon="folder", owners=["selin", "mert", "zeynep", "burak", "ece", "deniz", "ceren"],
   state=[oset("ws.{owner}.misfiled")],
   react=[desk_trap("iv_misfile_found", "misfile_{owner}"), trap("iv_misfile_boss", place="desk_ahmet", who="@ahmet", key="misfile_boss_{owner}", after=10)],
   watch=["iv_misfile_found", "iv_misfile_boss", "ivm_boss_talk", "ivm_it_fix"])

# --- A04 change the author of their project file ------------------------------
L("author_boss_sees", ["{target}! This project file — excellent work.", "I just read {target}'s project. Finally, some quality."])
L("author_take", ["Thank you, Ahmet Bey. I worked hard on it.", "Oh — happy you liked it!"], deniz=["Of course. I always deliver."])
L("author_correct", ["Actually, Ahmet Bey, that's {owner}'s work, not mine.", "That one's {owner}'s. I can't take credit for it."],
  ceren=["That's {owner}'s project. Let's give credit where it's due."], selin=["That isn't mine. It's {owner}'s."])
L("author_owner_hears", ["...Wait. That's MY project.", "Excuse me? I wrote that!"])
S_("log.author_take", "Ahmet praised {target} for {owner}'s project (the author's name had changed). {target} just... said thank you.")
S_("log.author_correct", "Ahmet praised {target} for {owner}'s project. {target} set the record straight. Respect.")
S_("mem.author_credit", "{target} took credit for my project.")
S_("mem.author_honest", "{target} told Ahmet that project was mine.")
scene("iv_author_review", allow_absent=True, conditions=[c_present("actor"), c_present("target")],
      effects=[emote("actor", "idea"), visit("actor", "target", "iv_author_praise", prio=60, ttl=70)])
scene("iv_author_praise", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "author_boss_sees", to="target")],
      outcomes=[
          out("take", [say("target", "author_take", to="actor", delay=1.8), favor("target", 7), favor("owner", -3),
                       rumor("credit_steal", a="target", b="owner", juicy=0.8, knowers=["target"]), witness([learn("self", "$rumor")], near="actor", r=5),
                       say("owner", "author_owner_hears", delay=3.4, when=[c_near("owner", "actor", 6.5)]),
                       learn("owner", "$rumor", c=0.9, when=[c_near("owner", "actor", 6.5)]),
                       mem("owner", "target", "credit_stolen", -0.7, 0.9, "mem.author_credit", 3, when=[c_near("owner", "actor", 6.5)]),
                       rel("owner", "target", "resentment", 22, when=[c_near("owner", "actor", 6.5)]), log("log.author_take", 3, "scheme", who=["target", "owner"])],
              score=[s_trait("target", "cunning", 1.2), s_trait("target", "honesty", -1.0), s_trait("target", "ambition", 0.5)]),
          out("correct", [say("target", "author_correct", to="actor", delay=1.8), favor("owner", 5), favor("target", 2),
                          rel("actor", "target", "respect", 10), rel("owner", "target", "trust", 10), rel("owner", "target", "friendship", 6),
                          mem("owner", "target", "honest", 0.6, 0.8, "mem.author_honest", 2), log("log.author_correct", 2, "reward", who=["target", "owner"])],
              score=[s_trait("target", "honesty", 1.3), s_aff("target", "owner", 0.015)]),
      ])
iv("A04", "change_author", title="Change the project file's author", desc="Put someone else's name on their work. Ahmet reads it later.",
   log="The ghost put {target}'s name on {owner}'s project file.", **PC, needs="person", icon="file",
   owners=["selin", "mert", "zeynep", "burak", "ece", "deniz", "ceren"], pick=[c_is("self", "ahmet", neg=True)],
   conds=[r_present("@ahmet"), r_time(before="15:45")],
   state=[oset("ws.{owner}.author", "%target")],
   react=[trap("iv_author_review", place="desk_ahmet", who="@ahmet", key="author_{owner}", after=5)],
   watch=["iv_author_praise"], reuse={"cool": 240, "day": 1})

# --- A05 swap their presentation slides --------------------------------------
L("slides_wrong", ["...These aren't my slides.", "Wait. Whose presentation is this?!", "Um. Slide one... is not my slide one."],
  selin=["This is not my deck. Someone swapped my file!"], mert=["Okay, plot twist: I'll be presenting someone else's work."])
L("slides_improv", ["Well. Let me tell you about it anyway — from memory.", "Forget the slides. Here's the idea."])
L("slides_freeze", ["I... um... I'm sorry, I...", "Can we... take five?"])
L("slides_steal", ["Actually, these are some ideas I've been exploring.", "As you can see... my vision."])
L("slides_target_angry", ["Those are MY slides!", "Hey! That's my presentation!"])
S_("log.slides_improv", "{actor}'s presentation file had {owner2}'s slides in it. {actor} improvised the whole thing. Ahmet was impressed.")
S_("log.slides_freeze", "{actor} opened their presentation and found {owner2}'s slides. They froze in front of everyone.")
S_("log.slides_steal", "{actor} found {owner2}'s slides in their file — and presented them as their own. {owner2} noticed.")
S_("mem.slides_humiliated", "I froze in the meeting. Someone swapped my slides.")
scene("iv_slides_swapped", noise=0.9, allow_absent=True, conditions=[c_present("actor")],
      vars=[var("owner2", "slides_owner")],
      effects=[hold(["actor"], 4), expr("actor", "surprised", 5), emote("actor", "exclaim"), say("actor", "slides_wrong")],
      outcomes=[
          out("improv", [say("actor", "slides_improv", delay=1.8), emote("actor", "idea", delay=1.8), favor("actor", 6), morale("actor", 3),
                         witness([rel("self", "actor", "respect", 8)], r=6), log("log.slides_improv", 3, "meeting")],
              score=[s_trait("actor", "diligence", 0.8), s_trait("actor", "ambition", 0.5), s_trait("actor", "temper", -0.3)]),
          out("freeze", [say("actor", "slides_freeze", delay=1.8), expr("actor", "sad", 6, delay=1.8), emote("actor", "sweat", delay=1.8), favor("actor", -6),
                         mem("actor", "", "humiliated", -0.6, 0.9, "mem.slides_humiliated", 3), witness([rel("self", "actor", "respect", -4)], r=6),
                         log("log.slides_freeze", 3, "meeting")],
              score=[s_stress("actor", 0.02), s_trait("actor", "clumsiness", 0.8), s_const(0.3)]),
          out("steal", [say("actor", "slides_steal", delay=1.8), favor("actor", 4), say("$owner2", "slides_target_angry", delay=3.6, when=[c_present("$owner2")]),
                        rel("$owner2", "actor", "resentment", 25), rel("$owner2", "actor", "trust", -15),
                        rumor("credit_steal", a="actor", b="$owner2", juicy=0.85, knowers=["$owner2"]), witness([learn("self", "$rumor")], r=6),
                        log("log.slides_steal", 4, "scheme", who=["actor", "$owner2"])],
              score=[s_trait("actor", "cunning", 1.3), s_trait("actor", "honesty", -0.8)], when=[c_filled("$owner2")]),
      ])
iv("A05", "swap_slides", title="Swap their presentation file", desc="Their deck now contains someone else's slides — and they're presenting first.",
   log="The ghost swapped {owner}'s presentation with {target}'s slides.", **PC, needs="person", icon="board",
   owners=["selin", "mert", "zeynep", "burak", "ece", "deniz", "ceren"], pick=[c_is("self", "ahmet", neg=True)],
   conds=[r_meeting_pending(), r_meeting_not_started(),
          why({"c": "attends", "who": "owner"}, "not_attending", "They're not at today's meeting.")],
   state=[mtg("swap", "%target", who="owner"), mtg("first", "%owner")],
   react=[on_trap("meeting_present", "iv_slides_swapped", who="owner", key="slides_{owner}", replace=True)],
   watch=["iv_slides_swapped"], reuse={"cool": 600, "day": 1, "per": "global"})

# --- A06 change their computer clock ------------------------------------
L("clock_leave_boss", ["Where do you think you're going? It's {time}!", "Leaving already, {target}? It's only {time}."])
L("clock_leave_excuse", ["But my computer says it's five o'clock!", "What? My clock says I'm done!"])
L("clock_leave_scold", ["Then your computer can do your job. Back to your desk.", "Get that clock fixed. And sit down."])
L("clock_leave_laugh", ["...Your clock is wrong. Go on then, just this once.", "Ha. Go. But get that fixed."])
L("clock_late_react", ["My clock said I had twenty minutes!", "Late?! My computer is LYING to me."])
S_("log.clock_leave_scold", "{target}'s computer clock ran 45 minutes fast. They packed up early — right past Ahmet. Back to the desk.")
S_("log.clock_leave_free", "{target}'s computer clock ran fast and they left early. Ahmet let it slide.")
S_("log.clock_left", "{actor} left 45 minutes early because their computer clock was wrong. Nobody stopped them.")
S_("log.clock_late", "{actor} was late for the meeting — their computer clock was running slow.")
scene("iv_clock_leave", noise=0.8, allow_absent=True, conditions=[c_present("actor")],
      vars=[var("time", "now_time")],
      outcomes=[
          out("caught", [setv("caught", True), visit("@ahmet", "actor", "iv_clock_caught", prio=80, ttl=12)], score=[s_const(2)],
              when=[c_avail("@ahmet"), c_time(before="17:10"), c_is("actor", "ahmet", neg=True)]),
          out("gone", [log("log.clock_left", 2, "work"), favor("actor", -2)], score=[s_const(1)]),
      ])
scene("iv_clock_caught", noise=0.8, conditions=[c_present("target")],
      vars=[var("time", "now_time")],
      effects=[hold(["actor", "target"], 5), expr("actor", "angry", 4), say("actor", "clock_leave_boss", to="target"),
               say("target", "clock_leave_excuse", to="actor", delay=1.6)],
      outcomes=[
          out("scold", [say("actor", "clock_leave_scold", to="target", delay=3.2), npcval("target", "leave_at", d=50), favor("target", -4),
                        mood("target", -8), log("log.clock_leave_scold", 3, "boss", who=["target"])],
              score=[s_trait("actor", "temper", 1.0), s_const(0.4)]),
          out("free", [say("actor", "clock_leave_laugh", to="target", delay=3.2), log("log.clock_leave_free", 2, "boss", who=["target"])],
              score=[s_mood("actor", 0.02), s_rel("actor", "target", "trust", 0.02)]),
      ])
scene("iv_clock_late", allow_absent=True, conditions=[c_present("actor")],
      effects=[say("actor", "clock_late_react"), emote("actor", "sweat"), log("log.clock_late", 2, "meeting")])
what("clock_fast", "45 minutes fast")
what("clock_slow", "30 minutes slow")
iv("A06", "pc_clock", title="Change their computer clock", desc="Fast: they pack up early. Slow: they're late for everything.",
   log="The ghost set {owner}'s computer clock {what}.", **PC, needs="choice", icon="calendar",
   choices=[choice("fast", "45 minutes fast"), choice("slow", "30 minutes slow")],
   conds=[r_present(), r_time(before="16:30")],
   state=[oset("ws.{owner}.clock", "$choice"), setf("what", "clock_{choice}"),
          npcval("owner", "leave_at", d=-45, when=[c_var("choice", eq="fast")]),
          npcval("owner", "leave_at", d=30, when=[c_var("choice", eq="slow")]),
          mtg("belief", who="owner", d=-20, when=[c_var("choice", eq="fast")]),
          mtg("belief", who="owner", d=25, when=[c_var("choice", eq="slow")])],
   react=[on_trap("leaving", "iv_clock_leave", who="owner", key="clock_{owner}"),
          on_trap("meeting_late", "iv_clock_late", who="owner", key="clockm_{owner}")],
   watch=["iv_clock_caught", "iv_clock_leave", "iv_clock_late"])

# --- A07 hide an important document ----------------------------------------
L("hide_doc_react", ["Where is it? It was on my desktop a second ago!", "My report. Has. Vanished.", "Okay, don't panic. Don't panic. PANIC."],
  ceren=["That file was right here. I'm never wrong about where things are."], zeynep=["My spreadsheet! Somebody took my spreadsheet!"])
L("hide_doc_search", ["Did anyone print my report? Has anyone SEEN it?", "Checking the printer... the archive... anywhere!"])
L("hide_doc_found", ["THERE you are! In 'Old Stuff 2019'?! How?!", "Found it. In a folder I've never seen before. Creepy."])
L("hide_doc_gone", ["It's gone. I'll have to redo it.", "Three hours of work... gone."])
S_("log.hide_doc_found", "{actor} searched the whole office for a missing report — it was hiding in a folder called 'Old Stuff 2019'.")
S_("log.hide_doc_gone", "{actor} never found the missing report and has to start over.")
scene("iv_doc_hidden", effects=[expr("actor", "surprised", 4), emote("actor", "exclaim"), say("actor", "hide_doc_react"), stress("actor", 10),
                                say("actor", "hide_doc_search", delay=1.6),
                                hunt("actor", ["printer", "archive", "kitchen", "desk_{owner}"], "iv_doc_hunt_end", prio=66, ttl=60)])
scene("iv_doc_hunt_end", noise=0.8, allow_absent=True, conditions=[c_present("actor")], vars=SUSPECT_DESK,
      outcomes=[
          out("found", [say("actor", "hide_doc_found"), emote("actor", "question"), oset("ws.{owner}.hidden_doc", False), ghost(), call("ghost_theory"),
                        log("log.hide_doc_found", 2, "ghost")], score=[s_trait("actor", "curiosity", 0.6), s_const(0.6)]),
          out("gone", [say("actor", "hide_doc_gone"), expr("actor", "sad", 6), work("actor", -16), npcval("actor", "leave_at", d=25),
                       oset("ws.{owner}.hidden_doc", False), mood("actor", -10), log("log.hide_doc_gone", 3, "work")],
              score=[s_stress("actor", 0.01), s_const(0.3)]),
          O_blame()])
iv("A07", "hide_doc", title="Hide an important document", desc="Tuck their report somewhere nobody would look.",
   log="The ghost hid {owner}'s report deep in an old folder.", **PC, icon="folder",
   state=[oset("ws.{owner}.hidden_doc")], react=[desk_trap("iv_doc_hidden", "hidedoc_{owner}")],
   watch=["iv_doc_hidden", "iv_doc_hunt_end", "ivm_accuse"])

# --- A08 restore an old version of their file ---------------------------------
L("oldver_react", ["Why is my report from LAST WEEK?!", "All my changes... they're gone!", "Who rolled back my file?!"],
  selin=["I have rewritten this section four times. FOUR."], deniz=["This is... last Tuesday's version. Interesting."])
L("oldver_ask", ["{target}, do we have backups? Please say we have backups.", "{target}, can you bring back my file? My changes vanished."])
L("oldver_saved", ["Restored from last night's backup. You owe me.", "There. Every comma back where it was."])
L("oldver_none", ["Backups run Fridays. Today isn't Friday.", "Sorry. That version is gone."])
L("oldver_redo", ["Fine. I'll redo it. Tonight. Apparently.", "Overtime it is."])
S_("log.oldver_saved", "Someone rolled back {actor}'s report to last week's version. {target} rescued it from a backup.")
S_("log.oldver_none", "{actor}'s file was rolled back a week. No backup. {actor} is redoing everything.")
S_("log.oldver_redo", "{actor}'s changes vanished — they're staying late to redo them.")
scene("iv_oldver_backup", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "oldver_ask", to="target")],
      outcomes=[
          out("saved", [say("target", "oldver_saved", to="actor", delay=1.6), work("actor", 18), rel("actor", "target", "respect", 8), rel("actor", "target", "friendship", 5),
                        mem("actor", "target", "helped_me", 0.6, 0.8, "mem.ivm_it_helped", 2), log("log.oldver_saved", 3, "help")],
              score=[s_trait("target", "diligence", 0.8), s_aff("target", "actor", 0.02), s_const(0.3)]),
          out("none", [say("target", "oldver_none", to="actor", delay=1.6), mood("actor", -10), npcval("actor", "leave_at", d=30),
                       log("log.oldver_none", 3, "work")], score=[s_const(0.5)]),
      ])
scene("iv_oldver_found", vars=SUSPECT_DESK,
      effects=[expr("actor", "angry", 5), emote("actor", "anger"), say("actor", "oldver_react"), stress("actor", 10)],
      outcomes=[
          out("backup", [visit("actor", "@burak", "iv_oldver_backup", prio=64, ttl=60, delay=1.5)], score=[s_const(0.8)],
              when=[c_present("@burak"), c_is("actor", "burak", neg=True)]),
          out("redo", [say("actor", "oldver_redo", delay=1.5), npcval("actor", "leave_at", d=35), log("log.oldver_redo", 2, "work")],
              score=[s_trait("actor", "diligence", 0.9), s_const(0.2)]),
          O_blame()])
iv("A08", "old_version", title="Restore an old version of their file", desc="Roll their report back to last week. Every change: gone.",
   log="The ghost rolled {owner}'s report back to last week's version.", **PC, icon="file",
   conds=[why(c_work_left("owner", gt=8), "no_work", "They don't have any work in progress.")],
   state=[work("owner", -18), oset("ws.{owner}.oldver")], react=[desk_trap("iv_oldver_found", "oldver_{owner}")],
   watch=["iv_oldver_found", "iv_oldver_backup", "ivm_accuse"])

# --- A09 fake virus alert --------------------------------------------------
L("virus_scream", ["AAAH! 'YOUR COMPUTER IS INFECTED'!", "Virus! VIRUS! Everybody unplug everything!", "It says 'all your files are encrypted'!!"],
  ahmet=["What is this flashing red thing?! Burak!"], burak=["...A fake popup. On MY network? Bold."], ece=["I clicked nothing! I swear I clicked nothing!"])
L("virus_ask", ["{target}! VIRUS! Red screen! Skull!", "{target}, my computer's been hacked!"])
L("virus_fake", ["...It's a fake popup. Close the window.", "That's not a virus. That's a joke. Close it."])
L("virus_shutdown", ["Unplugging the network. NOBODY TOUCH ANYTHING.", "Pulling the plug on the whole floor, just in case."])
S_("log.virus_fake", "{actor} screamed about a virus. {target} closed a fake popup in two seconds. The office is still laughing.")
S_("log.virus_shutdown", "{actor}'s 'virus' made {target} pull the plug on the office network. Nobody can work.")
scene("iv_virus_it", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "virus_ask", to="target")],
      outcomes=[
          out("fake", [say("target", "virus_fake", to="actor", delay=1.5), oset("ws.{owner}.virus", False), mood("actor", -6),
                       witness([say("self", "witness_laugh", p=0.5, delay=2.5), rel("self", "actor", "respect", -3)], r=6),
                       log("log.virus_fake", 2, "prank")], score=[s_trait("target", "curiosity", 0.6), s_const(0.6)]),
          out("shutdown", [say("target", "virus_shutdown", to="actor", delay=1.5), oset("ws.{owner}.virus", False), oset("net.down"), oset("net.broken"),
                           call("fix_intent", who="target", obj="net", requester="actor", prio=70, delay=10), stat("breakdowns"),
                           each([emote("self", "question", when=[c_not(c_same("self", "target"))])], stagger=0.2),
                           log("log.virus_shutdown", 3, "malfunction")],
              score=[s_trait("target", "diligence", 0.6), s_stress("target", 0.01), s_const(0.2)]),
      ])
L("witness_laugh", ["Hahaha!", "Oh, that's priceless.", "I can't breathe!", "Somebody record this!"], mert=["Best day ever."], zeynep=["Ooh, this is going in my diary."])
scene("iv_virus_found", effects=[expr("actor", "surprised", 6), emote("actor", "exclaim"), say("actor", "virus_scream"), stress("actor", 14), sfx("alarm"),
                                 witness([emote("self", "exclaim")], r=6)],
      outcomes=[
          out("burak", [visit("actor", "@burak", "iv_virus_it", prio=70, ttl=40, delay=1.0)], score=[s_const(1)],
              when=[c_present("@burak"), c_is("actor", "burak", neg=True)]),
          out("selfclose", [say("actor", "virus_fake"), oset("ws.{owner}.virus", False), mood("actor", -2)], score=[s_const(0.2), s_is("actor", "burak", 5)]),
      ])
iv("A09", "virus_alert", title="Pop up a fake virus alert", desc="Flashing red skull, scary sirens. It's harmless. They don't know that.",
   log="The ghost put a fake virus alert on {owner}'s screen.", **PC, icon="ghost",
   state=[oset("ws.{owner}.virus")], react=[desk_trap("iv_virus_found", "virus_{owner}")],
   watch=["iv_virus_found", "iv_virus_it", "fix_done"])

# --- A10 make their confidential file appear on someone else's screen ------
L("onscreen_read", ["Wait... why is this on MY screen?", "Huh. This isn't my file. Oh. OH.", "...I definitely wasn't supposed to see this."],
  zeynep=["Well, well. Look what landed on my desktop."], ceren=["This must have been sent to me by mistake. ...Still."])
S_("log.onscreen", "{owner}'s private file popped up on {actor}'s screen. {actor} read it.")
scene("iv_onscreen_read", allow_absent=True, conditions=[c_present("actor"), {"c": "fact_exists", "fact": "$fact"}],
      effects=[expr("actor", "surprised", 4), say("actor", "onscreen_read"), learn("actor", "$fact", c=1.0), reveal("$fact"),
               log("log.onscreen", 3, "secret", who=["actor", "owner"]), chain("ivm_secret", delay=1.5, roles={"actor": "actor"})])
iv("A10", "file_elsewhere", title="Make their private file open on someone else's screen", desc="Pick whose screen. They'll read it at their desk.",
   log="The ghost sent one of {owner}'s private files to {target}'s screen.", **PC, needs="person", icon="redirect",
   vars=private_vars("owner"), pick=[],
   state=private_info("owner") + [oset("ws.{target}.foreign_file", "%owner")],
   react=[trap("iv_onscreen_read", place="desk_{target}", who="target", key="onscreen_{target}")],
   watch=["iv_onscreen_read", "ivm_secret", "ivm_spread", "kitchen_gossip_scene", "ivm_tell_boss", "rumor_check_scene"], reuse={"cool": 120, "day": 1})

# --- A11 change their wallpaper ----------------------------------------------
L("wall_kittens", ["Why are there forty kittens on my screen?", "Kittens. Everywhere. ...Okay, they're cute."], ahmet=["WHO PUT KITTENS ON MY COMPUTER?"], burak=["Kittens. On MY screen. Okay."])
L("wall_boss", ["Why is Ahmet's face on my wallpaper?!", "Ahmet is... staring at me. From my desktop.", "That is a HUGE photo of our boss."], ahmet=["...Well. It's a good photo."])
L("wall_beach", ["Ahh... a beach. I could just... leave.", "Palm trees. Ocean. And here I am, doing expenses."])
L("wall_keep", ["You know what? It stays.", "I'm keeping it. It's growing on me."])
L("wall_change", ["Nope. Changing it back.", "Absolutely not. Back to blue."])
L("wall_witness", ["Nice wallpaper!", "Is that... what I think it is?", "Ha! Love it."])
S_("log.wall_kittens", "{actor} sat down to find forty kittens on their wallpaper.")
S_("log.wall_boss", "{actor}'s wallpaper is now a giant photo of Ahmet. People are staring.")
S_("log.wall_beach", "{actor}'s wallpaper is a tropical beach. Productivity: gone.")
S_("log.wall_keep", "{actor} decided to keep the ghost's wallpaper.")
scene("iv_wallpaper_seen", noise=0.7,
      effects=[expr("actor", "surprised", 3), say("actor", "wall_kittens", when=[c_var("choice", eq="kittens")]), say("actor", "wall_boss", when=[c_var("choice", eq="boss")]),
               say("actor", "wall_beach", when=[c_var("choice", eq="beach")]), mood("actor", 4, when=[c_var("choice", in_=["kittens", "beach"])]),
               work("actor", -4, when=[c_var("choice", eq="beach")]), npcflag("actor", "daydream", when=[c_var("choice", eq="beach")]),
               log("log.wall_kittens", 2, "prank", when=[c_var("choice", eq="kittens")]), log("log.wall_boss", 2, "prank", when=[c_var("choice", eq="boss")]),
               log("log.wall_beach", 2, "prank", when=[c_var("choice", eq="beach")]),
               witness([say("self", "wall_witness", p=0.45, delay=2.0), rel("self", "actor", "friendship", 2, when=[c_trait("self", "humor", gt=0.5)])], r=3.5)],
      outcomes=[out("keep", [say("actor", "wall_keep", delay=2.2), emote("actor", "ok", delay=2.2), log("log.wall_keep", 1, "prank")],
                    score=[s_trait("actor", "humor", 1.2), s_const(0.1)]),
                out("change", [say("actor", "wall_change", delay=2.2), oset("ws.{owner}.wallpaper", "")], score=[s_trait("actor", "temper", 0.8), s_const(0.3)]),
                O_blame()], vars=SUSPECT_DESK)
iv("A11", "wallpaper", title="Change their wallpaper", desc="Something they'll definitely notice.",
   log="The ghost changed {owner}'s wallpaper.", **PC, needs="choice", icon="star",
   choices=[choice("kittens", "Forty kittens"), choice("boss", "A huge photo of Ahmet"), choice("beach", "A tropical beach")],
   state=[oset("ws.{owner}.wallpaper", "$choice")], react=[desk_trap("iv_wallpaper_seen", "wallpaper_{owner}")],
   watch=["iv_wallpaper_seen", "ivm_accuse"])

# --- A12 autocorrect "Ahmet Bey" -> "Ahmet Bae" ------------------------------------
L("bae_boss_reads", ["'Dear Ahmet Bae'?! {owner}! In here. NOW.", "Did {owner} just call me... 'Bae'?"])
L("bae_mortified", ["It's AUTOCORRECT! I swear it's autocorrect!", "I would NEVER— that's not— my keyboard!"])
L("bae_boss_amused", ["...Hm. Fix your keyboard. And — never mind.", "I've been called worse. Go."])
L("bae_boss_offended", ["This is a workplace, not a dating app.", "Unprofessional. Extremely."])
L("bae_gossip", ["Did you hear? {owner} called Ahmet 'Bae'!", "'Ahmet Bae'! I'm framing that email."])
S_("log.bae_amused", "{owner}'s email to Ahmet started 'Dear Ahmet Bae'. Ahmet was... oddly amused.")
S_("log.bae_offended", "{owner}'s email to Ahmet started 'Dear Ahmet Bae'. Ahmet was not amused.")
scene("iv_bae_summon", allow_absent=True, conditions=[c_present("@ahmet"), c_present("owner")],
      effects=[visit("@ahmet", "owner", "iv_bae_scene", prio=70, ttl=40)])
scene("iv_bae_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "bae_boss_reads", to="target"), say("target", "bae_mortified", to="actor", delay=1.6),
               expr("target", "surprised", 5, delay=1.6), emote("target", "sweat", delay=1.6),
               witness([say("self", "bae_gossip", p=0.4, delay=3.5)], near="target", r=6)],
      outcomes=[out("amused", [say("actor", "bae_boss_amused", to="target", delay=3.2), rel("actor", "target", "friendship", 4), log("log.bae_amused", 3, "boss")],
                    score=[s_mood("actor", 0.02), s_trait("actor", "humor", 1.0), s_const(0.2)]),
                out("offended", [say("actor", "bae_boss_offended", to="target", delay=3.2), expr("actor", "angry", 5, delay=3.2), favor("target", -5),
                                 rel("actor", "target", "respect", -8), log("log.bae_offended", 3, "boss")],
                    score=[s_trait("actor", "temper", 0.8), s_stress("actor", 0.01)])])
iv("A12", "autocorrect", title="Set autocorrect: 'Ahmet Bey' → 'Ahmet Bae'", desc="Their next email to the boss will be... memorable.",
   log="The ghost changed {owner}'s autocorrect. 'Ahmet Bey' is now 'Ahmet Bae'.", **PC, icon="email",
   owners=["selin", "mert", "zeynep", "burak", "ece", "deniz", "ceren"], conds=[r_present("@ahmet")],
   state=[oset("ws.{owner}.autocorrect")], react=[desk_trap("iv_bae_summon", "bae_{owner}")],
   watch=["iv_bae_scene"], reuse={"cool": 300, "day": 1})

# --- A13 leave a job-site tab open on their screen ---------------------------------
L("jobtab_see", ["Is {owner} looking at job listings?!", "Hm. 'Senior positions — apply now.' On {owner}'s screen.", "{owner}'s browsing job ads. Interesting."],
  ahmet=["Job listings. On company time. On {owner}'s screen."], zeynep=["Oh, {owner} is shopping for a new office!"])
S_("log.jobtab", "{actor} walked past {owner}'s desk and saw job listings open on the screen.")
scene("iv_jobtab_seen", allow_absent=True, conditions=[c_present("actor"), c_not(c_same("actor", "owner"))],
      effects=[emote("actor", "question"), say("actor", "jobtab_see"), rumor("job_hunting", a="owner", b="actor", juicy=0.75, knowers=[], key="fact", truth=False,
               when=[c_plan("owner", "job_search", neg=True), {"c": "goal", "who": "owner", "goal": "find_new_job", "not": True}]),
               rumor("job_hunting", a="owner", b="actor", juicy=0.75, knowers=[], key="fact",
                     when=[c_any(c_plan("owner", "job_search"), c_goal("owner", "find_new_job"))]),
               learn("actor", "$fact", c=0.8), log("log.jobtab", 2, "rumor", who=["actor", "owner"])],
      outcomes=[out("boss", [summon("owner", "ivm_boss_talk", delay=2), setv("what", "job_ads"), rel("actor", "owner", "trust", -12), favor("owner", -6)],
                    score=[s_const(5)], when=[c_is("actor", "ahmet")]),
                out("think", [chain("ivm_secret", delay=1.5)], score=[s_const(1)])])
what("job_ads", "the job listings on your screen")
iv("A13", "job_tab", title="Leave job listings open on their screen", desc="The next person walking past will draw conclusions.",
   log="The ghost opened job listings on {owner}'s screen.", **PC, icon="newspaper",
   owners=["selin", "mert", "zeynep", "burak", "ece", "deniz", "ceren"],
   state=[oset("ws.{owner}.jobtab")], react=[near_trap("iv_jobtab_seen", "desk_{owner}", not_="owner", key="jobtab_{owner}", r=2.2, days=0)],
   watch=["iv_jobtab_seen", "ivm_boss_talk", "ivm_secret"])

# --- A14 unplug their monitor ----------------------------------------------
L("unplug_react", ["My screen's black. Did my computer die?!", "It's dead. Completely dead.", "Hello? HELLO? Screen?"],
  ahmet=["My monitor is broken. Somebody fix it."], burak=["...The cable's out. Somebody unplugged my monitor."])
L("unplug_self", ["Oh. It's... unplugged. Hah. Don't tell anyone.", "Wait. The cable. Who unplugs a monitor?!"])
S_("log.unplug_self", "{actor}'s 'dead' monitor was just unplugged. They noticed. Eventually.")
scene("iv_unplug_found", vars=SUSPECT_DESK,
      effects=[expr("actor", "surprised", 4), say("actor", "unplug_react"), stress("actor", 6), oset("ws.{owner}.unplugged", False, delay=30)],
      outcomes=[O_it("ws.{owner}.unplugged"),
                out("self", [say("actor", "unplug_self", delay=1.6), oset("ws.{owner}.unplugged", False, delay=1), emote("actor", "sweat", delay=1.6),
                             log("log.unplug_self", 2, "prank")], score=[s_trait("actor", "curiosity", 0.7), s_is("actor", "burak", 4), s_const(0.1)]),
                O_blame()])
iv("A14", "unplug_monitor", title="Unplug their monitor", desc="The simplest prank. Watch them panic.",
   log="The ghost unplugged {owner}'s monitor.", **PC, icon="bulb",
   state=[oset("ws.{owner}.unplugged")], react=[desk_trap("iv_unplug_found", "unplug_{owner}")],
   watch=["iv_unplug_found", "ivm_it_fix", "ivm_accuse"])

# --- A15 send their private file to the shared printer --------------------------
L("printjob_mine", ["Why is MY private document coming out of the printer?!", "Wait — I didn't print this! Give me that!"])
L("printjob_other", ["Ooh. Whose is this? Oh. OH.", "This was in the printer tray. I didn't read it. ...I read it.", "Hm. Somebody printed something private."],
  zeynep=["The printer is my favourite newspaper."], ece=["I'm not reading it! ...I read a little."])
S_("log.printjob_mine", "{owner}'s private file came out of the shared printer — luckily {owner} grabbed it first.")
S_("log.printjob_other", "{actor} picked up {owner}'s private document from the printer tray. And read it.")
scene("iv_printjob", allow_absent=True, conditions=[c_present("actor")],
      outcomes=[
          out("mine", [say("actor", "printjob_mine"), emote("actor", "sweat"), stress("actor", 6), oset("printer.queue", ""), log("log.printjob_mine", 2, "prank")],
              score=[s_const(9)], when=[c_same("actor", "owner")]),
          out("read", [say("actor", "printjob_other"), learn("actor", "$fact", c=1.0), reveal("$fact"), oset("printer.queue", ""),
                       log("log.printjob_other", 3, "secret", who=["actor", "owner"]), chain("ivm_secret", delay=1.5)],
              score=[s_const(1)], when=[c_not(c_same("actor", "owner")), {"c": "fact_exists", "fact": "$fact"}]),
      ])
iv("A15", "print_private", title="Send their private file to the shared printer", desc="Whoever prints next gets a surprise page.",
   log="The ghost sent one of {owner}'s private files to the office printer.", **PC, icon="printer",
   conds=[why(c_office("printer.broken", False), "printer_broken", "The printer is broken.")],
   vars=private_vars("owner"), state=private_info("owner") + [oset("printer.queue", "%owner")],
   react=[trap("iv_printjob", place="#printer", key="printjob", days=1)],
   watch=["iv_printjob", "ivm_secret", "ivm_spread", "ivm_tell_boss"])

# --- A16 put a fake appointment in their calendar -------------------------------
L("cal_remind", ["Oh no — my {what} is in ten minutes! I completely forgot!", "My calendar says: {what}. Right. Gotta go!"])
L("cal_doubt", ["A {what}? I don't have a {what}...", "That's not mine. Who put this in my calendar?"])
L("cal_where", ["Where's {owner}? Anybody?", "Has anyone seen {owner}? Their desk's been empty for ages."])
S_("log.cal_left", "A {what} appeared in {actor}'s calendar. {actor} rushed out of the office for it.")
S_("log.cal_doubt", "{actor} found a {what} in their calendar they never made. Creepy.")
S_("log.cal_where", "Ahmet noticed {owner} was gone. Rumours started about where.")
scene("iv_cal_found", noise=0.8,
      outcomes=[
          out("go", [say("actor", "cal_remind"), emote("actor", "exclaim"), away("actor", 40, "appointment", delay=1.5),
                     log("log.cal_left", 2, "work"), chain("iv_cal_missing", delay=20)],
              score=[s_trait("actor", "diligence", -0.8), s_trait("actor", "curiosity", -0.3), s_const(0.9)]),
          out("doubt", [say("actor", "cal_doubt"), emote("actor", "question"), ghost(), call("ghost_theory"), log("log.cal_doubt", 2, "ghost")],
              score=[s_trait("actor", "diligence", 0.9), s_trait("actor", "curiosity", 0.4)]),
      ])
scene("iv_cal_missing", allow_absent=True, conditions=[c_avail("@ahmet")],
      effects=[say("@ahmet", "cal_where"), rumor("interview", a="owner", b="@ahmet", juicy=0.7, truth=False, knowers=["@ahmet"], when=[c_var("choice", eq="interview")]),
               rumor("slacker", a="owner", b="@ahmet", juicy=0.5, truth=False, knowers=["@ahmet"], when=[c_var("choice", eq="dentist")]),
               witness([learn("self", "$rumor")], near="@ahmet", r=6), favor("owner", -3), log("log.cal_where", 2, "rumor", who=["owner"])])
iv("A16", "fake_appointment", title="Add a fake appointment to their calendar", desc="A reminder pops up. Will they go?",
   log="The ghost added a fake {what} to {owner}'s calendar.", **PC, needs="choice", icon="calendar",
   choices=[choice("dentist", "Dentist appointment"), choice("interview", "'Job interview' (in the shared calendar)")],
   conds=[r_present(), r_time(after="09:30", before="15:30")],
   state=[oset("ws.{owner}.calendar", "$choice"), setf("what", "appt_{choice}")],
   react=[desk_trap("iv_cal_found", "cal_{owner}")], watch=["iv_cal_found", "iv_cal_missing"])
what("appt_dentist", "dentist appointment")
what("appt_interview", "job interview")

# --- A17 throttle their internet ----------------------------------------------
L("slow_react", ["Why is everything loading at 1990s speed?", "Come ON. One email. ONE.", "The little wheel. The spinning wheel of doom."],
  mert=["My internet is slower than Monday."], selin=["I cannot work like this."])
L("slow_break", ["Forget it. Coffee break until the internet remembers me.", "I'm taking a walk. The internet can come find me."])
S_("log.slow", "{actor}'s internet slowed to a crawl. Work is crawling too.")
S_("log.slow_break", "{actor} gave up on their slow internet and went for a long coffee.")
scene("iv_slow_found", vars=SUSPECT_DESK,
      effects=[expr("actor", "angry", 4), say("actor", "slow_react"), stress("actor", 6), log("log.slow", 2, "work")],
      outcomes=[O_it("ws.{owner}.slow"),
                out("break", [say("actor", "slow_break", delay=1.6), act("actor", "coffee", dur=8), log("log.slow_break", 1, "work")],
                    score=[s_trait("actor", "diligence", -0.8), s_const(0.5)]),
                out("rage", [emote("actor", "anger", delay=1.4), sfx("thump", delay=1.4), fx("shake", "actor", delay=1.4), stress("actor", 6)],
                    score=[s_trait("actor", "temper", 1.2)])])
iv("A17", "slow_net", title="Throttle their internet", desc="Everything they do takes twice as long — until IT fixes it.",
   log="The ghost throttled {owner}'s internet connection.", **PC, icon="gear",
   state=[oset("ws.{owner}.slow")], react=[desk_trap("iv_slow_found", "slow_{owner}")],
   watch=["iv_slow_found", "ivm_it_fix"])

# --- A18 caps lock on their chat -----------------------------------------------
L("caps_read", ["Why is {owner} YELLING at me?!", "'HOW ARE YOU' — in capitals? Is {owner} angry with me?"])
L("caps_confront", ["{target}, why did you shout at me in chat?", "What did I do to deserve ALL CAPS, {target}?"])
L("caps_explain", ["What? I didn't shout! My caps lock must be stuck!", "I wrote 'how are you'! Normally!"])
L("caps_hurt", ["Sure. Whatever.", "Just say it if you're upset with me."])
L("caps_laugh", ["Oh my god, it's just caps lock. Ha!", "Okay, that's funny. Your keyboard hates you."])
S_("log.caps_hurt", "{actor} got an ALL-CAPS chat message from {target} and took it personally.")
S_("log.caps_laugh", "{actor} thought {target} was shouting at them in chat. It was a stuck caps lock. They laughed it off.")
scene("iv_caps_sent", allow_absent=True, conditions=[c_present("friend")],
      effects=[emote("friend", "question"), say("friend", "caps_read"), visit("friend", "owner", "iv_caps_scene", prio=60, ttl=45, delay=2)])
scene("iv_caps_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "caps_confront", to="target"), say("target", "caps_explain", to="actor", delay=1.6)],
      outcomes=[out("hurt", [say("actor", "caps_hurt", to="target", delay=3.2), expr("actor", "sad", 5, delay=3.2), rel("actor", "target", "friendship", -8),
                             rel("actor", "target", "resentment", 6), log("log.caps_hurt", 2, "misunderstanding")],
                    score=[s_trait("actor", "temper", 0.6), s_stress("actor", 0.012), s_trait("actor", "forgiveness", -0.5)]),
                out("laugh", [say("actor", "caps_laugh", to="target", delay=3.2), rel("actor", "target", "friendship", 4, both=True), log("log.caps_laugh", 2, "friendship")],
                    score=[s_trait("actor", "humor", 1.0), s_aff("actor", "target", 0.015), s_const(0.3)])])
iv("A18", "caps_lock", title="Jam caps lock on their chat", desc="Their next message to their best friend arrives as SHOUTING.",
   log="The ghost jammed {owner}'s caps lock.", **PC, icon="email", vars=[var("friend", "best_of", of="owner", lim=-50, role=True, avail=False)],
   state=[oset("ws.{owner}.caps")], react=[desk_trap("iv_caps_sent", "caps_{owner}")], watch=["iv_caps_scene"])

# --- A19 make their keyboard meow ------------------------------------------------
L("meow_react", ["Why does my keyboard MEOW?!", "Every key. Meow. Meow. MEOW.", "Is there a cat in my computer?"],
  ahmet=["Why is my keyboard meowing?! WHO DID THIS?"], burak=["...I respect the craftsmanship. I also hate it."])
L("meow_love", ["...Honestly? I love it. Meow.", "I'm never changing this. Meow meow."])
L("meow_witness", ["Is that... meowing?", "*giggles*", "Is there a CAT in the office?"])
S_("log.meow", "{actor}'s keyboard meows with every keystroke. The whole row can hear it.")
S_("log.meow_love", "{actor}'s keyboard meows now. They've decided they love it.")
scene("iv_meow_found", vars=SUSPECT_DESK,
      effects=[expr("actor", "surprised", 4), say("actor", "meow_react"), log("log.meow", 2, "prank"),
               witness([say("self", "meow_witness", p=0.5, delay=1.8), mood("self", 3, when=[c_trait("self", "humor", gt=0.5)]),
                        stress("self", 3, when=[c_trait("self", "humor", lt=0.35)])], r=4.5)],
      outcomes=[out("love", [say("actor", "meow_love", delay=2), emote("actor", "love", delay=2), mood("actor", 5), log("log.meow_love", 1, "prank")],
                    score=[s_trait("actor", "humor", 1.4)]),
                O_it("ws.{owner}.meow"), O_blame()])
iv("A19", "meow_keys", title="Make their keyboard meow", desc="Every key press: a little meow. Everyone nearby will hear it.",
   log="The ghost made {owner}'s keyboard meow.", **PC, icon="sound",
   state=[oset("ws.{owner}.meow")], react=[desk_trap("iv_meow_found", "meow_{owner}")], watch=["iv_meow_found", "ivm_it_fix"])

# --- A20 share their private folder with everyone ----------------------------------
L("snoop_find", ["Huh. {owner}'s private folder is shared with everyone?", "Oops. I can see all of {owner}'s files. Just... looking.", "Oh, {owner}, you should really check your settings."],
  zeynep=["An open folder is an invitation, darling."], burak=["Someone set {owner}'s folder to 'everyone'. Rookie mistake."])
S_("log.snoop", "{owner}'s private folder was suddenly visible to the whole office. {actor} had a look.")
ev(id="iv_folder_snoop", trigger="", priority=55, allow_absent=True,
   roles=[role("snoop", where=[c_avail("self"), c_not(c_same("self", "owner"))], score=[s_trait("self", "curiosity", 1.2), s_trait("self", "gossip", 0.8), s_rand(0.3)],
               exclude=["owner"])],
   conditions=[{"c": "fact_exists", "fact": "$fact"}],
   effects=[emote("snoop", "question"), say("snoop", "snoop_find"), learn("snoop", "$fact", c=1.0), reveal("$fact"),
            log("log.snoop", 3, "secret", who=["snoop", "owner"]), chain("ivm_secret", delay=1.5, roles={"actor": "snoop"})])
iv("A20", "share_folder", title="Share their private folder with everyone", desc="The most curious person in the office will find it first.",
   log="The ghost changed {owner}'s private folder to 'shared with everyone'.", **PC, icon="folder", absent_ok=True,
   vars=private_vars("owner"), state=private_info("owner") + [oset("ws.{owner}.shared")],
   react=[chain("iv_folder_snoop", delay=6)], watch=["iv_folder_snoop", "ivm_secret", "ivm_spread", "ivm_tell_boss"])
