# Interventions — J. Hidden combinations. Each one only appears in an object's menu
# once its ingredients (ordinary interventions) have been done today — and then it
# sets off a whole multi-stage story instead of a single reaction.
from iv_common import *  # noqa: F401,F403

J_REUSE = {"cool": 900, "day": 1, "per": "global"}
BOARD = dict(obj="meeting_board", cat="J")
NOTE = dict(obj="noticeboard", cat="J")


def starts(arc_id, cast, stage="", effects=None):
    """The scene that kicks a story off: whatever it shows, then the story starts."""
    return (effects or []) + [arc_start(arc_id, cast, stage=stage, force=True)]


# --- J01 promotion file + moved meeting = the wrong promotion, announced in public ---------------------------
L("j01_intro", ["Before we start — I have promotion news. I've read the file.", "One announcement first. The promotion file is very clear."])
S_("log.j01_intro", "Ahmet opened today's meeting with 'promotion news'. He's reading from the tampered file.")
scene("j01_announce", allow_absent=True, conditions=[c_present("actor")],
      effects=starts("wrong_promotion", {"boss": "@ahmet", "credited": "credited", "rightful": "rightful"}, "announce",
                     [say("actor", "j01_intro"), emote("actor", "idea"), log("log.j01_intro", 4, "promotion", who=["credited", "rightful"])]))
iv("J01", "j_promo_meeting", title="Put 'Promotion announcement' on the agenda", desc="The file says {credited}. The meeting is moved. Ahmet will read it out loud.",
   log="The ghost added 'Promotion announcement' to the top of today's agenda.", **BOARD, icon="star", hidden=True, combo=["E01", "C01"],
   vars=[var("credited", "ostate", path="promo.credit", role=True), var("rightful", "promo_rightful", role=True, **{"not": "credited"})],
   conds=[c_iv("E01"), c_iv("C01"), r_meeting_pending(), r_meeting_not_started(), r_present("@ahmet")],
   state=[oset("board.agenda", "promo"), oset("board.title", "promotion")],
   react=[on_trap("meeting_start", "j01_announce", who="@ahmet", key="j01")], reuse=J_REUSE, imp=4, arc="wrong_promotion",
   test={"at": "09:40", "minutes": 420})

# --- J02 love note to the wrong person + fake coffee invite = the coffee-date mix-up ---------------------------
L("j02_blush", ["A love note AND a coffee invite? From {owner}? Today?", "Oh my god. {owner} wants a DATE?"])
S_("log.j02", "{reader} now believes {owner} asked them out — the misdelivered love note and the fake coffee invite both came 'from' {owner}.")
scene("j02_setup", allow_absent=True, conditions=[c_present("reader")],
      effects=starts("coffee_date_mixup", {"sender": "owner", "reader": "reader", "crush": "crush"}, "",
                     [say("reader", "j02_blush"), emote("reader", "love"), mood("reader", 10), log("log.j02", 4, "romance", who=["owner", "reader"])]))
iv("J02", "j_candle_date", title="Turn the invite into a candle-lit date", desc="{reader} already has their love note. Now the 1:1 invite says 'just us, candles'.",
   log="The ghost edited {owner}'s fake 1:1 invite to {reader}: 'Coffee — just us. Candles.'", obj="ws", tab="mail", cat="J", icon="star", hidden=True, combo=["I09", "B07"],
   vars=[var("reader", "ostate", path="ws.{owner}.love_note", role=True), var("crush", "crush_of", of="owner", role=True, optional=True)],
   conds=[c_iv("I09", same="owner"), c_iv("B07", same="owner"), r_present()],
   state=[oset("ws.{owner}.candles", "%reader")], react=[chain("j02_setup", delay=2)], reuse=J_REUSE, imp=4, arc="coffee_date_mixup")

# --- J03 secret job application + rewritten performance report = a resignation crisis --------------------------
L("j03_read", ["A job application — stapled to THIS performance report? {applicant}. My office.", "So {applicant} wants out. And look at this report."])
L("j03_accuse", ["Your report is a disaster and you're applying elsewhere. Explain.", "Job hunting? With numbers like these? Interesting."])
L("j03_quit", ["You know what? Fine. I quit. I'll print my letter now.", "I'm done. You'll have my resignation in ten minutes."])
L("j03_plead", ["Please — the report is wrong! I can explain everything!", "That's not my report! Someone changed it!"])
S_("log.j03_read", "Ahmet found {applicant}'s job application stapled to a terrible performance report. He summoned {applicant} immediately.")
S_("log.j03_quit", "{actor} was confronted about the application and the report — and quit on the spot. A resignation crisis has begun.")
S_("log.j03_plead", "{actor} begged Ahmet to believe the report was wrong. Ahmet didn't. {actor} is shaken — and thinking about leaving.")
scene("j03_boss_reads", allow_absent=True, conditions=[c_present("actor")],
      effects=[expr("actor", "angry", 7), say("actor", "j03_read"), emote("actor", "anger"), rel("actor", "applicant", "trust", -15), favor("applicant", -8),
               log("log.j03_read", 4, "job", who=["applicant"]), summon("applicant", "j03_confront", delay=2)])
scene("j03_confront", noise=0.8, conditions=[c_present("actor")],
      effects=[hold(["actor", "target"], 6), say("target", "j03_accuse", to="actor"), emote("actor", "sweat")],
      outcomes=[out("quit", starts("resignation", {"quitter": "actor", "friend": "$friend", "boss": "@ahmet"}, "letter",
                                   [say("actor", "j03_quit", to="target", delay=1.8), expr("actor", "angry", 6, delay=1.8), morale("actor", -15),
                                    log("log.j03_quit", 5, "job", who=["actor"])]),
                    score=[s_trait("actor", "temper", 1.0), s_morale("actor", -0.03)]),
                out("plead", starts("resignation", {"quitter": "actor", "friend": "$friend", "boss": "@ahmet"}, "vent",
                                    [say("actor", "j03_plead", to="target", delay=1.8), expr("actor", "sad", 6, delay=1.8), morale("actor", -10),
                                     log("log.j03_plead", 4, "job", who=["actor"])]),
                    score=[s_trait("actor", "empathy", 0.6), s_const(0.5)])])
iv("J03", "j_staple_application", title="Staple the job application to their performance report", desc="Ahmet will read both at once.",
   log="The ghost stapled {applicant}'s secret job application to their rewritten performance report.", obj="hr_cabinet", cat="J", icon="papers", hidden=True,
   combo=["E06", "E03"],
   vars=[var("applicant", "ostate", path="hr.application", role=True), var("friend", "best_of", of="applicant", lim=-99, optional=True)],
   conds=[c_iv("E06"), c_iv("E03", same="applicant"), r_present("@ahmet")],
   state=[oset("hr.stapled", "%applicant"), favor("applicant", -4)],
   react=[trap("j03_boss_reads", place="desk_ahmet", who="@ahmet", key="j03", after=2)], reuse=J_REUSE, imp=4, arc="resignation",
   test={"prefer": "burak", "minutes": 300})

# --- J04 old version of the report + CC to the boss = the wrong figures go to the client -------------------------
L("j04_send", ["*whoosh* — 'Final figures, CC Ahmet' — sent.", "*the old spreadsheet leaves the building*"])
S_("log.j04", "The OLD version of {owner}'s figures went to the client — with Ahmet in CC. The client is already dialling.")
scene("j04_sent", allow_absent=True, conditions=[c_present("@ahmet")],
      effects=starts("blame_game", {"boss": "@ahmet", "culprit": "owner"}, "complaint",
                     [sfx("email"), say("owner", "j04_send", when=[c_present("owner")]), log("log.j04", 4, "blame", who=["owner"])]))
iv("J04", "j_send_old_figures", title="Send the old figures to the client — CC Ahmet", desc="The outdated version is open and Ahmet is already in CC. One click.",
   log="The ghost sent the old version of {owner}'s figures to the client, with Ahmet in CC.", obj="ws", tab="mail", cat="J", icon="email", hidden=True,
   combo=["A08", "B13"], conds=[c_iv("A08", same="owner"), c_iv("B13", same="owner"), r_present("@ahmet"), r_time(before="15:30")],
   state=[oset("ws.{owner}.sent_old", True)], react=[chain("j04_sent", delay=3)], reuse=J_REUSE, imp=4, arc="blame_game", owners=["selin", "mert", "zeynep", "burak", "ece", "deniz", "ceren"])

# --- J05 leaked draft memo + agenda rewrite = full layoff panic ----------------------------------------------------
L("j05_read", ["'Restructuring — Q&A, 11:00'?! It's on the AGENDA?!", "The memo AND the agenda? This is real. They're firing people."])
S_("log.j05", "{ear} put Ahmet's leaked memo together with today's agenda and concluded: layoffs are coming. Today.")
scene("j05_panic", allow_absent=True, conditions=[c_present("ear")],
      effects=starts("layoff_panic", {"ear": "ear", "boss": "@ahmet"}, "",
                     [say("ear", "j05_read"), expr("ear", "surprised", 6), emote("ear", "exclaim"), stress("ear", 15), log("log.j05", 4, "rumor", who=["ear"])]))
iv("J05", "j_restructure_qa", title="Add 'Restructuring Q&A' under the leaked memo", desc="Everyone saw the memo. Now the board makes it official.",
   log="The ghost wrote 'Restructuring — Q&A' on the meeting board, right under the agenda.", **BOARD, icon="board", hidden=True, combo=["B18", "C05"],
   vars=[var("ear", "most_curious", role=True, **{"not": "@ahmet"})],
   conds=[c_iv("B18"), c_iv("C05"), why({"c": "arc", "arc": "layoff_panic", "not": True}, "panic_running")],
   state=[oset("board.title", "restructuring")], react=[chain("j05_panic", delay=3)], reuse=J_REUSE, imp=4, arc="layoff_panic")

# --- J06 wrong meeting chair + boss's golf game = a coup ----------------------------------------------------------
L("j06_crown", ["The board says I'm acting manager today. Who am I to argue?", "'Acting manager: me.' Well. If the board says so."])
S_("log.j06", "With Ahmet off to 'golf' and the board naming {usurper} as chair, {usurper} has declared themselves acting manager.")
scene("j06_usurp", allow_absent=True, conditions=[c_present("usurper")],
      effects=starts("office_coup", {"usurper": "usurper", "boss": "@ahmet"}, "",
                     [say("usurper", "j06_crown"), emote("usurper", "idea"), favor("usurper", 2), log("log.j06", 4, "boss", who=["usurper"])]))
iv("J06", "j_acting_manager", title="Rename the chair 'Acting Manager'", desc="Ahmet has a golf game. {usurper} is already the chair.",
   log="The ghost changed the board: '{usurper} — Acting Manager'.", **BOARD, icon="star", hidden=True, combo=["C09", "C17"],
   vars=[var("usurper", "ostate", path="board.chair", role=True)],
   conds=[c_iv("C09"), c_iv("C17"), r_present("usurper")],
   state=[oset("board.title", "acting_boss")], react=[chain("j06_usurp", delay=3)], reuse=J_REUSE, imp=4, arc="office_coup")

# --- J07 flickering lights + fake virus alert = the ghost hunt -----------------------------------------------------
L("j07_scream", ["THE LIGHTS ARE FLICKERING AND MY SCREEN HAS A SKULL ON IT!", "It's in the COMPUTERS now. The ghost is in the computers!"])
S_("log.j07", "The lights flickered in time with a virus siren. {believer} has seen enough: the office is haunted.")
scene("j07_spooked", allow_absent=True, conditions=[c_present("believer")],
      effects=starts("ghost_hunt", {"believer": "believer", "skeptic": "@burak"}, "",
                     [say("believer", "j07_scream"), expr("believer", "surprised", 6), sfx("gasp"), call("ghost_theory"), ghost(2), log("log.j07", 4, "ghost", who=["believer"])]))
iv("J07", "j_haunting", title="Sync the flicker with the virus siren", desc="Lights and screens, pulsing together. Very, very spooky.",
   log="The ghost synchronised the flickering lights with the fake virus siren.", obj="lights", cat="J", icon="ghost", hidden=True, combo=["H20", "A09"],
   vars=[var("believer", "most_curious", role=True, **{"not": "@burak"})],
   conds=[c_iv("H20"), c_iv("A09"), why({"c": "arc", "arc": "ghost_hunt", "not": True}, "hunt_running", "The office is already hunting a ghost.")],
   state=[{"e": "call", "fn": "flicker", "minutes": 10}, oset("lights.synced", True)], react=[chain("j07_spooked", delay=2)], reuse=J_REUSE, imp=4, arc="ghost_hunt")

# --- J08 leaked payroll + "raise budget: 0" = a salary revolt ------------------------------------------------------
L("j08_read", ["Raise budget ZERO — and THAT's what some people earn?!", "I've seen the payroll. And now 'no raises'? No. Absolutely not."])
S_("log.j08", "{leader} saw the leaked payroll right next to 'Raise budget this year: 0'. {leader} is organising a revolt.")
scene("j08_rally", allow_absent=True, conditions=[c_present("leader")],
      effects=starts("salary_revolt", {"leader": "leader", "boss": "@ahmet"}, "",
                     [say("leader", "j08_read"), expr("leader", "angry", 7), emote("leader", "anger"), morale("leader", -8), log("log.j08", 4, "work", who=["leader"])]))
iv("J08", "j_payroll_pin", title="Pin the payroll next to 'Raise budget: 0'", desc="{leader} has already seen the payroll. Now everybody can compare.",
   log="The ghost pinned the leaked payroll right next to 'Raise budget this year: 0'.", **NOTE, icon="pin", hidden=True, combo=["B17", "E04"],
   vars=[var("leader", "ostate", path="ws.zeynep.payroll_leak", role=True)],
   conds=[c_iv("B17"), c_iv("E04"), r_present("leader")],
   state=[pin("payroll", about="@ahmet"), oset("notice.payroll", True)], react=[chain("j08_rally", delay=3)], reuse=J_REUSE, imp=4, arc="salary_revolt")

# --- J09 disco lights + music + anonymous tray = an office party ---------------------------------------------------
L("j09_kickoff", ["Music? Disco lights? SNACKS? This is a party. I'm making it a party.", "Okay, the universe wants a party. Who am I to say no?"])
S_("log.j09", "Disco lights, music and a mystery snack tray: {host} has decided this is now an office party.")
scene("j09_kickoff", allow_absent=True, conditions=[c_present("host")],
      effects=starts("office_party", {"host": "host", "helper": "helper", "boss": "@ahmet"}, "prep",
                     [say("host", "j09_kickoff"), emote("host", "cheer"), mood("host", 12), log("log.j09", 4, "celebration", who=["host"])]))
iv("J09", "j_party_mode", title="Hang a 'PARTY' banner over the kitchen", desc="The music's on, the lights are pink and there's a tray. It only needs a name.",
   log="The ghost hung a 'PARTY!' banner over the kitchen doorway.", obj="kitchen_table", cat="J", icon="music", hidden=True, combo=["H10", "H19", "G17"],
   vars=[var("host", "top_trait", trait="sociability", role=True), var("helper", "best_of", of="host", lim=-30, role=True, optional=True)],
   conds=[c_iv("H10"), c_iv("H19"), c_iv("G17"), why({"c": "arc", "arc": "office_party", "not": True}, "party_running", "There's already a party going on.")],
   state=[oset("kitchen.party", True)], react=[chain("j09_kickoff", delay=2)], reuse=J_REUSE, imp=4, arc="office_party")

# --- J10 transfer request + reference letter for the same person = a loyalty test -----------------------------------
L("j10_find", ["A transfer request. AND a reference letter. Both for {target}.", "Hm. {target}'s papers. Both of them. Interesting."])
S_("log.j10", "Ahmet found a transfer request and a reference letter for {target} on his desk — together.")
scene("j10_found", allow_absent=True, conditions=[c_present("actor")],
      effects=starts("loyalty_test", {"boss": "@ahmet", "target": "target", "friend": "friend"}, "",
                     [say("actor", "j10_find"), emote("actor", "question"), log("log.j10", 3, "boss", who=["target"])]))
iv("J10", "j_loyalty_file", title="Put both letters in Ahmet's in-tray", desc="A transfer request and a glowing reference — for the same person.",
   log="The ghost put {target}'s transfer request and reference letter together in Ahmet's in-tray.", obj="hr_cabinet", cat="J", icon="papers", hidden=True,
   combo=["E16", "E18"],
   vars=[var("target", "ostate", path="hr.transfer", role=True), var("friend", "best_of", of="target", lim=-30, role=True, optional=True)],
   conds=[c_iv("E16"), c_iv("E18", same="target"), r_present("@ahmet")],
   state=[oset("hr.loyalty", "%target")], react=[trap("j10_found", place="desk_ahmet", who="@ahmet", key="j10", after=2)], reuse=J_REUSE, imp=4, arc="loyalty_test")

# --- J11 doctored couple photo + redirected lunch invite = the accidental double date --------------------------------
L("j11_note", ["'Double date at lunch?' Who wrote that on our photo?!", "Someone's drawn hearts on the photo. And a lunch table. For four."])
S_("log.j11", "Someone doodled 'DOUBLE DATE — lunch' on the couple photo of {a} and {b}. {c} and {d} are apparently invited too.")
scene("j11_setup", allow_absent=True, conditions=[c_present("a")],
      effects=starts("double_date", {"a": "a", "b": "b", "c": "c", "d": "d"}, "",
                     [say("a", "j11_note"), emote("a", "sweat"), log("log.j11", 4, "romance", who=["a", "b", "c", "d"])]))
iv("J11", "j_double_date", title="Doodle 'Double date at lunch!' on the couple photo", desc="{c} invited {d} to lunch. {a} and {b} are already 'a couple'. Why not all four?",
   log="The ghost doodled 'DOUBLE DATE at lunch!' on the photo of {a} and {b}.", **NOTE, icon="star", hidden=True, combo=["I16", "I08"],
   vars=[var("a", "ostate", path="notice.couple", role=True), var("b", "ostate", path="notice.couple_with", role=True),
         var("c", "iv_who", id="I08", field="owner", role=True), var("d", "ostate", path="ws.{c}.lunch_inv", role=True)],
   conds=[c_iv("I16"), c_iv("I08"), r_time(before="13:30", key="after_lunch")],
   state=[oset("notice.double_date", True)], react=[chain("j11_setup", delay=3)], reuse=J_REUSE, imp=4, arc="double_date",
   test={"at": "10:30"})

# --- J12 speakerphone + "we need to talk" = the crush calls back, on speaker ------------------------------------------
S_("log.j12", "The ghost made {crush} call {owner} back. {owner}'s phone is still on speaker.")
scene("j12_ring", allow_absent=True, conditions=[c_present("owner")],
      effects=starts("speaker_confession", {"owner": "owner", "crush": "crush"}, "", [sfx("phone"), emote("owner", "phone"), log("log.j12", 3, "romance", who=["owner", "crush"])]))
iv("J12", "j_callback_speaker", title="Make {crush} call back — on speaker", desc="'We need to talk' was sent. The phone is on speaker. Let it ring.",
   log="The ghost put {crush}'s call back through to {owner}'s phone — on speaker.", obj="ws", tab="phone", cat="J", icon="phone", hidden=True, combo=["F17", "F11"],
   vars=[var("crush", "ostate", path="ws.{owner}.wntt", role=True)],
   conds=[c_iv("F11", same="owner"), c_iv("F17", same="owner"), r_present(), r_present("crush")],
   state=[oset("ws.{owner}.ringing", True)], react=[chain("j12_ring", delay=2)], reuse=J_REUSE, imp=4, arc="speaker_confession")

# --- J13 client visit + dead projector = client meltdown ----------------------------------------------------------
L("j13_reminder", ["CLIENT ARRIVING IN 30 MINUTES — the projector's first.", "*taps the board* 'Client presentation: {presenter}'. Wait. Me?"])
S_("log.j13", "The board now says {presenter} presents to the client — on the projector that doesn't work.")
scene("j13_setup", allow_absent=True, conditions=[c_present("presenter")],
      effects=starts("client_meltdown", {"presenter": "presenter", "boss": "@ahmet", "it": "@burak"}, "",
                     [say("presenter", "j13_reminder"), emote("presenter", "sweat"), stress("presenter", 10), log("log.j13", 4, "meeting", who=["presenter"])]))
iv("J13", "j_client_presenter", title="Write '{presenter} presents to the client' on the board", desc="A client is coming. The projector is dead. Somebody has to present.",
   log="The ghost wrote '{presenter} presents to the client' on the board.", obj="meeting_table", cat="J", icon="people", hidden=True, combo=["C19", "C15"],
   vars=[var("presenter", "boss_fav", role=True, **{"not": "@ahmet"})],
   conds=[c_iv("C19"), c_iv("C15"), r_present("@ahmet"), r_time(before="15:00")],
   state=[oset("board.presenter", "%presenter")], react=[chain("j13_setup", delay=2)], reuse=J_REUSE, imp=4, arc="client_meltdown")

# --- J14 fire alarm + jammed front door = the great evacuation -----------------------------------------------------
S_("log.j14", "The ghost jammed the fire exit as well. With the alarm ringing, the whole office is trapped at reception.")
scene("j14_trap", allow_absent=True, conditions=[c_present("hero")],
      effects=starts("evacuation", {"hero": "hero", "panicker": "panicker", "boss": "@ahmet"}, "",
                     [sfx("slam"), each([emote("self", "exclaim")], where=[c_zone("self", ["reception"])]), log("log.j14", 4, "drama", who=["hero", "panicker"])]))
iv("J14", "j_jam_fire_exit", title="Jam the fire exit too", desc="The alarm is ringing and the front door is stuck. Close the last way out.",
   log="The ghost jammed the fire exit while the alarm was ringing.", obj="front_door", cat="J", icon="lock", hidden=True, combo=["H14", "H11"],
   vars=[var("hero", "top_trait", trait="diligence", role=True), var("panicker", "most_stressed", role=True, **{"not": "hero"})],
   conds=[c_iv("H14"), c_iv("H11"), c_os("alarm.on", True), c_os("front_door.jammed", True)],
   state=[oset("front_door.exit_jammed", True)], react=[chain("j14_trap", delay=1)], reuse=J_REUSE, imp=4, arc="evacuation",
   test={"at": "11:05"})

# --- J15 emptied fridge + "signed" note = the fridge war -----------------------------------------------------------
L("j15_sign", ["'I threw it all out. Label your food. — {signer}'?!", "{signer} threw out EVERYONE's lunch? And signed it?!"])
S_("log.j15", "A second note appeared on the empty fridge: 'I threw it all out. Label your food. — {signer}'. {victim} saw it first.")
scene("j15_war", allow_absent=True, conditions=[c_present("victim")],
      effects=starts("fridge_war", {"victim": "victim", "signer": "signer"}, "", [say("victim", "j15_sign"), emote("victim", "anger"), log("log.j15", 4, "conflict", who=["victim", "signer"])]))
iv("J15", "j_sign_the_purge", title="Add 'I threw it all out' to the signed note", desc="The fridge is empty and there's a note with {signer}'s name on it. Make it a confession.",
   log="The ghost added 'I threw it all out. Label your food.' to {signer}'s fridge note.", obj="fridge", cat="J", icon="pin", hidden=True, combo=["G15", "G14"],
   vars=[var("signer", "ostate", path="fridge.note", role=True), var("victim", "top_trait", trait="temper", role=True, **{"not": "signer"})],
   conds=[c_iv("G15"), c_iv("G14")],
   state=[oset("fridge.confession", "%signer")], react=[chain("j15_war", delay=3)], reuse=J_REUSE, imp=4, arc="fridge_war")

# --- J16 "I quit" auto-reply + resignation draft = a farewell for someone who isn't leaving ---------------------------
L("j16_see", ["'I quit' auto-reply AND a resignation letter? {owner} is really leaving!", "Oh no. {owner}'s leaving. It's real. The letter's right there."])
S_("log.j16", "{organiser} saw {owner}'s 'I quit' auto-reply and the resignation letter. {organiser} is sure {owner} is leaving.")
scene("j16_news", allow_absent=True, conditions=[c_present("organiser")],
      effects=starts("farewell_mixup", {"leaver": "owner", "organiser": "organiser", "boss": "@ahmet"}, "",
                     [say("organiser", "j16_see"), expr("organiser", "sad", 6), log("log.j16", 4, "job", who=["owner", "organiser"])]))
iv("J16", "j_cc_the_letter", title="Attach the resignation draft to the auto-reply", desc="Anyone who emails {owner} now gets 'I quit' — with the letter attached.",
   log="The ghost attached {owner}'s resignation draft to their 'I quit' auto-reply.", obj="ws", tab="mail", cat="J", icon="email", hidden=True, combo=["D17", "B09"],
   vars=[var("organiser", "best_of", of="owner", lim=-30, role=True)],
   conds=[c_iv("D17", same="owner"), c_iv("B09", same="owner"), r_present("organiser")],
   state=[oset("ws.{owner}.autoreply", "quit_letter")], react=[chain("j16_news", delay=3)], reuse=J_REUSE, imp=4, arc="farewell_mixup",
   owners=["selin", "mert", "zeynep", "burak", "ece", "deniz", "ceren"])

# --- J17 private folder shared + confidential document = the leak ---------------------------------------------------
S_("log.j17", "The ghost copied the confidential document into {leaker}'s shared folder. Anyone can see it — and whose folder it's in.")
scene("j17_leak", allow_absent=True, conditions=[c_present("finder")],
      effects=starts("leak_scandal", {"leaker": "leaker", "finder": "finder", "boss": "@ahmet", "it": "@burak"}, "", [emote("finder", "question"), log("log.j17", 3, "secret", who=["leaker"])]))
iv("J17", "j_leak_to_folder", title="Copy the confidential document into the shared folder", desc="{leaker}'s private folder is open to everyone. The confidential file would fit right in.",
   log="The ghost copied the confidential document into {leaker}'s shared folder.", obj="file_cabinet", cat="J", icon="folder", hidden=True, combo=["A20", "D08"],
   vars=[var("leaker", "iv_who", id="A20", field="owner", role=True), var("finder", "most_curious", role=True, **{"not": "leaker"})],
   conds=[c_iv("A20"), c_iv("D08"), r_present("@ahmet")],
   state=[oset("hr.leaked_to", "%leaker")], react=[chain("j17_leak", delay=4)], reuse=J_REUSE, imp=4, arc="leak_scandal")

# --- J18 rewritten report + surprise review for the same person = open war with the boss -----------------------------
L("j18_storm", ["That review was RIGGED. Someone rewrote my report and he believed every word!", "He read me a report I never wrote. And he enjoyed it."])
S_("log.j18", "{rebel} came out of the surprise review convinced Ahmet rigged it. Open war with the boss has begun.")
scene("j18_clash", allow_absent=True, conditions=[c_present("rebel")],
      effects=starts("boss_clash", {"rebel": "rebel", "boss": "@ahmet", "ally": "ally"}, "",
                     [say("rebel", "j18_storm"), expr("rebel", "angry", 7), rel("rebel", "@ahmet", "resentment", 15), log("log.j18", 4, "boss", who=["rebel"])]))
iv("J18", "j_rigged_review", title="Hand Ahmet the rewritten report for the review", desc="{rebel}'s surprise review is booked and their report has been 'edited'.",
   log="The ghost slid {rebel}'s rewritten report into Ahmet's review folder.", **BOARD, icon="file", hidden=True, combo=["E03", "C18"],
   vars=[var("rebel", "ostate", path="hr.perf", role=True), var("ally", "best_of", of="rebel", lim=-30, role=True, optional=True)],
   conds=[c_iv("E03"), c_iv("C18", same="rebel"), r_present("rebel")],
   state=[oset("board.review_file", "%rebel")], react=[chain("j18_clash", delay=3)], reuse=J_REUSE, imp=4, arc="boss_clash")

# --- J19 named rumour-starter + anonymous complaint = a rumour war -------------------------------------------------
L("j19_sign", ["The anonymous complaint about me is in {gossip}'s handwriting?!", "So it was {gossip}. The rumour AND the complaint."])
S_("log.j19", "{enemy} noticed the anonymous complaint is in the same handwriting as {gossip}'s rumours. A rumour war is coming.")
scene("j19_war", allow_absent=True, conditions=[c_present("enemy")],
      effects=starts("rumor_war", {"gossip": "gossip", "enemy": "enemy"}, "",
                     [say("enemy", "j19_sign"), expr("enemy", "angry", 6), rel("enemy", "gossip", "resentment", 12), log("log.j19", 4, "rumor", who=["enemy", "gossip"])]))
iv("J19", "j_sign_complaint", title="'Sign' the anonymous complaint with the rumour-starter's name", desc="One note names who started a rumour. The other is anonymous. Not any more.",
   log="The ghost signed the anonymous complaint about {enemy} with {gossip}'s name.", **NOTE, icon="pin", hidden=True, combo=["I03", "I12"],
   vars=[var("gossip", "ostate", path="notice.source_of", role=True), var("enemy", "ostate", path="notice.complaint_about", role=True)],
   conds=[c_iv("I03"), c_iv("I12"), c_same("gossip", "enemy", neg=True)],
   state=[oset("notice.signed_complaint", "%gossip")], react=[chain("j19_war", delay=3)], reuse=J_REUSE, imp=4, arc="rumor_war",
   test={"setup": [{"e": "rumor", "kind": "slacker", "a": "@mert", "b": "@zeynep", "truth": False, "origin": "@zeynep", "juicy": 0.5, "knowers": ["@zeynep", "@ece"]}]})

# --- J20 kind note + anonymous compliment for the same person = a secret admirer -----------------------------------
L("j20_wonder", ["A kind note AND a compliment on the board? Someone likes me. Who?!", "Two anonymous nice things in one day? This is a secret admirer."])
S_("log.j20", "After a kind note and an anonymous compliment, {owner} is convinced they have a secret admirer. (They do: {admirer}.)")
scene("j20_admirer", allow_absent=True, conditions=[c_present("owner")],
      effects=starts("secret_admirer", {"admirer": "admirer", "beloved": "owner"}, "wonder",
                     [say("owner", "j20_wonder"), emote("owner", "love"), mood("owner", 10), log("log.j20", 4, "romance", who=["owner", "admirer"])]))
iv("J20", "j_secret_admirer", title="Sign both notes 'your secret admirer'", desc="{owner} got a kind note and an anonymous compliment. Tie them together.",
   log="The ghost signed {owner}'s kind note and compliment 'your secret admirer'.", obj="ws", tab="papers", cat="J", icon="star", hidden=True, combo=["I01", "I11"],
   vars=[var("admirer", "admirer_of", of="owner", lim=10, role=True)],
   conds=[c_iv("I01", same="owner"), c_iv("I11", same="owner")],
   state=[oset("ws.{owner}.admirer_note", "%admirer")], react=[chain("j20_admirer", delay=3)], reuse=J_REUSE, imp=4, arc="secret_admirer")
