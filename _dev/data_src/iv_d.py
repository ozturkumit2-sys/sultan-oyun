# Interventions — D. Documents & paperwork (desk papers, printer, file cabinets, HR files, supplies)
from iv_common import *  # noqa: F401,F403
from rumors import RUMORS
RUMORS["shortlisted"] = {"on_learn": [{"who": "*", "about": "a", "stat": "rivalry", "d": 6}, {"who": "subject", "mood": 10}], "life": 4}
S_("rumor.shortlisted", "{a} is on the promotion shortlist.")

PAPERS = dict(obj="ws", tab="papers", cat="D")
NOT_BOSS = ["selin", "mert", "zeynep", "burak", "ece", "deniz", "ceren"]

# --- D02 swap the signature page of their contract -----------------------------------
L("sigpage_boss", ["{target}, why is this contract signed by {other}?!", "Your contract has {other}'s signature on the last page. Explain."])
L("sigpage_baffled", ["That's impossible! I signed it myself!", "Someone swapped my pages!"])
L("sigpage_blame", ["...This was {other}. It has to be.", "Ask {other} how their signature got there."])
S_("log.sigpage", "Ahmet bounced {target}'s contract: the signature page was {other}'s. {target} smells sabotage.")
scene("iv_sigpage_check", allow_absent=True, conditions=[c_present("@ahmet"), c_present("owner")],
      effects=[visit("@ahmet", "owner", "iv_sigpage_scene", prio=64, ttl=60)])
scene("iv_sigpage_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "sigpage_boss", to="target"), say("target", "sigpage_baffled", to="actor", delay=1.6),
               rel("actor", "target", "respect", -5), work("target", -8), log("log.sigpage", 3, "work", who=["target", "$other"])],
      outcomes=[out("blame", [say("target", "sigpage_blame", delay=3.2), rel("target", "$other", "suspicion", 22),
                              visit("target", "$other", "ivm_accuse", prio=60, ttl=50, delay=5, when=[c_present("$other")])],
                    score=[s_rel("target", "$other", "rivalry", 0.03), s_trait("target", "temper", 0.6)]),
                out("redo", [say("target", "oldver_redo", delay=3.2), npcval("target", "leave_at", d=15)], score=[s_const(0.5)])])
iv("D02", "swap_sigpage", title="Swap the signature page of their contract", desc="Their contract now ends with someone else's signature.",
   log="The ghost swapped {owner}'s contract signature page with {target}'s.", **PAPERS, needs="person", icon="papers", owners=NOT_BOSS,
   pick=[c_is("self", "ahmet", neg=True)], conds=[r_present("@ahmet"), r_time(before="15:30")],
   state=[oset("ws.{owner}.sigpage", "%target"), {"e": "set", "key": "other", "who": "target"}], react=[chain("iv_sigpage_check", delay=35)])

# --- D03 hide their printed report in the archive ---------------------------------------
L("archive_hide_react", ["My printout! It was right on my desk!", "Where's my report? I printed it an HOUR ago."])
L("archive_found", ["...In the ARCHIVE? Under 'Z'? Who does that?!", "Found it. Filed. Under 'Z'. Unbelievable."])
S_("log.archive_found", "{actor} searched everywhere for their printed report. It had been filed in the archive under 'Z'.")
scene("iv_archive_hide", effects=[expr("actor", "surprised", 4), say("actor", "archive_hide_react"), stress("actor", 8),
                                  hunt("actor", ["printer", "kitchen", "archive"], "iv_archive_hunt_end", prio=64, ttl=60)])
scene("iv_archive_hunt_end", noise=0.8, allow_absent=True, conditions=[c_present("actor")],
      vars=[var("suspect", "suspect", loc="archive", optional=True)],
      effects=[say("actor", "archive_found"), emote("actor", "question"), log("log.archive_found", 2, "prank")],
      outcomes=[O_blame(), O_ghost(), O_shrug()])
iv("D03", "archive_report", title="File their printed report in the archive", desc="Under 'Z'. Where nobody looks.",
   log="The ghost filed {owner}'s printed report in the archive, under 'Z'.", **PAPERS, icon="folder",
   state=[oset("ws.{owner}.report_at", "archive")], react=[desk_trap("iv_archive_hide", "archive_{owner}")])

# --- D04 relabel their folders ---------------------------------------------------------------
L("label_see_dumb", ["'My Dumb Ideas'? That's what {owner}'s folder says?", "Ha! {owner}'s binder: 'MY DUMB IDEAS'."])
L("label_see_plans", ["'Secret Plans'... on {owner}'s folder. Hm.", "Why does {owner} have a folder called 'SECRET PLANS'?"])
L("label_see_love", ["'Love Letters'?! On {owner}'s desk? In plain sight?", "{owner} has a folder labelled 'LOVE LETTERS'. Wow."])
L("label_owner", ["Who relabelled my folders?!", "That's NOT what my folders say!"])
S_("log.label_dumb", "{actor} noticed {owner}'s folders are now labelled 'MY DUMB IDEAS'.")
S_("log.label_plans", "{actor} spotted a folder on {owner}'s desk labelled 'SECRET PLANS'. Suspicious.")
S_("log.label_love", "{actor} spotted a folder on {owner}'s desk labelled 'LOVE LETTERS'.")
scene("iv_label_seen", noise=0.4, allow_absent=True, conditions=[c_present("actor"), c_not(c_same("actor", "owner"))],
      effects=[emote("actor", "question")],
      outcomes=[out("dumb", [say("actor", "label_see_dumb"), rel("actor", "owner", "respect", -5), mood("actor", 3), log("log.label_dumb", 2, "prank", who=["actor", "owner"])],
                    score=[s_const(5)], when=[c_var("choice", eq="dumb")]),
                out("plans", [say("actor", "label_see_plans"), rel("actor", "owner", "suspicion", 15), rumor("scheme", a="owner", b="actor", juicy=0.6, truth=False, knowers=["actor"], c=0.6),
                              log("log.label_plans", 2, "rumor", who=["actor", "owner"]), chain("ivm_secret", delay=2, roles={"actor": "actor"})],
                    score=[s_const(5)], when=[c_var("choice", eq="plans")]),
                out("love", [say("actor", "label_see_love"), rumor("crush", a="owner", b="actor", juicy=0.6, truth=False, knowers=["actor"], c=0.6),
                             log("log.label_love", 2, "romance", who=["actor", "owner"]), chain("ivm_secret", delay=2, roles={"actor": "actor"})],
                    score=[s_const(5)], when=[c_var("choice", eq="love")])])
scene("iv_label_owner", effects=[expr("actor", "angry", 4), say("actor", "label_owner"), oset("ws.{owner}.labels", "", delay=4)])
iv("D04", "relabel_folders", title="Relabel their folders", desc="Anyone walking past their desk will read the new labels.",
   log="The ghost relabelled the folders on {owner}'s desk.", **PAPERS, needs="choice", icon="folder",
   choices=[choice("dumb", "'MY DUMB IDEAS'"), choice("plans", "'SECRET PLANS'"), choice("love", "'LOVE LETTERS'")],
   state=[oset("ws.{owner}.labels", "$choice")],
   react=[near_trap("iv_label_seen", "desk_{owner}", not_="owner", key="labels_{owner}", r=2.2), desk_trap("iv_label_owner", "labels_own_{owner}", after=20)])

# --- D05 print 500 copies of Ahmet's baby photo --------------------------------------------------
L("baby_find", ["Why is the printer full of... baby photos?", "Five hundred copies of a BABY. Whose baby is this?!", "Is this... Ahmet as a baby?!"],
  burak=["The printer ran out of paper printing a baby. Five hundred times."])
L("baby_laugh", ["Look at those cheeks! It's AHMET!", "Ahmet in a sailor suit! I'm framing this."])
L("baby_boss", ["WHO PRINTED MY BABY PHOTO?!", "That is a private family photograph!"], )
S_("log.baby_found", "The printer spat out 500 copies of a baby photo. It's Ahmet. In a sailor suit. Copies are spreading.")
S_("log.baby_boss_mad", "Ahmet saw his baby photo all over the office. He is hunting for the culprit.")
S_("log.baby_boss_ok", "Ahmet saw his baby photo all over the office... and laughed. First time anyone's seen that.")
scene("iv_baby_found", allow_absent=True, conditions=[c_present("actor")],
      effects=[expr("actor", "surprised", 4), say("actor", "baby_find"), sfx("papers"), oset("printer.queue", ""), log("log.baby_found", 3, "prank"),
               witness([say("self", "baby_laugh", p=0.5, delay=2), mood("self", 4)], r=6), chain("iv_baby_boss", delay=15)])
scene("iv_baby_boss", allow_absent=True, conditions=[c_present("@ahmet")],
      effects=[say("@ahmet", "baby_boss")],
      outcomes=[out("mad", [expr("@ahmet", "angry", 6), emote("@ahmet", "anger"), stress("@ahmet", 12), ghost(), log("log.baby_boss_mad", 3, "boss")],
                    score=[s_trait("@ahmet", "temper", 1.2), s_stress("@ahmet", 0.01)]),
                out("laugh", [expr("@ahmet", "happy", 6), mood("@ahmet", 8), each([rel("self", "@ahmet", "friendship", 4)], exclude=["@ahmet"]),
                              log("log.baby_boss_ok", 3, "boss")], score=[s_mood("@ahmet", 0.02), s_const(0.3)])])
iv("D05", "print_500", title="Print 500 copies of Ahmet's baby photo", desc="The next person to use the printer gets buried in them.",
   log="The ghost queued 500 copies of Ahmet's baby photo on the printer.", obj="printer", cat="D", icon="printer",
   conds=[why(c_office("printer.broken", False), "printer_broken", "The printer is broken.")],
   state=[oset("printer.queue", "baby"), oset("printer.no_paper", True, delay=6)],
   react=[trap("iv_baby_found", place="#printer", key="baby", days=1)], reuse={"cool": 600, "day": 1})

# --- D06 put their report on someone else's desk ------------------------------------------------------
L("misplaced_find", ["Hm? Whose report is this? Oh — it's {owner}'s.", "This isn't mine. {owner}'s report... on MY desk?"])
L("misplaced_return", ["Here — this ended up on my desk.", "Found your report on my desk. Weird, right?"])
L("misplaced_thanks", ["Thank you! I was about to panic.", "You're a lifesaver!"])
L("misplaced_steal", ["...Nobody would know if I handed this in.", "Finders keepers."], deniz=["Excellent work. My work, now."])
S_("log.misplaced_return", "{owner}'s report turned up on {actor}'s desk. {actor} brought it straight back.")
S_("log.misplaced_read", "{owner}'s report turned up on {actor}'s desk. {actor} read every page before returning it.")
S_("log.misplaced_steal", "{owner}'s report turned up on {actor}'s desk. {actor} handed it in to Ahmet. As their own.")
S_("mem.misplaced_returned", "{actor} returned my lost report.")
scene("iv_misplaced_find", noise=0.8, allow_absent=True, conditions=[c_present("actor")],
      effects=[emote("actor", "question"), say("actor", "misplaced_find")],
      outcomes=[out("return", [visit("actor", "owner", "iv_misplaced_return", prio=56, ttl=60, delay=1.5), log("log.misplaced_return", 2, "help")],
                    score=[s_trait("actor", "honesty", 1.0), s_aff("actor", "owner", 0.015), s_const(0.3)], when=[c_present("owner")]),
                out("read", [learn("actor", "$fact", c=1.0, when=[{"c": "fact_exists", "fact": "$fact"}]), rel("actor", "owner", "respect", 6),
                             visit("actor", "owner", "iv_misplaced_return", prio=56, ttl=60, delay=3), log("log.misplaced_read", 2, "secret")],
                    score=[s_trait("actor", "curiosity", 1.0), s_trait("actor", "gossip", 0.5)], when=[c_present("owner")]),
                out("steal", [say("actor", "misplaced_steal"), favor("actor", 6), favor("owner", -4),
                              rumor("credit_steal", a="actor", b="owner", juicy=0.85, knowers=["actor"]), log("log.misplaced_steal", 4, "scheme"),
                              trap("iv_misplaced_owner", place="desk_{owner}", who="owner", key="misplaced_owner_{owner}", roles={"thief": "actor", "owner": "owner"})],
                    score=[s_trait("actor", "cunning", 1.3), s_trait("actor", "honesty", -1.0), s_rel("actor", "owner", "rivalry", 0.02)])])
scene("iv_misplaced_return", noise=0.6, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4), say("actor", "misplaced_return", to="target"), say("target", "misplaced_thanks", to="actor", delay=1.6),
               rel("target", "actor", "trust", 8), rel("target", "actor", "friendship", 6), mem("target", "actor", "helped_me", 0.5, 0.7, "mem.misplaced_returned", 2)])
L("misplaced_owner", ["Where's my report?! I left it RIGHT HERE.", "My report is gone. Gone!"])
S_("log.misplaced_owner", "{owner} can't find their report anywhere. (It's already on Ahmet's desk — under {thief}'s name.)")
scene("iv_misplaced_owner", effects=[expr("actor", "surprised", 5), say("actor", "misplaced_owner"), stress("actor", 12), work("actor", -12),
                                     log("log.misplaced_owner", 3, "scheme", who=["owner", "thief"]),
                                     learn("actor", "$rumor", c=0.5, when=[c_chance(0.5)])])
iv("D06", "report_elsewhere", title="Put their report on someone else's desk", desc="Pick whose desk. What they do with it is up to them.",
   log="The ghost moved {owner}'s report onto {target}'s desk.", **PAPERS, needs="person", icon="papers", owners=NOT_BOSS,
   pick=[c_is("self", "ahmet", neg=True), c_present("self")], vars=private_vars("owner"),
   state=private_info("owner") + [oset("ws.{owner}.report_at", "%target")],
   react=[trap("iv_misplaced_find", place="desk_{target}", who="target", key="misplaced_{owner}")])

# --- D07 shuffle the pages of their printed presentation ---------------------------------------------------
L("pages_chaos", ["...And as you can see on page seven— this is page two. Hang on.", "So our results show— wait, where's the chart?", "Page four. No. Nine? Why is there a page nine?"])
L("pages_joke", ["Okay! Interactive presentation: guess the next page!", "Nobody panic. I'll do it from memory. Ha."])
L("pages_meltdown", ["I— I'm so sorry, the pages— I can't—", "I swear these were in order this morning."])
S_("log.pages_joke", "{actor}'s presentation pages were completely out of order. {actor} turned it into a joke — the room loved it.")
S_("log.pages_melt", "{actor}'s presentation pages were scrambled. {actor} melted down in front of Ahmet.")
scene("iv_pages_present", noise=0.7, allow_absent=True, conditions=[c_present("actor")],
      effects=[hold(["actor"], 4), say("actor", "pages_chaos"), emote("actor", "sweat")],
      outcomes=[out("joke", [say("actor", "pages_joke", delay=1.8), witness([mood("self", 4), rel("self", "actor", "friendship", 3)], r=6), favor("actor", 2),
                             log("log.pages_joke", 3, "meeting")], score=[s_trait("actor", "humor", 1.3), s_trait("actor", "sociability", 0.4)]),
                out("melt", [say("actor", "pages_meltdown", delay=1.8), expr("actor", "sad", 6, delay=1.8), favor("actor", -6), stress("actor", 14),
                             mem("actor", "", "humiliated", -0.6, 0.9, "mem.slides_humiliated", 3), log("log.pages_melt", 3, "meeting")],
                    score=[s_stress("actor", 0.02), s_trait("actor", "humor", -0.6), s_const(0.4)])])
iv("D07", "shuffle_pages", title="Shuffle the pages of their presentation", desc="They'll find out in front of everyone.",
   log="The ghost shuffled the pages of {owner}'s printed presentation.", **PAPERS, icon="papers", owners=NOT_BOSS,
   conds=[r_meeting_pending(), r_meeting_not_started(), why({"c": "attends", "who": "owner"}, "not_attending")],
   state=[oset("ws.{owner}.pages", "shuffled"), mtg("first", "%owner")],
   react=[on_trap("meeting_present", "iv_pages_present", who="owner", key="pages_{owner}", replace=True)])

# --- D08 leave a confidential document open in the archive ---------------------------------------------------
L("conf_read_salary", ["The salary list... {subject} earns THAT much?", "This is everyone's salary. Oh. OH."])
L("conf_read_layoff", ["'Positions under review: {subject}'?!", "This list says {subject}'s job is 'under review'..."])
L("conf_read_promo", ["'Promotion shortlist: {subject}'. Interesting.", "So {subject} is on the shortlist. Huh."])
S_("log.conf_read", "{actor} found a confidential document left open in the archive — and read it.")
scene("iv_conf_read", allow_absent=True, conditions=[c_present("actor")],
      effects=[expr("actor", "surprised", 4), log("log.conf_read", 3, "secret"),
               say("actor", "conf_read_salary", when=[c_var("choice", eq="salary")]), say("actor", "conf_read_layoff", when=[c_var("choice", eq="layoff")]),
               say("actor", "conf_read_promo", when=[c_var("choice", eq="promo")]),
               rel("actor", "subject", "rivalry", 8, when=[c_var("choice", in_=["salary", "promo"])]),
               learn("actor", "$fact", c=0.95), chain("ivm_secret", delay=1.5, roles={"actor": "actor"})])
iv("D08", "confidential_doc", title="Leave a confidential document open in the archive", desc="The next person at the filing cabinets will read it.",
   log="The ghost left a confidential {choice} document lying open in the archive.", obj="file_cabinet", cat="D", needs="choice", icon="file",
   choices=[choice("salary", "the salary list"), choice("layoff", "a 'positions under review' list"), choice("promo", "the promotion shortlist")],
   state=[pick_role("subject", "worst_of", of="@ahmet", lim=99),
          rumor("raise", a="subject", b="subject", juicy=0.6, knowers=[], key="fact", when=[c_var("choice", eq="salary")]),
          rumor("getting_fired", a="subject", b="subject", juicy=0.85, truth=False, knowers=[], key="fact", when=[c_var("choice", eq="layoff")]),
          rumor("shortlisted", a="subject", b="subject", juicy=0.7, truth=False, knowers=[], key="fact", when=[c_var("choice", eq="promo")]),
          oset("hr.open_doc", "$choice")],
   react=[trap("iv_conf_read", place="#archive", key="confdoc", days=1)])

# --- D09 swap two people's performance reviews ---------------------------------------------------------
L("swapreview_praise", ["{actor}, your review is outstanding. Outstanding!", "I read your review, {actor}. Excellent quarter."])
L("swapreview_confused", ["...Thank you? I wasn't expecting that.", "Really? Wow. Okay!"])
L("swapreview_scold", ["Your review is a disaster, {actor}.", "Frankly, {actor}, these numbers are embarrassing."])
L("swapreview_shock", ["What? My numbers were great!", "That can't be my review. It can't be."])
S_("log.swapreview", "Two performance reviews were swapped. Ahmet praised {owner}... and grilled {target} for {owner}'s numbers.")
scene("iv_swapreview_boss", allow_absent=True, conditions=[c_present("@ahmet")],
      effects=[log("log.swapreview", 4, "boss", who=["owner", "target"]),
               summon("owner", "iv_swapreview_good", delay=1, when=[c_present("owner")]), summon("target", "iv_swapreview_bad", delay=12, when=[c_present("target")])])
scene("iv_swapreview_good", noise=0.5, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("target", "swapreview_praise", to="actor"), say("actor", "swapreview_confused", to="target", delay=1.6),
               emote("actor", "cheer", delay=1.8), morale("actor", 6), mood("actor", 10)])
scene("iv_swapreview_bad", noise=0.5, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("target", "swapreview_scold", to="actor"), say("actor", "swapreview_shock", to="target", delay=1.6),
               expr("actor", "angry", 6, delay=1.6), morale("actor", -8), mood("actor", -12), rel("actor", "target", "resentment", 10),
               mem("actor", "target", "scolded", -0.6, 0.9, "mem.review_bad", 3), plan("actor", "prove_self", "", heat=1.0)])
iv("D09", "swap_reviews", title="Swap two people's performance reviews", desc="Pick whose file trades places with this desk owner's.",
   log="The ghost swapped the performance reviews of {owner} and {target}.", obj="hr_cabinet", cat="D", needs="person", icon="file",
   pick=[c_is("self", "ahmet", neg=True), c_present("self")], conds=[r_present("@ahmet"), r_time(before="15:30")],
   state=[pick_role("owner", "rival_of", of="target", lim=-1), pick_role("owner", "worst_of", keep=True, of="target", lim=99),
          call("swap_favor", a="owner", b="target"), oset("hr.swapped", "%target")],
   react=[trap("iv_swapreview_boss", place="desk_ahmet", who="@ahmet", key="swapreview", after=5)])

# --- D10 send their contract to the recycling ---------------------------------------------------------------
L("recycle_react", ["The contract! The signed one! Where is it?!", "No, no, no — the original contract is GONE."])
L("recycle_found", ["...In the RECYCLING bin. Next to the yoghurt pots.", "Found it. In the recycling. With coffee on it."])
S_("log.recycle_found", "{actor}'s signed contract was found in the kitchen recycling. Coffee stain included.")
scene("iv_recycle_react", effects=[expr("actor", "surprised", 5), emote("actor", "exclaim"), say("actor", "recycle_react"), stress("actor", 14),
                                   hunt("actor", ["archive", "printer", "kitchen"], "iv_recycle_end", prio=68, ttl=60)])
scene("iv_recycle_end", noise=0.8, allow_absent=True, conditions=[c_present("actor")],
      vars=[var("suspect", "clumsy_one", optional=True)],
      effects=[say("actor", "recycle_found"), emote("actor", "sweat"), mood("actor", -6), log("log.recycle_found", 2, "prank")],
      outcomes=[O_blame(), O_ghost(), O_shrug()])
iv("D10", "recycle_contract", title="Put their signed contract in the recycling", desc="The kitchen recycling bin. Next to the yoghurt pots.",
   log="The ghost moved {owner}'s signed contract into the kitchen recycling.", **PAPERS, icon="papers",
   state=[oset("ws.{owner}.contract_at", "kitchen")], react=[desk_trap("iv_recycle_react", "recycle_{owner}")])

# --- D11 forge Ahmet's signature on their expense claim -------------------------------------------------------
L("forge_spot", ["This signature... Ahmet doesn't loop his A like that.", "Hm. This 'Ahmet' signature is forged."])
L("forge_pass", ["Approved, signed... fine. Paid.", "Another expense claim. Processed."])
L("forge_accuse", ["{target}. Your expense claim has a FORGED signature.", "Did you forge Ahmet's signature, {target}?"])
L("forge_deny", ["Forged?! I'd never! I didn't even submit it yet!", "That's not my doing! I swear!"])
S_("log.forge_caught", "Zeynep spotted a forged Ahmet signature on {target}'s expense claim. {target} swears they know nothing.")
S_("log.forge_pass", "{target}'s expense claim sailed through with a forged signature. Nobody noticed. Yet.")
scene("iv_forge_check", allow_absent=True, conditions=[c_present("@zeynep")],
      outcomes=[out("spot", [say("@zeynep", "forge_spot"), visit("@zeynep", "owner", "iv_forge_scene", prio=60, ttl=60, delay=2)],
                    score=[s_trait("@zeynep", "diligence", 1.0), s_trait("@zeynep", "curiosity", 0.6)], when=[c_present("owner")]),
                out("pass", [say("@zeynep", "forge_pass"), mood("owner", 4), log("log.forge_pass", 2, "work", who=["owner"])], score=[s_const(0.5)])])
scene("iv_forge_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "forge_accuse", to="target"), say("target", "forge_deny", to="actor", delay=1.6), emote("target", "sweat", delay=1.6),
               rel("actor", "target", "trust", -15), rel("actor", "target", "suspicion", 20), favor("target", -6),
               rumor("scheme", a="target", b="actor", juicy=0.75, truth=False, knowers=["actor"]), log("log.forge_caught", 4, "scheme")],
      outcomes=[out("tell_boss", [visit("actor", "@ahmet", "ivm_tell_boss", prio=58, ttl=60, delay=3, roles={"subject": "target"}), setv("fact", "$rumor")],
                    score=[s_trait("actor", "diligence", 0.8), s_rel("actor", "target", "rivalry", 0.02)], when=[c_present("@ahmet")]),
                out("let_go", [rel("actor", "target", "suspicion", -8)], score=[s_aff("actor", "target", 0.02), s_const(0.3)])])
iv("D11", "forge_signature", title="Forge Ahmet's signature on their expense claim", desc="Zeynep checks every claim. Will she notice?",
   log="The ghost forged Ahmet's signature on {owner}'s expense claim.", **PAPERS, icon="papers", owners=["selin", "mert", "burak", "ece", "deniz", "ceren"],
   conds=[r_present("@zeynep")], state=[oset("ws.{owner}.forged")], react=[chain("iv_forge_check", delay=25)])

# --- D12 add a karaoke machine to someone's expenses ----------------------------------------------------------
L("karaoke_spot", ["'One karaoke machine — 4,000'? On {target}'s expenses?!", "Who expenses a KARAOKE MACHINE?"])
L("karaoke_ask", ["{target}, explain the karaoke machine.", "Care to tell me about the karaoke machine, {target}?"])
L("karaoke_deny", ["The WHAT? I don't even sing!", "Karaoke machine? I've never bought one in my life!"])
L("karaoke_own", ["...It's for team building. Obviously.", "Morale is important, Zeynep."], mert=["Team building, Zeynep. Team. Building."])
S_("log.karaoke_deny", "Zeynep found a karaoke machine on {target}'s expense claim. {target} has never seen it. Zeynep isn't convinced.")
S_("log.karaoke_own", "Zeynep found a karaoke machine on {target}'s expense claim. {target} defended it as 'team building'.")
scene("iv_karaoke_audit", allow_absent=True, conditions=[c_present("@zeynep"), c_present("target")],
      effects=[say("@zeynep", "karaoke_spot"), emote("@zeynep", "exclaim"), visit("@zeynep", "target", "iv_karaoke_scene", prio=60, ttl=60, delay=2)])
scene("iv_karaoke_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "karaoke_ask", to="target")],
      outcomes=[out("deny", [say("target", "karaoke_deny", to="actor", delay=1.6), rel("actor", "target", "suspicion", 15), favor("target", -3),
                             rumor("scheme", a="target", b="actor", juicy=0.5, truth=False, knowers=["actor"]), witness([learn("self", "$rumor")], r=4),
                             log("log.karaoke_deny", 3, "misunderstanding")], score=[s_trait("target", "honesty", 1.0), s_const(0.3)]),
                out("own", [say("target", "karaoke_own", to="actor", delay=1.6), mood("actor", 3), rel("actor", "target", "friendship", 2),
                            log("log.karaoke_own", 2, "misunderstanding")], score=[s_trait("target", "humor", 1.2), s_trait("target", "cunning", 0.6)])])
iv("D12", "karaoke_expense", title="Add a karaoke machine to someone's expense claim", desc="Zeynep is doing the expense audit today.",
   log="The ghost added 'one karaoke machine' to {target}'s expense claim.", obj="file_cabinet", cat="D", needs="person", icon="music",
   pick=[c_is("self", "zeynep", neg=True), c_is("self", "ahmet", neg=True)], conds=[r_present("@zeynep")],
   state=[oset("hr.karaoke", "%target")], react=[chain("iv_karaoke_audit", delay=20)])

# --- D13 write a rude note in the margin of their report ----------------------------------------------------------
L("margin_boss", ["'Ahmet is wrong about everything' — in YOUR handwriting, {actor}?", "Interesting margin note in your report, {actor}."])
L("margin_explain", ["I didn't write that! I swear!", "That's not my handwriting! ...Is it?"])
L("margin_respect", ["...Well, at least you're honest. Wrong, but honest.", "Hm. Bold. I almost respect it."])
L("margin_angry", ["I don't want to see that kind of thing again.", "Remember who signs your reviews."])
S_("log.margin_respect", "Ahmet found 'Ahmet is wrong about everything' in the margin of {actor}'s report. Oddly, he respected the honesty.")
S_("log.margin_angry", "Ahmet found 'Ahmet is wrong about everything' in the margin of {actor}'s report. He did not take it well.")
scene("iv_margin", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("target", "margin_boss", to="actor"), say("actor", "margin_explain", to="target", delay=1.6), emote("actor", "sweat", delay=1.6)],
      outcomes=[out("respect", [say("target", "margin_respect", to="actor", delay=3.2), rel("target", "actor", "respect", 8), log("log.margin_respect", 3, "boss")],
                    score=[s_mood("target", 0.02), s_trait("target", "honesty", 0.8)]),
                out("angry", [say("target", "margin_angry", to="actor", delay=3.2), expr("target", "angry", 5, delay=3.2), favor("actor", -7), rel("target", "actor", "trust", -12),
                              log("log.margin_angry", 3, "boss")], score=[s_trait("target", "temper", 1.0), s_const(0.3)])])
iv("D13", "margin_note", title="Write a rude note in the margin of their report", desc="'Ahmet is wrong about everything.' In their handwriting.",
   log="The ghost wrote 'Ahmet is wrong about everything' in the margin of {owner}'s report.", **PAPERS, icon="papers", owners=NOT_BOSS,
   conds=[r_present("@ahmet"), r_present("owner")], state=[oset("ws.{owner}.margin")],
   react=[trap("iv_margin_read", place="desk_ahmet", who="@ahmet", key="margin_{owner}", after=6)])
L("margin_read", ["...'Ahmet is wrong about everything'? In {owner}'s report?", "Hm. A margin note. About ME. {owner}, my office."])
scene("iv_margin_read", allow_absent=True, conditions=[c_present("actor")],
      effects=[expr("actor", "angry", 5), say("actor", "margin_read"), emote("actor", "anger"), summon("owner", "iv_margin", delay=1)])

# --- D14 jam the copier with a love letter ------------------------------------------------------------------------
L("jam_find", ["Paper jam... wait. This is a letter. A LOVE letter.", "There's something stuck in the rollers... 'Dear {crush}...'"])
L("jam_read_aloud", ["'Dear {crush}, every time you walk past my desk...' — signed {writer}!", "Listen to this: '{crush}, your laugh is my favourite sound.' From {writer}!"])
L("jam_pocket", ["...I'll just give this back to {writer}. Quietly.", "This isn't mine to read. I'll return it."])
L("jam_mortified", ["THAT WAS PRIVATE!", "Give that BACK!"], mert=["...I can explain. No I can't."])
S_("log.jam_aloud", "A love letter from {writer} to {crush} got stuck in the copier. {actor} read it out loud.")
S_("log.jam_quiet", "A love letter from {writer} to {crush} got stuck in the copier. {actor} quietly gave it back.")
scene("iv_jam_letter", noise=0.8, allow_absent=True, conditions=[c_present("actor"), c_present("writer"), c_present("crush")],
      effects=[expr("actor", "surprised", 4), say("actor", "jam_find"), call("fix_intent", obj="printer", requester="", prio=55, delay=4)],
      outcomes=[out("aloud", [say("actor", "jam_read_aloud", delay=1.8), say("writer", "jam_mortified", delay=3.4, when=[c_near("writer", "actor", 7)]),
                              rumor("crush", a="writer", b="crush", juicy=0.8, knowers=["actor"]), each([learn("self", "$rumor", frm="actor", c=0.9)],
                              where=[c_near("self", "actor", 7)]), learn("crush", "$rumor", c=0.9), rel("writer", "actor", "resentment", 15),
                              rel("crush", "writer", "romance", 8, when=[c_rel("crush", "writer", "romance", gt=15)]), mood("writer", -12),
                              log("log.jam_aloud", 4, "romance", who=["writer", "crush"])],
                    score=[s_trait("actor", "gossip", 1.2), s_trait("actor", "humor", 0.5)]),
                out("quiet", [say("actor", "jam_pocket", delay=1.8), rel("writer", "actor", "trust", 10),
                              log("log.jam_quiet", 2, "romance", who=["writer", "crush"])], score=[s_trait("actor", "empathy", 1.0), s_trait("actor", "honesty", 0.5)])])
iv("D14", "jam_love_letter", title="Jam a love letter in the copier", desc="Pick whose secret love letter gets stuck in the rollers.",
   log="The ghost jammed {target}'s love letter into the copier.", obj="printer", cat="D", needs="person", icon="star",
   pick=[{"c": "picks", "fn": "crush_of", "of": "self"}, c_present("self")],
   state=[pick_role("crush", "crush_of", of="target"), oset("printer.broken", True)],
   react=[trap("iv_jam_letter", place="#printer", key="jamletter", days=1, roles={"writer": "target", "crush": "crush"})])

# --- D15 move all the office supplies into one person's drawer --------------------------------------------------------
L("supplies_none", ["No staplers. No pens. Nothing. Where did it all go?", "The supply shelf is EMPTY."])
L("supplies_found", ["...It's all in {target}'s drawer. ALL of it.", "{target}'s drawer: forty pens, six staplers, and every sticky note we own."])
L("supplies_hoarder", ["Supply hoarder!", "So YOU'RE the stapler thief!"], mert=["Dragon on a pile of pens!"])
L("supplies_innocent", ["Those aren't mine! I don't even like staplers!", "How did all that get in my drawer?!"])
S_("log.supplies", "{actor} went looking for office supplies and found ALL of them stashed in {target}'s drawer.")
S_("mem.supplies_accused", "Everyone thinks I've been hoarding office supplies.")
scene("iv_supplies_search", allow_absent=True, conditions=[c_present("actor")],
      effects=[say("actor", "supplies_none"), emote("actor", "question"), hunt("actor", ["supplies", "archive", "desk_{target}"], "iv_supplies_found", prio=55, ttl=50)])
scene("iv_supplies_found", allow_absent=True, conditions=[c_present("actor")],
      effects=[expr("actor", "surprised", 4), say("actor", "supplies_found"), say("actor", "supplies_hoarder", delay=1.6), rel("actor", "target", "suspicion", 12),
               rumor("prank", a="target", b="actor", juicy=0.35, truth=False, knowers=["actor"]), witness([learn("self", "$rumor")], r=5),
               say("target", "supplies_innocent", delay=3.2, when=[c_near("target", "actor", 6)]), mem("target", "actor", "accused", -0.3, 0.6, "mem.supplies_accused", 2),
               oset("supplies.at", ""), log("log.supplies", 2, "prank", who=["actor", "target"])])
ev(id="iv_supplies_need", trigger="", priority=50,
   roles=[role("needer", where=[c_avail("self"), c_not(c_same("self", "target"))], score=[s_trait("self", "diligence", 1.0), s_rand(0.5)], exclude=["target"])],
   effects=[chain("iv_supplies_search", roles={"actor": "needer", "target": "target"})])
iv("D15", "hoard_supplies", title="Move every office supply into someone's drawer", desc="Pens, staplers, sticky notes — all of it. Pick whose drawer.",
   log="The ghost moved every office supply into {target}'s drawer.", obj="supply_shelf", cat="D", needs="person", icon="papers",
   pick=[c_is("self", "ahmet", neg=True)], state=[oset("supplies.at", "%target")], react=[chain("iv_supplies_need", delay=6)])

# --- D16 misfile the archive -------------------------------------------------------------------------------------------
L("archive_mess", ["Who reorganised the archive?! Nothing's where it should be!", "'Accounts' is in 'Holidays'. 'Holidays' is in 'Legal'. WHY?"])
L("archive_together", ["You're looking too? Okay — I'll take A to M.", "Let's do this together or we'll be here all night."])
L("archive_fight", ["Stop moving my piles!", "I was here first!"])
S_("log.archive_mess", "{actor} found the archive completely misfiled. Searching for anything takes forever now.")
S_("log.archive_team", "{actor} and {target} both got lost in the misfiled archive — and sorted it out together.")
S_("log.archive_fight", "{actor} and {target} both needed the misfiled archive. They ended up fighting over the piles.")
scene("iv_archive_mess", noise=0.8, allow_absent=True, conditions=[c_present("actor")],
      roles=[role("target", where=[c_avail("self")], near="actor", r=4.0, score=[s_dist("actor", "self", -0.2)], exclude=["actor"], optional=True)],
      vars=[var("suspect", "clumsy_one", optional=True)],
      effects=[expr("actor", "angry", 4), say("actor", "archive_mess"), work("actor", -8), log("log.archive_mess", 2, "work")],
      outcomes=[out("team", [say("target", "archive_together", to="actor", delay=1.6), rel("actor", "target", "friendship", 6, both=True), log("log.archive_team", 2, "friendship")],
                    score=[s_aff("actor", "target", 0.02), s_trait("target", "empathy", 0.6)], when=[c_filled("target")]),
                out("fight", [say("actor", "archive_fight", to="target", delay=1.6), stat("arguments"), rel("actor", "target", "friendship", -6, both=True),
                              log("log.archive_fight", 2, "conflict")], score=[s_rel("actor", "target", "rivalry", 0.03), s_stress("actor", 0.01)], when=[c_filled("target")]),
                O_blame()])
iv("D16", "misfile_archive", title="Misfile the whole archive", desc="'Accounts' goes in 'Holidays'. The next two visitors will suffer.",
   log="The ghost misfiled the archive.", obj="file_cabinet", cat="D", icon="folder",
   state=[oset("hr.archive_mess", True)], react=[trap("iv_archive_mess", place="#archive", key="archmess", uses=2, days=1)])

# --- D17 leave their resignation draft visible on their desk -----------------------------------------------------------
L("resdraft_see", ["Is that a... resignation letter? On {owner}'s desk?", "'Dear Ahmet, I hereby resign...' — {owner}?!"], ahmet=["A resignation letter. From {owner}. On their desk."])
S_("log.resdraft", "{actor} spotted a resignation letter draft on {owner}'s desk.")
scene("iv_resdraft_seen", allow_absent=True, conditions=[c_present("actor"), c_not(c_same("actor", "owner"))],
      effects=[expr("actor", "surprised", 4), say("actor", "resdraft_see"), rumor("resigning", a="owner", b="actor", juicy=0.85, knowers=[], key="fact"),
               learn("actor", "$fact", c=0.9), log("log.resdraft", 3, "secret", who=["actor", "owner"])],
      outcomes=[out("boss", [visit("actor", "owner", "iv_quit_scene", prio=70, ttl=50, delay=2)], score=[s_const(5)], when=[c_is("actor", "ahmet")]),
                out("other", [chain("ivm_secret", delay=1.5, roles={"actor": "actor"})], score=[s_const(1)])])
iv("D17", "resignation_draft", title="Leave their resignation draft in plain sight", desc="They wrote it on a bad day. They never sent it. Now it's on top of the pile.",
   log="The ghost left {owner}'s draft resignation letter on top of their desk.", **PAPERS, icon="papers", owners=NOT_BOSS,
   conds=[why(c_any(c_morale("owner", lt=55), c_plan("owner", "job_search"), c_goal("owner", "find_new_job")), "happy_here", "They're happy here — there's no resignation letter.")],
   state=[oset("ws.{owner}.resdraft")], react=[near_trap("iv_resdraft_seen", "desk_{owner}", not_="owner", key="resdraft_{owner}", r=2.2, days=1)])

# --- D18 stamp URGENT on every paper on their desk ---------------------------------------------------------------------
L("urgent_panic", ["Everything is URGENT?! Since when?!", "URGENT. URGENT. URGENT. All of it?!", "Okay. No lunch today. No breathing either."])
L("urgent_care", ["Hey... you okay? You look like you're about to explode.", "Breathe. Want me to take something off your plate?"])
L("urgent_thanks", ["...Yes. Please. Thank you.", "I'm drowning. Thank you."])
S_("log.urgent", "Every sheet on {actor}'s desk is suddenly stamped URGENT. {actor} is working through lunch in a panic.")
S_("log.urgent_help", "{target} saw {actor} drowning in 'URGENT' papers and helped out.")
scene("iv_urgent_found", effects=[expr("actor", "surprised", 4), emote("actor", "sweat"), say("actor", "urgent_panic"), stress("actor", 18), npcflag("actor", "jitter"),
                                  npcval("actor", "lunch_at", d=70), log("log.urgent", 3, "work"), chain("iv_urgent_help", delay=20)])
ev(id="iv_urgent_help", trigger="", priority=55,
   roles=[role("helper", where=[c_avail("self"), c_trait("self", "empathy", gt=0.5), c_not(c_same("self", "actor"))], score=[s_trait("self", "empathy", 1.0), s_aff("self", "actor", 0.02)], exclude=["actor"])],
   conditions=[c_present("actor")],
   effects=[visit("helper", "actor", "iv_urgent_help_scene", prio=58, ttl=50)])
scene("iv_urgent_help_scene", conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "urgent_care", to="target"), say("target", "urgent_thanks", to="actor", delay=1.6), work("target", 15),
               stress("target", -10), rel("target", "actor", "friendship", 10), rel("target", "actor", "trust", 6), mem("target", "actor", "helped_me", 0.6, 0.8, "mem.helped_me", 2),
               log("log.urgent_help", 3, "help")])
iv("D18", "urgent_stamps", title="Stamp URGENT on every paper on their desk", desc="All of it. Every single sheet.",
   log="The ghost stamped URGENT on every paper on {owner}'s desk.", **PAPERS, icon="papers", conds=[r_time(before="15:30")],
   state=[oset("ws.{owner}.urgent")], react=[desk_trap("iv_urgent_found", "urgent_{owner}")])

# --- D19 edit the printed org chart --------------------------------------------------------------------------------------
L("orgchart_see", ["Why is {target} ABOVE Ahmet on the org chart?!", "New org chart? {target} is... the boss now?", "Ha! Look at the org chart. {target}: CEO."])
L("orgchart_boss", ["WHO edited the org chart?!", "{target} is NOT my superior. Fix this. Now."])
L("orgchart_smug", ["Well. The chart doesn't lie.", "I always knew they'd see sense."], deniz=["About time."])
L("orgchart_terrified", ["I didn't do that! Please believe me!", "Take it down! TAKE IT DOWN!"])
S_("log.orgchart", "Someone pinned an org chart showing {target} above Ahmet. Ahmet saw it.")
scene("iv_orgchart_seen", noise=0.6, allow_absent=True, conditions=[c_present("actor")],
      effects=[say("actor", "orgchart_see"), emote("actor", "question")],
      outcomes=[out("boss", [say("actor", "orgchart_boss", delay=1.6), expr("actor", "angry", 6), rel("actor", "target", "trust", -10), rel("actor", "target", "suspicion", 12),
                             unpin("orgchart"), log("log.orgchart", 3, "boss"), visit("actor", "target", "iv_orgchart_scene", prio=66, ttl=50, delay=2)],
                    score=[s_const(5)], when=[c_is("actor", "ahmet")]),
                out("laugh", [mood("actor", 3), rel("actor", "target", "respect", 2)], score=[s_const(1)])])
scene("iv_orgchart_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "orgchart_boss", to="target")],
      outcomes=[out("smug", [say("target", "orgchart_smug", to="actor", delay=1.6), rel("actor", "target", "rivalry", 15), favor("target", -6)],
                    score=[s_trait("target", "ambition", 1.0), s_trait("target", "cunning", 0.6)]),
                out("terrified", [say("target", "orgchart_terrified", to="actor", delay=1.6), emote("target", "sweat", delay=1.6), stress("target", 12)],
                    score=[s_trait("target", "empathy", 0.5), s_const(0.5)])])
iv("D19", "org_chart", title="Edit the org chart on the cork board", desc="Put someone above Ahmet. Everyone in the meeting room will see it.",
   log="The ghost pinned an org chart with {target} above Ahmet.", obj="noticeboard", cat="D", needs="person", icon="pin",
   pick=[c_is("self", "ahmet", neg=True)], state=[pin("orgchart", about="target")],
   react=[near_trap("iv_orgchart_seen", "notice", key="orgchart", r=3.2, days=1, uses=3)])

# --- D20 remove the last page of their report --------------------------------------------------------------------
L("lastpage_boss", ["{actor}, your report just... stops. Where's the conclusion?", "Page twelve of twelve is missing, {actor}. The important one."])
L("lastpage_baffled", ["It was there! I printed thirteen pages!", "What? I definitely wrote a conclusion!"])
S_("log.lastpage", "Ahmet read {actor}'s report — the last page, the conclusion, was missing. {actor} looked unprepared.")
scene("iv_lastpage", noise=0.6, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("target", "lastpage_boss", to="actor"), say("actor", "lastpage_baffled", to="target", delay=1.6), emote("actor", "sweat", delay=1.6),
               rel("target", "actor", "respect", -6), favor("actor", -4), work("actor", -6), log("log.lastpage", 3, "boss")],
      outcomes=[O_blame(), O_shrug()], vars=[var("suspect", "suspect", of="actor", desk=True, optional=True)])
iv("D20", "missing_page", title="Remove the last page of their report", desc="The conclusion. The page Ahmet always reads first.",
   log="The ghost removed the last page of {owner}'s report.", **PAPERS, icon="papers", owners=NOT_BOSS,
   conds=[r_present("@ahmet"), r_present("owner"), r_time(before="16:00")], state=[oset("ws.{owner}.lastpage")],
   react=[trap("iv_lastpage_read", place="desk_ahmet", who="@ahmet", key="lastpage_{owner}", after=8)])
L("lastpage_read", ["...and the conclusion is— there is no conclusion. {owner}!", "Where's the last page? {owner}, come here."])
scene("iv_lastpage_read", allow_absent=True, conditions=[c_present("actor")],
      effects=[say("actor", "lastpage_read"), emote("actor", "question"), summon("owner", "iv_lastpage", delay=1)])
