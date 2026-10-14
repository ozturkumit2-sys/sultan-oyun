# Interventions — H. Office equipment & physical environment
from iv_common import *  # noqa: F401,F403

DESK = dict(obj="ws", tab="papers", cat="H")

# --- H06 secretly repair the printer -----------------------------------------------------------------
L("printer_ghostfix", ["...It works? It WORKS! Who fixed it?", "The printer's fixed! Nobody touched it... did they?"])
S_("log.printer_ghostfix", "{actor} found the broken printer mysteriously working again.")
scene("iv_printer_ghostfix", noise=0.8, allow_absent=True, conditions=[c_present("actor")],
      roles=[role("credited", where=[c_avail("self")], score=[s_is("self", "burak", 1.5), s_aff("actor", "self", 0.01), s_rand(0.8)], exclude=["actor"], optional=True)],
      effects=[expr("actor", "surprised", 3), say("actor", "printer_ghostfix"), log("log.printer_ghostfix", 2, "ghost")],
      outcomes=[out("credit", [visit("actor", "credited", "thank_wrong_person", prio=48, ttl=40, delay=1.5)], score=[s_trait("actor", "sociability", 0.6), s_const(0.4)],
                    when=[c_filled("credited")]),
                out("spooky", [say("actor", "coffee_spooky", delay=1.5), ghost(), call("ghost_theory")], score=[s_trait("actor", "curiosity", 1.0), s_const(0.2)])])
iv("H06", "fix_printer", title="Secretly repair the printer", desc="Someone will get the credit. It won't be you.",
   log="The ghost quietly repaired the printer.", obj="printer", cat="H", icon="printer",
   conds=[why(c_office("printer.broken", True), "printer_working", "The printer is working fine.")],
   state=[oset("printer.broken", False), oset("printer.fixing", "")], react=[trap("iv_printer_ghostfix", place="#printer", key="ghostfix", days=1)],
   test={"setup": [{"e": "obj", "obj": "printer", "key": "broken", "v": True}]})

# --- H07 swap their chair for the wobbly one -----------------------------------------------------------
L("wchair_collapse", ["WHOA— *CRASH*", "AAH! My chair!", "*thud* ...Ow."], ahmet=["*CRASH* WHO GAVE ME THIS CHAIR?!"])
L("wchair_help", ["Are you okay?! Here, take my hand.", "Oh no! Are you hurt?"])
L("wchair_laugh", ["HAHAHA! Sorry! Sorry. Are you okay? HAHA!", "That was the best thing I've seen all week."])
S_("log.chair_collapse", "{actor}'s chair collapsed the moment they sat down. Someone had swapped it for the broken one.")
scene("iv_chair_collapse", vars=[var("suspect", "suspect", desk=True, optional=True)],
      effects=[fx("shake", "actor"), sfx("thump"), expr("actor", "surprised", 5), say("actor", "wchair_collapse"), stress("actor", 10), mood("actor", -8),
               log("log.chair_collapse", 3, "prank"),
               witness([say("self", "wchair_help", p=1.0, delay=1.5, when=[c_trait("self", "empathy", gt=0.6)]), rel("actor", "self", "friendship", 5, when=[c_trait("self", "empathy", gt=0.6)]),
                        say("self", "wchair_laugh", p=0.6, delay=1.8, when=[c_trait("self", "empathy", lt=0.6), c_trait("self", "humor", gt=0.4)])], r=5, mx=3)],
      outcomes=[O_blame(), O_shrug()])
iv("H07", "wobbly_chair", title="Swap their chair for the broken one", desc="It looks fine. It isn't.",
   log="The ghost swapped {owner}'s office chair for the broken one.", **DESK, icon="people",
   state=[oset("ws.{owner}.chair", "broken")], react=[desk_trap("iv_chair_collapse", "chair_{owner}")])

# --- H08 pack their desk into a cardboard box ---------------------------------------------------------------
L("packed_see", ["...Why is all my stuff in a BOX?", "My desk is packed. In a box. Am I... fired?!", "A cardboard box. With my things. Oh no."])
L("packed_witness", ["Is {owner} being let go?!", "{owner}'s desk is in a box... poor thing."])
L("packed_ask", ["Ahmet Bey — am I fired? My things are in a box!", "Please tell me I still have a job."])
L("packed_boss_no", ["Fired? Who packed your desk? You're not going anywhere.", "Nobody's fired. Unpack. And find out who did that."])
S_("log.packed", "{actor} arrived at their desk to find everything packed in a cardboard box. The office assumes the worst.")
S_("log.packed_relief", "Ahmet confirmed to {actor}: nobody's fired. Somebody just packed their desk. Relief — and suspicion.")
scene("iv_packed", effects=[expr("actor", "surprised", 6), emote("actor", "exclaim"), say("actor", "packed_see"), stress("actor", 18), mood("actor", -12),
                            rumor("getting_fired", a="actor", b="actor", juicy=0.85, truth=False, knowers=[]),
                            witness([learn("self", "$rumor", c=0.7), say("self", "packed_witness", p=0.5, delay=2)], r=5), log("log.packed", 3, "drama"),
                            visit("actor", "@ahmet", "iv_packed_ask", prio=64, ttl=50, delay=3, when=[c_present("@ahmet"), c_is("actor", "ahmet", neg=True)])])
scene("iv_packed_ask", conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "packed_ask", to="target"), say("target", "packed_boss_no", to="actor", delay=1.6), stress("actor", -10),
               debunk("$rumor", who=["actor", "target"], by="target"), oset("ws.{actor}.packed", False), log("log.packed_relief", 2, "misunderstanding")])
iv("H08", "pack_desk", title="Pack their desk into a cardboard box", desc="Everything. Neatly. Like someone who's been let go.",
   log="The ghost packed {owner}'s desk into a cardboard box.", **DESK, icon="item", owners=["selin", "mert", "zeynep", "burak", "ece", "deniz", "ceren"],
   state=[oset("ws.{owner}.packed")], react=[desk_trap("iv_packed", "packed_{owner}")])

# --- H09 empty the printer's paper tray -------------------------------------------------------------------------
L("nopaper", ["Out of paper? Again?", "'Load paper'. With WHAT? The tray's empty!"])
L("nopaper_shelf", ["The supply shelf has no paper either?!", "Not a single sheet in the whole office."])
L("nopaper_ok", ["Found some. Crisis averted.", "There we go. Paper."])
S_("log.nopaper", "{actor} went to print and found the printer — and the supply shelf — out of paper.")
ev(id="iv_nopaper", trigger="object_failed", filter={"obj": "paper"}, priority=70, scope="actor", cooldown=20,
   effects=[say("actor", "nopaper"), emote("actor", "question"), go_place("actor", "supplies", "iv_nopaper_shelf", prio=58, ttl=30, dur=2)])
scene("iv_nopaper_shelf", allow_absent=True, conditions=[c_present("actor")],
      outcomes=[out("none", [say("actor", "nopaper_shelf"), expr("actor", "angry", 4), stress("actor", 6), npcflag("actor", "printer_gave_up"), log("log.nopaper", 2, "malfunction")],
                    score=[s_const(3)], when=[c_os("supplies.at", neg=True, eq="")]),
                out("ok", [say("actor", "nopaper_ok"), oset("printer.no_paper", False)], score=[s_const(1)])])
iv("H09", "no_paper", title="Empty the printer's paper tray", desc="The next print job won't happen. Someone goes hunting for paper.",
   log="The ghost emptied the printer's paper tray.", obj="printer", cat="H", icon="papers",
   conds=[why(c_os("printer.no_paper", neg=True), "already")], state=[oset("printer.no_paper", True)], watch=["iv_nopaper", "iv_nopaper_shelf"])

# --- H10 change the office music ---------------------------------------------------------------------------------
L("music_love", ["Ooh, I LOVE this song!", "Finally, some good music!", "*dancing in chair*"], mert=["DJ, turn it UP!"], ece=["This is my JAM!"])
L("music_hate", ["Who put THIS on?!", "Make it stop. Please.", "My ears. My poor ears."], burak=["Noise-cancelling headphones: ON."])
L("music_boss_off", ["Who's playing music in MY office?!", "Turn that off! This is a workplace!"])
S_("log.music", "The office speaker started playing {what}. Some people are dancing. Some are suffering.")
S_("log.music_off", "Ahmet marched over and switched off the office music.")
scene("iv_music_on", allow_absent=True,
      effects=[each([say("self", "music_love", p=0.5, delay=1.0), emote("self", "cheer")], stagger=0.5, where=[{"c": "picks", "fn": "loves_music", "of": "self"}]),
               each([say("self", "music_hate", p=0.5, delay=1.4), expr("self", "angry", 3)], stagger=0.5, where=[{"c": "picks", "fn": "hates_music", "of": "self"}]),
               log("log.music", 2, "prank")],
      outcomes=[out("boss_off", [go_place("@ahmet", "fridge", "iv_music_off", prio=62, ttl=40, dur=2)], score=[s_const(1)],
                    when=[c_present("@ahmet"), {"c": "picks", "fn": "hates_music", "of": "@ahmet"}]),
                out("stays", [], score=[s_const(0.5)])])
scene("iv_music_off", allow_absent=True, conditions=[c_present("actor")],
      effects=[say("actor", "music_boss_off"), oset("music.genre", ""), each([mood("self", -3)], exclude=["actor"], where=[{"c": "picks", "fn": "loves_music", "of": "self"}]),
               log("log.music_off", 2, "boss")])
for g, t in (("classical", "classical music"), ("arabesk", "heartbreaking arabesk"), ("disco", "70s disco"), ("pop", "cheesy pop hits")):
    what("music_" + g, t)
iv("H10", "office_music", title="Change the office music", desc="Everybody hears the speaker. Not everybody likes the same music.",
   log="The ghost switched the office speaker to {what}.", obj="speaker", cat="H", needs="choice", icon="music",
   choices=[choice("classical", "Classical"), choice("arabesk", "Arabesk"), choice("disco", "Disco"), choice("pop", "Cheesy pop")],
   state=[oset("music.genre", "$choice"), setf("what", "music_{choice}")], react=[chain("iv_music_on", delay=2)], reuse={"cool": 20, "day": 4})

# --- H11 set off the fire alarm -----------------------------------------------------------------------------------
L("alarm_panic", ["FIRE ALARM! Everybody out!", "Is this a drill?! Out, out, out!", "Leave everything! GO!"], ahmet=["Everyone — calmly — OUT. NOW!"],
  ece=["My laptop! No — leave it! Run!"], burak=["Probably nothing. Still leaving."])
L("alarm_outside", ["Was it real? I don't smell smoke.", "Well, this is the most social we've been all week.", "Who pulled the alarm?!"])
L("alarm_back", ["False alarm. Back to work, everyone.", "Nothing. NOTHING. Back inside."])
S_("log.alarm", "The fire alarm went off. The whole office evacuated to the reception.")
S_("log.alarm_gather", "Everyone stood around in reception after the false fire alarm. Lots of chatting. No fire.")
S_("log.alarm_over", "The alarm stopped. False alarm. Ahmet wants to know who pulled it.")
scene("iv_alarm_go", allow_absent=True,
      effects=[sfx("alarm"), each([say("self", "alarm_panic", p=0.5, delay=0.5), emote("self", "exclaim"), stress("self", 6)], stagger=0.3),
               meetup("iv_alarm_gather", who="all", area="reception", need=3, ttl=25, prio=92), log("log.alarm", 4, "drama")])
scene("iv_alarm_gather", noise=0.6,
      effects=[each([say("self", "alarm_outside", p=0.4, delay=1.5), stress("self", -3)], stagger=0.8, where=[c_zone("self", ["reception"])]),
               each([rel("self", "actor", "friendship", 2)], exclude=["actor"], where=[c_zone("self", ["reception"])]), log("log.alarm_gather", 2, "friendship")])
ev(id="iv_alarm_over", trigger="alarm_over", priority=70,
   effects=[say("@ahmet", "alarm_back", when=[c_present("@ahmet")]), ghost(), log("log.alarm_over", 2, "boss")])
iv("H11", "fire_alarm", title="Set off the fire alarm", desc="Everyone evacuates to reception. Whatever they were doing — meetings included.",
   log="The ghost set off the fire alarm.", obj="alarm_panel", cat="H", icon="bulb", sfx="alarm",
   conds=[why(c_os("alarm.on", neg=True), "alarm_on", "The alarm is already ringing.")],
   state=[oset("alarm.on", True), {"e": "call", "fn": "alarm_timer", "minutes": 12}], react=[chain("iv_alarm_go", delay=0.5)], watch=["iv_alarm_over"],
   reuse={"cool": 600, "day": 1})

# --- H12 change the wall clock ---------------------------------------------------------------------------------------
L("wallclock_see", ["Is it really {time} already?", "The clock says {time}! Where did the day go?"])
L("wallclock_leave_boss", ["Where are you going? It's not even five!", "Sit down. That clock is wrong and you know it."])
L("wallclock_excuse", ["The wall clock said it was home time!", "But... the clock!"])
S_("log.wallclock", "Someone moved the office wall clock {what}. People are trusting it.")
S_("log.wallclock_leave", "{actor} trusted the wall clock and packed up early. Ahmet caught them at the door.")
scene("iv_wallclock_leave", noise=0.6, allow_absent=True, conditions=[c_present("actor"), c_avail("@ahmet")],
      effects=[visit("@ahmet", "actor", "iv_wallclock_caught", prio=82, ttl=10)])
scene("iv_wallclock_caught", conditions=[c_present("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "wallclock_leave_boss", to="target"), say("target", "wallclock_excuse", to="actor", delay=1.6),
               npcval("target", "leave_at", d=40), favor("target", -2), log("log.wallclock_leave", 2, "boss", who=["target"])])
what("clockwall_fast", "45 minutes forward")
what("clockwall_slow", "30 minutes back")
iv("H12", "wall_clock", title="Change the office wall clock", desc="People trust that clock. Some will act on it.",
   log="The ghost moved the office wall clock {what}.", obj="wall_clock", cat="H", needs="choice", icon="calendar",
   choices=[choice("fast", "45 minutes forward"), choice("slow", "30 minutes back")], conds=[r_time(after="14:00", before="16:45", key="clock_time", text="Nobody's watching the clock right now.")],
   state=[oset("clock.offset", 45, when=[c_var("choice", eq="fast")]), oset("clock.offset", -30, when=[c_var("choice", eq="slow")]), setf("what", "clockwall_{choice}"),
          {"e": "call", "fn": "clock_time"},
          each([npcval("self", "leave_at", d=-45), say("self", "wallclock_see", p=0.3, delay=1.5)], exclude=["@ahmet"],
               where=[c_trait("self", "diligence", lt=0.75), {"c": "var", "key": "choice", "eq": "fast"}], stagger=0.5),
          each([npcval("self", "leave_at", d=25)], where=[{"c": "var", "key": "choice", "eq": "slow"}])],
   react=[on_trap("leaving", "iv_wallclock_leave", key="wallclock", uses=2)], watch=["iv_wallclock_caught"], test={"at": "14:30"})

# --- H13 revive the dying office plant ---------------------------------------------------------------------------------
L("plant_notice", ["Has the ficus... come back to life?", "Look at the plant! It's GREEN again!", "Someone's been looking after Ficus."])
L("plant_thank", ["{target}, was it you who saved the plant? That's so sweet.", "I bet you rescued the ficus, {target}."])
L("plant_nope", ["Not me! I can't even keep a cactus alive.", "Wasn't me. But it looks great!"])
S_("log.plant", "The dying office plant is suddenly green and healthy. {actor} noticed. Nobody knows who did it.")
scene("iv_plant_seen", allow_absent=True, conditions=[c_present("actor")],
      roles=[role("target", where=[c_avail("self")], score=[s_trait("self", "empathy", 1.0), s_rand(0.5)], exclude=["actor"], optional=True)],
      effects=[expr("actor", "happy", 4), say("actor", "plant_notice"), mood("actor", 5), log("log.plant", 2, "ghost"),
               each([mood("self", 2)], where=[c_zone("self", ["lounge"])])],
      outcomes=[out("thank", [visit("actor", "target", "iv_plant_thank", prio=48, ttl=40, delay=2)], score=[s_trait("actor", "sociability", 0.8)], when=[c_filled("target")]),
                out("ghost", [ghost(), call("ghost_theory")], score=[s_trait("actor", "curiosity", 0.6), s_const(0.2)])])
scene("iv_plant_thank", conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4), say("actor", "plant_thank", to="target")],
      outcomes=[out("credit", [say("target", "ivm_take_credit", to="actor", delay=1.6), rel("actor", "target", "friendship", 6)], score=[s_trait("target", "cunning", 1.0)]),
                out("nope", [say("target", "plant_nope", to="actor", delay=1.6), rel("actor", "target", "trust", 2)], score=[s_trait("target", "honesty", 1.0)])])
iv("H13", "revive_plant", title="Bring the dying office plant back to life", desc="A small, kind haunting.",
   log="The ghost watered and revived the lounge plant.", obj="plant", cat="H", icon="star",
   conds=[why(c_os("plant.revived", neg=True), "plant_ok", "The plant is already thriving.")],
   state=[oset("plant.revived", True)], react=[near_trap("iv_plant_seen", "plant", key="plant", r=2.6, days=1)])

# --- H14 jam the front door ------------------------------------------------------------------------------------------
L("door_stuck", ["The door won't open! We're locked IN!", "It's stuck! I can't get out!"])
L("door_fix", ["Stand back. It's just the latch.", "Here — you have to lift it AND push."], burak=["Classic. The latch again."])
S_("log.frontdoor", "The front door jammed. {actor} was stuck inside until {fixer} got it open.")
scene("iv_frontdoor", noise=0.6, allow_absent=True, conditions=[c_present("actor")],
      roles=[role("fixer", where=[c_avail("self")], score=[s_is("self", "burak", 2.0), s_trait("self", "diligence", 0.5), s_rand(0.3)], exclude=["actor"], optional=True)],
      effects=[hold(["actor"], 6), say("actor", "door_stuck"), emote("actor", "sweat"), stress("actor", 6),
               say("fixer", "door_fix", delay=3), oset("front_door.jammed", False, delay=5), rel("actor", "fixer", "friendship", 5),
               log("log.frontdoor", 2, "malfunction")])
iv("H14", "jam_door", title="Jam the front door", desc="The next person trying to leave gets stuck.",
   log="The ghost jammed the office front door.", obj="front_door", cat="H", icon="lock",
   conds=[r_time(after="11:00")], state=[oset("front_door.jammed", True)], react=[on_trap("leaving", "iv_frontdoor", key="frontdoor", days=0)],
   test={"at": "16:40"})

# --- H15 lock the thermostat --------------------------------------------------------------------------------------------
L("thermo_locked", ["The thermostat's LOCKED?! Who locked it?!", "'Settings locked'. LOCKED. I'm FREEZING.", "It won't let me change it!"])
S_("log.thermo_locked", "{actor} tried to change the temperature — the thermostat was locked.")
ev(id="iv_thermo_locked", trigger="thermostat_locked", priority=70, scope="actor", cooldown=20,
   vars=[var("suspect", "suspect", loc="", optional=True)],
   effects=[expr("actor", "angry", 5), say("actor", "thermo_locked"), stress("actor", 8), log("log.thermo_locked", 2, "malfunction")],
   outcomes=[out("burak", [setf("fixpath", "ac.locked"), visit("actor", "@burak", "ivm_it_fix", prio=60, ttl=50, delay=1.5)], score=[s_const(1)],
                 when=[c_present("@burak"), c_is("actor", "burak", neg=True)]),
             out("kick", [emote("actor", "anger", delay=1.2), sfx("thump", delay=1.2), fx("shake", "actor", delay=1.2)], score=[s_trait("actor", "temper", 1.2)]),
             O_blame()])
iv("H15", "lock_thermostat", title="Lock the thermostat", desc="Whatever the temperature is now — that's how it stays.",
   log="The ghost locked the thermostat at {temp}°C.", obj="ac", cat="H", icon="thermo",
   conds=[why(c_os("ac.locked", neg=True), "already_locked")],
   state=[oset("ac.locked", True), {"e": "set", "key": "temp", "v": 22}], watch=["iv_thermo_locked", "ivm_it_fix"], test={"setup": [{"e": "obj", "obj": "ac", "key": "temp", "v": 16}]})

# --- H16 unplug the network switch -------------------------------------------------------------------------------------------
L("net_down", ["The internet's down! Everywhere!", "No network?! I can't do ANYTHING.", "Did we just go back to the Stone Age?"], burak=["...That's not a glitch. Someone unplugged the switch."])
L("net_hero", ["Back online. You're welcome.", "Network's up. Nobody touch the blue box."])
S_("log.net_down", "The whole office network went down. Nobody can work — so everybody's chatting.")
scene("iv_net_down", allow_absent=True,
      effects=[each([say("self", "net_down", p=0.5, delay=0.8), emote("self", "question")], stagger=0.4),
               each([act("self", "coffee", dur=6)], where=[c_chance(0.4), c_is("self", "burak", neg=True)], stagger=1.0),
               call("fix_intent", who="@burak", obj="net", requester="", prio=72, delay=2), log("log.net_down", 4, "malfunction")])
iv("H16", "unplug_network", title="Unplug the network switch", desc="The little blue box behind the archive. The whole office goes offline.",
   log="The ghost unplugged the office network switch.", obj="server_box", cat="H", icon="gear",
   conds=[why(c_os("net.down", neg=True), "net_down", "The network is already down.")],
   state=[oset("net.down", True), oset("net.broken", True)], react=[chain("iv_net_down", delay=1)], watch=["fix_done"], reuse={"cool": 300, "day": 1})

# --- H17 swap two people's coats ---------------------------------------------------------------------------------------------
L("coat_wrong", ["...This coat smells like someone else's perfume.", "Why are the sleeves so long? ...This isn't my coat."])
L("coat_swapback", ["I think you went home in my coat yesterday.", "Is this yours? I wore it all evening. Sorry!"])
L("coat_laugh", ["Ha! It looked better on you, honestly.", "Keep it. Kidding. Give it back."])
L("coat_romance", ["It still smells like you. ...I mean. Here's your coat.", "I... kind of liked wearing it."])
S_("log.coat_home", "{target} went home in {other}'s coat by mistake.")
S_("log.coat_swap", "{actor} and {target} swapped back the coats they'd taken home by mistake.")
S_("log.coat_romance", "{actor} and {target} swapped coats back after a mix-up. Lingering eye contact.")
scene("iv_coat_leave", allow_absent=True, conditions=[c_present("target")],
      effects=[say("target", "coat_wrong", delay=1), log("log.coat_home", 2, "misunderstanding"),
               pair_trap("iv_coat_morning", "target", "other", key="coatswap", days=1)])
scene("iv_coat_morning", noise=0.8, conditions=[c_avail("actor"), c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "coat_swapback", to="target")],
      outcomes=[out("laugh", [say("target", "coat_laugh", to="actor", delay=1.6), rel("actor", "target", "friendship", 6, both=True), log("log.coat_swap", 2, "friendship")],
                    score=[s_const(1), s_trait("target", "humor", 0.6)]),
                out("romance", [say("target", "coat_romance", to="actor", delay=1.6), emote("target", "love", delay=1.6), rel("actor", "target", "romance", 10, both=True),
                                log("log.coat_romance", 3, "romance")], score=[s_rel("target", "actor", "romance", 0.05)], when=[c_rel("target", "actor", "romance", gt=15)])])
iv("H17", "swap_coats", title="Swap two coats on the rack", desc="Pick one coat owner. They'll take home someone else's coat.",
   log="The ghost swapped {target}'s coat with {other}'s on the rack.", obj="coat_rack", cat="H", needs="person", icon="item", pick=[c_present("self")],
   state=[pick_role("other", "crush_of", of="target"), pick_role("other", "best_of", keep=True, of="target", lim=-99), oset("coats.swapped", "%target")],
   react=[on_trap("leaving", "iv_coat_leave", who="target", key="coatleave", roles={"target": "target", "other": "other"})], test={"at": "16:20", "days": 2})

# --- H18 spill water in front of the printer --------------------------------------------------------------------------------------
L("slip", ["WHOA— *SPLAT*", "*slips* AAAH!", "Who put a PUDDLE here?!"])
L("slip_help", ["Are you okay?! Careful!", "Here, let me help you up."])
S_("log.slip", "{actor} slipped on a puddle in front of the printer. Spectacularly.")
scene("iv_slip", allow_absent=True, conditions=[c_present("actor")],
      effects=[fx("shake", "actor"), sfx("splash"), expr("actor", "surprised", 5), say("actor", "slip"), stress("actor", 8), mood("actor", -6), log("log.slip", 2, "prank"),
               witness([say("self", "slip_help", p=1.0, delay=1.5, when=[c_trait("self", "empathy", gt=0.55)]), rel("actor", "self", "friendship", 4, when=[c_trait("self", "empathy", gt=0.55)]),
                        say("self", "witness_laugh", p=0.6, delay=1.8, when=[c_trait("self", "empathy", lt=0.55)])], r=5, mx=3)])
iv("H18", "puddle", title="Spill water in front of the printer", desc="The next person printing won't see it coming.",
   log="The ghost left a slippery puddle in front of the printer.", obj="printer", cat="H", icon="coffee",
   state=[oset("printer.puddle", True)], react=[trap("iv_slip", place="#printer", key="puddle", days=1)])

# --- H19 disco lights ---------------------------------------------------------------------------------------------------------
L("disco_wow", ["DISCO LIGHTS?! In the OFFICE?!", "Why is everything purple and flashing?!", "Party time? It's a Tuesday!"], mert=["Finally. My moment has come."], ece=["DANCE BREAK!"])
L("disco_boss", ["WHAT IS HAPPENING TO MY LIGHTS?!", "This is an office, not a nightclub!"])
S_("log.disco", "The office lights switched to disco mode. Half the office is dancing.")
S_("log.disco_off", "Ahmet stormed to the breaker and killed the disco lights.")
scene("iv_disco", allow_absent=True,
      effects=[each([say("self", "disco_wow", p=0.5, delay=0.8), emote("self", "cheer", when=[c_trait("self", "humor", gt=0.5)])], stagger=0.4),
               log("log.disco", 3, "prank"), go_place("@ahmet", "breaker", "iv_disco_off", prio=70, ttl=40, delay=4, dur=2)])
scene("iv_disco_off", allow_absent=True, conditions=[c_present("actor")],
      effects=[say("actor", "disco_boss"), expr("actor", "angry", 5), oset("lights.party", False), each([mood("self", -2)], where=[c_trait("self", "humor", gt=0.5)]),
               log("log.disco_off", 2, "boss")])
iv("H19", "disco_lights", title="Switch the office lights to disco mode", desc="Purple, pink, flashing. Some will dance. One will not.",
   log="The ghost switched the office lights to disco mode.", obj="lights", cat="H", icon="music",
   conds=[why(c_office("lights.on", True), "dark", "The lights are off."), why(c_os("lights.party", neg=True), "already")],
   state=[oset("lights.party", True)], react=[chain("iv_disco", delay=1)])

# --- H20 make the lights flicker ------------------------------------------------------------------------------------------
L("flicker_scared", ["Why are the lights flickering like that?!", "Okay, this is how horror movies start.", "Did you see that? The lights... breathed."],
  ece=["I'm not scared. I'm NOT scared. I'm a LITTLE scared."], zeynep=["I knew it. This building is haunted."])
L("flicker_burak", ["It's a loose connection. Not ghosts. Probably.", "I'll check the breaker. Nobody panic."])
S_("log.flicker", "The office lights started flickering by themselves. Some people are now convinced the office is haunted.")
scene("iv_flicker", allow_absent=True,
      effects=[each([say("self", "flicker_scared", p=0.5, delay=0.8), emote("self", "question"), stress("self", 4, when=[c_trait("self", "curiosity", gt=0.7)])], stagger=0.5),
               ghost(2), call("ghost_theory"), rumor("haunted", a="@ahmet", b="@ahmet", juicy=0.6, truth=False, knowers=[]),
               each([learn("self", "$rumor", c=0.5)], where=[c_trait("self", "curiosity", gt=0.6)]),
               say("@burak", "flicker_burak", delay=3, when=[c_present("@burak")]), log("log.flicker", 3, "ghost")])
iv("H20", "flicker_lights", title="Make the lights flicker", desc="Twenty minutes of horror-movie lighting.",
   log="The ghost made the office lights flicker.", obj="lights", cat="H", icon="ghost",
   conds=[why(c_office("lights.on", True), "dark", "The lights are off.")],
   state=[{"e": "call", "fn": "flicker", "minutes": 20}], react=[chain("iv_flicker", delay=1)])
