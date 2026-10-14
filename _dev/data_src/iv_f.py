# Interventions — F. Phones & calls (desk phone / mobile tab, reception switchboard, coat rack)
from iv_common import *  # noqa: F401,F403

PH = dict(obj="ws", tab="phone", cat="F")
NOT_BOSS = ["selin", "mert", "zeynep", "burak", "ece", "deniz", "ceren"]

def ring(who="actor"):
    return [emote(who, "phone"), sfx("phone")]

# --- F01 swap two people's mobiles ---------------------------------------------------------
L("swapphone_read", ["...This isn't my phone. And this message isn't for me.", "Wait. Whose phone is— oh. OH.", "That's not my lock screen. But I've already read the message."])
L("swapphone_return", ["I think we swapped phones. Here. I... didn't read anything.", "Your phone. I may have seen a message. Sorry."])
L("swapphone_mortified", ["You READ it?!", "Please tell me you didn't read the messages."])
L("swapphone_cool", ["Ha, they look identical. Thanks.", "No harm done. Here's yours."])
S_("log.swapphone", "{target} picked up {owner}'s phone by mistake and read a message that wasn't meant for them.")
S_("log.swapphone_back", "{owner} and {target} swapped their phones back. {target} looked like they knew something.")
scene("iv_swapphone_read", allow_absent=True, conditions=[c_present("target"), {"c": "fact_exists", "fact": "$fact"}],
      effects=ring("target") + [expr("target", "surprised", 4, delay=1.2), say("target", "swapphone_read", delay=1.2), learn("target", "$fact", c=1.0),
                                reveal("$fact"), log("log.swapphone", 3, "secret", who=["target", "owner"])])
scene("iv_swapphone_back", noise=0.8, conditions=[c_avail("actor"), c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("target", "swapphone_return", to="actor"), log("log.swapphone_back", 2, "secret")],
      outcomes=[out("mortified", [say("actor", "swapphone_mortified", to="target", delay=1.6), emote("actor", "sweat", delay=1.6), stress("actor", 10),
                                  chain("ivm_secret", delay=4, roles={"actor": "target"})], score=[s_const(0.8)]),
                out("cool", [say("actor", "swapphone_cool", to="target", delay=1.6), rel("actor", "target", "trust", 3)], score=[s_trait("actor", "humor", 0.8)])])
iv("F01", "swap_phones", title="Swap their mobile with someone's identical one", desc="Pick whose. One of them will read a message that wasn't for them.",
   log="The ghost swapped {owner}'s mobile with {target}'s.", **PH, needs="person", icon="phone", pick=[c_present("self")],
   vars=private_vars("owner"), state=private_info("owner") + [oset("ws.{owner}.phone_swap", "%target")],
   react=[chain("iv_swapphone_read", delay=4), pair_trap("iv_swapphone_back", "owner", "target", key="swapphone_{owner}", r=2.4)])

# --- F02 fake caller ID ----------------------------------------------------------------------
L("callerid_mom", ["MUM?! Not now, Mum! I'm at WORK!", "Mum, I love you, but I'm in the middle of— hello? Mum?"])
L("callerid_ex", ["...Why is my EX calling me?", "My ex. Calling me. In the office. Great."])
L("callerid_headhunter", ["A recruiter? Calling me HERE?", "'Talent Partners Ltd'? ...I'll take this outside."])
L("callerid_boss", ["It's Ahmet! Yes, Ahmet Bey? ...Hello? ...He hung up.", "Ahmet's calling from his desk? Why not just shout?"])
L("callerid_heard_hh", ["Was that a recruiter calling {owner}?", "Hm. {owner} just got a call from a headhunter."])
L("callerid_jealous", ["Who was THAT on the phone?", "Your ex? Calling you? Today?"])
S_("log.callerid_mom", "{owner}'s phone rang — 'Mum' — right in the middle of work. Everyone heard.")
S_("log.callerid_ex", "{owner}'s phone lit up with their ex's name. Someone noticed.")
S_("log.callerid_hh", "{owner}'s phone rang: 'Talent Partners — recruiter'. People nearby put two and two together.")
S_("log.callerid_boss", "{owner}'s phone showed a call from Ahmet. Nobody was on the line.")
scene("iv_callerid", noise=0.4, allow_absent=True, conditions=[c_present("owner")],
      effects=ring("owner"),
      outcomes=[out("mom", [say("owner", "callerid_mom", delay=1), emote("owner", "sweat", delay=1), witness([say("self", "witness_laugh", p=0.4, delay=2.5)], near="owner", r=5),
                            log("log.callerid_mom", 2, "prank")], score=[s_const(5)], when=[c_var("choice", eq="mom")]),
                out("ex", [say("owner", "callerid_ex", delay=1), log("log.callerid_ex", 2, "romance"),
                           each([say("self", "callerid_jealous", p=0.8, delay=2.5), rel("self", "owner", "suspicion", 12)], exclude=["owner"],
                                where=[c_any(c_bond("self", "owner", "romance"), c_rel("self", "owner", "romance", gt=40)), c_near("self", "owner", 7)])],
                    score=[s_const(5)], when=[c_var("choice", eq="ex")]),
                out("hh", [say("owner", "callerid_headhunter", delay=1), rumor("job_hunting", a="owner", b="owner", juicy=0.7, truth=False, knowers=[]),
                           witness([learn("self", "$rumor", c=0.7), say("self", "callerid_heard_hh", p=0.4, delay=2.5)], near="owner", r=5),
                           log("log.callerid_hh", 3, "rumor")], score=[s_const(5)], when=[c_var("choice", eq="headhunter")]),
                out("boss", [say("owner", "callerid_boss", delay=1), emote("owner", "question", delay=2), ghost(), log("log.callerid_boss", 2, "ghost")],
                    score=[s_const(5)], when=[c_var("choice", eq="boss")])])
iv("F02", "caller_id", title="Fake who's calling them", desc="Their phone rings. The screen shows a name of your choice.",
   log="The ghost spoofed the caller ID on {owner}'s phone.", **PH, needs="choice", icon="phone",
   choices=[choice("mom", "'Mum'"), choice("ex", "Their ex"), choice("headhunter", "A headhunter"), choice("boss", "Ahmet")],
   conds=[r_present()], state=[oset("ws.{owner}.callerid", "$choice")], react=[chain("iv_callerid", delay=2)])

# --- F03 change their ringtone ----------------------------------------------------------------------
L("ringtone_siren", ["*WEE-OOO WEE-OOO*", "*AIR RAID SIREN*"])
L("ringtone_love", ["♪ I will always love yoooou ♪", "♪ Baby, baby, baby, ooh ♪"])
L("ringtone_baby", ["*WAAAAH WAAAAH*", "*baby crying loudly*"])
L("ringtone_react", ["Who has a SIREN for a ringtone?!", "Is someone's phone... crying?", "Is that a LOVE SONG coming from {owner}'s pocket?"],
  ahmet=["Whose phone is that?! Turn it OFF!"])
L("ringtone_owner", ["That's not my ringtone! Make it stop!", "I didn't choose that! I swear!"])
S_("log.iv_ringtone", "{owner}'s phone rang with a brand-new ringtone. The whole floor heard it.")
scene("iv_ringtone", noise=0.4, allow_absent=True, conditions=[c_present("owner")],
      effects=ring("owner") + [say("owner", "ringtone_siren", when=[c_var("choice", eq="siren")]), say("owner", "ringtone_love", when=[c_var("choice", eq="love")]),
                               say("owner", "ringtone_baby", when=[c_var("choice", eq="baby")]), say("owner", "ringtone_owner", delay=2.2), emote("owner", "sweat", delay=2.2),
                               witness([say("self", "ringtone_react", p=0.5, delay=1.2), stress("self", 3, when=[c_var("choice", eq="siren")])], near="owner", r=6),
                               rumor("crush", a="owner", b="owner", juicy=0.3, truth=False, knowers=[], when=[c_var("choice", eq="love")]),
                               log("log.iv_ringtone", 2, "prank"), call("scold", target="owner", reason="general", prio=55, delay=4,
                                                                    when=[c_act("owner", ["meeting"]), c_meeting("started", True)])])
iv("F03", "ringtone", title="Change their ringtone", desc="Their next call will ring with... this.",
   log="The ghost changed {owner}'s ringtone.", **PH, needs="choice", icon="sound",
   choices=[choice("siren", "Air-raid siren"), choice("love", "A soppy love song"), choice("baby", "A crying baby")],
   state=[oset("ws.{owner}.ringtone", "$choice")], react=[chain("iv_ringtone", delay=12)])

# --- F04 forward their calls to someone else ----------------------------------------------------------
L("fwdcall_answer", ["Hello, {owner}'s phone... er, MY phone... Hello?", "Yes, this is— no, I'm not {owner}. But I can help!"])
L("fwdcall_help", ["I took a client call for you. Here's the message.", "Your client called me by mistake. I sorted it out for you."])
L("fwdcall_thanks", ["You did? Thank you!", "That's... really nice of you."])
L("fwdcall_steal", ["A client looking for {owner}? ...I'll handle this personally.", "Hm. {owner}'s client. My client now."], deniz=["Opportunity knocks. Literally."])
L("fwdcall_owner_finds", ["My client says they've been dealing with {target}?!", "{target} took my client?!"])
S_("log.fwdcall_help", "{owner}'s calls were going to {target}. {target} handled a client call and passed the message on.")
S_("log.fwdcall_steal", "{owner}'s calls were going to {target} — and {target} quietly kept {owner}'s client for themselves.")
scene("iv_fwdcall", noise=0.8, allow_absent=True, conditions=[c_present("target")],
      effects=ring("target") + [say("target", "fwdcall_answer", delay=1), act("target", "phone", dur=4)],
      outcomes=[out("help", [visit("target", "owner", "iv_fwdcall_help", prio=56, ttl=50, delay=4), log("log.fwdcall_help", 2, "help")],
                    score=[s_trait("target", "empathy", 1.0), s_aff("target", "owner", 0.02)], when=[c_present("owner")]),
                out("steal", [say("target", "fwdcall_steal", delay=2), favor("target", 6), favor("owner", -4),
                              rumor("credit_steal", a="target", b="owner", juicy=0.8, knowers=["target"], key="fact"), log("log.fwdcall_steal", 4, "scheme"),
                              chain("iv_fwdcall_owner", delay=40)],
                    score=[s_trait("target", "cunning", 1.2), s_rel("target", "owner", "rivalry", 0.02), s_trait("target", "honesty", -0.8)])])
scene("iv_fwdcall_help", conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4), say("actor", "fwdcall_help", to="target"), say("target", "fwdcall_thanks", to="actor", delay=1.6),
               rel("target", "actor", "friendship", 8), rel("target", "actor", "trust", 6), mem("target", "actor", "helped_me", 0.5, 0.7, "mem.helped_me", 2)])
scene("iv_fwdcall_owner", allow_absent=True, conditions=[c_present("owner")],
      effects=[expr("owner", "angry", 6), say("owner", "fwdcall_owner_finds"), learn("owner", "$fact", c=1.0), rel("owner", "target", "resentment", 22),
               mem("owner", "target", "credit_stolen", -0.8, 0.9, "mem.author_credit", 3), plan("owner", "revenge", "target", heat=1.0),
               visit("owner", "target", "ivm_accuse", prio=62, ttl=50, delay=2, when=[c_present("target")])])
iv("F04", "forward_calls", title="Forward their calls to someone else", desc="Pick who answers their phone today. Their clients included.",
   log="The ghost forwarded {owner}'s calls to {target}.", **PH, needs="person", icon="redirect", owners=["selin", "mert", "deniz", "ceren", "zeynep"],
   pick=[c_present("self")], state=[oset("ws.{owner}.forward", "%target")], react=[chain("iv_fwdcall", delay=8)])

# --- F05 show their message notification on someone else's phone ----------------------------------------
L("notif_preview", ["Huh — a preview popped up: '{owner}: can't stand {worst} today'...", "Why am I getting {owner}'s notifications? '...{worst} is SO annoying.'"])
L("notif_preview_hurt", ["...{owner} can't stand me?", "Oh. So that's what {owner} says about me."])
S_("log.notif_preview", "{owner}'s message preview — complaining about {worst} — popped up on {target}'s phone.")
scene("iv_notif_preview", allow_absent=True, conditions=[c_present("target")],
      effects=ring("target") + [learn("target", "$fact", c=1.0), log("log.notif_preview", 3, "secret", who=["target", "owner"])],
      outcomes=[out("me", [say("target", "notif_preview_hurt", delay=1.2), expr("target", "sad", 5, delay=1.2), rel("target", "owner", "resentment", 15),
                           rel("target", "owner", "friendship", -10), mood("target", -8)], score=[s_const(5)], when=[c_same("target", "$worst")]),
                out("other", [say("target", "notif_preview", delay=1.2), chain("ivm_secret", delay=2, roles={"actor": "target"})], score=[s_const(1)])])
iv("F05", "notif_elsewhere", title="Show their message preview on someone else's phone", desc="Pick whose phone. The preview isn't kind.",
   log="The ghost mirrored {owner}'s message notifications to {target}'s phone.", **PH, needs="person", icon="phone", pick=[c_present("self")],
   vars=[var("worst", "worst_of", of="owner", lim=15, avail=False, why="why.no_grudge")],
   state=[rumor("dislikes", a="owner", b="$worst", juicy=0.6, knowers=["owner"], key="fact"), oset("ws.{owner}.mirror", "%target")],
   react=[chain("iv_notif_preview", delay=3)])

# --- F06 hide their phone in the fridge ---------------------------------------------------------------------
L("fridgephone_lost", ["My phone. Where's my phone? It was RIGHT HERE.", "Has anyone seen my phone?!"])
L("fridgephone_found", ["...It's in the FRIDGE. Next to the milk. It's FREEZING.", "My phone is in the fridge. Why is my phone in the fridge?!"])
S_("log.fridgephone", "{actor}'s phone vanished from their desk and turned up in the office fridge. Chilled.")
scene("iv_fridgephone", effects=[expr("actor", "surprised", 4), say("actor", "fridgephone_lost"), stress("actor", 8),
                                 hunt("actor", ["printer", "archive", "kitchen"], "iv_fridgephone_end", prio=64, ttl=60)])
scene("iv_fridgephone_end", noise=0.8, allow_absent=True, conditions=[c_present("actor")],
      vars=[var("suspect", "suspect", loc="kitchen", optional=True)],
      effects=[say("actor", "fridgephone_found"), emote("actor", "question"), log("log.fridgephone", 2, "prank"),
               witness([say("self", "witness_laugh", p=0.5, delay=1.8)], r=4)],
      outcomes=[O_blame(), O_ghost(), O_shrug()])
iv("F06", "phone_in_fridge", title="Hide their phone in the fridge", desc="Next to the milk. They'll look everywhere else first.",
   log="The ghost hid {owner}'s phone in the office fridge.", **PH, icon="phone", state=[oset("ws.{owner}.phone_at", "fridge")],
   react=[desk_trap("iv_fridgephone", "fridgephone_{owner}")])

# --- F07 create a misleading reminder ---------------------------------------------------------------------------
L("remind_flowers", ["'Reminder: buy flowers for {crush}'? Did I set that?", "My phone says I should buy {crush} flowers. ...Should I?"])
L("remind_gym", ["'Gym — 16:30 — DON'T SKIP'. Okay, phone. Okay.", "Gym reminder. I guess I'm leaving early!"])
L("remind_raise", ["'TODAY: ask Ahmet for a raise.' ...You know what? Yes.", "Phone says: ask for a raise. The phone is right."])
L("flowers_give", ["These are for you. Don't ask why. Even I don't know.", "I got you flowers. My phone told me to. That sounds weird."])
L("flowers_love", ["For me? ...That's really sweet.", "Flowers! Nobody's ever— thank you."])
L("flowers_awkward", ["...Thanks? Is this a joke?", "Oh. Um. Flowers. Okay."])
L("raise_ask_line", ["Ahmet Bey, I'd like a raise. Today.", "I've decided I deserve a raise. Can we talk?"])
S_("log.remind_flowers_love", "A mystery phone reminder told {owner} to buy {crush} flowers. {owner} did. {crush} loved it.")
S_("log.remind_flowers_awk", "A mystery phone reminder told {owner} to buy {crush} flowers. It was... awkward.")
S_("log.remind_gym", "{owner}'s phone told them they had the gym at 16:30. They left early.")
S_("log.remind_raise", "A phone reminder told {owner} to ask for a raise today. So {owner} marched into Ahmet's office.")
scene("iv_remind", noise=0.4, allow_absent=True, conditions=[c_present("owner")],
      effects=ring("owner"),
      outcomes=[out("flowers", [say("owner", "remind_flowers", delay=1), away("owner", 15, "flowers", delay=2),
                                trap("iv_flowers_back", kind="on", on="returned", who="owner", key="flowers_{owner}", roles={"owner": "owner", "crush": "crush"})],
                    score=[s_const(5)], when=[c_var("choice", eq="flowers"), c_filled("crush")]),
                out("gym", [say("owner", "remind_gym", delay=1), npcval("owner", "leave_at", v=450), log("log.remind_gym", 2, "work")],
                    score=[s_const(5)], when=[c_var("choice", eq="gym")]),
                out("raise", [say("owner", "remind_raise", delay=1), visit("owner", "@ahmet", "iv_remind_raise", prio=60, ttl=60, delay=2), log("log.remind_raise", 2, "promotion")],
                    score=[s_const(5)], when=[c_var("choice", eq="raise"), c_present("@ahmet")])])
scene("iv_flowers_back", allow_absent=True, conditions=[c_present("owner"), c_present("crush")],
      effects=[visit("owner", "crush", "iv_flowers_give", prio=62, ttl=60, delay=1)])
scene("iv_flowers_give", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "flowers_give", to="target")],
      outcomes=[out("love", [say("target", "flowers_love", to="actor", delay=1.6), emote("target", "love", delay=1.6), emote("actor", "love", delay=2.4),
                             rel("target", "actor", "romance", 15), rel("actor", "target", "romance", 8), mem("target", "actor", "flowers", 0.7, 0.9, "mem.got_flowers", 3),
                             rumor("crush", a="actor", b="target", juicy=0.7, knowers=[]), witness([learn("self", "$rumor")], r=5),
                             log("log.remind_flowers_love", 3, "romance", who=["actor", "target"])],
                    score=[s_rel("target", "actor", "romance", 0.04), s_aff("target", "actor", 0.01)]),
                out("awkward", [say("target", "flowers_awkward", to="actor", delay=1.6), emote("actor", "sweat", delay=1.6), mood("actor", -6),
                                log("log.remind_flowers_awk", 2, "romance", who=["actor", "target"])], score=[s_const(0.6)])])
S_("mem.got_flowers", "{actor} brought me flowers.")
scene("iv_remind_raise", noise=0.6, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "raise_ask_line", to="target")],
      outcomes=[out("yes", [say("target", "promise_honour", to="actor", delay=1.6), favor("actor", 3), morale("actor", 8), emote("actor", "cheer", delay=1.8)],
                    score=[{"s": "favor", "who": "actor", "w": 0.04}]),
                out("no", [say("target", "promise_dodge", to="actor", delay=1.6), morale("actor", -5), rel("actor", "target", "resentment", 6)], score=[s_const(2.4)])])
iv("F07", "fake_reminder", title="Add a misleading reminder to their phone", desc="Their phone will tell them to do something. Will they?",
   log="The ghost set a mysterious reminder on {owner}'s phone.", **PH, needs="choice", icon="calendar", owners=NOT_BOSS,
   choices=[choice("flowers", "'Buy flowers for (their crush)'", ), choice("gym", "'Gym at 16:30 — leave early'"), choice("raise", "'Ask Ahmet for a raise TODAY'")],
   conds=[r_present(), r_time(before="15:00")], vars=[var("crush", "crush_of", of="owner", role=True, optional=True)],
   state=[oset("ws.{owner}.reminder", "$choice")], react=[chain("iv_remind", delay=6)])

# --- F08 delay an important client callback ----------------------------------------------------------------
L("callback_late", ["The client called back — an HOUR late — and the deal's gone.", "They signed with a competitor. Because I missed one call?!"])
L("callback_boss", ["You LOST the client, {owner}?!", "One call. You missed ONE call and we lost the account?"])
S_("log.callback", "An important client callback reached {owner} an hour late. The deal went to a competitor.")
scene("iv_callback_lost", allow_absent=True, conditions=[c_present("owner")],
      effects=ring("owner") + [expr("owner", "sad", 6, delay=1.2), say("owner", "callback_late", delay=1.2), mood("owner", -14), morale("owner", -6), favor("owner", -8),
                               say("@ahmet", "callback_boss", delay=4, when=[c_present("@ahmet")]), call("scold", target="owner", reason="general", prio=64, delay=6),
                               log("log.callback", 4, "work")])
iv("F08", "delay_callback", title="Delay an important client callback", desc="The client calls back — an hour too late.",
   log="The ghost delayed a client's callback to {owner}.", **PH, icon="phone", owners=["mert", "selin", "deniz"],
   conds=[r_present(), r_present("@ahmet")], state=[oset("ws.{owner}.callback", "delayed")], react=[chain("iv_callback_lost", delay=30)])

# --- F09 deliver their voicemail to the wrong person -----------------------------------------------------------
L("vm_listen", ["A voicemail from {owner}? For... me? Let's hear it.", "'New voicemail from {owner}.' Hm."])
L("vm_confession", ["...{owner} says they LIKE me?!", "Wait. Was that... a love confession? From {owner}?"])
L("vm_secret", ["...I wasn't supposed to hear that.", "Oh no. That was private."])
S_("log.vm_confession", "{owner} recorded a voicemail practising a confession to {crush}. It reached {crush}.")
S_("log.vm_secret", "A private voicemail from {owner} ended up in {target}'s mailbox.")
scene("iv_voicemail", allow_absent=True, conditions=[c_present("target"), {"c": "fact_exists", "fact": "$fact"}],
      effects=ring("target") + [say("target", "vm_listen", delay=1), act("target", "phone", dur=4)],
      outcomes=[out("confession", [say("target", "vm_confession", delay=3), emote("target", "love", delay=3), learn("target", "$fact", c=1.0),
                                   rel("target", "owner", "romance", 18, when=[c_rel("target", "owner", "romance", gt=10)]), rel("target", "owner", "friendship", 6),
                                   log("log.vm_confession", 4, "romance", who=["owner", "target"]),
                                   visit("target", "owner", "ivm_misattrib", prio=58, ttl=50, delay=4, when=[c_present("owner")]), setv("what", "voicemail")],
                    score=[s_const(5)], when=[c_same("target", "$crush")]),
                out("secret", [say("target", "vm_secret", delay=3), learn("target", "$fact", c=1.0), reveal("$fact"), log("log.vm_secret", 3, "secret", who=["owner", "target"]),
                               chain("ivm_secret", delay=2, roles={"actor": "target"})], score=[s_const(1)])])
what("voicemail", "that voicemail")
iv("F09", "voicemail_wrong", title="Deliver their voicemail to the wrong person", desc="Something private they recorded. Pick who hears it.",
   log="The ghost redirected {owner}'s private voicemail to {target}.", **PH, needs="person", icon="sound", pick=[c_present("self")],
   vars=private_vars("owner"), state=private_info("owner") + [oset("ws.{owner}.voicemail", "%target")], react=[chain("iv_voicemail", delay=4)])

# --- F10 make them call back the wrong person -------------------------------------------------------------------
L("wrongcb_call", ["Hi, returning your call— {target}?! YOU called me?", "Hello? Oh. It's... you."])
L("wrongcb_chat", ["Well, since we're on the phone... how are you, really?", "Ha. Okay, since I've got you — lunch sometime?"])
L("wrongcb_fight", ["I didn't call you. Why would I call you?", "Is this some kind of joke?"])
S_("log.wrongcb_chat", "{owner} returned a 'missed call' — it was {target}'s number. They ended up chatting for ages.")
S_("log.wrongcb_fight", "{owner} returned a 'missed call' to {target}. Neither had called. It got snippy.")
scene("iv_wrongcb", noise=0.8, allow_absent=True, conditions=[c_present("owner"), c_present("target")],
      effects=[act("owner", "phone", dur=5), act("target", "phone", dur=5)] + ring("target") + [say("owner", "wrongcb_call", delay=1.5)],
      outcomes=[out("chat", [say("target", "wrongcb_chat", delay=3), rel("owner", "target", "friendship", 8, both=True), call("lunch_sync", who="owner", target="target"),
                             log("log.wrongcb_chat", 2, "friendship")], score=[s_aff("target", "owner", 0.02), s_trait("target", "sociability", 0.6)]),
                out("fight", [say("target", "wrongcb_fight", delay=3), rel("owner", "target", "friendship", -5, both=True), log("log.wrongcb_fight", 2, "conflict")],
                    score=[s_rel("target", "owner", "rivalry", 0.03), s_trait("target", "temper", 0.5)])])
iv("F10", "wrong_callback", title="Make them call back the wrong person", desc="Their 'missed call' list now shows someone else's number. Pick whose.",
   log="The ghost put {target}'s number in {owner}'s missed calls.", **PH, needs="person", icon="phone", pick=[c_present("self"), c_avail("self")],
   conds=[r_present()], state=[oset("ws.{owner}.missed", "%target")], react=[chain("iv_wrongcb", delay=5)])

# --- F11 switch their phone to speaker ---------------------------------------------------------------------------
L("speaker_call", ["*on speaker* '...Yes Mum, I'm eating vegetables.'", "*on speaker* '...and then I told them I'd never seen that file. Ha!'"])
L("speaker_realise", ["...Why is everyone looking at me? Oh no. SPEAKER.", "It's on SPEAKER?!"])
S_("log.speaker", "{owner}'s personal call played on speakerphone. Everyone nearby heard every word.")
scene("iv_speaker", allow_absent=True, conditions=[c_present("owner")],
      effects=ring("owner") + [act("owner", "phone", dur=4), say("owner", "speaker_call", delay=1.5), say("owner", "speaker_realise", delay=3.5),
                               expr("owner", "surprised", 5, delay=3.5), emote("owner", "sweat", delay=3.5),
                               witness([learn("self", "$fact", c=0.9, when=[{"c": "fact_exists", "fact": "$fact"}]), say("self", "witness_laugh", p=0.4, delay=2.5)],
                                       near="owner", r=5.5),
                               log("log.speaker", 3, "secret")])
iv("F11", "speakerphone", title="Switch their phone to speaker", desc="Their next personal call: broadcast to everyone nearby.",
   log="The ghost switched {owner}'s phone to speaker mode.", **PH, icon="sound", conds=[r_present()],
   vars=private_vars("owner"), state=private_info("owner") + [oset("ws.{owner}.speaker")], react=[chain("iv_speaker", delay=8)])

# --- F12 Do Not Disturb ----------------------------------------------------------------------------------------
L("dnd_boss", ["I've called you FOUR TIMES, {target}!", "Why aren't you answering your phone, {target}?!"])
L("dnd_explain", ["What? It never rang! Look — Do Not Disturb? I didn't turn that on!", "My phone didn't ring once!"])
L("dnd_scold", ["Then fix your phone. I don't chase people.", "Unacceptable. Be reachable."])
L("dnd_ok", ["...Hm. Technology. Fine.", "Get Burak to look at it."])
S_("log.dnd", "Ahmet couldn't reach {target} — their phone was on Do Not Disturb. He stormed over to their desk.")
scene("iv_dnd_storm", allow_absent=True, conditions=[c_present("@ahmet"), c_present("owner")],
      effects=[act("@ahmet", "phone", place="desk_ahmet", dur=3), visit("@ahmet", "owner", "iv_dnd_scene", prio=70, ttl=50, delay=3)])
scene("iv_dnd_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), expr("actor", "angry", 5), say("actor", "dnd_boss", to="target"), say("target", "dnd_explain", to="actor", delay=1.6),
               oset("ws.{target}.dnd", False), log("log.dnd", 3, "boss")],
      outcomes=[out("scold", [say("actor", "dnd_scold", to="target", delay=3.2), favor("target", -4), rel("target", "actor", "resentment", 6)], score=[s_trait("actor", "temper", 1.0)]),
                out("ok", [say("actor", "dnd_ok", to="target", delay=3.2)], score=[s_rel("actor", "target", "trust", 0.02), s_const(0.3)])])
iv("F12", "do_not_disturb", title="Put their phone on Do Not Disturb", desc="Ahmet's about to call them. Several times.",
   log="The ghost switched {owner}'s phone to Do Not Disturb.", **PH, icon="close", owners=NOT_BOSS,
   conds=[r_present(), r_present("@ahmet")], state=[oset("ws.{owner}.dnd")], react=[chain("iv_dnd_storm", delay=15)])

# --- F13 prank-call Ahmet from their extension ------------------------------------------------------------------
L("prank_boss_pick", ["Hello? ...Hello? Who is this? ...Is someone BREATHING?", "*heavy breathing on the line* ...What on earth?"])
L("prank_boss_see", ["That call came from {owner}'s extension.", "Extension... {owner}. Interesting."])
what("prank_call", "that breathing phone call from your extension")
S_("log.prankcall", "Ahmet got a heavy-breathing prank call. The display said it came from {owner}'s extension.")
scene("iv_prankcall", allow_absent=True, conditions=[c_present("@ahmet"), c_present("owner")],
      effects=[act("@ahmet", "phone", place="desk_ahmet", dur=3), sfx("phone"), say("@ahmet", "prank_boss_pick", delay=1), say("@ahmet", "prank_boss_see", delay=3),
               expr("@ahmet", "angry", 5, delay=3), rel("@ahmet", "owner", "suspicion", 18), setv("what", "prank_call"), summon("owner", "ivm_boss_talk", delay=5),
               log("log.prankcall", 3, "boss", who=["owner"])])
iv("F13", "prank_boss", title="Prank-call Ahmet from their extension", desc="Heavy breathing. Ahmet's phone shows exactly where it came from.",
   log="The ghost prank-called Ahmet from {owner}'s desk phone.", **PH, icon="phone", owners=NOT_BOSS,
   conds=[r_present(), r_present("@ahmet")], state=[oset("ws.{owner}.prank_call")], react=[chain("iv_prankcall", delay=2)])

# --- F14 scramble the reception switchboard (Ceren's desk) --------------------------------------------------------
L("switch_wrong", ["Hello? ...No, this isn't accounting. Why does everyone think I'm accounting?", "Wrong desk AGAIN. Ceren, the phones are possessed!"])
L("switch_ceren", ["The switchboard's gone mad! I didn't touch it!", "Every call is going to the wrong desk. Every. Single. One."])
L("switch_overhear", ["...Wait, that call was for {intended}. And it was VERY interesting.", "I just took a call meant for {intended}. Oh, the things I heard."])
S_("log.switch", "The reception switchboard went haywire. Calls are landing on the wrong desks all over the office.")
S_("log.switch_heard", "{actor} took a call meant for {intended} — and learned something they shouldn't have.")
scene("iv_switch_start", allow_absent=True, conditions=[c_present("@ceren")],
      effects=[say("@ceren", "switch_ceren"), stress("@ceren", 12), expr("@ceren", "surprised", 5), log("log.switch", 3, "malfunction"),
               each([say("self", "switch_wrong", p=0.6, delay=1.0), emote("self", "phone"), stress("self", 3)], exclude=["@ceren"], stagger=2.5,
                    where=[c_chance(0.5)])],
      outcomes=[out("juicy", [chain("iv_switch_juicy", delay=5)], score=[s_const(1)])])
ev(id="iv_switch_juicy", trigger="", priority=55,
   roles=[role("actor", where=[c_avail("self")], score=[s_trait("self", "curiosity", 1.0), s_trait("self", "gossip", 0.8), s_rand(0.3)], exclude=[])],
   vars=[var("intended", "worst_of", of="actor", lim=99, avail=False)],
   effects=[sfx("phone"), act("actor", "phone", dur=4), say("actor", "switch_overhear", delay=1.5),
            rumor("interview", a="$intended", b="actor", juicy=0.7, truth=False, knowers=["actor"], c=0.6, key="fact", when=[c_chance(0.5)]),
            rumor("crush", a="$intended", b="$intended", juicy=0.5, truth=False, knowers=["actor"], c=0.6, key="fact", when=[{"c": "rolefilled", "who": "$fact", "not": True}]),
            log("log.switch_heard", 3, "secret", who=["actor", "$intended"]), chain("ivm_secret", delay=2, roles={"actor": "actor"})])
iv("F14", "scramble_switchboard", title="Scramble the reception switchboard", desc="Every incoming call goes to the wrong desk for an hour.",
   log="The ghost scrambled the reception switchboard.", **PH, icon="redirect", owners=["ceren"], absent_ok=True,
   state=[oset("ws.ceren.switchboard", "scrambled"), oset("ws.ceren.switchboard", "", delay=60)], react=[chain("iv_switch_start", delay=2)])

# --- F15 change the hold music (Ceren's desk) ------------------------------------------------------------------------
L("hold_client", ["The client says our hold music is 'heavy metal screaming'?!", "A client hung up because of the hold music. It's a break-up ballad?!"])
L("hold_boss", ["Ceren! Our hold music is driving clients away!", "WHO changed the hold music?"])
L("hold_ceren", ["I didn't change anything! I swear!", "That's not what I set! Someone's been in my system."])
S_("log.holdmusic", "Clients on hold were treated to {what}. Ahmet blamed Ceren.")
what("hold_metal", "screaming heavy metal")
what("hold_ballad", "a sobbing break-up ballad")
scene("iv_holdmusic", allow_absent=True, conditions=[c_present("@ahmet")],
      effects=[act("@ahmet", "phone", place="desk_ahmet", dur=3), say("@ahmet", "hold_client", delay=1), expr("@ahmet", "angry", 5, delay=1),
               visit("@ahmet", "@ceren", "iv_holdmusic_scene", prio=62, ttl=50, delay=3, when=[c_present("@ceren")]), log("log.holdmusic", 3, "work")])
scene("iv_holdmusic_scene", conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 4.5), say("actor", "hold_boss", to="target"), say("target", "hold_ceren", to="actor", delay=1.6),
               rel("actor", "target", "trust", -6), stress("target", 8), rel("target", "actor", "resentment", 5)])
iv("F15", "hold_music", title="Change the hold music", desc="Callers waiting on hold will hear something... unexpected.",
   log="The ghost changed the reception hold music.", **PH, needs="choice", icon="music", owners=["ceren"], absent_ok=True,
   choices=[choice("metal", "Screaming heavy metal"), choice("ballad", "A sobbing break-up ballad")],
   conds=[r_present("@ahmet")], state=[oset("ws.ceren.hold_music", "$choice"), setf("what", "hold_{choice}")], react=[chain("iv_holdmusic", delay=18)])

# --- F16 slip someone's phone into another person's coat ---------------------------------------------------------------
L("coatphone_ring", ["...Why is {coat}'s jacket RINGING with MY ringtone?", "That's my phone! In {coat}'s coat pocket!"])
L("coatphone_accuse", ["Why is my phone in YOUR coat, {target}?!", "Explain how my phone got in your pocket, {target}."])
L("coatphone_innocent", ["I have no idea! I haven't touched my coat all day!", "What?! I didn't take your phone!"])
S_("log.coatphone", "{target}'s missing phone rang — from inside {coat}'s coat on the rack. Accusations followed.")
scene("iv_coatphone", allow_absent=True, conditions=[c_present("target"), c_present("coat")],
      effects=[sfx("phone"), say("target", "coatphone_ring"), expr("target", "angry", 5), rel("target", "coat", "suspicion", 25), rel("target", "coat", "trust", -10),
               rumor("prank", a="coat", b="target", juicy=0.5, truth=False, knowers=["target"]), witness([learn("self", "$rumor")], near="target", r=5),
               log("log.coatphone", 3, "conflict", who=["target", "coat"]),
               visit("target", "coat", "iv_coatphone_scene", prio=62, ttl=50, delay=2)])
scene("iv_coatphone_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "coatphone_accuse", to="target"), say("target", "coatphone_innocent", to="actor", delay=1.6),
               mem("target", "actor", "falsely_accused", -0.5, 0.8, "mem.ivm_falsely_accused", 2)],
      outcomes=[out("argue", [say("actor", "ivm_accuse_argue", to="target", delay=3.2), stat("arguments"), rel("actor", "target", "friendship", -8, both=True)],
                    score=[s_trait("actor", "temper", 1.0)]),
                out("believe", [say("actor", "ivm_accuse_sorry", to="target", delay=3.2), rel("actor", "target", "suspicion", -15)], score=[s_trait("actor", "empathy", 0.8)])])
iv("F16", "phone_in_coat", title="Slip someone's phone into another person's coat", desc="Pick whose phone. It'll ring from the wrong pocket.",
   log="The ghost slipped {target}'s phone into a coat on the rack.", obj="coat_rack", cat="F", needs="person", icon="phone", pick=[c_present("self")],
   state=[pick_role("coat", "rival_of", of="target", lim=-1), pick_role("coat", "worst_of", keep=True, of="target", lim=99), oset("coats.phone", "%target")],
   react=[chain("iv_coatphone", delay=10)])

# --- F17 send "we need to talk" from their phone ---------------------------------------------------------------------
L("wntt_read", ["'We need to talk.' From {owner}. ...Oh no.", "'We need to talk'?! What did I do?"])
L("wntt_ask", ["You wanted to talk? I'm here. Just say it.", "Okay. I'm ready. What's wrong?"])
L("wntt_confused", ["Talk? About what? I never sent that!", "What? I didn't text you anything!"])
L("wntt_confess", ["...Okay, maybe I DO need to say something. I like you. A lot.", "Since you're here... I've wanted to tell you something for a while."])
L("wntt_relief", ["Oh thank god. I thought you were breaking up with me!", "Phew! I've been panicking for an hour!"])
S_("log.wntt_confess", "A 'we need to talk' text from {owner}'s phone led to an unexpected confession to {crush}.")
S_("log.wntt_relief", "{crush} spent an hour panicking over a 'we need to talk' text from {owner}. {owner} never sent it.")
scene("iv_wntt_read", allow_absent=True, conditions=[c_present("crush")],
      effects=ring("crush") + [expr("crush", "surprised", 5, delay=1), say("crush", "wntt_read", delay=1), stress("crush", 12),
                               visit("crush", "owner", "iv_wntt_scene", prio=62, ttl=60, delay=4, when=[c_present("owner")])])
scene("iv_wntt_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5.5), say("actor", "wntt_ask", to="target")],
      outcomes=[out("confess", [say("target", "wntt_confess", to="actor", delay=1.8), emote("target", "love", delay=1.8), rel("actor", "target", "romance", 12, both=True),
                                emote("actor", "love", delay=3), log("log.wntt_confess", 4, "romance")],
                    score=[s_rel("target", "actor", "romance", 0.04), s_rel("actor", "target", "romance", 0.02)], when=[c_rel("target", "actor", "romance", gt=30)]),
                out("relief", [say("target", "wntt_confused", to="actor", delay=1.8), say("actor", "wntt_relief", to="target", delay=3.4), stress("actor", -8),
                               rel("actor", "target", "friendship", 4), log("log.wntt_relief", 3, "misunderstanding")], score=[s_const(1)])])
iv("F17", "we_need_to_talk", title="Text 'we need to talk' from their phone", desc="To the person they have feelings for.",
   log="The ghost texted 'We need to talk.' from {owner}'s phone to {crush}.", **PH, icon="phone",
   vars=[var("crush", "crush_of", of="owner", role=True, why="why.no_crush")], state=[oset("ws.{owner}.wntt", "%crush")], react=[chain("iv_wntt_read", delay=3)])
S_("why.no_crush", "They don't have a crush on anyone who's here.")

# --- F18 set their phone alarm to go off in the meeting ------------------------------------------------------------
L("alarm_ring", ["*BEEP BEEP BEEP* 'WAKE UP! WAKE UP!'", "*phone alarm: 'TIME FOR YOUR NAP!'*"])
L("alarm_boss", ["Is that a PHONE ALARM in my meeting?!", "Whose phone is screaming 'wake up'?!"])
L("alarm_owner", ["That's not— I didn't set that!", "Sorry! Sorry! I don't know how to turn it off!"])
S_("log.alarm_meeting", "{owner}'s phone alarm went off mid-meeting: 'WAKE UP! WAKE UP!' Ahmet was not amused.")
scene("iv_alarm_meeting", allow_absent=True, conditions=[c_present("owner")],
      effects=[sfx("phone"), emote("owner", "phone"), say("owner", "alarm_ring"), say("@ahmet", "alarm_boss", delay=1.6), say("owner", "alarm_owner", delay=3.2),
               emote("owner", "sweat", delay=3.2), favor("owner", -4), each([mood("self", 3, when=[c_trait("self", "humor", gt=0.5)])], exclude=["owner", "@ahmet"],
               where=[c_act("self", ["meeting"])]), log("log.alarm_meeting", 3, "meeting")])
iv("F18", "meeting_alarm", title="Set their phone alarm for mid-meeting", desc="'WAKE UP! WAKE UP!' — right in the middle of Ahmet's meeting.",
   log="The ghost set {owner}'s phone alarm to go off during the meeting.", **PH, icon="sound", owners=NOT_BOSS,
   conds=[r_meeting_pending(), r_meeting_not_started(), why({"c": "attends", "who": "owner"}, "not_attending")],
   state=[oset("ws.{owner}.alarm")], react=[on_trap("meeting_start", "iv_alarm_meeting", who="@ahmet", key="malarm_{owner}", roles={"owner": "owner"})])

# --- F19 drain their phone battery ----------------------------------------------------------------------------------
L("battery_dead", ["Dead?! It was at 90% an hour ago!", "My phone's DEAD. I need a charger. Now."])
L("battery_borrow", ["Burak's charger! He won't mind. Probably.", "I'll just borrow Burak's charger for a minute."])
S_("log.battery", "{actor}'s phone died out of nowhere. They 'borrowed' Burak's charger without asking.")
scene("iv_battery", allow_absent=True, conditions=[c_present("actor")],
      effects=[expr("actor", "surprised", 4), say("actor", "battery_dead"), stress("actor", 6), say("actor", "battery_borrow", delay=1.6),
               setf("item", "charger"), item_to("charger", "desk_{owner}"), log("log.battery", 2, "work")])
iv("F19", "drain_battery", title="Drain their phone battery", desc="Dead in seconds. They'll need a charger — someone else's.",
   log="The ghost drained {owner}'s phone battery.", **PH, icon="bulb", owners=["selin", "mert", "zeynep", "ece", "deniz", "ceren", "ahmet"],
   conds=[why(c_present("@burak"), "no_burak", "There's no spare charger around.")],
   state=[oset("ws.{owner}.battery", 0)], react=[desk_trap("iv_battery", "battery_{owner}")], watch=["item_missing", "item_found", "foreign_item"])

# --- F20 post their embarrassing photo to the office group chat ---------------------------------------------------------
L("photo_see", ["Is that {owner} at the karaoke night?! Ha!", "That PHOTO of {owner}! The hair! The outfit!", "Who posted {owner} asleep at their desk?!"])
L("photo_owner", ["Who posted that?! DELETE IT!", "That photo was supposed to be gone forever!"])
L("photo_blame", ["I bet {suspect} posted that.", "{suspect}. It has to be {suspect}."])
S_("log.photo", "An embarrassing old photo of {owner} appeared in the office group chat. Everybody has seen it.")
scene("iv_photo", noise=0.6, allow_absent=True, conditions=[c_present("owner")],
      vars=[var("suspect", "worst_of", of="owner", lim=99, optional=True)],
      effects=[each([say("self", "photo_see", p=0.4, delay=1.0), mood("self", 3), rel("self", "owner", "respect", -2)], exclude=["owner"], stagger=0.6, where=[c_chance(0.6)]),
               say("owner", "photo_owner", delay=3), expr("owner", "angry", 6, delay=3), mood("owner", -14), mem("owner", "", "humiliated", -0.6, 0.9, "mem.photo", 3),
               log("log.photo", 3, "prank")],
      outcomes=[out("blame", [say("owner", "photo_blame", delay=4.5), rel("owner", "$suspect", "suspicion", 18), rel("owner", "$suspect", "resentment", 10),
                              visit("owner", "$suspect", "ivm_accuse", prio=60, ttl=50, delay=5, roles={"target": "$suspect"}, when=[c_present("$suspect")])],
                    score=[s_trait("owner", "temper", 1.0)], when=[c_filled("$suspect")]),
                out("laugh", [say("owner", "meow_love", delay=4.5), mood("owner", 8)], score=[s_trait("owner", "humor", 1.2)])])
S_("mem.photo", "Someone posted an embarrassing photo of me to the whole office.")
iv("F20", "group_photo", title="Post their embarrassing photo to the group chat", desc="That one. From the karaoke night.",
   log="The ghost posted an embarrassing photo of {owner} to the office group chat.", **PH, icon="star", conds=[r_present()],
   state=[oset("ws.{owner}.photo")], react=[chain("iv_photo", delay=3)])
