# Interventions — I. Social life & gossip. The ghost never touches anyone's mind:
# only notes, cards, photos, letters and what people happen to read.
from iv_common import *  # noqa: F401,F403

NOTE = dict(obj="noticeboard", cat="I")
TABLE = dict(obj="kitchen_table", cat="I")
DESK = dict(obj="ws", tab="papers", cat="I")

# --- I01 reveal the kind note they wrote about someone ---------------------------------------------
L("kindnote_read", ["'{best} is the only reason I come to work.' — {owner}'s note?", "A note on {owner}'s desk: '{best} always makes my day better.'"])
L("kindnote_me", ["...{owner} wrote that about ME?", "Oh. {owner} thinks that about me? I... wow."])
S_("log.kindnote_me", "{best} found a note {owner} had written: '{best} is the only reason I come to work.' {best} was deeply touched.")
S_("log.kindnote_other", "{actor} read a sweet note {owner} wrote about {best}. Now the office is wondering.")
scene("iv_kindnote", noise=0.4, allow_absent=True, conditions=[c_present("actor"), c_not(c_same("actor", "owner"))],
      outcomes=[out("me", [say("actor", "kindnote_me"), emote("actor", "love"), rel("actor", "owner", "friendship", 14), rel("actor", "owner", "trust", 8),
                           rel("actor", "owner", "romance", 8, when=[c_rel("actor", "owner", "romance", gt=10)]), mood("actor", 12), log("log.kindnote_me", 3, "friendship")],
                    score=[s_const(5)], when=[c_same("actor", "best")]),
                out("other", [say("actor", "kindnote_read"), rumor("crush", a="owner", b="best", juicy=0.5, truth=False, knowers=["actor"], c=0.5),
                              log("log.kindnote_other", 2, "rumor")], score=[s_const(1)])])
iv("I01", "kind_note", title="Leave the kind note they wrote in plain sight", desc="They wrote something lovely about someone. They never meant to share it.",
   log="The ghost left {owner}'s private note about {best} on top of their desk.", **DESK, icon="star",
   vars=[var("best", "best_of", of="owner", lim=20, avail=False, role=True, why="why.no_friend")],
   state=[oset("ws.{owner}.kind_note", "%best")], react=[near_trap("iv_kindnote", "desk_{owner}", not_="owner", key="kindnote_{owner}", r=2.2, days=1)])

# --- I02 change the name on a gift card --------------------------------------------------------------------
L("giftcard_find", ["A present? With MY name on it? From {giver}?", "'For {target}, with love — {giver}'. For me?!"])
L("giftcard_thank", ["{target}! I mean — {giver}! Thank you for the present!", "I got your gift! You shouldn't have!"])
L("giftcard_what", ["...That gift was for {intended}.", "Oh no. That was meant for {intended}!"])
L("giftcard_intended", ["So my present went to someone else. Nice.", "I didn't get anything. Cool. Cool cool cool."])
S_("log.giftcard", "{giver}'s gift for {intended} had {target}'s name on the card. {target} said thank you. {intended} got nothing.")
scene("iv_giftcard", allow_absent=True, conditions=[c_present("target"), c_present("giver")],
      effects=[expr("target", "happy", 5), say("target", "giftcard_find"), mood("target", 10), visit("target", "giver", "iv_giftcard_scene", prio=58, ttl=60, delay=2)])
scene("iv_giftcard_scene", noise=0.6, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "giftcard_thank", to="target"), say("target", "giftcard_what", to="actor", delay=1.6), emote("actor", "sweat", delay=1.6),
               mood("actor", -8), rel("actor", "target", "romance", 6, when=[c_rel("actor", "target", "romance", gt=15)]),
               say("intended", "giftcard_intended", delay=4, when=[c_present("intended")]), rel("intended", "target", "resentment", 6), mood("intended", -6),
               log("log.giftcard", 3, "misunderstanding", who=["giver", "target", "intended"])])
iv("I02", "gift_card", title="Change the name on a gift card", desc="Someone's present for a friend. Pick whose name goes on the card instead.",
   log="The ghost rewrote the name on a gift card in the kitchen to {target}.", **TABLE, needs="person", icon="star", pick=[c_present("self")],
   state=[pick_role("giver", "best_of", of="target", lim=-99), pick_role("intended", "best_of", of="giver", lim=-99), oset("kitchen.gift", "%target")],
   react=[chain("iv_giftcard", delay=4)])

# --- I03 pin who started a false rumour --------------------------------------------------------------------
L("source_read", ["'The rumour about {subject}? Started by {origin}.' Pinned right there.", "So {origin} started that story about {subject}..."])
S_("log.source", "A note on the cork board named {origin} as the source of the rumour about {subject}. {subject} read it.")
scene("iv_source", allow_absent=True, conditions=[c_present("subject"), c_present("origin")],
      effects=[expr("subject", "angry", 5), say("subject", "source_read"), rel("subject", "origin", "resentment", 15), rel("subject", "origin", "trust", -10),
               log("log.source", 3, "rumor", who=["subject", "origin"]), visit("subject", "origin", "rumor_source_confront", prio=62, ttl=60, delay=2)])
iv("I03", "rumor_source", title="Pin up who started a false rumour", desc="Someone made something up. Name them on the cork board.",
   log="The ghost pinned a note naming {origin} as the source of the rumour about {subject}.", **NOTE, icon="pin",
   vars=[var("fact", "false_rumor", why="why.no_false_rumor")],
   state=[pin("source", about="$origin"), {"e": "call", "fn": "vars_to_roles", "keys": ["origin", "subject"]}, oset("notice.source_of", "$origin")],
   react=[chain("iv_source", delay=4)],
   test={"setup": [{"e": "rumor", "kind": "slacker", "a": "@mert", "b": "@zeynep", "truth": False, "origin": "@zeynep", "juicy": 0.5, "knowers": ["@zeynep", "@ece"]}]})
S_("why.no_false_rumor", "No false rumours are going around right now.")

# --- I04 swap two people's sticky notes --------------------------------------------------------------------
L("stickyswap_read", ["'Lunch at one? My treat.' — from {owner}? To me?", "A note from {owner}: 'Lunch at 1?' ...Sure!"])
L("stickyswap_meet", ["You wanted lunch? ...With me?", "Here I am, lunch buddy."])
L("stickyswap_ok", ["Ha. Why not? Let's go.", "Wrong note, right person, maybe."])
S_("log.stickyswap", "{owner}'s 'lunch at 1?' sticky note — meant for {friend} — landed on {target}'s desk. They ended up having lunch together.")
scene("iv_stickyswap", allow_absent=True, conditions=[c_present("target"), c_present("owner")],
      effects=[say("target", "stickyswap_read"), visit("target", "owner", "iv_stickyswap_meet", prio=56, ttl=60, delay=2)])
scene("iv_stickyswap_meet", noise=0.6, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "stickyswap_meet", to="target"), say("target", "stickyswap_ok", to="actor", delay=1.6),
               call("lunch_sync", who="actor", target="target"), rel("actor", "target", "friendship", 6, both=True),
               rel("friend", "owner", "friendship", -3), log("log.stickyswap", 2, "friendship")])
iv("I04", "swap_notes", title="Swap their sticky note to someone else's desk", desc="'Lunch at 1? My treat.' Pick who finds it.",
   log="The ghost moved {owner}'s sticky note to {target}'s desk.", **DESK, needs="person", icon="pin", pick=[c_present("self")],
   conds=[r_present(), r_time(before="12:30", key="after_lunch")], vars=[var("friend", "best_of", of="owner", lim=-99, role=True, avail=False)],
   state=[oset("ws.{owner}.note_to", "%target")], react=[chain("iv_stickyswap", delay=3)])

# --- I05 deliver their apology letter to the wrong person ----------------------------------------------------
L("apology_wrong_read", ["'I'm so sorry for what I said'... from {owner}? What did {owner} say?", "An apology letter from {owner}? To me? For what?"])
L("apology_wrong_ask", ["{target}, I got your apology. Did you... say something about me?", "Why are you apologising to me? What happened?"])
L("apology_wrong_explain", ["That letter wasn't for you! It was for {foe}!", "Oh no. That was meant for {foe}."])
S_("log.apology_wrong", "{owner}'s apology letter to {foe} landed on {target}'s desk instead. {foe} is still waiting for it.")
scene("iv_apology_wrong", allow_absent=True, conditions=[c_present("target")],
      effects=[emote("target", "question"), say("target", "apology_wrong_read"), rel("target", "owner", "suspicion", 8),
               visit("target", "owner", "iv_apology_wrong_scene", prio=56, ttl=60, delay=3, when=[c_present("owner")])])
scene("iv_apology_wrong_scene", noise=0.6, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "apology_wrong_ask", to="target"), say("target", "apology_wrong_explain", to="actor", delay=1.6),
               emote("target", "sweat", delay=1.6), rumor("argument", a="target", b="foe", juicy=0.4, knowers=["actor"]), learn("actor", "$rumor"),
               rel("foe", "target", "resentment", 5), log("log.apology_wrong", 3, "misunderstanding", who=["owner", "foe"])])
iv("I05", "apology_wrong", title="Deliver their apology letter to the wrong person", desc="They wrote an apology to someone they fell out with. Pick who gets it instead.",
   log="The ghost delivered {owner}'s apology letter to {target}.", **DESK, needs="person", icon="email", pick=[c_present("self")],
   vars=[var("foe", "foe_of", of="owner", role=True, why="why.no_foe")],
   state=[oset("ws.{owner}.apology_to", "%target"), mem("owner", "foe", "apologised", 0.3, 0.6)], react=[chain("iv_apology_wrong", delay=3)])

# --- I06 leave the secret birthday collection in plain sight ----------------------------------------------------
L("collection_see", ["'Collection for {bdayp}'s birthday'... for ME?", "A secret envelope collecting for my birthday? Aww."])
L("collection_sad", ["Who left the envelope OUT?! It was a secret!", "There goes the surprise."])
S_("log.collection", "The secret envelope collecting money for {bdayp}'s upcoming birthday was left in plain sight. {bdayp} found it.")
scene("iv_collection", allow_absent=True, conditions=[c_present("bdayp")],
      effects=[expr("bdayp", "happy", 5), say("bdayp", "collection_see"), emote("bdayp", "love"), mood("bdayp", 10),
               each([say("self", "collection_sad", p=0.5, delay=2), mood("self", -4)], exclude=["bdayp"], where=[c_trait("self", "sociability", gt=0.6)]),
               log("log.collection", 3, "party", who=["bdayp"])])
iv("I06", "birthday_collection", title="Leave the secret birthday collection in plain sight", desc="The envelope everyone's been secretly chipping into.",
   log="The ghost left the secret birthday collection envelope for {bdayp} on the kitchen table.", **TABLE, icon="email",
   vars=[var("bdayp", "upcoming_birthday", role=True, why="why.no_upcoming")],
   state=[oset("kitchen.collection", "%bdayp")], react=[trap("iv_collection", place="#lunch", who="bdayp", key="collection", days=1),
                                                       trap("iv_collection", place="#coffee", who="bdayp", key="collection2", days=1)])
S_("why.no_upcoming", "Nobody's birthday is coming up soon.")

# --- I07 expose the message where they stood up for someone --------------------------------------------------------
L("defend_read", ["{owner} wrote to Ahmet: '{best} deserves more credit than anyone here.'", "{owner} defended me? To AHMET? When I wasn't even there?"])
L("defend_thank", ["{target}... I saw what you wrote about me. Thank you.", "You stood up for me. I didn't know. Thank you."])
L("defend_shy", ["Oh — you saw that? It's just the truth.", "Don't make it a big deal. You deserve it."])
S_("log.defend", "{best} discovered that {owner} had quietly stood up for them in an email to Ahmet. {best} is moved.")
scene("iv_defend", allow_absent=True, conditions=[c_present("best")],
      effects=[expr("best", "happy", 5), say("best", "defend_read"), rel("best", "owner", "trust", 15), rel("best", "owner", "friendship", 10), mood("best", 10),
               log("log.defend", 3, "friendship", who=["best", "owner"]), visit("best", "owner", "iv_defend_scene", prio=56, ttl=60, delay=3, when=[c_present("owner")])])
scene("iv_defend_scene", conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "defend_thank", to="target"), say("target", "defend_shy", to="actor", delay=1.6),
               rel("target", "actor", "friendship", 6), mem("actor", "target", "defended_me", 0.7, 0.9, "mem.defended_me", 3)])
iv("I07", "defense_message", title="Expose the message where they defended someone", desc="Behind closed doors, they stood up for a colleague. Let the colleague find out.",
   log="The ghost forwarded {owner}'s message defending {best} — to {best}.", **DESK, icon="email",
   vars=[var("best", "best_of", of="owner", lim=20, avail=False, role=True, why="why.no_friend")],
   state=[oset("ws.{owner}.defended", "%best")], react=[chain("iv_defend", delay=3)])

# --- I08 send their lunch invitation to the wrong person -------------------------------------------------------------
L("lunchinv_read", ["An invitation to lunch — from {owner}? For me?", "'Lunch together today?' — {owner}. ...Okay!"])
L("lunchinv_awk", ["So. Um. Lunch. Great weather.", "...", "Nice sandwich."])
L("lunchinv_click", ["Okay, why have we never done this before?!", "You're actually really funny!"])
S_("log.lunchinv_click", "{owner}'s lunch invitation went to {target} by mistake. They had lunch anyway — and really clicked.")
S_("log.lunchinv_awk", "{owner}'s lunch invitation went to {target} by mistake. A long, silent lunch followed.")
scene("iv_lunchinv", noise=0.8, allow_absent=True, conditions=[c_present("target"), c_present("owner")],
      effects=[say("target", "lunchinv_read"), call("lunch_sync", who="owner", target="target"), hold(["owner"], 1)],
      outcomes=[out("click", [say("target", "lunchinv_click", delay=3), rel("owner", "target", "friendship", 12, both=True), log("log.lunchinv_click", 3, "friendship")],
                    score=[s_trait("target", "sociability", 0.6), s_trait("owner", "humor", 0.5), s_aff("target", "owner", 0.02), s_const(0.3)]),
                out("awkward", [say("owner", "lunchinv_awk", delay=3), log("log.lunchinv_awk", 2, "misunderstanding")],
                    score=[s_rel("target", "owner", "rivalry", 0.03), s_trait("target", "sociability", -0.5), s_const(0.2)])])
iv("I08", "lunch_invite_wrong", title="Send their lunch invitation to the wrong person", desc="Pick who gets it. Lunch for two, whether they like it or not.",
   log="The ghost redirected {owner}'s lunch invitation to {target}.", obj="ws", tab="mail", cat="I", needs="person", icon="email", pick=[c_present("self")],
   conds=[r_present(), r_time(before="12:30", key="after_lunch")], state=[oset("ws.{owner}.lunch_inv", "%target")], react=[chain("iv_lunchinv", delay=3)])

# --- I09 deliver their romantic note to the wrong person ----------------------------------------------------------------
L("lovenote_read", ["'Every time you walk by, I forget my password.' — {owner}? To ME?", "A love note. From {owner}. On my desk. Oh my."])
L("lovenote_jealous", ["{owner} sent YOU a love note?!", "Wait. {owner} likes {target}?"])
S_("log.lovenote", "{owner}'s love note for {crush} landed on {target}'s desk. {target} thinks {owner} is in love with them.")
scene("iv_lovenote", allow_absent=True, conditions=[c_present("target")],
      effects=[expr("target", "surprised", 5), emote("target", "love"), say("target", "lovenote_read"), rel("target", "owner", "romance", 12),
               rumor("crush", a="owner", b="target", juicy=0.8, truth=False, knowers=["target"]), witness([learn("self", "$rumor")], near="target", r=4.5),
               say("crush", "lovenote_jealous", delay=3, when=[c_near("crush", "target", 6)]), rel("crush", "target", "rivalry", 8, when=[c_rel("crush", "owner", "romance", gt=20)]),
               log("log.lovenote", 4, "romance", who=["owner", "target", "crush"]), setv("what", "lovenote"),
               visit("target", "owner", "ivm_misattrib", prio=60, ttl=60, delay=4, when=[c_present("owner")])])
what("lovenote", "the love note")
iv("I09", "love_note_wrong", title="Deliver their love note to the wrong person", desc="It was for their crush. Pick who reads it instead.",
   log="The ghost delivered {owner}'s love note to {target} instead of {crush}.", **DESK, needs="person", icon="star", pick=[c_present("self")],
   vars=[var("crush", "crush_of", of="owner", role=True, why="why.no_crush")],
   state=[oset("ws.{owner}.love_note", "%target")], react=[chain("iv_lovenote", delay=3)])

# --- I10 leave proof of a secret alliance lying around ---------------------------------------------------------------------
L("pact_read", ["'Alliance agreement: {a} and {b} will back each other up.' Signed?!", "{a} and {b} have a WRITTEN pact? Wow."])
S_("log.pact", "A signed 'alliance agreement' between {a} and {b} was found in the archive. The whole office knows now.")
scene("iv_pact", allow_absent=True, conditions=[c_present("actor")],
      effects=[expr("actor", "surprised", 4), say("actor", "pact_read"), rumor("alliance", a="$a", b="$b", juicy=0.8, knowers=["actor"]),
               each([learn("self", "$rumor", frm="actor", c=0.8)], exclude=["$a", "$b"], stagger=0.4, where=[c_chance(0.6)]),
               each([rel("self", "$a", "trust", -6), rel("self", "$b", "trust", -6)], exclude=["$a", "$b"], where=[c_knows("self", "$rumor")]),
               stress("$a", 10), stress("$b", 10), log("log.pact", 4, "scheme", who=["$a", "$b"])])
iv("I10", "alliance_proof", title="Leave proof of a secret alliance in the archive", desc="Two people have a secret pact. It's in writing. Not for long.",
   log="The ghost left a signed alliance agreement between {a} and {b} in the archive.", obj="file_cabinet", cat="I", icon="papers",
   vars=[var("a", "alliance_pair", why="why.no_alliance")], state=[oset("hr.pact", "$a")], react=[trap("iv_pact", place="#archive", key="pact", days=1)],
   test={"setup": [{"e": "bond", "a": "@deniz", "b": "@zeynep", "kind": "alliance", "v": True}]})
S_("why.no_alliance", "Nobody has a secret alliance right now.")

# --- I11 pin an anonymous compliment ----------------------------------------------------------------------------------------
L("compliment_read", ["'{target} is the kindest person in this office.' Anonymous!", "Someone pinned a compliment about {target}. Aww."])
L("compliment_self", ["Someone wrote that about ME? Who?!", "An anonymous compliment... for me. I need to know who wrote it."])
S_("log.compliment", "An anonymous note praising {target} appeared on the cork board. {target} is glowing — and investigating.")
scene("iv_compliment", allow_absent=True, conditions=[c_present("target")],
      vars=[var("guess", "best_of", of="target", lim=-50, optional=True)],
      effects=[expr("target", "happy", 6), say("target", "compliment_self"), mood("target", 14), morale("target", 4),
               each([rel("self", "target", "respect", 4)], exclude=["target"], where=[c_chance(0.6)]), log("log.compliment", 3, "friendship", who=["target"]),
               setv("what", "compliment"), visit("target", "$guess", "ivm_misattrib", prio=54, ttl=60, delay=4, when=[c_filled("$guess"), c_present("$guess")])])
what("compliment", "the note on the cork board")
iv("I11", "anon_compliment", title="Pin an anonymous compliment about someone", desc="Kind words on the cork board. They'll want to know who wrote it.",
   log="The ghost pinned an anonymous compliment about {target}.", **NOTE, needs="person", icon="star", pick=[c_present("self")],
   state=[pin("compliment", about="target")], react=[chain("iv_compliment", delay=4)])

# --- I12 pin an anonymous complaint ------------------------------------------------------------------------------------------
L("complaint_read", ["'Dear {target}: please stop humming. Signed, everyone.' ...Wow.", "An anonymous note on the board. About me. About my HUMMING."])
L("complaint_suspect", ["This is {hater}. I know it is.", "{hater}. Has to be."])
S_("log.complaint", "An anonymous complaint about {target}'s humming went up on the cork board. {target} has a suspect.")
scene("iv_complaint", allow_absent=True, conditions=[c_present("target")],
      vars=[var("hater", "hater_of", of="target", lim=60, optional=True)],
      effects=[expr("target", "sad", 5), say("target", "complaint_read"), mood("target", -12), log("log.complaint", 3, "conflict", who=["target"])],
      outcomes=[out("accuse", [say("target", "complaint_suspect", delay=1.6), rel("target", "$hater", "suspicion", 20), rel("target", "$hater", "resentment", 10),
                               visit("target", "$hater", "ivm_accuse", prio=60, ttl=50, delay=3, when=[c_present("$hater")])],
                    score=[s_trait("target", "temper", 1.0), s_const(0.3)], when=[c_filled("$hater")]),
                out("sulk", [emote("target", "cloud"), morale("target", -3)], score=[s_trait("target", "empathy", 0.6), s_const(0.3)])])
iv("I12", "anon_complaint", title="Pin an anonymous complaint about someone", desc="'Please stop humming. Signed, everyone.' They'll look for a culprit.",
   log="The ghost pinned an anonymous complaint about {target}.", **NOTE, needs="person", icon="pin", pick=[c_present("self")],
   state=[pin("complaint", about="target"), oset("notice.complaint_about", "%target")], react=[chain("iv_complaint", delay=4)])

# --- I13 rig the secret-gift draw so rivals pick each other ---------------------------------------------------------------------
L("santa_give", ["So... I drew your name. Here. It's a gift.", "Secret gift time. I got... you."])
L("santa_nice", ["...This is actually really thoughtful. Thank you.", "You remembered I like this? Huh."])
L("santa_mean", ["A book called 'How To Be Less Annoying'? Really?", "Is this a joke? Because it's not funny."])
S_("log.santa_nice", "The secret gift draw paired rivals {actor} and {target}. {actor}'s gift was genuinely thoughtful. A thaw!")
S_("log.santa_mean", "The secret gift draw paired rivals {actor} and {target}. {actor}'s gift was... a statement. War.")
scene("iv_santa", noise=0.8, allow_absent=True, conditions=[c_present("$a"), c_present("$b")],
      effects=[visit("$a", "$b", "iv_santa_scene", prio=58, ttl=60)])
scene("iv_santa_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "santa_give", to="target")],
      outcomes=[out("nice", [say("target", "santa_nice", to="actor", delay=1.6), rel("actor", "target", "rivalry", -12, both=True), rel("actor", "target", "friendship", 10, both=True),
                             rel("target", "actor", "resentment", -10), log("log.santa_nice", 3, "friendship")], score=[s_trait("actor", "empathy", 1.0), s_trait("actor", "forgiveness", 0.6)]),
                out("mean", [say("target", "santa_mean", to="actor", delay=1.6), expr("target", "angry", 5, delay=1.6), rel("target", "actor", "resentment", 12),
                             rel("actor", "target", "rivalry", 8, both=True), log("log.santa_mean", 3, "conflict")], score=[s_trait("actor", "cunning", 0.8), s_rel("actor", "target", "rivalry", 0.02)])])
iv("I13", "rig_gift_draw", title="Rig the secret gift draw", desc="The two people who can't stand each other will have to give each other a present.",
   log="The ghost rigged the secret gift draw: {a} drew {b}.", **TABLE, icon="star",
   vars=[var("a", "rival_pair", lim=25, why="why.no_rivals")], state=[oset("kitchen.gift_draw", "$a")], react=[chain("iv_santa", delay=20)])
S_("why.no_rivals", "Nobody here is at odds right now.")

# --- I14 leave someone's private notebook on the sofa --------------------------------------------------------------------------
L("notebook_find", ["Whose notebook is this? ...{target}'s.", "{target} left their notebook on the sofa. Open."])
L("notebook_close", ["Nope. Not reading it. I'll give it back.", "This is private. I'm not looking."])
L("notebook_return", ["You left this on the sofa. I didn't read it.", "Your notebook. Don't worry, I didn't look."])
L("notebook_thanks", ["Thank you. Seriously.", "You're a good person."])
S_("log.notebook_keep", "{actor} found {target}'s private notebook on the sofa — and gave it back unread.")
S_("log.notebook_read", "{actor} found {target}'s private notebook on the sofa. And read it.")
scene("iv_notebook", noise=0.8, allow_absent=True, conditions=[c_present("actor"), c_not(c_same("actor", "target")), {"c": "fact_exists", "fact": "$fact"}],
      effects=[say("actor", "notebook_find")],
      outcomes=[out("return", [say("actor", "notebook_close", delay=1.4), visit("actor", "target", "iv_notebook_back", prio=54, ttl=60, delay=2), log("log.notebook_keep", 2, "friendship")],
                    score=[s_rel("actor", "target", "trust", 0.03), s_trait("actor", "honesty", 1.0), s_trait("actor", "gossip", -0.8)], when=[c_present("target")]),
                out("read", [learn("actor", "$fact", c=1.0), reveal("$fact"), log("log.notebook_read", 3, "secret"), chain("ivm_secret", delay=1.5, roles={"actor": "actor"})],
                    score=[s_trait("actor", "curiosity", 1.0), s_trait("actor", "gossip", 0.8)])])
scene("iv_notebook_back", conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4), say("actor", "notebook_return", to="target"), say("target", "notebook_thanks", to="actor", delay=1.6),
               rel("target", "actor", "trust", 12), mem("target", "actor", "kept_secret", 0.5, 0.8, "mem.returned_notebook", 2)])
S_("mem.returned_notebook", "{actor} returned my notebook without reading it.")
iv("I14", "lost_notebook", title="Leave someone's private notebook on the sofa", desc="Pick whose. The next person to sit there will find it.",
   log="The ghost left {target}'s private notebook open on the sofa.", obj="sofa", cat="I", needs="person", icon="papers", pick=[],
   vars=private_vars("target"), state=private_info("target") + [oset("plant.notebook", "%target")],
   react=[trap("iv_notebook", place="#rest", key="notebook", days=1, roles={"target": "target"})])

# --- I15 seat two rivals together at lunch -------------------------------------------------------------------------------------------
L("lunchseat_a", ["...Of course. The name cards put me next to YOU.", "Great. Lunch with you."])
L("lunchseat_fight", ["Can you chew more quietly?", "You're in my elbow space."])
L("lunchseat_peace", ["...Okay. Look. Maybe we got off on the wrong foot.", "Truce over sandwiches?"])
S_("log.lunchseat_fight", "Lunch name cards seated {a} beside {b}. It ended with raised voices.")
S_("log.lunchseat_peace", "Lunch name cards seated {a} beside {b}. Somehow, over sandwiches, they made peace.")
scene("iv_lunchseat", noise=0.8, allow_absent=True, conditions=[c_present("$a"), c_present("$b")],
      effects=[call("lunch_sync", who="$a", target="$b"), say("$a", "lunchseat_a", to="$b", delay=1)],
      outcomes=[out("fight", [say("$b", "lunchseat_fight", to="$a", delay=2.6), sfx("argue", delay=2.6), stat("arguments"), rel("$a", "$b", "friendship", -6, both=True),
                              log("log.lunchseat_fight", 3, "conflict", who=["$a", "$b"])], score=[s_trait("$b", "temper", 1.0), s_rel("$b", "$a", "rivalry", 0.02)]),
                out("peace", [say("$b", "lunchseat_peace", to="$a", delay=2.6), rel("$a", "$b", "rivalry", -10, both=True), rel("$a", "$b", "resentment", -10, both=True),
                              bond("$a", "$b", "feud", False), stat("reconciliations"), log("log.lunchseat_peace", 3, "friendship", who=["$a", "$b"])],
                    score=[s_trait("$b", "empathy", 1.0), s_trait("$a", "forgiveness", 0.8)])])
iv("I15", "lunch_seating", title="Put out lunch name cards: rivals side by side", desc="The two people who can't stand each other. One table.",
   log="The ghost put lunch name cards on the kitchen table: {a} next to {b}.", **TABLE, icon="people",
   vars=[var("a", "rival_pair", lim=25, why="why.no_rivals")], conds=[r_time(before="12:30", key="after_lunch")],
   state=[oset("kitchen.seating", "$a")], react=[on_trap("lunch_start", "iv_lunchseat", key="lunchseat")])

# --- I16 pin a doctored "couple" photo -------------------------------------------------------------------------------------------------
L("couplephoto_see", ["Is that {target} and {partner}... holding hands?!", "A photo of {target} and {partner}! Together!"])
L("couplephoto_deny", ["That's FAKE! That's photoshopped!", "We have NEVER held hands!"])
L("couplephoto_secret", ["...It's fake. Obviously. ...It's a nice photo, though.", "Ha. Fake. Right. Totally fake."])
S_("log.couplephoto", "A doctored photo of {target} and {partner} 'holding hands' went up on the cork board.")
scene("iv_couplephoto", allow_absent=True, conditions=[c_present("target")],
      effects=[rumor("couple", a="target", b="partner", juicy=0.85, truth=False, knowers=[], key="fact"),
               each([learn("self", "$fact", c=0.6), say("self", "couplephoto_see", p=0.3, delay=1.0)], exclude=["target", "partner"], stagger=0.5, where=[c_chance(0.7)]),
               say("target", "couplephoto_deny", delay=3), expr("target", "surprised", 5, delay=3), stress("target", 8),
               say("partner", "couplephoto_secret", delay=4.5, when=[c_present("partner"), c_rel("partner", "target", "romance", gt=20)]),
               rel("partner", "target", "romance", 8, when=[c_rel("partner", "target", "romance", gt=10)]),
               each([rel("self", "partner", "rivalry", 10)], exclude=["target", "partner"], where=[c_rel("self", "target", "romance", gt=30)]),
               log("log.couplephoto", 4, "romance", who=["target", "partner"])])
iv("I16", "couple_photo", title="Pin a doctored 'couple' photo", desc="Pick one half of the 'couple'. The other half is whoever suits the story best.",
   log="The ghost pinned a doctored photo of {target} and {partner} together.", **NOTE, needs="person", icon="star", pick=[c_present("self")],
   state=[pick_role("partner", "crush_of", of="target"), pick_role("partner", "best_of", keep=True, of="target", lim=-99), pin("couple", about="target"),
          oset("notice.couple", "%target"), oset("notice.couple_with", "%partner")],
   react=[chain("iv_couplephoto", delay=4)])

# --- I17 post an after-work invite that leaves someone out ------------------------------------------------------------------------------
L("excluded_read", ["'Drinks after work! Everyone welcome!' ...Except me, apparently.", "Every name on the list but mine."])
L("excluded_ask", ["So... your drinks invite. Did you leave me off on purpose?", "Why wasn't I on the list?"])
L("excluded_sorry", ["What? No! You're invited! Of course you're invited!", "That's not my list! Come! Please come!"])
L("excluded_cold", ["Well... it's a small group.", "It's not a big deal."])
S_("log.excluded_fix", "{target} was left off an after-work drinks invite 'from' {organizer}. {organizer} insisted they were welcome.")
S_("log.excluded_cold", "{target} was left off an after-work drinks invite 'from' {organizer}. {organizer} didn't exactly fix it.")
scene("iv_excluded", allow_absent=True, conditions=[c_present("target"), c_present("organizer")],
      effects=[expr("target", "sad", 5), say("target", "excluded_read"), mood("target", -10), rel("target", "organizer", "resentment", 10),
               visit("target", "organizer", "iv_excluded_scene", prio=56, ttl=60, delay=3, when=[c_trait("target", "temper", gt=0.25)])])
scene("iv_excluded_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "excluded_ask", to="target")],
      outcomes=[out("sorry", [say("target", "excluded_sorry", to="actor", delay=1.6), rel("actor", "target", "resentment", -10), rel("actor", "target", "friendship", 5),
                              log("log.excluded_fix", 2, "friendship")], score=[s_trait("target", "empathy", 1.0), s_aff("target", "actor", 0.02)]),
                out("cold", [say("target", "excluded_cold", to="actor", delay=1.6), rel("actor", "target", "friendship", -8), log("log.excluded_cold", 3, "conflict")],
                    score=[s_aff("target", "actor", -0.02), s_const(0.3)])])
iv("I17", "exclusion_invite", title="Post a drinks invite that leaves someone out", desc="'Everyone welcome!' Everyone except one name. Pick whose.",
   log="The ghost pinned an after-work drinks invite that leaves out {target}.", **NOTE, needs="person", icon="people", pick=[c_present("self")],
   state=[pick_role("organizer", "hater_of", of="target", lim=99), pin("drinks", about="target")], react=[chain("iv_excluded", delay=4)])

# --- I18 a tip jar for Burak -------------------------------------------------------------------------------------------------------------
L("tipjar_see", ["'Thank you Burak for fixing everything.' A tip jar! I'm in.", "A tip jar for Burak? He deserves it."])
L("tipjar_burak", ["...Is this for me? Who did this?", "A tip jar. For me. Huh. Thanks, everyone."])
S_("log.tipjar", "A 'Thank you Burak for fixing everything' tip jar appeared in the kitchen. People are chipping in. Burak is speechless.")
scene("iv_tipjar", allow_absent=True,
      effects=[each([say("self", "tipjar_see", p=0.4, delay=1.0), rel("self", "@burak", "respect", 5), rel("self", "@burak", "friendship", 3)], exclude=["@burak"],
                    where=[c_chance(0.7)], stagger=0.6),
               say("@burak", "tipjar_burak", delay=4, when=[c_present("@burak")]), emote("@burak", "love", delay=4), morale("@burak", 10), mood("@burak", 12),
               log("log.tipjar", 3, "friendship")])
iv("I18", "tip_jar", title="Put out a 'Thank you Burak' tip jar", desc="He fixes everything. Nobody ever says thanks.",
   log="The ghost put a 'Thank you Burak for fixing everything' tip jar in the kitchen.", **TABLE, icon="star",
   conds=[r_present("@burak")], state=[oset("kitchen.tipjar", True)], react=[chain("iv_tipjar", delay=4)], reuse={"cool": 900, "day": 1, "per": "global"})

# --- I19 stuff the suggestion box ---------------------------------------------------------------------------------------------------------
L("sbox_boss_promote", ["Six notes saying 'Promote {target}'. Interesting.", "The staff seem to love {target}. Noted."])
L("sbox_boss_fire", ["Six notes saying 'Fire {target}'?! What's going on?", "Hm. Someone REALLY doesn't like {target}."])
L("sbox_target_hear", ["People wrote 'fire me' in the suggestion box?!", "Who would write that about me?!"])
S_("log.sbox_promote", "The suggestion box was stuffed with notes: 'Promote {target}'. Ahmet read them all.")
S_("log.sbox_fire", "The suggestion box was stuffed with notes: 'Fire {target}'. Ahmet read them — and so did {target}.")
scene("iv_sbox", noise=0.4, allow_absent=True, conditions=[c_present("actor"), c_present("target")],
      outcomes=[out("promote", [say("actor", "sbox_boss_promote"), favor("target", 8), rel("actor", "target", "respect", 6), log("log.sbox_promote", 3, "promotion", who=["target"])],
                    score=[s_const(5)], when=[c_var("choice", eq="promote")]),
                out("fire", [say("actor", "sbox_boss_fire"), favor("target", -6), rel("actor", "target", "trust", -6), say("target", "sbox_target_hear", delay=3),
                             stress("target", 15), each([rel("target", "self", "suspicion", 8)], exclude=["target", "actor"]),
                             log("log.sbox_fire", 3, "promotion", who=["target"])], score=[s_const(5)], when=[c_var("choice", eq="fire")])])
iv("I19", "suggestion_box", title="Stuff the suggestion box", desc="Six identical notes about one person. Ahmet reads the box at his desk.",
   log="The ghost stuffed the suggestion box with notes about {target}.", **NOTE, needs="person", icon="papers", pick=[c_is("self", "ahmet", neg=True)],
   choices=[choice("promote", "'Promote them!'"), choice("fire", "'Fire them!'")], conds=[r_present("@ahmet")],
   state=[oset("notice.sbox", "%target")], react=[trap("iv_sbox", place="desk_ahmet", who="@ahmet", key="sbox", roles={"target": "target"})])

# --- I20 leave an anonymous "I know what you did" note -------------------------------------------------------------------------------------
L("iknow_read", ["'I know what you did.' ...What? WHO knows WHAT?", "'I know what you did.' No signature. My hands are shaking."])
L("iknow_confess", ["I have to tell someone. Okay. {friend}... I need to tell you something.", "{friend}, can we talk? Somewhere private?"])
L("iknow_paranoid", ["Everybody's looking at me. They all know. Don't they?", "Was it you? Was it YOU?"])
S_("log.iknow_confess", "An anonymous 'I know what you did' note rattled {target} into confessing their secret to {friend}.")
S_("log.iknow_paranoid", "An anonymous 'I know what you did' note has {target} suspecting everyone.")
scene("iv_iknow", noise=0.8, allow_absent=True, conditions=[c_present("target")],
      vars=[var("friend", "best_of", of="target", lim=0, optional=True), var("secretf", "has_secret", of="target", optional=True)],
      effects=[expr("target", "surprised", 6), emote("target", "sweat"), say("target", "iknow_read"), stress("target", 18)],
      outcomes=[out("confess", [say("target", "iknow_confess", delay=2), learn("$friend", "$secretf", frm="target", c=1.0), rel("$friend", "target", "trust", 6),
                                log("log.iknow_confess", 4, "secret", who=["target", "$friend"])],
                    score=[s_trait("target", "honesty", 1.0), s_aff("target", "$friend", 0.02)], when=[c_filled("$secretf"), c_filled("$friend"), c_present("$friend")]),
                out("paranoid", [say("target", "iknow_paranoid", delay=2), each([rel("target", "self", "suspicion", 10)], exclude=["target"]), log("log.iknow_paranoid", 3, "drama", who=["target"])],
                    score=[s_const(0.6), s_trait("target", "temper", 0.4)])])
iv("I20", "i_know_note", title="Leave an anonymous 'I know what you did' note", desc="It means nothing. Unless they actually did something.",
   log="The ghost left an anonymous 'I know what you did' note for {target}.", obj="coat_rack", cat="I", needs="person", icon="email", pick=[c_present("self")],
   state=[oset("coats.note", "%target")], react=[chain("iv_iknow", delay=4)])
