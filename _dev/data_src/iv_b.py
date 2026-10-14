# Interventions — B. Email & messages (desk -> Inbox tab)
from iv_common import *  # noqa: F401,F403

MAIL = dict(obj="ws", tab="mail", cat="B")
NOT_BOSS = ["selin", "mert", "zeynep", "burak", "ece", "deniz", "ceren"]

# --- B03 change the subject of their next email -----------------------------------
L("subj_layoffs_read", ["'URGENT: layoffs'?! From {owner}?!", "Wait, {owner} just emailed everyone about LAYOFFS?"])
L("subj_raise_read", ["'Re: your raise'... {owner} got a RAISE?", "Why does {owner}'s email say 'your raise approved'?"])
L("subj_party_read", ["'Party at my place tonight, everyone welcome!' — {owner}? Count me in!", "{owner}'s throwing a party? I'm there!"])
L("subj_owner_baffled", ["I did NOT write that subject line!", "That's not what I typed! I swear!"])
S_("log.subj_layoffs", "{owner}'s routine email went out with the subject 'URGENT: layoffs'. The office is panicking.")
S_("log.subj_raise", "{owner}'s email went out titled 'Re: your raise'. Now everyone thinks {owner} got one.")
S_("log.subj_party", "{owner}'s email went out titled 'Party at my place tonight!' People are RSVPing. {owner} has no party planned.")
what("layoff_mail", "your 'URGENT: layoffs' email")
scene("iv_subject_sent", allow_absent=True, conditions=[c_present("actor")],
      effects=[sfx("email"), say("actor", "subj_owner_baffled", delay=6), emote("actor", "sweat", delay=6)],
      outcomes=[
          out("layoffs", [rumor("layoffs", a="actor", b="actor", juicy=0.9, truth=False, knowers=[], key="fact"),
                          each([learn("self", "$fact", frm="actor", c=0.6), say("self", "subj_layoffs_read", p=0.35, delay=1.5), stress("self", 6)], exclude=["actor"], stagger=0.5),
                          setv("what", "layoff_mail"), summon("actor", "ivm_boss_talk", delay=8, when=[c_is("actor", "ahmet", neg=True)]),
                          log("log.subj_layoffs", 3, "email")], score=[s_const(5)], when=[c_var("choice", eq="layoffs")]),
          out("raise", [rumor("raise", a="actor", b="actor", juicy=0.7, truth=False, knowers=[], key="fact"),
                        each([learn("self", "$fact", frm="actor", c=0.7), say("self", "subj_raise_read", p=0.3, delay=1.5),
                              rel("self", "actor", "rivalry", 6, when=[c_trait("self", "ambition", gt=0.6)])], exclude=["actor"], stagger=0.5),
                        log("log.subj_raise", 3, "email")], score=[s_const(5)], when=[c_var("choice", eq="raise")]),
          out("party", [each([say("self", "subj_party_read", p=0.5, delay=1.5), rel("self", "actor", "friendship", 3)], exclude=["actor"], stagger=0.5,
                             where=[c_trait("self", "sociability", gt=0.5)]),
                        chain("iv_party_rsvp", delay=6), log("log.subj_party", 3, "email")], score=[s_const(5)], when=[c_var("choice", eq="party")]),
      ])
L("party_rsvp", ["So! Your party! What should I bring?", "Tonight, right? I'm bringing snacks!"], mert=["I'm bringing the speaker. And my moves."])
L("party_cancel", ["About that... there is no party. It was a mistake.", "There's no party! My email got hacked or something!"])
L("party_yes", ["...You know what? Fine. Party at my place. Why not!", "Okay. OKAY. Party's on. Bring chips."])
S_("log.party_cancel", "{target} had to tell {actor} the party doesn't exist. {actor} looked crushed.")
S_("log.party_yes", "{target} gave in: there IS a party tonight now. The office is thrilled.")
S_("mem.party_host", "{target} threw a party for everyone.")
ev(id="iv_party_rsvp", trigger="", priority=55,
   roles=[role("fan", where=[c_avail("self"), c_not(c_same("self", "actor"))], score=[s_trait("self", "sociability", 1.2), s_aff("self", "actor", 0.02)], exclude=["actor"])],
   conditions=[c_present("actor")],
   effects=[visit("fan", "actor", "iv_party_scene", prio=58, ttl=50)])
scene("iv_party_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "party_rsvp", to="target")],
      outcomes=[out("cancel", [say("target", "party_cancel", to="actor", delay=1.6), expr("actor", "sad", 5, delay=1.6), mood("actor", -6),
                               log("log.party_cancel", 2, "misunderstanding")], score=[s_trait("target", "sociability", -1.0), s_stress("target", 0.01), s_const(0.5)]),
                out("yes", [say("target", "party_yes", to="actor", delay=1.6), emote("actor", "cheer", delay=1.8), emote("target", "cheer", delay=1.8),
                            each([rel("self", "target", "friendship", 6), mood("self", 5)], exclude=["target"]),
                            mem("actor", "target", "party", 0.6, 0.8, "mem.party_host", 3), morale("target", 3), log("log.party_yes", 3, "friendship")],
                    score=[s_trait("target", "sociability", 1.2), s_trait("target", "humor", 0.5)])])
iv("B03", "change_subject", title="Change their next email's subject", desc="Their next email to the team goes out with a very different title.",
   log="The ghost edited the subject line of {owner}'s next email.", **MAIL, needs="choice", icon="email",
   choices=[choice("layoffs", "'URGENT: layoffs'"), choice("raise", "'Re: your raise (approved!)'"), choice("party", "'Party at my place tonight!'")],
   state=[oset("ws.{owner}.subject", "$choice")], react=[desk_trap("iv_subject_sent", "subject_{owner}")])

# --- B04 forward their private chat to the person it's about ---------------------
L("fwd_read", ["...{owner} wrote THIS about me?", "Wow. So that's what {owner} really thinks.", "I wasn't supposed to see this, was I."],
  selin=["I knew it. I KNEW {owner} talked about me."], ece=["Oh. Oh no. {owner} doesn't like me?"])
L("fwd_confront", ["I read your little chat about me, {target}.", "You want to say that to my face, {target}?", "Nice chat you had about me."])
L("fwd_sorry", ["I'm sorry. I was venting. I didn't mean it.", "That was a bad day. I'm sorry you saw it."])
L("fwd_double", ["Well, it's true.", "Maybe if you didn't make it so easy..."])
S_("log.fwd_read", "{actor} received a chat {owner} wrote about them. It was not flattering.")
S_("log.fwd_sorry", "{actor} confronted {target} about the forwarded chat. {target} apologised — it helped a little.")
S_("log.fwd_feud", "{actor} confronted {target} about the forwarded chat. {target} doubled down. They're not speaking now.")
S_("mem.fwd_hurt", "{owner} wrote horrible things about me in a chat.")
scene("iv_fwd_read", allow_absent=True, conditions=[c_present("actor")],
      effects=[expr("actor", "sad", 6), emote("actor", "cloud"), say("actor", "fwd_read"), learn("actor", "$fact", c=1.0),
               mem("actor", "owner", "betrayed", -0.6, 0.9, "mem.fwd_hurt", 3), rel("actor", "owner", "resentment", 18), mood("actor", -10),
               log("log.fwd_read", 3, "email", who=["actor", "owner"]),
               visit("actor", "owner", "iv_fwd_confront", prio=60, ttl=60, delay=3, when=[c_trait("actor", "temper", gt=0.35), c_present("owner")])])
scene("iv_fwd_confront", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), expr("actor", "angry", 5), say("actor", "fwd_confront", to="target"), emote("target", "sweat", delay=1.4)],
      outcomes=[out("sorry", [say("target", "fwd_sorry", to="actor", delay=1.8), rel("actor", "target", "resentment", -8), rel("actor", "target", "trust", -4),
                              log("log.fwd_sorry", 2, "conflict")], score=[s_trait("target", "empathy", 1.0), s_trait("target", "honesty", 0.4)]),
                out("feud", [say("target", "fwd_double", to="actor", delay=1.8), sfx("argue", delay=1.8), stat("arguments"), bond("actor", "target", "feud"),
                             rel("actor", "target", "friendship", -14, both=True), log("log.fwd_feud", 4, "conflict")],
                    score=[s_trait("target", "temper", 1.0), s_rel("target", "actor", "rivalry", 0.02), s_trait("target", "forgiveness", -0.5)])])
iv("B04", "forward_chat", title="Forward their private chat to the person it's about", desc="They wrote it to vent. Now the subject will read it.",
   log="The ghost forwarded {owner}'s private chat about {worst} to {worst}.", **MAIL, icon="redirect",
   vars=[var("worst", "worst_of", of="owner", lim=10, avail=False, why="why.no_grudge")],
   conds=[why(c_present("$worst"), "worst_absent", "The person they wrote about isn't here.")],
   state=[rumor("dislikes", a="owner", b="$worst", juicy=0.7, knowers=["owner"], key="fact")],
   react=[trap("iv_fwd_read", place="desk_{worst}", who="$worst", key="fwd_{owner}", roles={"owner": "owner"})])
S_("why.no_grudge", "They don't have anything bad to say about anyone. Yet.")

# --- B05 make Ahmet's reply say "Approved" -----------------------------------------
L("approve_cheer", ["YES! Approved! APPROVED!", "Ahmet said yes! I can't believe it!", "Finally! It's official!"], burak=["...Approved? Huh. Okay. YES."])
L("approve_brag", ["Guess who just got their {what} approved?", "Ahmet approved my {what}! Today's a good day."])
L("approve_boss_what", ["I approved WHAT? I never approved anything!", "There's been no approval. Who told you that?"])
L("approve_crushed", ["But... the email said...", "It said 'Approved'. In writing!"])
S_("log.approve_cheer", "{owner} received an email from Ahmet: 'Approved!' — for a {what} Ahmet never agreed to.")
S_("log.approve_fallout", "Ahmet found out {owner} thinks their {what} was approved. It wasn't. Awkward meeting.")
what("raise", "raise")
what("dayoff", "afternoon off")
scene("iv_approve_found", effects=[expr("actor", "happy", 6), emote("actor", "cheer"), say("actor", "approve_cheer"), mood("actor", 15), morale("actor", 4),
                                   log("log.approve_cheer", 3, "email"),
                                   witness([say("actor", "approve_brag", delay=2.0)], r=4, mx=1),
                                   rumor("raise", a="actor", b="actor", juicy=0.6, truth=False, knowers=[], when=[c_var("choice", eq="raise")]),
                                   witness([learn("self", "$rumor")], r=4.5),
                                   npcval("actor", "leave_at", d=-90, when=[c_var("choice", eq="dayoff")]),
                                   chain("iv_approve_fallout", delay=35)])
scene("iv_approve_fallout", allow_absent=True, conditions=[c_present("@ahmet")],
      effects=[log("log.approve_fallout", 3, "boss", who=["owner"])],
      outcomes=[out("visit", [visit("@ahmet", "owner", "iv_approve_scene", prio=70, ttl=50)], score=[s_const(1)], when=[c_present("owner")]),
                out("tomorrow", [trap("iv_approve_next_day", place="desk_{owner}", who="owner", key="approve_next_{owner}", days=1, after=200)], score=[s_const(0.5)])])
scene("iv_approve_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "approve_boss_what", to="target"), expr("actor", "angry", 5),
               say("target", "approve_crushed", to="actor", delay=1.7), expr("target", "sad", 6, delay=1.7), mood("target", -18), morale("target", -6),
               rel("target", "actor", "resentment", 10), npcval("target", "leave_at", v=530, when=[c_var("choice", eq="dayoff")]),
               mem("target", "actor", "humiliated", -0.6, 0.9, "mem.approve_crushed", 3), favor("target", -3)])
S_("mem.approve_crushed", "I thought my request was approved. It wasn't. Ahmet laughed at me.")
scene("iv_approve_next_day", allow_absent=True, conditions=[c_present("@ahmet"), c_present("actor")],
      effects=[setv("what", "dayoff_vanish"), summon("actor", "ivm_boss_talk", delay=2)])
what("dayoff_vanish", "you disappearing yesterday afternoon")
iv("B05", "fake_approval", title="Make Ahmet's reply say 'Approved!'", desc="Their pending request gets a cheerful 'Approved!' — from a boss who approved nothing.",
   log="The ghost sent {owner} a fake 'Approved!' reply from Ahmet.", **MAIL, needs="choice", icon="check", owners=NOT_BOSS,
   choices=[choice("raise", "Their raise request"), choice("dayoff", "Their afternoon off")],
   conds=[r_present("@ahmet"), r_time(before="15:30")],
   state=[oset("ws.{owner}.approved", "$choice"), setv("what", "$choice")], react=[desk_trap("iv_approve_found", "approve_{owner}")])

# --- B06 hide an important instruction in their spam -------------------------------
L("spam_boss_check", ["{target}, did you finish what I asked this morning?", "Where's the thing I emailed you about, {target}?"])
L("spam_what", ["What thing? I never got anything!", "Asked me? When? There's nothing in my inbox!"])
L("spam_found", ["Wait... it's in my SPAM folder?! Since this morning!", "Oh no. It's in spam. Of course it's in spam."])
L("spam_scold", ["Check your spam, then! It's urgent and it's due today.", "Excuses. I want it before you leave."])
L("spam_understand", ["Spam? Hm. Burak will hear about this. Do it now, please.", "Fine. Our email is a disaster. Get it done."])
S_("log.spam_scold", "Ahmet's urgent request to {target} had landed in spam. Ahmet didn't care: due today.")
S_("log.spam_understand", "Ahmet's urgent request to {target} was stuck in spam. Ahmet blamed the email system instead.")
scene("iv_spam_check", allow_absent=True, conditions=[c_present("@ahmet"), c_present("owner")],
      effects=[visit("@ahmet", "owner", "iv_spam_scene", prio=66, ttl=60)])
scene("iv_spam_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5.5), say("actor", "spam_boss_check", to="target"), say("target", "spam_what", to="actor", delay=1.6),
               say("target", "spam_found", delay=3.2), emote("target", "sweat", delay=3.2),
               call("extra_work", target="target", units=24, task="urgent_report", deadline="17:20"), stress("target", 12)],
      outcomes=[out("scold", [say("actor", "spam_scold", to="target", delay=4.6), favor("target", -4), rel("target", "actor", "resentment", 6),
                              log("log.spam_scold", 3, "boss", who=["target"])], score=[s_trait("actor", "temper", 1.0), s_const(0.3)]),
                out("understand", [say("actor", "spam_understand", to="target", delay=4.6), rel("actor", "@burak", "trust", -5),
                                   log("log.spam_understand", 2, "boss", who=["target"])], score=[s_rel("actor", "target", "trust", 0.02), s_const(0.2)])])
iv("B06", "spam_instruction", title="Send Ahmet's instruction to their spam", desc="An urgent request they'll never see — until Ahmet asks for it.",
   log="The ghost moved Ahmet's urgent instruction into {owner}'s spam folder.", **MAIL, icon="email", owners=NOT_BOSS,
   conds=[r_present("@ahmet"), r_time(before="15:00")],
   state=[oset("ws.{owner}.spam_instruction")], react=[chain("iv_spam_check", delay=50)])

# --- B07 send a fake 1:1 invite from them to someone --------------------------------
L("fake_date_q", ["You wanted to see me?", "So... what's this meeting about?", "I got your invite. Kitchen, right?"])
L("fake_date_a", ["What? I thought YOU invited ME.", "I didn't send anything. You did!"])
L("fake_date_laugh", ["Well, we're here. Coffee?", "Ha! Okay. Since we're both here..."])
L("fake_date_spark", ["Maybe the universe wanted us to have a coffee.", "I'm... actually glad it happened."])
L("fake_date_cold", ["I've got better things to do.", "Great. A waste of time."])
S_("log.fake_date_laugh", "{actor} and {target} both got a meeting invite from the other. Neither sent one. They had coffee anyway.")
S_("log.fake_date_spark", "{actor} and {target} met in the kitchen over an invite nobody sent. It turned into a long, warm chat...")
S_("log.fake_date_cold", "{actor} and {target} met over an invite nobody sent. It was very awkward.")
S_("mem.fake_date", "{target} and I ended up having coffee by accident.")
scene("iv_fake_date", noise=0.8, conditions=[c_present("actor"), c_present("target")],
      effects=[hold(["actor", "target"], 6), say("target", "fake_date_q", to="actor"), say("actor", "fake_date_a", to="target", delay=1.6), emote("target", "question", delay=1.6)],
      outcomes=[
          out("laugh", [say("target", "fake_date_laugh", to="actor", delay=3.2), rel("actor", "target", "friendship", 8, both=True),
                        mem("actor", "target", "coffee", 0.4, 0.6, "mem.fake_date", 2), log("log.fake_date_laugh", 2, "friendship")],
              score=[s_aff("actor", "target", 0.02), s_trait("target", "humor", 0.6), s_const(0.4)]),
          out("spark", [say("target", "fake_date_spark", to="actor", delay=3.2), emote("actor", "love", delay=3.4), emote("target", "love", delay=3.4),
                        rel("actor", "target", "romance", 14, both=True), rel("actor", "target", "friendship", 6, both=True),
                        rumor("crush", a="actor", b="target", juicy=0.6, knowers=[]), witness([learn("self", "$rumor")], r=5),
                        mem("actor", "target", "date", 0.6, 0.8, "mem.fake_date", 3), mem("target", "actor", "date", 0.6, 0.8, "mem.fake_date", 3),
                        log("log.fake_date_spark", 3, "romance")],
              score=[s_rel("actor", "target", "romance", 0.04), s_rel("target", "actor", "romance", 0.04)], when=[c_rel("target", "actor", "romance", gt=15)]),
          out("cold", [say("target", "fake_date_cold", to="actor", delay=3.2), rel("actor", "target", "friendship", -4, both=True), log("log.fake_date_cold", 2, "misunderstanding")],
              score=[s_rel("target", "actor", "rivalry", 0.03), s_aff("target", "actor", -0.02)]),
      ])
iv("B07", "fake_invite", title="Send a fake 1:1 invite from them", desc="Pick who gets it. They'll both turn up in the kitchen.",
   log="The ghost sent a fake '1:1 — kitchen' invite from {owner} to {target}.", **MAIL, needs="person", icon="calendar",
   pick=[c_avail("self"), c_busy_meeting("self")], conds=[r_present(), why(c_busy_meeting("owner"), "in_meeting", "They're in a meeting.")],
   state=[oset("ws.{owner}.invite", "%target")],
   react=[meetup("iv_fake_date", who=("owner", "target"), area="kitchen", ttl=40, delay=3)])

# --- B08 resurface an old promise from Ahmet ------------------------------------------
L("promise_find", ["Wait. Ahmet PROMISED me a promotion. In writing. Two years ago!", "Look at this old email... 'next year, a raise, I promise.' Next year was last year!"])
L("promise_claim", ["Ahmet Bey, remember this email? You promised me a raise.", "I found your old promise. In writing. I'd like to talk about it."])
L("promise_honour", ["...I did write that. Fine. I keep my word. Let's talk numbers.", "Hm. A promise is a promise."])
L("promise_dodge", ["Times change. Budgets change.", "That was a different year. A different me.", "I don't recall writing that."])
S_("log.promise_honour", "{actor} dug up Ahmet's two-year-old promise and walked in with it. Ahmet honoured it!")
S_("log.promise_dodge", "{actor} confronted Ahmet with an old written promise. Ahmet wriggled out of it. {actor} is bitter.")
S_("mem.promise_broken", "Ahmet broke a promise he made me in writing.")
scene("iv_promise_found", effects=[expr("actor", "surprised", 4), say("actor", "promise_find"), emote("actor", "idea"),
                                   visit("actor", "@ahmet", "iv_promise_scene", prio=62, ttl=80, delay=3)])
scene("iv_promise_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "promise_claim", to="target")],
      outcomes=[out("honour", [say("target", "promise_honour", to="actor", delay=1.8), emote("actor", "cheer", delay=2), favor("actor", 8), morale("actor", 10), mood("actor", 15),
                               rel("actor", "target", "trust", 10), rumor("raise", a="actor", b="target", juicy=0.6, knowers=[]), witness([learn("self", "$rumor")], r=5),
                               log("log.promise_honour", 3, "reward")], score=[s_trait("target", "honesty", 1.2), s_rel("target", "actor", "trust", 0.02)]),
                out("dodge", [say("target", "promise_dodge", to="actor", delay=1.8), morale("actor", -10), mood("actor", -12), rel("actor", "target", "resentment", 15),
                              mem("actor", "target", "betrayed", -0.6, 0.9, "mem.promise_broken", 3), plan("actor", "job_search", "", heat=0.6, when=[c_morale("actor", lt=50)]),
                              log("log.promise_dodge", 3, "boss")], score=[s_trait("target", "cunning", 0.8), s_stress("target", 0.01), s_const(0.4)])])
iv("B08", "old_promise", title="Resurface Ahmet's old promise", desc="An ancient email: 'next year, a raise — I promise.' Bring it back to the top of their inbox.",
   log="The ghost brought one of Ahmet's old promises back to the top of {owner}'s inbox.", **MAIL, icon="email", owners=NOT_BOSS,
   conds=[r_present("@ahmet")], state=[oset("ws.{owner}.old_promise")], react=[desk_trap("iv_promise_found", "promise_{owner}")],
   reuse={"cool": 600, "day": 1})

# --- B09 set their auto-reply to "I quit" ---------------------------------------------
L("quit_reply_read", ["'I quit. Don't contact me.' — {owner}'s auto-reply?!", "{owner}... QUIT? Since when?!"])
L("quit_boss_rush", ["{target}! What is this 'I quit' business?!", "You're QUITTING? Without telling me?!"])
L("quit_explain", ["What? No! I'm not quitting! ...Am I?", "That's not my auto-reply! I never set that!"])
L("quit_counter", ["Look... whatever it is, we can talk. More money? A better title?", "Don't do anything rash. Let's discuss your future here."])
L("quit_leverage", ["...Actually, now that you mention it — a raise would be nice.", "Well. Since you're offering..."])
L("quit_real", ["You know what? Maybe it's true. Maybe I SHOULD quit.", "...It's not wrong, though."])
S_("log.quit_read", "{owner}'s email auto-reply now says 'I quit. Don't contact me.' Ahmet just read it.")
S_("log.quit_relief", "Ahmet stormed over about {target}'s 'I quit' auto-reply. It was a glitch. Everyone breathed again.")
S_("log.quit_leverage", "Ahmet panicked about {target}'s 'I quit' auto-reply and offered a raise on the spot. {target} said yes.")
S_("log.quit_real", "{target}'s fake 'I quit' auto-reply made them realise... maybe they do want to quit.")
scene("iv_quit_reply", allow_absent=True, conditions=[c_present("@ahmet"), c_present("owner")],
      effects=[say("@ahmet", "quit_reply_read"), expr("@ahmet", "surprised", 4), rumor("resigning", a="owner", b="@ahmet", juicy=0.8, truth=False, knowers=["@ahmet"]),
               witness([learn("self", "$rumor")], near="@ahmet", r=6), log("log.quit_read", 3, "email", who=["owner"]),
               visit("@ahmet", "owner", "iv_quit_scene", prio=74, ttl=50, delay=1)])
scene("iv_quit_scene", noise=0.9, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 6), say("actor", "quit_boss_rush", to="target"), say("target", "quit_explain", to="actor", delay=1.6)],
      outcomes=[out("relief", [say("actor", "lights_back", delay=3.2), debunk("$rumor", who=["actor", "target"], by="target"), log("log.quit_relief", 2, "misunderstanding")],
                    score=[s_morale("target", 0.02), s_const(0.3)]),
                out("leverage", [say("actor", "quit_counter", to="target", delay=3.2), say("target", "quit_leverage", to="actor", delay=4.8), favor("target", 6), morale("target", 10),
                                 emote("target", "cheer", delay=5), rumor("raise", a="target", b="actor", juicy=0.6, knowers=[]), witness([learn("self", "$rumor")], r=5),
                                 log("log.quit_leverage", 3, "reward")],
                    score=[s_trait("target", "cunning", 1.0), s_trait("target", "ambition", 0.6), s_rel("actor", "target", "respect", 0.02)]),
                out("real", [say("target", "quit_real", delay=3.2), expr("target", "sad", 5, delay=3.2), plan("target", "job_search", "", heat=1.2), morale("target", -6),
                             log("log.quit_real", 3, "drama")], score=[s_morale("target", -0.04), s_goal("target", "find_new_job", 1.5)])])
iv("B09", "autoreply_quit", title="Set their auto-reply to 'I quit'", desc="The next person to email them is the boss.",
   log="The ghost set {owner}'s email auto-reply to 'I quit. Don't contact me.'", **MAIL, icon="email", owners=NOT_BOSS,
   conds=[r_present("@ahmet")], state=[oset("ws.{owner}.autoreply", "quit")], react=[chain("iv_quit_reply", delay=20)])

# --- B10 unsend their apology ------------------------------------------------------
L("unsent_hope", ["So... we're good now? After my message?", "Hey. Thanks for reading my message. Friends again?"])
L("unsent_cold", ["What message? You never apologised.", "Good? You didn't even say sorry."])
L("unsent_say_it", ["...Then I'll say it now. I'm sorry.", "It vanished? Okay. In person, then: I'm sorry."])
L("unsent_fight", ["I DID apologise! Don't pretend I didn't!", "Unbelievable. I apologised and you're acting like I didn't."])
S_("log.unsent_make_up", "{actor} thought their apology had reached {target}. It hadn't. So {actor} said sorry in person — and it worked.")
S_("log.unsent_fight", "{actor}'s apology to {target} vanished before it was read. Now they're fighting about whether it was ever sent.")
S_("mem.unsent_apology", "I apologised to {target}. They ignored it.")
scene("iv_unsent_meet", noise=0.9, conditions=[c_avail("actor"), c_avail("target")],
      effects=[hold(["actor", "target"], 6), say("actor", "unsent_hope", to="target"), say("target", "unsent_cold", to="actor", delay=1.7), emote("actor", "question", delay=1.7)],
      outcomes=[out("make_up", [say("actor", "unsent_say_it", to="target", delay=3.4), rel("target", "actor", "resentment", -15), rel("actor", "target", "friendship", 8, both=True),
                                bond("actor", "target", "feud", False), stat("reconciliations"), mem("target", "actor", "made_up", 0.5, 0.8, "mem.made_up", 2),
                                log("log.unsent_make_up", 3, "friendship")], score=[s_trait("actor", "empathy", 1.0), s_trait("actor", "forgiveness", 0.6)]),
                out("fight", [say("actor", "unsent_fight", to="target", delay=3.4), sfx("argue", delay=3.4), stat("arguments"), rel("actor", "target", "friendship", -8, both=True),
                              rel("actor", "target", "resentment", 10), mem("actor", "target", "ignored_apology", -0.5, 0.8, "mem.unsent_apology", 2),
                              log("log.unsent_fight", 3, "conflict")], score=[s_trait("actor", "temper", 1.0), s_trait("target", "temper", 0.5)])])
iv("B10", "unsend_apology", title="Unsend their apology", desc="They've just written someone an apology. Make it vanish before it's read.",
   log="The ghost deleted {owner}'s apology to {foe} before it was read.", **MAIL, icon="redirect",
   vars=[var("foe", "foe_of", of="owner", role=True, why="why.no_foe")],
   state=[mem("owner", "foe", "apologised", 0.3, 0.6), rel("owner", "foe", "resentment", -10), oset("ws.{owner}.unsent", "%foe")],
   react=[pair_trap("iv_unsent_meet", "owner", "foe", key="unsent_{owner}", days=1, r=2.6)])
S_("why.no_foe", "They're not in conflict with anyone right now.")

# --- B11 add someone to the group chat where people complain about them --------------
L("groupchat_read", ["...Why am I in a group called 'Ugh, {target}'?", "Oh. A whole group chat. About me.", "'{hater} says: can't stand {target}.' Lovely."])
L("groupchat_confront", ["Nice group chat, {target}. I can read it now, you know.", "So you have a whole CHAT about me?"])
L("groupchat_busted", ["...How are you in that chat?", "Oh no. Who added you?!"])
S_("log.groupchat", "{target} was added to a group chat where {hater} complains about them. {target} read everything.")
S_("mem.groupchat", "{hater} has a group chat dedicated to complaining about me.")
scene("iv_groupchat_read", allow_absent=True, conditions=[c_present("target")],
      effects=[expr("target", "sad", 6), emote("target", "cloud"), say("target", "groupchat_read"), learn("target", "$fact", c=1.0),
               mem("target", "hater", "betrayed", -0.7, 0.9, "mem.groupchat", 3), rel("target", "hater", "resentment", 20), rel("target", "hater", "trust", -15),
               mood("target", -12), log("log.groupchat", 3, "email", who=["target", "hater"]),
               visit("target", "hater", "iv_groupchat_confront", prio=60, ttl=60, delay=3, when=[c_present("hater"), c_trait("target", "temper", gt=0.3)])])
scene("iv_groupchat_confront", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "groupchat_confront", to="target"), say("target", "groupchat_busted", to="actor", delay=1.6),
               emote("target", "sweat", delay=1.6), rel("target", "actor", "friendship", -4)],
      outcomes=[out("sorry", [say("target", "fwd_sorry", to="actor", delay=3.2), rel("actor", "target", "resentment", -6), log("log.fwd_sorry", 2, "conflict")],
                    score=[s_trait("target", "empathy", 1.0)]),
                out("feud", [say("target", "fwd_double", to="actor", delay=3.2), bond("actor", "target", "feud"), stat("arguments"), sfx("argue", delay=3.2),
                             log("log.fwd_feud", 4, "conflict")], score=[s_trait("target", "temper", 1.0), s_trait("target", "forgiveness", -0.5)])])
iv("B11", "add_to_groupchat", title="Add someone to a group chat about them", desc="Somebody's been complaining about them in a group chat. Now they're a member.",
   log="The ghost added {target} to a group chat full of complaints about them.", **MAIL, needs="person", icon="people",
   pick=[{"c": "picks", "fn": "hater_of", "of": "self", "lim": 5}, c_avail("self")],
   state=[pick_role("hater", "hater_of", of="target", lim=5),
          rumor("dislikes", a="hater", b="target", juicy=0.6, knowers=["hater"], key="fact")],
   react=[chain("iv_groupchat_read", delay=3)])
S_("why.no_haters", "Nobody has a problem with them. Yet.")

# --- B12 typos in their client email ---------------------------------------------------
L("typo_boss", ["{target}. The client called. 'Dear Valued Cliient, we regert to infrom you...'?!", "The client says your email was 'unreadable'. Explain."])
L("typo_explain", ["That's impossible, I proofread it twice!", "What?! It was perfect when I sent it!"])
L("typo_scold", ["Proofread it THREE times next time.", "This company has a reputation. Had."])
L("typo_laugh", ["...'Regert'. Ha. Fine. Call them and apologise.", "At least the client laughed. Fix it."])
S_("log.typo_scold", "A client complained about typos all over {target}'s email. Ahmet was furious.")
S_("log.typo_laugh", "{target}'s client email was full of typos. Luckily the client found 'regert' funny.")
scene("iv_typo_call", allow_absent=True, conditions=[c_present("@ahmet"), c_present("owner")],
      effects=[act("@ahmet", "phone", place="desk_ahmet", dur=3), visit("@ahmet", "owner", "iv_typo_scene", prio=66, ttl=50, delay=3)])
scene("iv_typo_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "typo_boss", to="target"), say("target", "typo_explain", to="actor", delay=1.6), emote("target", "sweat", delay=1.6)],
      outcomes=[out("scold", [say("actor", "typo_scold", to="target", delay=3.2), favor("target", -6), rel("actor", "target", "respect", -8), mood("target", -8),
                              log("log.typo_scold", 3, "boss", who=["target"])], score=[s_trait("actor", "temper", 1.0)]),
                out("laugh", [say("actor", "typo_laugh", to="target", delay=3.2), mood("actor", 3), log("log.typo_laugh", 2, "boss", who=["target"])],
                    score=[s_rel("actor", "target", "trust", 0.02), s_const(0.3)])])
iv("B12", "typo_bomb", title="Sprinkle typos into their client email", desc="'Dear Valued Cliient...' The client will call Ahmet.",
   log="The ghost scrambled the spelling in {owner}'s client email.", **MAIL, icon="papers", owners=["selin", "mert", "deniz", "ceren", "zeynep"],
   conds=[r_present("@ahmet"), r_time(before="16:00")], state=[oset("ws.{owner}.typos")], react=[chain("iv_typo_call", delay=40)])

# --- B13 CC the boss on their casual chat ------------------------------------------------
L("cc_boss_read", ["Interesting reading, {owner}'s little chat.", "I've been CC'd on {owner}'s 'private' chat. How educational."])
L("cc_boss_rant", ["'Ahmet is a dinosaur'? Is that so, {target}?", "So I'm 'a walking meeting', {target}?"])
L("cc_boss_chatter", ["Forty messages about kebab during work hours, {target}?", "You two chat more than you work."])
L("cc_owner_mortified", ["...That was meant to be private!", "Oh no. Oh NO. You were CC'd?"])
S_("log.cc_rant", "Ahmet got CC'd on {owner}'s private chat — the part where {owner} complains about him.")
S_("log.cc_chatter", "Ahmet got CC'd on {owner}'s endless chat about kebab. He's not impressed with their 'productivity'.")
scene("iv_cc_read", allow_absent=True, conditions=[c_present("@ahmet"), c_present("owner")],
      effects=[say("@ahmet", "cc_boss_read"), visit("@ahmet", "owner", "iv_cc_scene", prio=66, ttl=50, delay=2)])
scene("iv_cc_scene", noise=0.6, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("target", "cc_owner_mortified", to="actor", delay=1.8), emote("target", "sweat", delay=1.8)],
      outcomes=[out("rant", [say("actor", "cc_boss_rant", to="target"), expr("actor", "angry", 6), rel("actor", "target", "trust", -20), favor("target", -8),
                             rel("actor", "target", "resentment", 10), log("log.cc_rant", 4, "boss", who=["target"])],
                    score=[s_const(5)], when=[c_aff("target", "actor", lt=10)]),
                out("chatter", [say("actor", "cc_boss_chatter", to="target"), rel("actor", "target", "respect", -6), call("extra_work", target="target", units=14),
                                log("log.cc_chatter", 2, "boss", who=["target"])], score=[s_const(1)])])
iv("B13", "cc_boss", title="CC Ahmet on their private chat", desc="Whatever they've been typing to their best friend, Ahmet gets a copy.",
   log="The ghost CC'd Ahmet on {owner}'s private chat.", **MAIL, icon="redirect", owners=NOT_BOSS,
   conds=[r_present("@ahmet")], state=[oset("ws.{owner}.cc_boss")], react=[chain("iv_cc_read", delay=8)])

# --- B14 mark their friend's message as read, no reply -----------------------------------
L("seen_hurt", ["{owner} read my message an hour ago. No reply. Cool.", "'Seen'. Just 'seen'. Wow, {owner}."])
L("seen_confront", ["You read my message and just... ignored it?", "I can see you read it, you know."])
L("seen_explain", ["What message? I never even opened it!", "I didn't see anything! I swear!"])
L("seen_ok", ["...Fine. Maybe your phone's weird.", "Okay. I believe you. Mostly."])
S_("log.seen_ok", "{actor} thought {target} had ignored their message. {target} had never even seen it. They patched it up.")
S_("log.seen_hurt", "{actor} is sure {target} 'left them on read'. {target} never saw the message. The friendship took a hit.")
scene("iv_seen_hurt", allow_absent=True, conditions=[c_present("friend")],
      effects=[expr("friend", "sad", 5), say("friend", "seen_hurt"), visit("friend", "owner", "iv_seen_scene", prio=58, ttl=60, delay=4)])
scene("iv_seen_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "seen_confront", to="target"), say("target", "seen_explain", to="actor", delay=1.6)],
      outcomes=[out("ok", [say("actor", "seen_ok", to="target", delay=3.2), rel("actor", "target", "trust", -2), log("log.seen_ok", 2, "misunderstanding")],
                    score=[s_rel("actor", "target", "trust", 0.02), s_trait("actor", "forgiveness", 0.6)]),
                out("hurt", [say("actor", "caps_hurt", to="target", delay=3.2), rel("actor", "target", "friendship", -8), rel("actor", "target", "resentment", 6),
                             log("log.seen_hurt", 2, "misunderstanding")], score=[s_trait("actor", "temper", 0.6), s_stress("actor", 0.012)])])
iv("B14", "left_on_read", title="Mark their friend's message as 'seen'", desc="Their best friend will think they're being ignored.",
   log="The ghost marked {friend}'s message to {owner} as read. No reply is coming.", **MAIL, icon="check",
   vars=[var("friend", "best_of", of="owner", lim=10, role=True, avail=False, why="why.no_friend")],
   state=[oset("ws.{owner}.seen", "%friend")], react=[chain("iv_seen_hurt", delay=25)])
S_("why.no_friend", "They don't have a close friend here.")

# --- B15 change their email signature ------------------------------------------------------
L("sig_ceo_react", ["'Future CEO'? In your signature, {owner}?", "Bold signature, {owner}. Very bold."], ahmet=["'Future CEO.' Is that a threat, {owner}?"], deniz=["Future CEO? Over my dead body."])
L("sig_bath_react", ["'Sent from my bathtub'?! {owner}!", "Why does your email say you're in a bathtub?"], mert=["Bathtub emails! Legend."])
L("sig_fav_react", ["'Ahmet's favourite employee'? Really, {owner}?", "Teacher's pet signature. Nice."], ahmet=["Hm. 'Favourite.' Well. Maybe."])
L("sig_owner", ["My signature says WHAT?!", "I didn't write that! I would never!"])
S_("log.sig_ceo", "{owner}'s email signature now reads 'Future CEO'. Ahmet and Deniz noticed.")
S_("log.sig_bath", "{owner}'s email signature now reads 'Sent from my bathtub'. The whole office has seen it.")
S_("log.sig_fav", "{owner}'s email signature now reads 'Ahmet's favourite employee'. Eye-rolls everywhere.")
scene("iv_sig_seen", allow_absent=True, conditions=[c_present("actor")],
      effects=[say("actor", "sig_owner", delay=4), expr("actor", "surprised", 4, delay=4)],
      outcomes=[
          out("ceo", [each([say("self", "sig_ceo_react", p=0.4, delay=1.2), rel("self", "actor", "rivalry", 8, when=[c_trait("self", "ambition", gt=0.7)]),
                            rel("self", "actor", "respect", -3)], exclude=["actor"], stagger=0.7, where=[c_any(c_is("self", "ahmet"), c_is("self", "deniz"), c_chance(0.4))]),
                      rel("@ahmet", "actor", "trust", -6), log("log.sig_ceo", 3, "email")], score=[s_const(5)], when=[c_var("choice", eq="ceo")]),
          out("bath", [each([say("self", "sig_bath_react", p=0.4, delay=1.2), rel("self", "actor", "respect", -4), mood("self", 2)], exclude=["actor"], stagger=0.7,
                            where=[c_chance(0.6)]), mood("actor", -6), log("log.sig_bath", 3, "email")], score=[s_const(5)], when=[c_var("choice", eq="bath")]),
          out("fav", [each([say("self", "sig_fav_react", p=0.4, delay=1.2), rel("self", "actor", "rivalry", 5)], exclude=["actor"], stagger=0.7, where=[c_chance(0.6)]),
                      favor("actor", 2), log("log.sig_fav", 3, "email")], score=[s_const(5)], when=[c_var("choice", eq="fav")]),
      ])
iv("B15", "signature", title="Change their email signature", desc="Every email they send from now on carries it.",
   log="The ghost rewrote {owner}'s email signature.", **MAIL, needs="choice", icon="star",
   choices=[choice("ceo", "'Future CEO'"), choice("bath", "'Sent from my bathtub'"), choice("fav", "'Ahmet's favourite employee'")],
   state=[oset("ws.{owner}.signature", "$choice")], react=[desk_trap("iv_sig_seen", "sig_{owner}")])

# --- B16 add hearts to their next work message --------------------------------------------
L("heart_read", ["...Did {owner} just send me a heart?", "Three heart emojis. On a budget email. From {owner}.", "Hearts? From {owner}? Huh."])
L("heart_ask", ["So... about those hearts in your email...", "Was that heart... intentional?"])
L("heart_deny", ["Hearts?! No! I sent you a spreadsheet!", "That wasn't me! My keyboard has a mind of its own!"])
L("heart_admit", ["...Maybe it was a little bit intentional.", "Okay. Yes. I like you. There, I said it."])
S_("log.heart_deny", "{actor} asked {target} about the hearts in their work email. {target} denied everything, bright red.")
S_("log.heart_admit", "Three hearts in a work email led to a confession: {target} likes {actor}!")
scene("iv_heart_read", allow_absent=True, conditions=[c_present("target")],
      effects=[expr("target", "surprised", 4), say("target", "heart_read"), rel("target", "owner", "romance", 8),
               visit("target", "owner", "iv_heart_scene", prio=58, ttl=60, delay=4, when=[c_present("owner")])])
scene("iv_heart_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "heart_ask", to="target")],
      outcomes=[out("deny", [say("target", "heart_deny", to="actor", delay=1.6), emote("target", "sweat", delay=1.6), rel("actor", "target", "romance", -6),
                             rumor("crush", a="target", b="actor", juicy=0.6, truth=False, knowers=[]), witness([learn("self", "$rumor")], r=4.5),
                             log("log.heart_deny", 2, "romance")], score=[s_rel("target", "actor", "romance", -0.03), s_const(0.6)]),
                out("admit", [say("target", "heart_admit", to="actor", delay=1.6), emote("target", "love", delay=1.6), emote("actor", "love", delay=2.6),
                              rel("actor", "target", "romance", 14, both=True), rumor("crush", a="target", b="actor", juicy=0.7, knowers=[]),
                              witness([learn("self", "$rumor")], r=4.5), log("log.heart_admit", 4, "romance")],
                    score=[s_rel("target", "actor", "romance", 0.05)], when=[c_rel("target", "actor", "romance", gt=25)])])
iv("B16", "love_emoji", title="Add hearts to their next work message", desc="Pick who receives a very business-like email... with three hearts.",
   log="The ghost added heart emojis to {owner}'s email to {target}.", **MAIL, needs="person", icon="star", pick=[c_avail("self")],
   state=[oset("ws.{owner}.hearts", "%target")], react=[chain("iv_heart_read", delay=6, roles={"target": "target", "owner": "owner"})])

# --- B17 forward the payroll sheet (Zeynep's desk) -------------------------------------------
L("payroll_read", ["...{rich} earns HOW much more than me?!", "This is the payroll. I shouldn't— wait. {rich}?!", "So that's what {rich} makes. Interesting."])
L("payroll_demand", ["Ahmet Bey, I've seen what others earn. I want what's fair.", "I'd like to talk about my salary. Now. Please."])
L("payroll_boss_angry", ["Who showed you the payroll?! That's confidential!", "Where did you get those numbers?!"])
S_("log.payroll_read", "Zeynep's payroll sheet landed in {target}'s inbox. {target} now knows exactly what {rich} earns.")
S_("log.payroll_demand", "{actor} marched into Ahmet's office with payroll numbers. Ahmet wants to know who leaked them.")
S_("mem.payroll_envy", "{rich} earns much more than me.")
scene("iv_payroll_read", allow_absent=True, conditions=[c_present("target")],
      effects=[expr("target", "surprised", 5), emote("target", "exclaim"), say("target", "payroll_read"), mood("target", -8), morale("target", -4),
               rel("target", "rich", "resentment", 12), rel("target", "rich", "rivalry", 8), mem("target", "rich", "envy", -0.3, 0.7, "mem.payroll_envy", 2),
               log("log.payroll_read", 3, "secret", who=["target", "rich"])],
      outcomes=[out("demand", [visit("target", "@ahmet", "iv_payroll_demand", prio=62, ttl=70, delay=4, roles={"rich": "rich"})],
                    score=[s_trait("target", "ambition", 1.0), s_trait("target", "temper", 0.6)], when=[c_present("@ahmet"), c_is("target", "ahmet", neg=True)]),
                out("stew", [plan("target", "job_search", "", heat=0.5), mood("target", -4)], score=[s_const(0.4)])])
scene("iv_payroll_demand", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "payroll_demand", to="target"), say("target", "payroll_boss_angry", to="actor", delay=1.7),
               rel("target", "@zeynep", "trust", -12), log("log.payroll_demand", 3, "boss")],
      outcomes=[out("raise", [say("target", "promise_honour", to="actor", delay=3.4), favor("actor", 3), morale("actor", 6)], score=[s_rel("target", "actor", "respect", 0.03)]),
                out("no", [say("target", "promise_dodge", to="actor", delay=3.4), morale("actor", -6), rel("actor", "target", "resentment", 10)], score=[s_const(0.6)])])
iv("B17", "forward_payroll", title="Forward the payroll sheet to someone", desc="Zeynep's confidential payroll. Pick who gets to see everyone's salary.",
   log="The ghost forwarded the payroll sheet from Zeynep's inbox to {target}.", **MAIL, needs="person", icon="file", owners=["zeynep"],
   pick=[c_is("self", "ahmet", neg=True), c_avail("self")], absent_ok=True,
   state=[pick_role("rich", "boss_fav", **{"not": "target"}), oset("ws.zeynep.payroll_leak", "%target")],
   react=[chain("iv_payroll_read", delay=4)])

# --- B18 send Ahmet's draft restructuring memo to everyone (Ahmet's desk) ----------------
L("memo_read", ["'Restructuring... possible reductions'... REDUCTIONS?!", "Ahmet's memo says 'reductions'. That means us!", "Did everyone just get Ahmet's draft memo?!"],
  burak=["'Reductions.' Good thing my CV is up to date."], ece=["Reductions of WHAT? Of people?!"])
L("memo_boss", ["That was a DRAFT! Who sent my draft?!", "That memo was NOT ready!"])
S_("log.memo", "Ahmet's unfinished draft memo — 'restructuring, possible reductions' — went to the entire office.")
scene("iv_memo_sent", allow_absent=True,
      roles=[role("ear", where=[c_avail("self"), c_is("self", "ahmet", neg=True)], score=[s_stress("self", 0.02), s_trait("self", "gossip", 0.6), s_rand(0.4)], exclude=[])],
      effects=[rumor("layoffs", a="@ahmet", b="ear", juicy=0.95, truth=False, knowers=[], key="fact"),
               each([learn("self", "$fact", c=0.75), say("self", "memo_read", p=0.4, delay=1.0), stress("self", 8), emote("self", "exclaim", delay=0.8)],
                    exclude=["@ahmet"], stagger=0.5),
               say("@ahmet", "memo_boss", delay=4), expr("@ahmet", "angry", 6, delay=4), log("log.memo", 4, "email"),
               arc_start("layoff_panic", {"ear": "ear", "boss": "@ahmet"}, vars={"rumor": "$fact"}, stage="panic", force=True)])
iv("B18", "boss_memo", title="Send Ahmet's draft memo to everyone", desc="'Restructuring — possible reductions.' (It's about the coffee budget.)",
   log="The ghost sent Ahmet's unfinished draft memo to the whole office.", **MAIL, icon="email", owners=["ahmet"], absent_ok=True,
   conds=[why({"c": "arc", "arc": "layoff_panic", "not": True}, "panic_running", "The office is already panicking about layoffs.")],
   state=[oset("ws.ahmet.memo_sent")], react=[chain("iv_memo_sent", delay=3)], reuse={"cool": 900, "day": 1, "per": "global"})

# --- B19 edit the office newsletter (Ceren's desk) -------------------------------------------
L("news_read", ["'Spotted: {target} and {crush2} at a candlelit dinner'?!", "The newsletter says {target} and {crush2}... are a THING?"], zeynep=["Finally, journalism!"])
L("news_deny", ["That's not true! We've never had dinner!", "Who wrote that?! It's a lie!"])
L("news_blush", ["...I mean. It's not TRUE. But it's not... terrible.", "Dinner? With them? ...Hm."])
S_("log.news", "Ceren's newsletter announced that {target} and {crush2} were 'spotted at a candlelit dinner'. They weren't.")
scene("iv_news_out", allow_absent=True, conditions=[c_present("target")],
      effects=[rumor("couple", a="target", b="crush2", juicy=0.8, truth=False, knowers=[], key="fact"),
               each([learn("self", "$fact", c=0.6), say("self", "news_read", p=0.3, delay=1.0)], exclude=["target", "crush2"], stagger=0.6),
               log("log.news", 3, "romance", who=["target", "crush2"]),
               say("target", "news_deny", delay=3.5), expr("target", "surprised", 5, delay=3.5),
               say("crush2", "news_blush", delay=5, when=[c_rel("crush2", "target", "romance", gt=20)]),
               rel("crush2", "target", "romance", 8, when=[c_rel("crush2", "target", "romance", gt=10)]),
               rel("@ceren", "target", "trust", -2), rel("target", "@ceren", "suspicion", 15)])
iv("B19", "newsletter", title="Add a juicy line to the office newsletter", desc="'Spotted: (someone) at a candlelit dinner with...' Ceren sends it at noon.",
   log="The ghost slipped a fake 'Spotted' item about {target} into Ceren's newsletter.", **MAIL, needs="person", icon="newspaper", owners=["ceren"],
   pick=[c_present("self")], absent_ok=True,
   state=[pick_role("crush2", "crush_of", of="target"), pick_role("crush2", "best_of", keep=True, of="target", lim=-80)],
   react=[chain("iv_news_out", delay=12)])

# --- B20 garble their dictated message --------------------------------------------------
L("garble_read", ["'I'm going to KILL... ...the presentation'?! From {owner}?", "{owner}'s message says 'I'll destroy you'. Should I be worried?"])
L("garble_confront", ["Did you just threaten me?!", "What does 'I'll destroy you' mean, exactly?"])
L("garble_explain", ["I said 'I'll DEPLOY it for you'! Dictation!", "That was voice-to-text! I said 'kill it' as in 'do great'!"])
L("garble_laugh", ["Oh thank god. Your phone hates you.", "...Okay. That's hilarious, actually."])
L("garble_doubt", ["Sure. 'Dictation'.", "I'm keeping a screenshot. Just in case."])
S_("log.garble_laugh", "{owner}'s dictated message to {target} came out as a death threat. They laughed about it in the end.")
S_("log.garble_doubt", "{owner}'s garbled voice message sounded like a threat. {target} isn't fully convinced it was dictation.")
scene("iv_garble_read", allow_absent=True, conditions=[c_present("target")],
      effects=[expr("target", "surprised", 5), emote("target", "exclaim"), say("target", "garble_read"), stress("target", 8),
               rumor("threat", a="owner", b="target", juicy=0.7, truth=False, knowers=["target"], key="fact"),
               visit("target", "owner", "iv_garble_scene", prio=62, ttl=60, delay=3, when=[c_present("owner")])])
scene("iv_garble_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "garble_confront", to="target"), say("target", "garble_explain", to="actor", delay=1.6)],
      outcomes=[out("laugh", [say("actor", "garble_laugh", to="target", delay=3.2), debunk("$fact", who=["actor"], by="target"), rel("actor", "target", "friendship", 4, both=True),
                              log("log.garble_laugh", 2, "misunderstanding")], score=[s_trait("actor", "humor", 1.0), s_rel("actor", "target", "trust", 0.02)]),
                out("doubt", [say("actor", "garble_doubt", to="target", delay=3.2), rel("actor", "target", "suspicion", 15), rel("actor", "target", "trust", -8),
                              witness([learn("self", "$fact")], r=4), log("log.garble_doubt", 3, "misunderstanding")],
                    score=[s_rel("actor", "target", "rivalry", 0.02), s_trait("actor", "temper", 0.6), s_const(0.2)])])
iv("B20", "garble_dictation", title="Garble their voice-to-text message", desc="'I'll kill it in the meeting' becomes 'I'll kill you.' Pick who receives it.",
   log="The ghost garbled {owner}'s dictated message to {target}.", **MAIL, needs="person", icon="sound", pick=[c_avail("self")],
   state=[oset("ws.{owner}.garbled", "%target")], react=[chain("iv_garble_read", delay=5)])
