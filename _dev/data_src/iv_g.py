# Interventions — G. Kitchen & coffee (coffee machine, fridge, water cooler, kitchen table, microwave)
from iv_common import *  # noqa: F401,F403

COFFEE = dict(obj="coffee_machine", cat="G")
FRIDGE = dict(obj="fridge", cat="G")
TABLE = dict(obj="kitchen_table", cat="G")
LUNCH_LATER = [r_time(before="12:30", key="after_lunch", text="Lunch time is already over.")]

# --- G03 swap the mugs ----------------------------------------------------------------------------
L("mug_drink", ["Mmm. Coffee. ...This mug's new.", "Nice mug. Is it mine? It's mine now."])
L("mug_claim", ["Excuse me — that's MY mug.", "Are you drinking out of my mug?!", "That mug. Is. Mine."], selin=["That mug is mine. It has my initials on it."])
L("mug_sorry", ["Oh! Sorry! They were swapped on the rack!", "Is it? They all look the same!"])
L("mug_blush", ["...So we've shared a mug now. That's... a step.", "Indirect kiss! ...Sorry. That was weird."])
S_("log.mug_fight", "{target} caught {actor} drinking from their mug. The mugs had been swapped. Words were exchanged.")
S_("log.mug_laugh", "{actor} drank from {target}'s mug by mistake. They laughed it off.")
S_("log.mug_blush", "{actor} drank from {target}'s mug by mistake. Somehow it turned into flirting.")
scene("iv_mug_drink", allow_absent=True, conditions=[c_present("actor")],
      roles=[role("target", where=[c_present("self")], score=[s_rel("self", "actor", "romance", 0.03), s_rel("self", "actor", "rivalry", 0.03), s_rand(0.5)], exclude=["actor"],
                  avail=False)],
      effects=[say("actor", "mug_drink"), visit("target", "actor", "iv_mug_claim", prio=58, ttl=40, delay=2)])
scene("iv_mug_claim", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "mug_claim", to="target"), say("target", "mug_sorry", to="actor", delay=1.6)],
      outcomes=[out("fight", [say("actor", "ivm_accuse_argue", to="target", delay=3.2), rel("actor", "target", "friendship", -6, both=True), log("log.mug_fight", 2, "conflict")],
                    score=[s_trait("actor", "temper", 1.0), s_rel("actor", "target", "rivalry", 0.02)]),
                out("laugh", [say("actor", "ivm_accuse_laugh", to="target", delay=3.2), rel("actor", "target", "friendship", 4, both=True), log("log.mug_laugh", 2, "friendship")],
                    score=[s_trait("actor", "humor", 0.8), s_aff("actor", "target", 0.02)]),
                out("blush", [say("target", "mug_blush", to="actor", delay=3.2), emote("actor", "love", delay=3.4), rel("actor", "target", "romance", 8, both=True),
                              log("log.mug_blush", 3, "romance")], score=[s_rel("actor", "target", "romance", 0.05)], when=[c_rel("actor", "target", "romance", gt=20)])])
iv("G03", "swap_mugs", title="Swap everyone's mugs on the rack", desc="The next person making coffee grabs the wrong one.",
   log="The ghost swapped the mugs on the kitchen rack.", **COFFEE, icon="coffee",
   state=[oset("kitchen.mugs_swapped", True)], react=[trap("iv_mug_drink", place="#coffee", key="mugs", days=1)])

# --- G04 swap the coffee for decaf ---------------------------------------------------------------------
L("decaf_sleepy", ["...Why am I still tired? That was my third coffee.", "This coffee isn't working. Is it broken? Am I broken?", "*yaaawn*"])
L("decaf_blame", ["Zeynep, did you switch us to cheap coffee to save money?!", "It's DECAF! Somebody cut the coffee budget!"])
L("decaf_zeynep", ["I did NOT touch the coffee budget!", "Don't look at me. I'd never mess with coffee."])
S_("log.decaf", "Someone switched the office coffee to decaf. People are yawning everywhere.")
S_("log.decaf_blame", "{actor} accused Zeynep of switching to cheap decaf to save money. She swears she didn't.")
scene("iv_decaf_found", allow_absent=True, conditions=[c_present("actor")],
      effects=[emote("actor", "cloud"), say("actor", "decaf_sleepy"), log("log.decaf", 2, "malfunction")],
      outcomes=[out("blame", [say("actor", "decaf_blame", delay=1.6), visit("actor", "@zeynep", "iv_decaf_zeynep", prio=56, ttl=50, delay=2)],
                    score=[s_trait("actor", "temper", 1.0), s_rel("actor", "@zeynep", "rivalry", 0.02)], when=[c_present("@zeynep"), c_is("actor", "zeynep", neg=True)]),
                out("sleepy", [npcflag("actor", "sleepy"), stress("actor", 3)], score=[s_const(0.6)])])
scene("iv_decaf_zeynep", conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "decaf_blame", to="target"), say("target", "decaf_zeynep", to="actor", delay=1.6),
               rel("actor", "target", "suspicion", 12), rel("target", "actor", "resentment", 6), log("log.decaf_blame", 2, "conflict")])
iv("G04", "decaf", title="Swap the coffee beans for decaf", desc="Nobody will notice. At first.",
   log="The ghost replaced the office coffee with decaf.", **COFFEE, icon="coffee",
   conds=[why(c_os("coffee.decaf", neg=True), "already", "Already done.")],
   state=[oset("coffee.decaf")], react=[trap("iv_decaf_found", place="#coffee", key="decaf", uses=2)])

# --- G05 move someone's lunch to a different shelf ------------------------------------------------------
L("lunchmove_found", ["...My lunch. On the TOP shelf. Behind the mustard. I accused people for NOTHING.", "Oh. There it is. It was hiding. Oops."])
S_("log.lunchmove_found", "{actor} found their 'stolen' lunch on a different fridge shelf. Someone was accused for nothing.")
scene("iv_lunchmove_found", allow_absent=True, conditions=[c_present("actor")],
      effects=[say("actor", "lunchmove_found"), emote("actor", "sweat"), mood("actor", 5), log("log.lunchmove_found", 2, "misunderstanding"),
               rel("actor", "$suspect", "suspicion", -15, when=[c_filled("$suspect")])])
iv("G05", "move_lunch", title="Move someone's lunch to another shelf", desc="Behind the mustard. They'll think it was stolen.",
   log="The ghost moved {target}'s lunch to the back of the fridge.", **FRIDGE, needs="person", icon="coffee", pick=[c_present("self")], conds=LUNCH_LATER,
   state=[pick_role("suspect", "suspect", of="target"), {"e": "set", "key": "suspect", "who": "suspect"},
          call("take_lunch", who="suspect", target="target")],
   react=[trap("iv_lunchmove_found", place="#fridge", who="target", key="lunchmove", after=30)], watch=["lunch_gone"])

# --- G06 make the coffee machine warm up for 40 minutes ----------------------------------------------------
L("cwait_line", ["'Warming up'? For how long?!", "It says 'please wait'. I've been waiting.", "Come on, come on, warm up!"])
L("cwait_chat", ["So... since we're both stuck here...", "Coffee queue buddies. How's your day?", "Did you hear what happened yesterday?"])
S_("log.cwait_pair", "The coffee machine took forever to warm up. {actor} and {target}, stuck waiting together, got chatting.")
ev(id="iv_coffee_wait", trigger="coffee_wait", priority=60, cooldown=6,
   roles=[role("target", where=[c_present("self")], near="actor", r=3.5, score=[s_dist("actor", "self", -0.2)], exclude=["actor"], optional=True, avail=False)],
   effects=[say("actor", "cwait_line"), emote("actor", "cloud")],
   outcomes=[out("pair", [say("actor", "cwait_chat", to="target", delay=1.4), hold(["actor", "target"], 4), rel("actor", "target", "friendship", 5, both=True),
                          chain("gossip_share", delay=2, when=[c_trait("actor", "gossip", gt=0.5)]), log("log.cwait_pair", 2, "friendship")],
                 score=[s_const(2)], when=[c_filled("target")]),
             out("alone", [stress("actor", 3)], score=[s_const(1)])])
iv("G06", "coffee_late", title="Make the coffee machine take 40 minutes to warm up", desc="A queue forms. People talk.",
   log="The ghost set the coffee machine to a 40-minute warm-up.", **COFFEE, icon="coffee",
   conds=[why(c_office("coffee.broken", False), "coffee_broken", "The machine is broken.")],
   state=[{"e": "call", "fn": "coffee_late", "minutes": 40}], watch=["iv_coffee_wait"])

# --- G07 break the water cooler --------------------------------------------------------------------------------
L("water_dead", ["The water cooler's dry. In THIS heat?", "No water? Not even water?", "*glug*... nothing."])
L("water_ece_try", ["I'll fix it! I watched a video once!", "Leave it to me!"])
L("water_flood", ["Oh no. Oh no no no. WATER EVERYWHERE!", "It's leaking! It's LEAKING!"])
S_("log.water_dead", "{actor} found the water cooler dead.")
S_("log.water_flood", "Ece tried to fix the water cooler. The lounge is now a lake.")
ev(id="iv_water_broken", trigger="object_failed", filter={"obj": "water"}, priority=70, scope="actor", cooldown=20,
   effects=[expr("actor", "surprised", 3), say("actor", "water_dead"), mood("actor", -3), log("log.water_dead", 2, "malfunction")],
   outcomes=[out("ece", [say("@ece", "water_ece_try", delay=1.5), say("@ece", "water_flood", delay=4.5), fx("spill", "@ece", delay=4.5), sfx("splash", delay=4.5),
                         emote("@ece", "sweat", delay=4.5), stress("@ece", 10), witness([say("self", "witness_laugh", p=0.5, delay=5.5)], near="@ece", r=6),
                         call("fix_intent", who="@burak", obj="water", requester="actor", prio=60, delay=6), log("log.water_flood", 3, "malfunction")],
                 score=[s_const(1.5)], when=[c_avail("@ece"), c_near("@ece", "actor", 6)]),
             out("call", [call("fix_intent", who="@burak", obj="water", requester="actor", prio=62, delay=2)], score=[s_const(1)], when=[c_present("@burak")]),
             out("shrug", [say("actor", "ivm_shrug")], score=[s_const(0.4)])])
iv("G07", "break_water", title="Break the water cooler", desc="No water, no small talk.",
   log="The ghost broke the water cooler.", obj="water_cooler", cat="G", icon="coffee",
   conds=[why(c_os("water.broken", neg=True), "already_broken", "It's already broken.")],
   state=[oset("water.broken"), oset("water.discovered", False)], watch=["iv_water_broken", "fix_done"])

# --- G08 move the snack box into someone's drawer --------------------------------------------------------------
L("snack_search", ["Where did the snacks go? The snack box is GONE.", "No snacks? This is a crisis."], mert=["Snack emergency. Snack. Emergency."])
L("snack_found", ["{target}'s drawer is FULL of our snacks!", "So THIS is where the snacks went, {target}."])
L("snack_share", ["...Okay, they're not mine, but — take some! Take all of them!", "Snacks for everyone! I'm as surprised as you!"])
L("snack_refuse", ["They're in MY drawer, so... they're my snacks now.", "Finders keepers."])
S_("log.snack_share", "The snack box turned up in {target}'s drawer. {target} handed them out. Instant popularity.")
S_("log.snack_refuse", "The snack box turned up in {target}'s drawer — and {target} wouldn't give them back.")
ev(id="iv_snack_need", trigger="", priority=55,
   roles=[role("hungry", where=[c_avail("self"), c_not(c_same("self", "target"))], score=[s_trait("self", "sociability", 0.6), s_trait("self", "humor", 0.6), s_rand(0.6)],
               exclude=["target"])],
   effects=[say("hungry", "snack_search"), hunt("hungry", ["kitchen", "lounge", "desk_{target}"], "iv_snack_found", prio=55, ttl=50, roles={"target": "target"})])
scene("iv_snack_found", noise=0.8, allow_absent=True, conditions=[c_present("actor"), c_present("target")],
      effects=[say("actor", "snack_found"), emote("actor", "exclaim")],
      outcomes=[out("share", [say("target", "snack_share", delay=1.6, when=[c_near("target", "actor", 5)]), each([rel("self", "target", "friendship", 4), mood("self", 3)],
                              exclude=["target"], where=[c_near("self", "target", 6)]), log("log.snack_share", 3, "friendship")],
                    score=[s_trait("target", "empathy", 1.0), s_trait("target", "sociability", 0.5)]),
                out("refuse", [say("target", "snack_refuse", delay=1.6, when=[c_near("target", "actor", 5)]), rel("actor", "target", "resentment", 8),
                               rel("actor", "target", "friendship", -6), log("log.snack_refuse", 2, "conflict")], score=[s_trait("target", "cunning", 0.8), s_const(0.2)])])
iv("G08", "hide_snacks", title="Move the snack box into someone's drawer", desc="Pick whose. Hungry colleagues will find it.",
   log="The ghost hid the office snack box in {target}'s desk drawer.", **TABLE, needs="person", icon="coffee", pick=[c_present("self")],
   state=[oset("kitchen.snacks_at", "%target")], react=[chain("iv_snack_need", delay=8)])

# --- G09 reveal the birthday cake too early ----------------------------------------------------------------------
L("cake_early_see", ["...Is that a birthday cake? With MY name on it?", "Wait. That cake says my name. Was that... a surprise?"])
L("cake_planner_sad", ["NO! That was supposed to be a SURPRISE!", "Who put the cake out?! It was hidden!"])
S_("log.cake_early", "The surprise birthday cake for {bday} was sitting out on the kitchen table hours early. {bday} saw it.")
scene("iv_cake_early", allow_absent=True, conditions=[c_present("bday")],
      effects=[expr("bday", "surprised", 5), say("bday", "cake_early_see"), emote("bday", "love"), mood("bday", 8),
               each([say("self", "cake_planner_sad", p=0.6, delay=2), mood("self", -6)], exclude=["bday"], where=[c_any(c_is("self", "ceren"), c_is("self", "ece"))]),
               flag("birthday_spoiled", True, day=True), log("log.cake_early", 3, "party", who=["bday"])])
iv("G09", "cake_early", title="Put the birthday cake out too early", desc="The surprise cake. On the table. Hours early.",
   log="The ghost put the hidden birthday cake out on the kitchen table.", **TABLE, icon="star",
   vars=[var("bday", "birthday_person", role=True, why="why.no_birthday")],
   state=[oset("kitchen.cake_out", True)], react=[trap("iv_cake_early", place="#lunch", key="cakeearly", roles={"bday": "bday"}),
                                                 trap("iv_cake_early", place="#coffee", key="cakeearly2", roles={"bday": "bday"})],
   test={"setup": [{"e": "flag", "key": "birthday", "v": "mert", "day": True}]})
S_("why.no_birthday", "Nobody has a birthday today.")

# --- G10 reserve the whole kitchen --------------------------------------------------------------------------------
L("reserved_sign", ["'KITCHEN RESERVED — Ahmet — private lunch'?!", "We can't eat in the kitchen? Since when?"])
L("reserved_boss", ["Why is there a sign with my name on the kitchen?", "Private lunch? I'm eating a sandwich at my desk!"])
S_("log.reserved", "A sign on the kitchen door says it's reserved for Ahmet's 'private lunch'. Everyone's eating at their desks, grumbling.")
scene("iv_reserved", allow_absent=True,
      effects=[each([say("self", "reserved_sign", p=0.4, delay=1.0), mood("self", -4), rel("self", "@ahmet", "resentment", 3)], exclude=["@ahmet"], stagger=0.5,
                    where=[c_chance(0.7)]),
               say("@ahmet", "reserved_boss", delay=4, when=[c_present("@ahmet")]), log("log.reserved", 3, "boss")])
iv("G10", "reserve_kitchen", title="Put a 'Reserved' sign on the kitchen", desc="'Reserved for Ahmet's private lunch.' Nobody else gets the kitchen today.",
   log="The ghost hung a 'Reserved — Ahmet's private lunch' sign on the kitchen.", **TABLE, icon="lock", conds=LUNCH_LATER,
   state=[oset("kitchen.reserved", "ahmet")], react=[on_trap("lunch_start", "iv_reserved", key="reserved")])

# --- G11 break the microwave ---------------------------------------------------------------------------------------------
L("micro_dead", ["The microwave's dead! My lunch is FROZEN!", "Not the microwave. Anything but the microwave.", "Cold pasta. Again."])
L("micro_queue", ["Is there another microwave anywhere?", "I'm starving and my soup is an ice cube."])
S_("log.micro_dead", "The microwave died at lunchtime. {actor} is staring at a frozen lunch.")
ev(id="iv_microwave_broken", trigger="object_failed", filter={"obj": "microwave"}, priority=70, scope="actor", cooldown=15,
   vars=[var("suspect", "suspect", loc="kitchen", optional=True)],
   effects=[expr("actor", "angry", 4), say("actor", "micro_dead"), mood("actor", -8), log("log.micro_dead", 2, "malfunction"),
            witness([say("self", "micro_queue", p=0.4, delay=1.5)], r=4)],
   outcomes=[out("call", [call("fix_intent", who="@burak", obj="microwave", requester="actor", prio=60, delay=2)], score=[s_const(1)], when=[c_present("@burak")]),
             O_blame()])
iv("G11", "break_microwave", title="Break the microwave", desc="Right before lunch.",
   log="The ghost broke the microwave.", obj="microwave", cat="G", icon="bulb", conds=LUNCH_LATER + [why(c_os("microwave.broken", neg=True), "already_broken")],
   state=[oset("microwave.broken"), oset("microwave.discovered", False)], watch=["iv_microwave_broken", "fix_done", "ivm_accuse"])

# --- G12 label someone's lunch "fish curry — microwave at noon" -----------------------------------------------------------
L("fish_smell", ["WHO MICROWAVED FISH?!", "What is that SMELL?!", "Fish. In the microwave. In an OFFICE."], ahmet=["Who is responsible for this STENCH?"])
L("fish_label", ["The label says it's {target}'s.", "It's {target}'s lunch. The label's right there."])
L("fish_innocent", ["That's not my lunch! I brought a sandwich!", "I don't even LIKE fish!"])
S_("log.fish", "Someone microwaved fish curry at noon. The label said it was {target}'s. {target} swears it isn't.")
S_("mem.fish_shamed", "Everyone thinks I microwaved fish in the office.")
scene("iv_fish", allow_absent=True, conditions=[c_present("target")],
      effects=[sfx("gasp"), each([say("self", "fish_smell", p=0.5, delay=0.8), emote("self", "anger"), mood("self", -4), rel("self", "target", "friendship", -3)],
                                 exclude=["target"], stagger=0.4, where=[c_chance(0.7)]),
               say("target", "fish_innocent", delay=3), emote("target", "sweat", delay=3), mem("target", "", "humiliated", -0.4, 0.7, "mem.fish_shamed", 2),
               rumor("prank", a="target", b="target", juicy=0.3, truth=False, knowers=[]), log("log.fish", 3, "prank", who=["target"])])
iv("G12", "fish_label", title="Label a fish curry as someone's lunch", desc="It goes in the microwave at noon. The smell will find its 'owner'.",
   log="The ghost labelled a fish curry in the fridge with {target}'s name.", **FRIDGE, needs="person", icon="coffee", pick=[c_present("self")], conds=LUNCH_LATER,
   state=[oset("fridge.fish", "%target")], react=[on_trap("lunch_start", "iv_fish", key="fish", roles={"target": "target"})])

# --- G13 salt in the sugar jar ------------------------------------------------------------------------------------------------
L("salt_spit", ["*PFFT* SALT! There's SALT in the sugar!", "BLEGH! Who put salt in the sugar jar?!"])
S_("log.salt", "{actor} took a big sip of coffee — the sugar jar was full of salt.")
scene("iv_salt", allow_absent=True, conditions=[c_present("actor")], vars=[var("suspect", "suspect", loc="kitchen", optional=True)],
      effects=[fx("spill", "actor"), sfx("splash"), expr("actor", "angry", 5), say("actor", "salt_spit"), mood("actor", -6), log("log.salt", 2, "prank"),
               witness([say("self", "witness_laugh", p=0.5, delay=1.6)], r=4)],
      outcomes=[O_blame(), O_ghost(), O_shrug()])
iv("G13", "salt_sugar", title="Fill the sugar jar with salt", desc="The next two coffees will be memorable.",
   log="The ghost filled the kitchen sugar jar with salt.", **COFFEE, icon="coffee",
   state=[oset("kitchen.salt", True)], react=[trap("iv_salt", place="#coffee", key="salt", uses=2, days=1)])

# --- G14 a passive-aggressive fridge note "signed" by someone ------------------------------------------------------------------
L("fnote_read", ["'STOP STEALING MY YOGHURT. I KNOW WHO YOU ARE. — {target}' ...Wow.", "Passive-aggressive note from {target} on the fridge. Classy."])
L("fnote_deny", ["I didn't write that note! I don't even eat yoghurt!", "That's not my handwriting!"])
S_("log.fnote", "A passive-aggressive note 'signed' by {target} is on the fridge. People think it's petty. {target} didn't write it.")
scene("iv_fnote", allow_absent=True, conditions=[c_present("actor"), c_not(c_same("actor", "target"))],
      effects=[say("actor", "fnote_read"), rel("actor", "target", "friendship", -4), rel("actor", "target", "suspicion", 6), log("log.fnote", 2, "conflict", who=["actor", "target"]),
               say("target", "fnote_deny", delay=2.5, when=[c_near("target", "actor", 6)])])
iv("G14", "fridge_note", title="Stick a passive-aggressive note on the fridge — signed by someone", desc="'STOP STEALING MY YOGHURT.' Pick whose name is on it.",
   log="The ghost stuck a passive-aggressive note on the fridge, 'signed' by {target}.", **FRIDGE, needs="person", icon="pin", pick=[],
   state=[oset("fridge.note", "%target")], react=[trap("iv_fnote", place="#fridge", key="fnote", uses=2, days=1), trap("iv_fnote", place="#coffee", key="fnote2", uses=1, days=1)])

# --- G15 clear out the whole fridge ---------------------------------------------------------------------------------------------
L("purge_shock", ["The fridge is EMPTY. Where's everyone's lunch?!", "Someone cleaned out the fridge. My lunch was in there!"])
L("purge_out", ["You know what? Let's all go out for lunch.", "Lunch out, together? My treat-ish."])
S_("log.purge", "Someone emptied the office fridge. {actor} rounded up the hungry and they all went out for lunch together.")
scene("iv_purge", allow_absent=True, conditions=[c_present("actor")],
      roles=[role("buddy", where=[c_avail("self")], score=[s_aff("actor", "self", 0.02), s_rand(0.4)], exclude=["actor"], optional=True)],
      effects=[expr("actor", "surprised", 4), say("actor", "purge_shock"), mood("actor", -6), say("actor", "purge_out", delay=2),
               away("actor", 35, "lunch_out", delay=3), away("buddy", 35, "lunch_out", delay=3.5), rel("actor", "buddy", "friendship", 8, both=True),
               npcflag("buddy", "lunch_done"), log("log.purge", 3, "friendship")])
iv("G15", "fridge_purge", title="Throw out everything in the fridge", desc="Everyone's lunch. Gone.",
   log="The ghost emptied the office fridge.", **FRIDGE, icon="close", conds=LUNCH_LATER,
   state=[oset("fridge.cleared", True)], react=[trap("iv_purge", place="#fridge", key="purge", days=0), on_trap("lunch_start", "iv_purge", key="purge2")])

# --- G16 triple-strength coffee -----------------------------------------------------------------------------------------------
L("strong_jitter", ["I can hear colours.", "WOW. That's... that's coffee. WOW.", "My heart is doing a drum solo."], mert=["I could close ten deals right now. TEN."])
L("jitter_snap", ["Can you STOP TAPPING?!", "Could you breathe more QUIETLY?", "WHY are you so LOUD?"])
L("jitter_snap2", ["I'M NOT TAPPING! YOU'RE tapping!", "Oh, I'M loud?!"])
S_("log.strong", "The coffee is triple-strength today. {actor} is vibrating.")
S_("log.jitter_fight", "Two over-caffeinated colleagues, {actor} and {target}, snapped at each other over nothing.")
scene("iv_strong", allow_absent=True, conditions=[c_present("actor")], effects=[emote("actor", "sweat"), say("actor", "strong_jitter"), log("log.strong", 1, "malfunction")])
ev(id="iv_jitter_fight", trigger="", priority=55,
   roles=[role("actor", where=[c_avail("self"), {"c": "npcflag", "who": "self", "key": "jitter"}], score=[s_trait("self", "temper", 1.0)], exclude=[]),
          role("target", where=[c_avail("self")], score=[s_dist("actor", "self", -0.2), s_rel("actor", "self", "rivalry", 0.02)], exclude=["actor"])],
   effects=[hold(["actor", "target"], 4), say("actor", "jitter_snap", to="target"), say("target", "jitter_snap2", to="actor", delay=1.4), sfx("argue", delay=1.4),
            rel("actor", "target", "friendship", -5, both=True), stat("arguments"), log("log.jitter_fight", 2, "conflict")])
iv("G16", "strong_coffee", title="Set the coffee to triple strength", desc="Productivity up. Patience down.",
   log="The ghost set the coffee machine to triple strength.", **COFFEE, icon="coffee",
   conds=[why(c_os("coffee.strong", neg=True), "already")],
   state=[oset("coffee.strong")], react=[trap("iv_strong", place="#coffee", key="strong", uses=3), chain("iv_jitter_fight", delay=45)])

# --- G17 set out an anonymous tea & cookies tray ---------------------------------------------------------------------------------
L("tray_call", ["Free cookies in the kitchen! Who brought these?", "Tea and cookies! Kitchen! Now!"])
L("tray_claim", ["...Oh, the cookies? Yes. That was me. You're welcome.", "Just a little something for the team."])
L("tray_thanks", ["You're the best!", "Thank you! These are amazing."])
S_("log.tray", "An anonymous tea-and-cookies tray drew half the office into the kitchen. {claimer} took the credit.")
ev(id="iv_tray_call", trigger="", priority=56,
   roles=[role("actor", where=[c_avail("self")], score=[s_trait("self", "sociability", 1.0), s_rand(0.3)], exclude=[])],
   effects=[say("actor", "tray_call"), emote("actor", "exclaim"), meetup("iv_tray_party", who="all", area="kitchen", need=3, ttl=30)])
scene("iv_tray_party", noise=0.8,
      roles=[role("claimer", where=[c_present("self")], score=[s_trait("self", "cunning", 1.2), s_trait("self", "honesty", -0.8), s_rand(0.3)], exclude=[], optional=True)],
      effects=[each([mood("self", 6), stress("self", -4)], stagger=0.2, where=[c_zone("self", ["kitchen"])]), oset("kitchen.tray", False)],
      outcomes=[out("claim", [say("claimer", "tray_claim"), each([say("self", "tray_thanks", p=0.4, delay=1.5), rel("self", "claimer", "friendship", 4)], exclude=["claimer"],
                              where=[c_zone("self", ["kitchen"])]), favor("claimer", 1), log("log.tray", 3, "friendship")],
                    score=[s_trait("claimer", "cunning", 1.0)], when=[c_filled("claimer"), c_trait("claimer", "cunning", gt=0.45)]),
                out("mystery", [ghost(), call("ghost_theory"), each([rel("self", "actor", "friendship", 2)], exclude=["actor"], where=[c_zone("self", ["kitchen"])])], score=[s_const(0.5)])])
iv("G17", "tea_tray", title="Set out an anonymous tea & cookies tray", desc="Nobody knows who brought it. Someone will claim it.",
   log="The ghost set out a tea-and-cookies tray in the kitchen.", **TABLE, icon="coffee",
   state=[oset("kitchen.tray", True)], react=[chain("iv_tray_call", delay=3)])

# --- G18 leave exactly one cup of coffee ----------------------------------------------------------------------------------------------
L("lastcup_take", ["Last cup! Ha! Mine.", "Ooh, exactly one cup left. Lucky me."])
L("lastcup_whine", ["Did you just take the LAST cup?!", "That was the last coffee. I saw it. You saw me see it."])
L("lastcup_share", ["...Fine. Half each?", "Here. Have half. I'm not a monster."])
L("lastcup_keep", ["First come, first served.", "Snooze you lose."])
S_("log.lastcup_share", "{actor} and {target} both wanted the last cup of coffee. They split it. Friendship +1.")
S_("log.lastcup_keep", "{actor} took the last cup of coffee right in front of {target}. Coldest move of the day.")
scene("iv_lastcup", allow_absent=True, conditions=[c_present("actor")],
      roles=[role("target", where=[c_avail("self")], score=[s_rand(0.5), s_dist("actor", "self", -0.1)], exclude=["actor"])],
      effects=[say("actor", "lastcup_take"), oset("kitchen.last_cup", False), visit("target", "actor", "iv_lastcup_scene", prio=58, ttl=30, delay=1)])
scene("iv_lastcup_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "lastcup_whine", to="target")],
      outcomes=[out("share", [say("target", "lastcup_share", to="actor", delay=1.6), rel("actor", "target", "friendship", 7, both=True), log("log.lastcup_share", 2, "friendship")],
                    score=[s_trait("target", "empathy", 1.0), s_aff("target", "actor", 0.02)]),
                out("keep", [say("target", "lastcup_keep", to="actor", delay=1.6), rel("actor", "target", "resentment", 6), rel("actor", "target", "friendship", -5),
                             log("log.lastcup_keep", 2, "conflict")], score=[s_trait("target", "cunning", 0.7), s_rel("target", "actor", "rivalry", 0.02)])])
iv("G18", "last_cup", title="Leave exactly one cup of coffee", desc="Two people will want it.",
   log="The ghost left exactly one cup of coffee in the machine.", **COFFEE, icon="coffee",
   conds=[why(c_office("coffee.broken", False), "coffee_broken")], state=[oset("kitchen.last_cup", True)],
   react=[trap("iv_lastcup", place="#coffee", key="lastcup", days=0)])

# --- G19 a "World's Best Boss" mug from someone ------------------------------------------------------------------------------------
L("bestboss_boss", ["'World's Best Boss'... from {target}? Well. Well, well.", "A mug! For me! From {target}! How thoughtful."])
L("bestboss_thank", ["{target}, thank you for the mug. I'm touched.", "Excellent taste in mugs, {target}."])
L("bestboss_confused", ["...You're welcome? What mug?", "Oh — um — yes! The mug! Of course."])
L("bestboss_eyeroll", ["A 'World's Best Boss' mug? Really, {target}?", "Wow. Shameless."])
S_("log.bestboss", "A 'World's Best Boss' mug appeared on Ahmet's desk 'from {target}'. Ahmet loved it. The office rolled its eyes.")
scene("iv_bestboss", allow_absent=True, conditions=[c_present("actor"), c_present("target")],
      effects=[expr("actor", "happy", 5), say("actor", "bestboss_boss"), favor("target", 6), rel("actor", "target", "friendship", 6),
               visit("actor", "target", "iv_bestboss_scene", prio=56, ttl=50, delay=2), log("log.bestboss", 3, "boss", who=["target"])])
scene("iv_bestboss_scene", conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "bestboss_thank", to="target"), say("target", "bestboss_confused", to="actor", delay=1.6),
               witness([say("self", "bestboss_eyeroll", p=0.5, delay=3), rel("self", "target", "rivalry", 5), rel("self", "target", "respect", -3)], near="target", r=5)])
iv("G19", "best_boss_mug", title="Leave a 'World's Best Boss' mug for Ahmet — from someone", desc="Pick who 'gave' it. Ahmet will thank them. Publicly.",
   log="The ghost left a 'World's Best Boss' mug on Ahmet's desk with {target}'s name on the tag.", **TABLE, needs="person", icon="coffee",
   pick=[c_is("self", "ahmet", neg=True), c_present("self")], conds=[r_present("@ahmet")],
   state=[oset("kitchen.bestboss", "%target")], react=[trap("iv_bestboss", place="desk_ahmet", who="@ahmet", key="bestboss", roles={"target": "target"})])

# --- G20 turn the water cooler into a spa -------------------------------------------------------------------------------------------
L("spa_enjoy", ["Lemon water? Cucumber slices? I'm never leaving.", "'Spa day'. I could get used to this.", "Ahh. Hydration. Luxury."])
L("spa_boss", ["Is this a spa or an office?!", "Back to your desks! This isn't a holiday resort!"])
S_("log.spa", "Someone turned the water cooler into a 'spa corner'. People keep lingering there.")
S_("log.spa_boss", "Ahmet found a crowd at the 'spa' water cooler and broke it up.")
scene("iv_spa", allow_absent=True, conditions=[c_present("actor")],
      roles=[role("target", where=[c_avail("self")], near="actor", r=4.0, score=[s_dist("actor", "self", -0.3)], exclude=["actor"], optional=True)],
      effects=[say("actor", "spa_enjoy"), mood("actor", 6), stress("actor", -6), act("actor", "rest", place="armchair", dur=6), log("log.spa", 1, "friendship"),
               rel("actor", "target", "friendship", 4, both=True, when=[c_filled("target")])])
scene("iv_spa_boss", allow_absent=True, conditions=[c_present("@ahmet")],
      effects=[say("@ahmet", "spa_boss"), expr("@ahmet", "angry", 4), oset("water.lemon", False), log("log.spa_boss", 2, "boss")])
iv("G20", "spa_water", title="Turn the water cooler into a 'spa corner'", desc="Lemon slices, cucumber, a little sign. People will linger.",
   log="The ghost turned the water cooler into a 'spa corner'.", obj="water_cooler", cat="G", icon="star",
   conds=[why(c_os("water.broken", neg=True), "water_broken", "The water cooler is broken.")],
   state=[oset("water.lemon", True)], react=[trap("iv_spa", place="#water", key="spa", uses=3), chain("iv_spa_boss", delay=70)])
