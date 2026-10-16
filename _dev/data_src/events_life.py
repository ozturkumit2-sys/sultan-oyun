# Living-office events: things characters start on their own (trigger "initiative",
# chosen by the StoryDirector from personality, goals, mood, relationships, plans
# and memories) plus reactions that hook into existing moments.
# Every starter walks people somewhere (desk, kitchen, archive, boss office) and
# the "scene" event plays when they get there.
from story_helpers import *  # noqa: F401,F403

# =====================================================================
# 1. GOSSIP — kitchen huddles, rumours that grow, rumours that get checked
# =====================================================================
L("kg_psst", ["Psst. {target}. Kitchen. Now.", "{target}! Coffee? I have NEWS.", "Got a minute, {target}? Not here though."],
  zeynep=["{target}, kitchen. You'll want to sit down for this.", "Oh {target}, you have NO idea what I just heard."],
  mert=["{target}! Kitchen summit, two minutes."])
L("gossip_tell_unsure", ["I'm not a hundred percent sure, but... {gossip}", "Don't quote me, but apparently: {gossip}", "I only heard it secondhand, but — {gossip}"],
  zeynep=["My source is... let's say semi-reliable. {gossip}"], ece=["I might have heard wrong! But... {gossip}"])
L("gossip_tell_spicy", ["And it's worse than you think: {gossip}", "Okay, so — {gossip} I KNOW."],
  zeynep=["You didn't hear it from me, but {gossip}", "Brace yourself. {gossip}"])
S_("log.gossip_kitchen", "{actor} pulled {target} into the kitchen to whisper: \"{gossip}\"")
S_("log.gossip_twisted", "{actor} spiced up the story while passing it to {target}: \"{gossip}\" (that's not what happened)")

initiative("kitchen_gossip", "small", cooldown=55,
    roles=[actor([c_trait("self", "gossip", gt=0.42)], [s_trait("self", "gossip", 1.3), s_trait("self", "sociability", 0.3),
                                                         s_goal("self", "collect_secrets", 0.5), s_busy("self", -0.3)]),
           by_fn("target", "gossip_target")],
    vars=[var("gossip", "gossip_fact")],
    effects=[emote("actor", "whisper"), say("actor", "kg_psst", to="target"),
             meetup("kitchen_gossip_scene", area="kitchen", ttl=35)])

scene("kitchen_gossip_scene",
    effects=[hold(["actor", "target"], 5), distort("$gossip", "actor", 0.9), emote("actor", "whisper"),
             say("actor", "gossip_open", to="target"),
             say("actor", "gossip_tell_spicy", to="target", delay=1.5, when=[c_var("twisted", eq=True)]),
             say("actor", "gossip_tell", to="target", delay=1.5, when=[c_not(c_var("twisted", eq=True)), c_sure("actor", "$gossip", gt=0.69)]),
             say("actor", "gossip_tell_unsure", to="target", delay=1.5, when=[c_not(c_var("twisted", eq=True)), c_sure("actor", "$gossip", lt=0.7)]),
             learn("target", "$gossip", frm="actor"), rel("actor", "target", "friendship", 3), stat("rumors"),
             log("log.gossip_twisted", 2, "rumor", when=[c_var("twisted", eq=True)]),
             log("log.gossip_kitchen", 2, "rumor", when=[c_not(c_var("twisted", eq=True))]),
             chain("paranoid_passerby", delay=2.5, roles={"actor": "actor", "target": "target"}),
             chain("overheard_by_subject", delay=3.0, roles={"actor": "actor", "target": "target"})],
    outcomes=[
        out("shocked", [say("target", "gossip_react", to="actor", delay=3.2)], score=[s_const(0.6)]),
        out("doubt", [say("target", "gossip_doubt", to="actor", delay=3.2), rel("target", "actor", "trust", -3)],
            score=[s_trait("target", "honesty", 1.0), s_trait("target", "gossip", -0.8)]),
        out("eager", [say("target", "gossip_eager", to="actor", delay=3.2), rel("target", "actor", "friendship", 4), emote("target", "exclaim", delay=3.2)],
            score=[s_trait("target", "gossip", 1.2), s_trait("target", "curiosity", 0.4)]),
    ])
L("gossip_doubt", ["Hm. Are you sure about that?", "That sounds made up.", "I'll believe it when I see it."],
  ceren=["Let's not repeat that until we know it's true."], selin=["Gossip isn't evidence."], burak=["Source?"])

# --- someone walking past thinks the whispering is about them
L("paranoid_think", ["...Why did they stop talking when I walked in?", "Are they whispering about ME?", "Hmm. Suspicious huddle."])
L("were_you_talking_about_me", ["Were you two talking about me?", "What was all that whispering about?", "If you have something to say, say it to my face."],
  selin=["I saw you whispering. About me?"], burak=["You went quiet when I came in. Why?"])
L("caught_gossiping", ["Uh... no? Weather. We were talking about the weather.", "What? No! ...Okay, maybe a little."],
  zeynep=["Darling, I talk about EVERYONE. Don't take it personally."])
L("paranoid_furious", ["Unbelievable. Behind my back?!", "I knew it.", "Keep my name out of your mouth."])
L("not_about_you", ["Relax! We were talking about football.", "It wasn't about you, I promise!", "Not everything is about you."],
  mert=["We were debating kebab places. Life or death stuff."])
L("paranoid_relief", ["Oh. Right. Sorry.", "...Okay. I'm just tired.", "Fine. Carry on."])
S_("log.paranoid_caught", "{actor} caught {target} gossiping about them. Things got ugly.")
S_("log.paranoid_relief", "{actor} thought {target} was gossiping about them. It was about football.")
S_("mem.gossiped_about_me", "{target} gossiped about me behind my back.")

ev(id="paranoid_passerby", trigger="", priority=55, tier="",
   roles=[role("passerby", where=[c_avail("self"), c_any(c_stress("self", gt=40), c_trait("self", "temper", gt=0.55))],
               score=[s_trait("self", "temper", 1.0), s_stress("self", 0.01), s_rand(0.4)], near="actor", r=5.0)],
   conditions=[c_chance(0.55)],
   effects=[emote("passerby", "question"), say("passerby", "paranoid_think"),
            visit("passerby", "actor", "paranoid_confront", prio=63, ttl=25, delay=3, roles={"partner": "target"})])

scene("paranoid_confront", noise=0.8, conditions=[c_avail("target")],
    vars=[var("subj", "rumor_subject", fact="$gossip", optional=True)],
    effects=[hold(["actor", "target"], 5), say("actor", "were_you_talking_about_me", to="target")],
    outcomes=[
        out("caught", [say("target", "caught_gossiping", to="actor", delay=1.6), say("actor", "paranoid_furious", to="target", delay=3.2),
                       expr("actor", "angry", 6, delay=1.6), emote("actor", "anger", delay=3.2), sfx("argue", delay=3.2),
                       rel("actor", "target", "friendship", -14), rel("actor", "target", "trust", -16), rel("target", "actor", "friendship", -5),
                       mem("actor", "target", "gossiped_about_me", -0.7, 0.9, "mem.gossiped_about_me", 3), stat("arguments"),
                       plan("actor", "revenge", "target", heat=0.8, when=[c_trait("actor", "forgiveness", lt=0.45)]),
                       log("log.paranoid_caught", 3, "conflict")],
            score=[s_const(5)], when=[c_same("$subj", "actor")]),
        out("relief", [say("target", "not_about_you", to="actor", delay=1.6), say("actor", "paranoid_relief", delay=3.2),
                       expr("actor", "sad", 4, delay=3.2), rel("target", "actor", "trust", -2), log("log.paranoid_relief", 1, "misunderstanding")],
            score=[s_const(1)]),
    ])

# --- the person the rumour is about happens to be close enough to hear it
L("overheard_self", ["Excuse me?! I can HEAR you.", "Wow. I'm standing right here.", "That's about me, isn't it."],
  selin=["Say it louder, I don't think the whole floor heard."], ahmet=["Is that what you think? In MY office?"])
L("busted_sorry", ["Oh no. I didn't — sorry.", "That came out wrong!", "...How long have you been there?"])
S_("log.overheard_self", "{subject} walked in right as {actor} was gossiping about them.")
ev(id="overheard_by_subject", trigger="", priority=60,
   vars=[var("subject", "rumor_subject", fact="$gossip")],
   conditions=[c_present("$subject"), {"c": "near", "a": "$subject", "b": "actor", "lt": 4.5},
               c_same("$subject", "target", neg=True), c_chance(0.8)],
   effects=[expr("$subject", "angry", 6), emote("$subject", "anger"), say("$subject", "overheard_self", to="actor"),
            say("actor", "busted_sorry", to="$subject", delay=1.6), emote("actor", "sweat", delay=1.6),
            rel("$subject", "actor", "friendship", -15), rel("$subject", "actor", "trust", -15), stress("$subject", 10),
            mem("$subject", "actor", "gossiped_about_me", -0.7, 0.9, "mem.gossiped_about_me", 3), learn("$subject", "$gossip"),
            log("log.overheard_self", 3, "conflict", who=["$subject", "actor"])])

# --- checking a rumour with the person it's about
L("rumor_check_think", ["I keep hearing things about {target}. I should just ask.", "Is that rumour about {target} even true?"])
L("is_it_true", ["Can I ask you something? People are saying: {fact} Is that true?", "{target}, is it true that... well. {fact}",
                 "Tell me straight: {fact}"],
  ceren=["I'd rather hear it from you than from the kitchen: {fact}"], ece=["Sorry if this is weird but — {fact} Is it true?"])
L("rumor_admit", ["...Yes. It's true. Happy?", "Ugh. Okay, yes. Please keep it quiet.", "Fine. It's true."],
  burak=["Yes. And I'd appreciate discretion."])
L("rumor_false", ["WHAT? That's completely false!", "Who on earth is saying that?!", "Absolutely not. Where did you hear that?"],
  selin=["That is a lie, and I want to know who started it."], ahmet=["Nonsense! Who's spreading this?"])
L("rumor_lie", ["Pfft. No. Of course not.", "Me? Never. Ridiculous.", "Haha. No. Next question."], deniz=["Do I look like someone who'd do that?"])
L("rumor_relief", ["Phew. I knew it sounded off.", "Good. I didn't believe it anyway.", "Okay, I'll set people straight."])
S_("log.rumor_confirmed", "{actor} asked {target} straight out about a rumour. {target} admitted it was true.")
S_("log.rumor_debunked", "{actor} asked {target} about a rumour — it was false. \"{fact}\" Now {target} wants to know who started it.")
S_("log.rumor_lied", "{actor} asked {target} about a rumour. {target} denied it... but it's true.")
S_("mem.asked_straight", "{actor} asked me straight instead of gossiping.")

initiative("rumor_check", "small", cooldown=90, weight=1.6,
    roles=[actor([c_any(c_trait("self", "honesty", gt=0.6), c_trait("self", "curiosity", gt=0.7))],
                 [s_trait("self", "honesty", 0.8), s_trait("self", "curiosity", 0.5), s_goal("self", "keep_peace", 0.5)]),
           by_fn("target", "doubtful_subject")],
    effects=[emote("actor", "question"), say("actor", "rumor_check_think"),
             visit("actor", "target", "rumor_check_scene", prio=58, ttl=45)])

scene("rumor_check_scene", noise=0.8, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), say("actor", "is_it_true", to="target")],
    outcomes=[
        out("admit", [say("target", "rumor_admit", to="actor", delay=1.6), learn("actor", "$fact", c=1.0), mood("target", -5),
                      rel("target", "actor", "trust", 4), mem("target", "actor", "asked_straight", 0.3, 0.6, "mem.asked_straight", 2),
                      log("log.rumor_confirmed", 2, "rumor")],
            score=[s_trait("target", "honesty", 1.2), s_const(0.3)], when=[c_truth("$fact", True)]),
        out("lie", [say("target", "rumor_lie", to="actor", delay=1.6), forget("actor", "$fact"), emote("target", "sweat", delay=2.6),
                    log("log.rumor_lied", 3, "rumor")],
            score=[s_trait("target", "cunning", 1.2), s_trait("target", "honesty", -1.0)], when=[c_truth("$fact", True)]),
        out("debunk", [say("target", "rumor_false", to="actor", delay=1.6), say("actor", "rumor_relief", to="target", delay=3.2),
                       expr("target", "angry", 5, delay=1.6), debunk("$fact", who=["actor", "target"], by="target"),
                       rel("target", "actor", "trust", 6), stress("target", 6),
                       witness([debunk("$fact", who=["self"], by="target")], near="target", r=4.5),
                       chain("hunt_rumor_source", delay=6, roles={"actor": "target", "target": "actor"}),
                       log("log.rumor_debunked", 3, "rumor")],
            score=[s_const(5)], when=[c_truth("$fact", False)]),
    ])

L("who_started_it", ["Right. Who started this?", "I'm going to find whoever made that up.", "Someone's been talking. I'll find out who."])
ev(id="hunt_rumor_source", trigger="", priority=55, allow_absent=True,
   vars=[var("liar", "rumor_spreader", fact="$fact")],
   conditions=[c_present("actor"), c_present("$liar")],
   effects=[say("actor", "who_started_it"), visit("actor", "$liar", "rumor_source_confront", prio=60, ttl=50, delay=2)])

L("you_spread_lies", ["I hear you've been telling people {fact} It's a lie.", "Did you tell people that {fact} Because it's NOT true.",
                      "Stop spreading rumours about me."],
  selin=["You spread a lie about me. I'd like an explanation."], ahmet=["You've been spreading false stories about me?"])
L("liar_apology", ["I... heard it somewhere. I'm sorry.", "You're right. I shouldn't have repeated it.", "Sorry. I got carried away."],
  ece=["I'm so sorry! I thought it was true!"])
L("liar_deny", ["Me? I never said that.", "Don't look at me. Ask around.", "Wasn't me. I just listen."], zeynep=["I merely... relay information."])
L("liar_defiant", ["Well, everyone's saying it.", "If the shoe fits...", "Maybe if you weren't so suspicious..."])
S_("log.rumor_source_apology", "{actor} confronted {target} for spreading a false rumour. {target} apologised.")
S_("log.rumor_source_fight", "{actor} confronted {target} about a false rumour. It turned into a shouting match.")
S_("log.rumor_source_deny", "{actor} confronted {target} about a rumour. {target} denied everything.")
S_("mem.spread_lies", "{target} spread lies about me.")
scene("rumor_source_confront", noise=0.8, conditions=[c_avail("target")], tier="medium",
    effects=[hold(["actor", "target"], 5.5), expr("actor", "angry", 5), say("actor", "you_spread_lies", to="target")],
    outcomes=[
        out("apology", [say("target", "liar_apology", to="actor", delay=1.6), rel("actor", "target", "trust", -6), rel("actor", "target", "friendship", 2),
                        mem("actor", "target", "spread_lies", -0.3, 0.6, "mem.spread_lies", 2), log("log.rumor_source_apology", 2, "rumor")],
            score=[s_trait("target", "empathy", 1.0), s_trait("target", "honesty", 0.6)]),
        out("deny", [say("target", "liar_deny", to="actor", delay=1.6), rel("actor", "target", "trust", -10),
                     mem("actor", "target", "spread_lies", -0.5, 0.7, "mem.spread_lies", 2), log("log.rumor_source_deny", 2, "rumor")],
            score=[s_trait("target", "cunning", 1.0), s_trait("target", "gossip", 0.4)]),
        out("fight", [say("target", "liar_defiant", to="actor", delay=1.6), say("actor", "grudge_escalate", to="target", delay=3.2),
                      expr("target", "angry", 5, delay=1.6), sfx("argue", delay=1.6), stat("arguments"),
                      rel("actor", "target", "friendship", -12, both=True), rel("actor", "target", "rivalry", 8, both=True),
                      mem("actor", "target", "spread_lies", -0.8, 0.9, "mem.spread_lies", 3),
                      rumor("argument", juicy=0.5, knowers=["actor", "target"]), witness([learn("self", "$rumor")]),
                      log("log.rumor_source_fight", 3, "conflict")],
            score=[s_trait("target", "temper", 1.2), s_rel("target", "actor", "rivalry", 0.02)]),
    ])

# --- half-heard phone call
L("misheard_think", ["Wait... did {target} just say {victim} is getting fired?!", "Did I hear that right? {victim}... fired?!",
                     "Oh my god. {victim}'s days are numbered?"], zeynep=["Ooh. Ooh! {victim} is OUT? This is big."])
S_("log.misheard", "{actor} half-heard {target} on the phone and is now convinced {victim} is about to be fired. ({target} was talking about a printer.)")
initiative("misheard_call", "small", cooldown=180, scope="global",
    roles=[actor([c_trait("self", "curiosity", gt=0.55)], [s_trait("self", "curiosity", 1.0), s_trait("self", "gossip", 0.6)]),
           role("target", where=[c_act("self", ["phone"]), c_present("self")], near="actor", r=6.5, avail=False,
                score=[s_dist("actor", "self", -0.1)]),
           role("victim", where=[c_is("self", "ahmet", neg=True)], score=[s_rand(1.0), s_aff("actor", "self", -0.01)])],
    effects=[emote("actor", "exclaim"), expr("actor", "surprised", 4), say("actor", "misheard_think"),
             rumor("getting_fired", a="victim", b="target", juicy=0.8, truth=False, knowers=["actor"], c=0.7),
             log("log.misheard", 2, "misunderstanding")])

# =====================================================================
# 2. PROMOTION & THE BOSS
# =====================================================================
L("suck_up_line", ["Ahmet Bey! Great tie today. Very... leadership.", "Brought you a coffee. The way you like it.", "Your speech yesterday really inspired me."],
  deniz=["Ahmet Bey, I took the liberty of summarising the market for you. One page. Bold font."],
  ece=["Uncle— Ahmet Bey! I made you tea!"])
L("boss_flattered", ["Hm. Good. Good man.", "That's the attitude I like to see.", "Finally, someone with initiative."])
L("boss_sees_through", ["What do you want?", "Flattery won't finish your report.", "Back to work."])
L("eye_roll", ["*eye roll*", "Oh, please.", "Subtle. Very subtle.", "Somebody get a mop for all that sucking up."],
  mert=["Brown-nose of the month award goes to..."], selin=["Unbelievable."])
S_("log.suck_up", "{actor} buttered up Ahmet. It worked.")
S_("log.suck_up_fail", "{actor} tried to butter up Ahmet. He wasn't having it.")
initiative("suck_up", "small", cooldown_days=1,
    roles=[actor([c_trait("self", "ambition", gt=0.6), c_is("self", "ahmet", neg=True), c_avail("@ahmet")],
                 [s_trait("self", "cunning", 1.0), s_trait("self", "ambition", 0.8), s_goal("self", "earn_promotion", 0.6)])],
    effects=[visit("actor", "@ahmet", "suck_up_scene", prio=55, ttl=40)])
scene("suck_up_scene", noise=0.8, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 4), say("actor", "suck_up_line", to="target"),
             witness([say("self", "eye_roll", p=0.45, delay=2.5), rel("self", "actor", "rivalry", 3)], near="actor", r=5),
             rumor("boss_pet", a="actor", b="target", juicy=0.35, knowers=[]), witness([learn("self", "$rumor")], r=5)],
    outcomes=[
        out("works", [say("target", "boss_flattered", to="actor", delay=1.6), favor("actor", 3), mood("target", 4), log("log.suck_up", 1, "promotion")],
            score=[s_rel("target", "actor", "trust", 0.02), s_mood("target", 0.01), s_const(0.4)]),
        out("fails", [say("target", "boss_sees_through", to="actor", delay=1.6), favor("actor", -1), mood("actor", -4), log("log.suck_up_fail", 2, "boss")],
            score=[s_trait("target", "temper", 0.6), s_stress("target", 0.01), s_rand(0.4)]),
    ])

L("raise_ask", ["Ahmet Bey, can we talk about my salary?", "I think it's time we discussed a raise.", "I've been here long enough. I'd like a raise."],
  zeynep=["I balance this company's books. I'd like mine balanced too."], burak=["I fix everything here. I want that reflected in my pay."])
L("raise_yes", ["...Fine. You've earned it. Don't tell anyone.", "Alright. A small one. Keep it quiet."])
L("raise_later", ["Next quarter. We'll see.", "Not now. Budgets are tight.", "Remind me in spring."])
L("raise_no", ["A raise? In THIS economy?", "Absolutely not. Back to work.", "You should be grateful you have a job."])
L("raise_happy", ["Thank you! Really!", "Finally!"], zeynep=["Pleasure doing business."])
L("raise_bitter", ["...Of course.", "Right. Spring. Sure.", "Unbelievable."], burak=["Noted. Very noted."])
S_("log.raise_yes", "{actor} asked Ahmet for a raise — and got one. Quietly.")
S_("log.raise_later", "{actor} asked for a raise. \"Next quarter.\"")
S_("log.raise_no", "{actor} asked for a raise and got shot down hard.")
S_("mem.raise_refused", "Ahmet refused my raise.")
S_("mem.raise_given", "Ahmet gave me a raise.")
initiative("raise_request", "medium", cooldown_days=3,
    roles=[actor([c_is("self", "ahmet", neg=True), c_avail("@ahmet"), c_any(c_goal("self", "get_raise"), c_morale("self", lt=45))],
                 [s_goal("self", "get_raise", 1.0), s_morale("self", -0.015), s_trait("self", "ambition", 0.5)])],
    effects=[say("actor", "think_raise"), meetup("raise_scene", who=["actor", "@ahmet"], area="boss", roles={"actor": "actor", "target": "@ahmet"}, ttl=40)])
L("think_raise", ["Today's the day. I'm asking.", "Deep breath. Raise. You can do this."])
scene("raise_scene", noise=0.8, conditions=[c_present("target")],
    effects=[hold(["actor", "target"], 5.5), say("actor", "raise_ask", to="target")],
    outcomes=[
        out("yes", [say("target", "raise_yes", to="actor", delay=1.8), say("actor", "raise_happy", delay=3.4), emote("actor", "cheer", delay=3.4),
                    morale("actor", 14), mood("actor", 18), mem("actor", "target", "recognized", 0.7, 0.8, "mem.raise_given", 3),
                    rumor("raise", a="actor", b="target", juicy=0.6, knowers=[]), log("log.raise_yes", 3, "boss")],
            score=[s_rel("target", "actor", "trust", 0.03), {"s": "favor", "who": "actor", "w": 0.02}, s_rand(0.5)]),
        out("later", [say("target", "raise_later", to="actor", delay=1.8), say("actor", "raise_bitter", delay=3.4), morale("actor", -5),
                      log("log.raise_later", 2, "boss")], score=[s_const(0.9)]),
        out("no", [say("target", "raise_no", to="actor", delay=1.8), say("actor", "raise_bitter", delay=3.4), expr("actor", "angry", 5, delay=3.4),
                   morale("actor", -10), mood("actor", -10), rel("actor", "target", "friendship", -8),
                   mem("actor", "target", "humiliated", -0.6, 0.8, "mem.raise_refused", 3),
                   plan("actor", "job_search", "", heat=1.0, when=[c_morale("actor", lt=40)]), log("log.raise_no", 3, "boss")],
            score=[s_trait("target", "temper", 1.0), s_stress("target", 0.01), s_const(0.2)]),
    ])

L("hover_line", ["Mm-hm. And what's this?", "You type very slowly.", "Is that a spreadsheet or modern art?", "I'm just watching. Pretend I'm not here."])
L("hover_nervous", ["...I'm almost done.", "Right. Yes. Faster. Yes.", "*types extremely fast*"], ece=["I promise I know what I'm doing! Mostly!"])
L("hover_snap", ["Could you please NOT stand over my shoulder?", "I work better without an audience.", "Do you need something, or...?"],
  burak=["Breathing on my neck doesn't make the server faster."])
L("hover_charm", ["Want me to make the font bigger for you, boss?", "This is my good side. Take a photo."], mert=["You're welcome to join the sales call! Bring snacks."])
L("boss_hmph", ["Hmph. Carry on.", "Watch the attitude.", "...Fine."])
L("boss_chuckle", ["Ha! Cheeky. Carry on.", "Hah. Get back to it."])
S_("log.micromanage", "Ahmet stood behind {target}'s desk, watching every keystroke.")
S_("log.micromanage_snap", "Ahmet hovered over {target}'s desk until {target} snapped at him.")
S_("mem.micromanaged", "Ahmet breathed down my neck all afternoon.")
initiative("micromanage", "small", cooldown=120,
    roles=[actor([c_is("self", "ahmet")], [s_goal("self", "keep_control", 0.8), s_stress("self", 0.01)]),
           role("target", where=[c_act("self", ["work"]), c_is("self", "ahmet", neg=True)],
                score=[s_rel("actor", "self", "trust", -0.02), s_rand(0.6)])],
    effects=[go_desk("actor", "target", "micromanage_scene", prio=55, ttl=30)])
scene("micromanage_scene", noise=0.8, conditions=[c_present("target"), {"c": "near", "a": "actor", "b": "target", "lt": 2.8}],
    effects=[hold(["actor", "target"], 4.5), say("actor", "hover_line", to="target"), stress("target", 6)],
    outcomes=[
        out("nervous", [say("target", "hover_nervous", delay=1.6), emote("target", "sweat", delay=1.6), stress("target", 6),
                        mem("target", "actor", "overworked", -0.2, 0.4, "mem.micromanaged", 1), log("log.micromanage", 1, "boss")],
            score=[s_trait("target", "temper", -1.0), s_const(0.5)]),
        out("snap", [say("target", "hover_snap", to="actor", delay=1.6), say("actor", "boss_hmph", to="target", delay=3.0), expr("target", "angry", 4, delay=1.6),
                     rel("actor", "target", "trust", -6), rel("target", "actor", "friendship", -6), favor("target", -2),
                     mem("target", "actor", "boss_snapped", -0.4, 0.6, "mem.micromanaged", 2), log("log.micromanage_snap", 2, "boss")],
            score=[s_trait("target", "temper", 1.3), s_stress("target", 0.012)]),
        out("charm", [say("target", "hover_charm", to="actor", delay=1.6), say("actor", "boss_chuckle", delay=3.0), rel("actor", "target", "friendship", 3)],
            score=[s_trait("target", "humor", 1.2)], when=[c_trait("target", "humor", gt=0.6)]),
    ])

L("dump_work", ["I need this report by end of day. Urgent.", "Drop everything. HQ wants numbers. Today.", "Here. This is yours now. By five."])
L("dump_accept", ["...Sure. Of course.", "I'll stay late. Fine.", "Okay. No problem. Big problem. Okay."])
L("dump_push_back", ["By five? That's impossible.", "I'm already drowning, Ahmet Bey.", "Can it wait until tomorrow? Please?"])
L("boss_not_negotiable", ["It's not a request.", "Five o'clock. Final.", "Everyone's busy. Do it anyway."])
L("pass_the_buck", ["{to}! Great learning opportunity for you!", "{to}, you're good with numbers, right?"], deniz=["{to}, this will look great on your CV."])
L("buck_taken", ["Oh! Sure! I'll... figure it out!", "Um. Okay. How hard can it be?"], burak=["...Fine. Again."])
S_("log.work_dump", "Ahmet dumped an urgent report on {target} at the last minute.")
S_("log.work_dump_pushback", "{target} pushed back on Ahmet's last-minute report. Ahmet didn't budge.")
S_("log.work_dump_passed", "Ahmet dumped an urgent report on {target}, who promptly passed it to {helper}.")
S_("mem.dumped_on", "Ahmet dumped urgent work on me at the last minute.")
initiative("work_dump", "medium", cooldown_days=1, scope="global",
    roles=[actor([c_is("self", "ahmet"), c_time(after="13:30", before="16:00")], [s_stress("self", 0.02), s_goal("self", "impress_hq", 1.0)]),
           role("target", where=[c_is("self", "ahmet", neg=True), c_avail("self")], score=[{"s": "favor", "who": "self", "w": -0.02}, s_rand(0.8)])],
    effects=[visit("actor", "target", "work_dump_scene", prio=62, ttl=40)])
scene("work_dump_scene", noise=0.8, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), say("actor", "dump_work", to="target"), call("extra_work", target="target", units=20, task="urgent_report")],
    roles=[role("helper", where=[c_avail("self"), c_is("self", "ahmet", neg=True)],
                score=[s_is("self", "ece", 1.5), s_aff("target", "self", -0.01), s_rand(0.4)], optional=True)],
    outcomes=[
        out("accept", [say("target", "dump_accept", to="actor", delay=1.6), stress("target", 12), morale("target", -2),
                       mem("target", "actor", "overworked", -0.4, 0.6, "mem.dumped_on", 2), favor("target", 2), log("log.work_dump", 2, "boss")],
            score=[s_trait("target", "diligence", 1.0), s_trait("target", "temper", -0.6)]),
        out("push", [say("target", "dump_push_back", to="actor", delay=1.6), say("actor", "boss_not_negotiable", to="target", delay=3.2),
                     expr("target", "angry", 5, delay=3.2), stress("target", 15), rel("target", "actor", "friendship", -8), favor("target", -3),
                     mem("target", "actor", "overworked", -0.6, 0.8, "mem.dumped_on", 2), log("log.work_dump_pushback", 3, "boss")],
            score=[s_trait("target", "temper", 1.2), s_stress("target", 0.012)]),
        out("pass", [say("target", "dump_accept", to="actor", delay=1.6),
                     visit("target", "helper", "buck_scene", prio=60, ttl=30, delay=3),
                     log("log.work_dump_passed", 2, "boss")],
            score=[s_trait("target", "cunning", 1.4)], when=[c_present("helper"), c_trait("target", "cunning", gt=0.5)]),
    ])
scene("buck_scene", conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 4), say("actor", "pass_the_buck", to="target"), say("target", "buck_taken", to="actor", delay=1.6),
             {"e": "call", "fn": "extra_work", "target": "target", "units": 16, "task": "urgent_report"}, work("actor", 20),
             stress("target", 8), rel("target", "actor", "friendship", -4), mem("target", "actor", "dumped_on_me", -0.3, 0.6, "mem.passed_buck", 2)])
S_("mem.passed_buck", "{actor} handed me their urgent work.")

L("rule_announce", ["Attention! From today: no personal mugs in the kitchen.", "New rule: meetings start five minutes EARLY. Always.",
                    "From now on, lunch is thirty minutes. Not thirty-five.", "Effective immediately: no headphones at desks."])
L("rule_grumble", ["Are you serious?", "That's ridiculous.", "Here we go again.", "Who comes up with this?"],
  burak=["...No headphones. Wonderful."], mert=["What about emotional-support mugs?"], zeynep=["I'm writing this down. For posterity."])
L("rule_support", ["Good idea, Ahmet Bey.", "Makes sense!", "Discipline is important."], deniz=["Excellent policy. Long overdue."])
S_("log.new_rule", "Ahmet announced a new office rule. Nobody asked for it.")
initiative("new_rule", "medium", cooldown_days=3, scope="global",
    roles=[actor([c_is("self", "ahmet"), c_time(after="10:30", before="16:00")], [s_goal("self", "keep_control", 1.0), s_stress("self", 0.01)])],
    effects=[go_place("actor", "announce", "new_rule_scene", prio=60, ttl=30)])
scene("new_rule_scene",
    effects=[say("actor", "rule_announce"), sfx("slam"),
             each([say("self", "rule_grumble", p=0.5, delay=1.5, when=[c_rel("self", "actor", "trust", lt=35)]),
                   say("self", "rule_support", p=0.5, delay=1.5, when=[c_rel("self", "actor", "trust", gt=35)]),
                   morale("self", -2, when=[c_rel("self", "actor", "trust", lt=35)]), emote("self", "cloud", when=[c_rel("self", "actor", "trust", lt=25)])],
                  exclude=["actor"], stagger=0.6),
             favor("@deniz", 2), log("log.new_rule", 2, "boss")])

L("bet_pitch", ["Betting pool! Who gets the next promotion? Five lira.", "Office pool's open. Selin or Deniz?", "Place your bets, folks."],
  mert=["Ladies and gentlemen, the promotion pool is OPEN."])
L("bet_place", ["Put me down for Selin.", "Deniz. He'll find a way.", "Ten on the dark horse.", "I'm not betting on my colleagues! ...Fine, five."])
L("bet_boss_caught", ["Is that a BETTING POOL in my office?", "Mert. My office. Now."])
S_("log.bet_pool", "{actor} started a betting pool on the next promotion. {target} placed a bet.")
S_("log.bet_pool_caught", "{actor}'s promotion betting pool was discovered by Ahmet.")
initiative("bet_pool", "small", cooldown_days=2,
    roles=[actor([c_trait("self", "humor", gt=0.75)], [s_trait("self", "humor", 1.0)]),
           role("target", where=[c_avail("self"), c_is("self", in_=["selin", "deniz"], neg=True)], score=[s_aff("actor", "self", 0.02), s_rand(0.5)])],
    effects=[visit("actor", "target", "bet_scene", prio=50, ttl=40)])
scene("bet_scene", conditions=[c_avail("target")],
    roles=[role("boss", where=[c_is("self", "ahmet")], near="actor", r=5.0, optional=True, avail=False)],
    effects=[hold(["actor", "target"], 4), say("actor", "bet_pitch", to="target"), say("target", "bet_place", to="actor", delay=1.6),
             rel("actor", "target", "friendship", 3, both=True), log("log.bet_pool", 1, "promotion")],
    outcomes=[
        out("caught", [say("boss", "bet_boss_caught", to="actor", delay=3.0), expr("boss", "angry", 5, delay=3.0), emote("actor", "sweat", delay=3.2),
                       favor("actor", -4), stress("actor", 8), log("log.bet_pool_caught", 2, "boss")],
            score=[s_const(3)], when=[c_filled("boss")]),
        out("fine", [], score=[s_const(1)]),
    ])

# =====================================================================
# 3. RIVALRY
# =====================================================================
L("brag_line", ["Closed three deals before lunch. How about you?", "Ahmet Bey loved my numbers. Just saying.", "Did you see my report? Everyone did."],
  deniz=["Funny how my numbers keep beating yours.", "I'd offer to help, but you seem... busy."], selin=["My client renewed. Two years. Beat that."])
L("brag_retort", ["Congratulations. Want a medal?", "Great. Now do it without stealing anyone's slides.", "Wow. Did you also invent coffee?"],
  selin=["Talk is cheap. Results are on my desk."], deniz=["Cute. Call me when you're senior."])
L("brag_ignore", ["Mm-hm. Good for you.", "...Okay.", "I'm busy."])
S_("log.brag", "{actor} went over to {target}'s desk to brag. The rivalry is heating up.")
initiative("brag_visit", "small", cooldown=150,
    roles=[actor([c_mood("self", gt=0)], [s_trait("self", "ambition", 0.6), s_mood("self", 0.01)]),
           by_fn("target", "rival_of", lim=35)],
    effects=[visit("actor", "target", "brag_scene", prio=52, ttl=35)])
scene("brag_scene", noise=0.8, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 4.5), say("actor", "brag_line", to="target")],
    outcomes=[
        out("retort", [say("target", "brag_retort", to="actor", delay=1.6), expr("target", "angry", 4, delay=1.6),
                       rel("actor", "target", "rivalry", 5, both=True), stat("jealousy"), log("log.brag", 2, "rivalry")],
            score=[s_trait("target", "temper", 1.0), s_rel("target", "actor", "rivalry", 0.015)]),
        out("ignore", [say("target", "brag_ignore", delay=1.6), mood("actor", -3)], score=[s_trait("target", "empathy", 0.6), s_const(0.4)]),
    ])

L("sabotage_mutter", ["Let's see how you like this...", "Oops. Clumsy me.", "Payback time."], deniz=["Nothing personal. Just business."])
S_("log.desk_sabotage", "{actor} sneaked over to {target}'s empty desk and wrecked their paperwork. Nobody saw. Probably.")
S_("log.desk_sabotage_seen", "{actor} wrecked {target}'s desk — and {spotter} saw the whole thing.")
initiative("desk_sabotage", "medium", cooldown_days=2,
    roles=[actor([c_trait("self", "cunning", gt=0.5), c_any(c_plan("self", "revenge"), c_plan("self", "undermine"), c_trait("self", "honesty", lt=0.3))],
                 [s_trait("self", "cunning", 1.0), s_plan("self", "revenge", 1.5), s_plan("self", "undermine", 1.0)]),
           role("target", where=[c_present("self"), {"c": "activity", "who": "self", "in": ["work", "review", "arrive"], "not": True},
                                 c_any(c_plan("actor", "revenge", "self"), c_plan("actor", "undermine", "self"), c_rel("actor", "self", "rivalry", gt=55))],
                score=[s_rel("actor", "self", "rivalry", 0.02), s_plan("actor", "revenge", 2.0, target="self")], avail=False)],
    effects=[go_desk("actor", "target", "desk_sabotage_scene", prio=60, ttl=25)])
scene("desk_sabotage_scene", allow_absent=True,
    conditions=[c_present("actor"), {"c": "activity", "who": "target", "in": ["work", "review", "arrive"], "not": True}],
    roles=[role("spotter", where=[c_avail("self")], score=[s_trait("self", "curiosity", 1.0)], near="actor", r=3.6, optional=True)],
    effects=[emote("actor", "whisper"), say("actor", "sabotage_mutter"), call("mess_desk", target="target"), sfx("papers"),
             plan("actor", "revenge", "target", v=False), plan("actor", "undermine", "target", heat=-0.5)],
    outcomes=[
        out("seen", [emote("spotter", "exclaim", delay=1.2), rumor("sabotage", a="actor", b="target", juicy=0.85, knowers=["spotter"]),
                     log("log.desk_sabotage_seen", 3, "scheme")], score=[s_const(2)], when=[c_filled("spotter")]),
        out("unseen", [log("log.desk_sabotage", 3, "scheme")], score=[s_const(1)]),
    ])

L("hide_prank_think", ["Hehe. This is going to be good.", "Let's see how long it takes them...", "Comedy is all about timing."])
S_("log.hide_prank", "{actor} hid {target}'s {item} as a joke.")
initiative("hide_prank", "small", cooldown_days=2,
    roles=[actor([c_trait("self", "humor", gt=0.6)], [s_trait("self", "humor", 1.0), s_plan("self", "revenge", 1.2)]),
           role("target", where=[c_present("self"), {"c": "activity", "who": "self", "in": ["work", "review"], "not": True}],
                score=[s_aff("actor", "self", 0.01), s_plan("actor", "revenge", 2.0, target="self"), s_rand(0.5)], avail=False)],
    vars=[var("item", "own_item_of", of="target")],
    conditions=[c_var("item", in_=["mug", "charger", "planner", "glasses"])],
    effects=[go_desk("actor", "target", "hide_prank_scene", prio=52, ttl=25)])
scene("hide_prank_scene", allow_absent=True, conditions=[c_present("actor")],
    effects=[emote("actor", "whisper"), say("actor", "hide_prank_think"), call("hide_item", item="$item", to="lounge"),
             rumor("prank", a="actor", b="target", juicy=0.4, knowers=["actor"]), plan("actor", "revenge", "target", v=False),
             log("log.hide_prank", 2, "prank")])

# =====================================================================
# 4. FRIENDSHIP
# =====================================================================
L("lunch_ask", ["Lunch together today?", "Want to grab lunch? My treat. Partly.", "Kebab place? You and me?"],
  ece=["Can I sit with you at lunch?"], mert=["Lunch? I know a guy who knows a guy who makes great lahmacun."])
L("lunch_yes", ["Yes! Please. Save me from my desk.", "Sure, let's go.", "Deal."])
L("lunch_no", ["Sorry, I'm eating at my desk today.", "Can't, deadline.", "Maybe tomorrow?"])
S_("log.lunch_together", "{actor} and {target} are having lunch together.")
initiative("lunch_invite", "small", cooldown_days=1,
    roles=[actor([c_time(after="11:30", before="12:55"), c_trait("self", "sociability", gt=0.4)], [s_trait("self", "sociability", 1.0)]),
           by_fn("target", "best_of", lim=12)],
    conditions=[c_npcflag("actor", "lunch_invited", neg=True)],
    effects=[visit("actor", "target", "lunch_invite_scene", prio=52, ttl=30)])
scene("lunch_invite_scene", noise=0.8, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 3.5), say("actor", "lunch_ask", to="target"), npcflag("actor", "lunch_invited")],
    outcomes=[
        out("yes", [say("target", "lunch_yes", to="actor", delay=1.5), emote("target", "ok", delay=1.5), rel("actor", "target", "friendship", 5, both=True),
                    call("lunch_sync", target="target"), log("log.lunch_together", 1, "friendship")],
            score=[s_aff("target", "actor", 0.03), s_const(0.5)]),
        out("no", [say("target", "lunch_no", to="actor", delay=1.5), mood("actor", -3)], score=[s_stress("target", 0.015), s_const(0.2)]),
    ])

L("snack_offer", ["You look like you need this. Simit.", "Here — chocolate. Doctor's orders.", "Brought you a snack. Breathe."],
  ece=["I baked cookies! They're... mostly cookie-shaped."], ceren=["Tea and a biscuit. Five minutes off. Go."])
L("snack_thanks", ["You're an angel.", "Oh, thank you. Really.", "I needed that more than you know."], burak=["...Thanks. Seriously."])
S_("log.snack", "{actor} noticed {target} was stressed and brought them a snack.")
S_("mem.brought_snack", "{actor} brought me a snack when I was drowning.")
initiative("bring_snack", "small", cooldown=120, weight=1.3,
    roles=[actor([c_trait("self", "empathy", gt=0.55)], [s_trait("self", "empathy", 1.2)]),
           role("target", where=[c_avail("self"), c_stress("self", gt=28)], score=[s_stress("self", 0.02), s_aff("actor", "self", 0.01)])],
    effects=[visit("actor", "target", "snack_scene", prio=52, ttl=35)])
scene("snack_scene", conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 4), say("actor", "snack_offer", to="target"), say("target", "snack_thanks", to="actor", delay=1.5),
             emote("target", "love", delay=1.5), stress("target", -12), mood("target", 8), rel("target", "actor", "friendship", 8),
             mem("target", "actor", "helped_me", 0.6, 0.7, "mem.brought_snack", 2), log("log.snack", 1, "friendship")])

L("inside_joke", ["Remember the fax machine incident?", "Say it. Say the thing.", "...Pineapple.", "Same time next year?"])
L("inside_laugh", ["HAHAHA stop!", "I can't breathe!", "Every time!", "*wheezes*"])
S_("log.inside_joke", "{actor} and {target} are cracking up in the kitchen over an inside joke.")
initiative("inside_joke", "small", cooldown=120,
    roles=[actor([c_trait("self", "humor", gt=0.4)], [s_trait("self", "humor", 0.8), s_trait("self", "sociability", 0.4)]),
           by_fn("target", "best_of", lim=30)],
    effects=[emote("actor", "wave"), meetup("inside_joke_scene", area="kitchen", ttl=30)])
scene("inside_joke_scene",
    effects=[hold(["actor", "target"], 4.5), say("actor", "inside_joke", to="target"), say("target", "inside_laugh", delay=1.4),
             emote("actor", "cheer", delay=1.4), emote("target", "cheer", delay=1.4), expr("actor", "happy", 5), expr("target", "happy", 5, delay=1.4),
             mood("actor", 6), mood("target", 6), rel("actor", "target", "friendship", 4, both=True), log("log.inside_joke", 1, "friendship")])

L("cover_line", ["Oh, {actor}'s been in since early — went to pick up the client files for me.", "That's on me — I sent {actor} to the bank.",
                 "{actor} was here! Archive. Dust everywhere."])
L("boss_not_buying", ["Nice try. Very nice try.", "I wasn't born yesterday.", "Mm-hm. Both of you, back to work."])
L("boss_buys_it", ["Hm. Fine.", "Next time, tell me first.", "Oh. Alright then."])
S_("log.cover_friend", "{friend} covered for {actor}'s late arrival. Ahmet bought it.")
S_("log.cover_friend_fail", "{friend} tried to cover for {actor}'s late arrival. Ahmet didn't buy it.")
S_("mem.covered_for_me", "{friend} covered for me with Ahmet.")
ev(id="cover_for_friend", trigger="late_to_work", priority=48, also=True, tier="medium", allow_absent=True,
   roles=[role("friend", where=[c_avail("self"), c_is("self", "ahmet", neg=True), c_aff("self", "actor", gt=30)],
               score=[s_aff("self", "actor", 0.02), s_trait("self", "empathy", 0.6)], exclude=["actor"])],
   conditions=[c_present("@ahmet"), c_is("actor", "ahmet", neg=True), c_chance(0.55)],
   effects=[say("friend", "cover_line", to="@ahmet", delay=2.6)],
   outcomes=[
       out("believed", [say("@ahmet", "boss_buys_it", delay=4.0), favor("actor", 3), rel("actor", "friend", "friendship", 10), rel("actor", "friend", "trust", 6),
                        mem("actor", "friend", "defended_me", 0.6, 0.8, "mem.covered_for_me", 2), log("log.cover_friend", 2, "protect", who=["friend", "actor"])],
           score=[s_rel("@ahmet", "friend", "trust", 0.025), s_trait("friend", "cunning", 0.5)]),
       out("caught", [say("@ahmet", "boss_not_buying", delay=4.0), rel("@ahmet", "friend", "trust", -8), favor("friend", -3),
                      rel("actor", "friend", "friendship", 6), log("log.cover_friend_fail", 2, "protect", who=["friend", "actor"])],
           score=[s_trait("@ahmet", "temper", 0.8), s_const(0.4)]),
   ])

L("congrats", ["Heard Ahmet loved your work. Well done!", "Look at you, star of the day!", "Congrats! You earned it."])
L("congrats_thanks", ["Thanks! That means a lot.", "Aw, thank you!", "Ha, thanks."])
S_("log.congrats", "{actor} went over to congratulate {target}.")
initiative("congratulate", "small", cooldown=90,
    roles=[actor([c_trait("self", "empathy", gt=0.4)], [s_trait("self", "empathy", 0.8)]),
           role("target", where=[c_avail("self"), c_mem("self", "praised", days=0), c_aff("actor", "self", gt=12), c_rel("actor", "self", "rivalry", lt=40)],
                score=[s_aff("actor", "self", 0.02)])],
    effects=[visit("actor", "target", "congrats_scene", prio=50, ttl=35)])
scene("congrats_scene", conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 3.5), say("actor", "congrats", to="target"), say("target", "congrats_thanks", to="actor", delay=1.4),
             emote("target", "cheer", delay=1.4), rel("target", "actor", "friendship", 5), mood("target", 4), log("log.congrats", 1, "friendship")])

L("confide_open", ["Can you keep a secret? Like, really keep it?", "Between us. Promise?", "I have to tell someone or I'll explode."])
L("confide_tell", ["{fact}", "So... {fact}", "Okay. {fact} Don't tell anyone."])
L("confide_promise", ["My lips are sealed.", "I won't say a word.", "Wow. Okay. Safe with me."])
L("confide_wow", ["No WAY.", "Shut up. Really?!", "Oh, that's juicy."])
S_("log.confide", "{actor} confided a secret to {target} in the lounge: \"{fact}\"")
initiative("confide", "small", cooldown=180,
    roles=[actor([], [s_trait("self", "sociability", 0.5), s_trait("self", "gossip", 0.4)]),
           by_fn("target", "best_of", lim=35)],
    vars=[var("fact", "any_secret", knower="actor", **{"not": "target"})],
    conditions=[c_knows("target", "$fact", neg=True)],
    effects=[meetup("confide_scene", area="lounge", ttl=35)])
scene("confide_scene",
noise=0.8,
    effects=[hold(["actor", "target"], 5), emote("actor", "whisper"), say("actor", "confide_open", to="target"),
             say("actor", "confide_tell", to="target", delay=1.5), learn("target", "$fact", frm="actor"), reveal("$fact"),
             rel("actor", "target", "trust", 5, both=True), log("log.confide", 2, "secret")],
    outcomes=[
        out("promise", [say("target", "confide_promise", to="actor", delay=3.0)], score=[s_trait("target", "honesty", 1.0)]),
        out("wow", [say("target", "confide_wow", to="actor", delay=3.0), emote("target", "exclaim", delay=3.0)], score=[s_trait("target", "gossip", 1.2)]),
    ])

# =====================================================================
# 5. ROMANCE (secret)
# =====================================================================
L("note_drop_think", ["Just... leave it here. Anonymous. Smooth.", "No name. Mysterious. Perfect.", "Okay. Okay. Leave the note. RUN."])
L("note_read", ["A note? \"You make Mondays bearable.\" ...Who?!", "Who left this on my desk?", "\"Have a great day :)\" — no name?"])
S_("log.note_drop", "{actor} sneaked an anonymous note onto {target}'s desk.")
S_("log.note_found", "{actor} found an anonymous note on their desk and thinks it was {guess}. (It was {writer}.)")
S_("log.note_found_right", "{actor} found an anonymous note and guessed right: it was {writer}.")
initiative("note_drop", "small", cooldown_days=2,
    roles=[actor([{"c": "picks", "fn": "crush_of", "of": "self"}], [s_trait("self", "empathy", 0.4), s_goal("self", "win_ceren", 1.0)]),
           by_fn("target", "crush_of", avail=False, where=[{"c": "activity", "who": "self", "in": ["work", "review"], "not": True}])],
    effects=[go_desk("actor", "target", "note_drop_scene", prio=52, ttl=25)])
scene("note_drop_scene", allow_absent=True, conditions=[c_present("actor")],
    effects=[emote("actor", "love"), say("actor", "note_drop_think"), log("log.note_drop", 1, "romance"),
             chain("note_found", delay=18, roles={"actor": "target", "writer": "actor"})])
ev(id="note_found", trigger="", priority=55, allow_absent=True, conditions=[c_avail("actor")],
   vars=[var("guess", "best_of", of="actor", lim=-100, avail=False)],
   effects=[emote("actor", "love"), expr("actor", "surprised", 3), say("actor", "note_read")],
   outcomes=[
       out("right", [rel("actor", "writer", "friendship", 8), visit("actor", "writer", "admirer_ask", prio=45, ttl=50, delay=3),
                     log("log.note_found_right", 2, "romance")],
           score=[s_const(5)], when=[c_same("$guess", "writer")]),
       out("wrong", [visit("actor", "$guess", "admirer_ask", prio=45, ttl=50, delay=3), log("log.note_found", 2, "misunderstanding")],
           score=[s_const(1)], when=[c_present("$guess")]),
   ])

L("date_whisper", ["Hi. Act normal.", "Five minutes. Nobody's looking.", "I saved you the last simit."],
  mert=["Is it weird that I rehearsed this?"], ceren=["We have exactly four minutes before Ahmet needs me."])
L("date_reply", ["Hi yourself.", "You're ridiculous. Thank you.", "Shh, someone's coming."])
L("spot_couple", ["Well, well, well...", "Oh-ho! What do we have here?", "I KNEW it."], zeynep=["Christmas came early."])
S_("log.coffee_date", "{actor} and {target} snuck off to the kitchen together. Again.")
S_("log.coffee_date_spotted", "{spotter} caught {actor} and {target} being very cosy by the coffee machine.")
initiative("coffee_date", "small", cooldown=150,
    roles=[actor([{"c": "picks", "fn": "crush_of", "of": "self"}], [s_goal("self", "win_ceren", 0.8), s_trait("self", "sociability", 0.3)]),
           by_fn("target", "crush_of", where=[c_aff("self", "actor", gt=35)])],
    conditions=[c_any(c_bond("actor", "target", "romance"), c_aff("actor", "target", gt=55))],
    effects=[emote("actor", "love"), meetup("coffee_date_scene", area="kitchen", ttl=30)])
scene("coffee_date_scene",
noise=0.8,
    roles=[role("spotter", where=[c_avail("self"), c_trait("self", "gossip", gt=0.3)], score=[s_trait("self", "gossip", 1.0)], near="actor", r=5.0, optional=True)],
    effects=[hold(["actor", "target"], 5), say("actor", "date_whisper", to="target"), say("target", "date_reply", to="actor", delay=1.5),
             emote("actor", "love", delay=1.5), emote("target", "love", delay=1.5), expr("actor", "happy", 5), expr("target", "happy", 5),
             rel("actor", "target", "friendship", 5, both=True), mood("actor", 6), mood("target", 5), log("log.coffee_date", 1, "romance")],
    outcomes=[
        out("spotted", [say("spotter", "spot_couple", delay=2.6), emote("spotter", "idea", delay=2.6),
                        rumor("couple", juicy=0.85, knowers=["spotter"], when=[c_bond("actor", "target", "romance")]),
                        rumor("crush", juicy=0.7, knowers=["spotter"], when=[c_bond("actor", "target", "romance", neg=True)]),
                        log("log.coffee_date_spotted", 2, "romance")], score=[s_const(2)], when=[c_filled("spotter")]),
        out("alone", [], score=[s_const(1)]),
    ])

# =====================================================================
# 6. JEALOUSY
# =====================================================================
L("jealous_friend_mutter", ["Since when are THEY best friends?", "Oh, so {actor} has a new favourite.", "Hmph. I see how it is."],
  ece=["...They didn't invite me."], mert=["Burak's replacing me? With HIM?"])
S_("log.jealous_friend", "{spotter} saw their best friend {actor} laughing with {target} and felt left out.")
ev(id="jealous_friend", trigger=["encounter", "chat"], priority=48, also=True, tier="small", scope="pair", cooldown_days=2, max_day=1,
   roles=[role("spotter", where=[c_avail("self"), c_aff("self", "actor", gt=42), c_aff("self", "target", lt=18)],
               score=[s_aff("self", "actor", 0.02)], near="actor", r=5.0)],
   conditions=[c_aff("actor", "target", gt=35), c_chance(0.06)],
   effects=[expr("spotter", "sad", 5), emote("spotter", "cloud"), say("spotter", "jealous_friend_mutter"),
            rel("spotter", "target", "rivalry", 6), rel("spotter", "actor", "friendship", -2), stat("jealousy"),
            log("log.jealous_friend", 2, "jealousy", who=["spotter", "actor"])])

L("heartbreak_jab", ["Cute. Really cute. You two.", "Hope you're happy together.", "Don't mind me. Just getting water."],
  burak=["...Congratulations, I guess."])
L("heartbreak_reply", ["Uh... thanks?", "Is something wrong?", "Okay, what's that tone about?"])
S_("log.heartbreak", "{actor} saw {crush} with {target} and is quietly heartbroken. The tension is obvious.")
S_("mem.heartbreak", "{crush} chose {target}.")
initiative("heartbreak", "medium", cooldown_days=2,
    roles=[actor([{"c": "picks", "fn": "crush_of", "of": "self", "taken": True}], [s_trait("self", "empathy", 0.3), s_const(0.3)]),
           by_fn("crush", "crush_of", avail=False, taken=True),
           role("target", where=[c_bond("crush", "self", "romance"), c_avail("self")], exclude=["actor", "crush"])],
    effects=[expr("actor", "sad", 6), emote("actor", "cloud"), visit("actor", "target", "heartbreak_scene", prio=50, ttl=35, roles={"crush": "crush"})])
scene("heartbreak_scene", conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 4), say("actor", "heartbreak_jab", to="target"), say("target", "heartbreak_reply", to="actor", delay=1.6),
             rel("actor", "target", "rivalry", 15), rel("actor", "target", "friendship", -8), mood("actor", -12), morale("actor", -3),
             mem("actor", "crush", "heartbreak", -0.5, 0.8, "mem.heartbreak", 3), stat("jealousy"), log("log.heartbreak", 3, "jealousy")])

# =====================================================================
# 7. MISUNDERSTANDINGS
# =====================================================================
L("sarcasm", ["Wow, another meeting. My favourite.", "Love what you've done with your desk. Very... brave.", "Great shirt. Bold choice for an adult."],
  mert=["Nice tie! Did you lose a bet?"], zeynep=["Oh, you're wearing THAT? Brave."], deniz=["Interesting approach to the report. Very... creative."])
L("sarcasm_hurt", ["...Excuse me?", "Wow. Okay. Thanks.", "Was that supposed to be funny?"], burak=["I'll remember that."], selin=["Is that what you think of me?"])
L("sarcasm_explain", ["I was JOKING!", "Kidding! It was a joke!", "Oh no, that came out wrong."])
L("sarcasm_laugh", ["Ha! Fair.", "Rude. Accurate, but rude.", "Hahaha, okay, you got me."])
S_("log.sarcasm_hurt", "{actor} made a joke. {target} didn't take it as one.")
S_("mem.sarcasm", "{actor} mocked me.")
initiative("sarcasm_misfire", "small", cooldown=180,
    roles=[actor([c_trait("self", "humor", gt=0.5)], [s_trait("self", "humor", 1.0), s_mood("self", 0.01)]),
           role("target", where=[c_avail("self")], score=[s_trait("self", "humor", -1.0), s_dist("actor", "self", -0.1), s_rand(0.5)])],
    effects=[visit("actor", "target", "sarcasm_scene", prio=48, ttl=30)])
scene("sarcasm_scene", noise=0.8, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 4.5), say("actor", "sarcasm", to="target")],
    outcomes=[
        out("hurt", [say("target", "sarcasm_hurt", to="actor", delay=1.6), say("actor", "sarcasm_explain", to="target", delay=3.0),
                     expr("target", "sad", 5, delay=1.6), rel("target", "actor", "friendship", -8), rel("target", "actor", "trust", -4),
                     mem("target", "actor", "mocked", -0.4, 0.7, "mem.sarcasm", 2), log("log.sarcasm_hurt", 2, "misunderstanding")],
            score=[s_trait("target", "humor", -1.4), s_stress("target", 0.01), s_aff("target", "actor", -0.01)]),
        out("laugh", [say("target", "sarcasm_laugh", to="actor", delay=1.6), rel("target", "actor", "friendship", 3)],
            score=[s_trait("target", "humor", 1.2), s_aff("target", "actor", 0.01)]),
    ])

L("wrong_name_call", ["Ceren! Er— Ece. Whoever. Bring me the file.", "Selin, the— Zeynep. Yes. You.", "Mert! I mean Burak. The computer man."])
L("wrong_name_reply", ["...It's {target}, actually.", "Still {target}. Three years now.", "Close enough, I guess."], ece=["That's okay! Everyone does it! ...Do they?"])
S_("log.wrong_name", "Ahmet called {target} by the wrong name. Again.")
initiative("wrong_name", "small", cooldown_days=2, scope="global",
    roles=[actor([c_is("self", "ahmet")], [s_stress("self", 0.02), s_const(0.3)]),
           role("target", where=[c_avail("self")], near="actor", r=6.0, score=[s_rand(1.0)])],
    effects=[hold(["actor", "target"], 3.5), say("actor", "wrong_name_call", to="target"), say("target", "wrong_name_reply", to="actor", delay=1.6),
             emote("target", "cloud", delay=1.6), morale("target", -1), witness([say("self", "eye_roll", p=0.3, delay=2.6)], r=5),
             log("log.wrong_name", 1, "boss", who="target")])

# =====================================================================
# 8–9. QUITTING TALK, JOB HUNTING, INTERVIEWS
# =====================================================================
L("quit_vent", ["I swear, one more day like this and I quit.", "I'm updating my CV tonight. I mean it.", "Why do I even work here?"],
  burak=["The job market can't be worse than this."], selin=["If that promotion doesn't come, I'm gone."], zeynep=["I could audit a much nicer company."])
L("quit_comfort", ["Hey. Don't decide anything angry. Sleep on it.", "We'd fall apart without you, you know.", "Come on. Kebab after work. On me."])
L("quit_egg_on", ["Honestly? Do it. You're wasted here.", "If I were you, I'd already be gone.", "Show them. Walk out."], deniz=["You should absolutely leave. For your own good."])
S_("log.quit_vent", "{actor} told {target} in the kitchen that they're thinking of quitting.")
S_("log.quit_vent_egged", "{actor} vented about quitting — and {target} told them to go for it.")
initiative("quit_vent", "small", cooldown_days=1,
    roles=[actor([c_morale("self", lt=42), c_is("self", "ahmet", neg=True)], [s_morale("self", -0.03), s_stress("self", 0.01)]),
           by_fn("target", "best_of", lim=0)],
    effects=[emote("actor", "cloud"), meetup("quit_vent_scene", area="kitchen", ttl=35)])
scene("quit_vent_scene",
noise=0.8,
    effects=[hold(["actor", "target"], 5), expr("actor", "sad", 5), say("actor", "quit_vent", to="target")],
    outcomes=[
        out("comfort", [say("target", "quit_comfort", to="actor", delay=1.6), morale("actor", 6), mood("actor", 6), rel("actor", "target", "friendship", 6),
                        mem("actor", "target", "helped_me", 0.5, 0.6, "mem.brought_snack", 1), log("log.quit_vent", 2, "job")],
            score=[s_trait("target", "empathy", 1.2), s_aff("target", "actor", 0.015)]),
        out("egg", [say("target", "quit_egg_on", to="actor", delay=1.6), plan("actor", "job_search", "", heat=1.2),
                    rumor("job_hunting", a="actor", b="target", juicy=0.7, knowers=["target"], c=0.8), log("log.quit_vent_egged", 2, "job")],
            score=[s_trait("target", "cunning", 0.8), s_rel("target", "actor", "rivalry", 0.02), s_const(0.3)]),
    ])

L("cv_think", ["CV... \"excellent team player.\" Ha.", "Let's just see what's out there.", "Updating my CV. Just in case."])
L("cv_spotted", ["Is that a job site on your screen?", "Ooh, LinkedIn. Interesting.", "Looking for something?"])
L("cv_cover", ["What? No! It's... research.", "That's for a friend!", "Mind your own screen."])
S_("log.update_cv", "{actor} is quietly updating their CV at their desk.")
S_("log.update_cv_spotted", "{spotter} spotted a job site on {actor}'s screen.")
initiative("update_cv", "small", cooldown_days=1,
    roles=[actor([c_act("self", ["work"]), c_any(c_morale("self", lt=40), c_plan("self", "job_search"), c_goal("self", "find_new_job"))],
                 [s_morale("self", -0.02), s_plan("self", "job_search", 1.0)]),
           role("spotter", where=[c_avail("self"), c_trait("self", "curiosity", gt=0.4)], near="actor", r=3.0, optional=True,
                score=[s_trait("self", "curiosity", 1.0)])],
    effects=[say("actor", "cv_think"), plan("actor", "job_search", "", heat=0.6), log("log.update_cv", 1, "job")],
    outcomes=[
        out("spotted", [say("spotter", "cv_spotted", to="actor", delay=1.6), say("actor", "cv_cover", to="spotter", delay=3.0), emote("actor", "sweat", delay=3.0),
                        rumor("job_hunting", juicy=0.7, knowers=["spotter"], c=0.65, b="spotter"), log("log.update_cv_spotted", 2, "job", who=["spotter", "actor"])],
            score=[s_const(2)], when=[c_filled("spotter")]),
        out("quiet", [], score=[s_const(1)]),
    ])

L("recruiter_line", ["Yes, this is me. Thursday works.", "Salary? Let's discuss that in person.", "No, I can talk. Quietly."],
  burak=["Yes, I can start in a month. ...No, they don't know."])
L("overheard_recruiter", ["Was that a recruiter?!", "Thursday? Interview?", "Ohhh. Someone's leaving."])
S_("log.recruiter", "{actor} took a hushed call in the hallway. A recruiter.")
S_("log.recruiter_heard", "{listener} overheard {actor} talking to a recruiter.")
initiative("recruiter_call", "small", cooldown_days=1,
    roles=[actor([c_any(c_plan("self", "job_search"), c_goal("self", "find_new_job"))], [s_plan("self", "job_search", 1.0), s_morale("self", -0.01)])],
    effects=[go_place("actor", "phone4", "recruiter_scene", prio=55, ttl=35, dur=6)])
scene("recruiter_scene",
    roles=[role("listener", where=[c_avail("self")], score=[s_trait("self", "curiosity", 1.0)], near="actor", r=4.2, optional=True)],
    effects=[act("actor", "phone", place="phone4", dur=5), say("actor", "recruiter_line"), log("log.recruiter", 1, "job")],
    outcomes=[
        out("heard", [emote("listener", "exclaim", delay=1.4), say("listener", "overheard_recruiter", delay=1.6),
                      rumor("job_hunting", juicy=0.75, knowers=["listener"], c=0.7, b="listener"), log("log.recruiter_heard", 2, "job", who=["listener", "actor"])],
            score=[s_const(2)], when=[c_filled("listener")]),
        out("alone", [], score=[s_const(1)]),
    ])

# =====================================================================
# 10. LOST DOCUMENTS
# =====================================================================
L("lost_report", ["Where's my report?! It was right here!", "My folder is GONE.", "Has anyone seen a blue folder?"],
  zeynep=["My invoices. My precious invoices. WHERE."], selin=["I put it here. I always put it here."])
L("found_misfiled", ["Found it — filed under \"miscellaneous\"?! Who did this?", "In the ARCHIVE. Under Q. Q!", "{suspect} filed this. I know that handwriting."])
L("found_own_fault", ["...Oh. It's in my own drawer.", "Found it. Exactly where I left it. Don't say anything.", "Ah. My mistake."])
L("still_lost", ["It's gone. Completely gone.", "I'll have to redo the whole thing.", "This is a nightmare."])
S_("log.misfiled_found", "{actor} tore the archive apart looking for a report — and found it misfiled. They blame {suspect}.")
S_("log.misfiled_own", "{actor} turned the archive upside down for a report that was in their own drawer.")
S_("log.misfiled_lost", "{actor}'s report is truly lost. They'll have to start over.")
S_("mem.misfiled", "{suspect} misfiled my report.")
initiative("lost_report", "small", cooldown_days=1,
    roles=[actor([c_work_left("self", gt=10)], [s_trait("self", "clumsiness", 0.6), s_trait("self", "diligence", -0.3), s_stress("self", 0.01)])],
    vars=[var("suspect", "clumsy_one", optional=True)],
    effects=[expr("actor", "surprised", 4), emote("actor", "question"), say("actor", "lost_report"), stress("actor", 6),
             go_place("actor", "archive", "archive_search_scene", prio=60, ttl=30, dur=6)])
scene("archive_search_scene",
noise=0.8,
    effects=[act("actor", "archive", place="archive", dur=5), sfx("papers")],
    outcomes=[
        out("misfiled", [say("actor", "found_misfiled", delay=2.5), expr("actor", "angry", 5, delay=2.5), rel("actor", "$suspect", "trust", -6),
                         mem("actor", "$suspect", "misfiled", -0.3, 0.6, "mem.misfiled", 2),
                         rumor("blamed", a="$suspect", b="actor", juicy=0.35, knowers=["actor"]), log("log.misfiled_found", 2, "documents")],
            score=[s_const(1.0), s_rand(0.6)], when=[c_filled("$suspect"), c_same("$suspect", "actor", neg=True)]),
        out("own", [say("actor", "found_own_fault", delay=2.5), emote("actor", "sweat", delay=2.5), mood("actor", -3), log("log.misfiled_own", 1, "documents")],
            score=[s_trait("actor", "clumsiness", 1.0), s_rand(0.6)]),
        out("lost", [say("actor", "still_lost", delay=2.5), expr("actor", "sad", 5, delay=2.5), stress("actor", 10), work("actor", -10),
                     log("log.misfiled_lost", 2, "documents")], score=[s_const(0.3), s_rand(0.5)]),
    ])

# =====================================================================
# 11. WRONG EMAILS (without the player)
# =====================================================================
L("reply_all_oops", ["Oh no. Oh no no no. That was REPLY ALL.", "Why did that go to EVERYONE?!", "Undo. UNDO. Where's undo?!"],
  mert=["...That cat video was meant for Burak only."], ece=["I sent my grocery list to the whole company."])
L("reply_all_react", ["HAHAHA, the cat!", "Oh, this is going in the hall of fame.", "Did everyone get that?", "Thanks for the... video?"])
L("boss_reply_all_laugh", ["...Ha. Okay, that cat is funny.", "Delete it. ...After I watch it again."])
S_("log.reply_all", "{actor} accidentally hit Reply All. The whole office got a cat video.")
S_("log.reply_all_boss", "{actor}'s Reply All disaster reached Ahmet. He was NOT amused.")
initiative("reply_all", "medium", cooldown_days=2, scope="global",
    roles=[actor([c_act("self", ["work"]), c_any(c_trait("self", "humor", gt=0.7), c_trait("self", "clumsiness", gt=0.6))],
                 [s_trait("self", "humor", 0.6), s_trait("self", "clumsiness", 0.8)])],
    effects=[expr("actor", "surprised", 6), emote("actor", "sweat"), say("actor", "reply_all_oops"), sfx("email"), stat("emails"),
             each([emote("self", "exclaim", delay=1.0), say("self", "reply_all_react", p=0.4, delay=1.4)], exclude=["actor", "@ahmet"], stagger=0.6),
             log("log.reply_all", 2, "email")],
    outcomes=[
        out("boss_laughs", [say("@ahmet", "boss_reply_all_laugh", delay=4.0)], score=[s_trait("@ahmet", "humor", 1.0), s_mood("@ahmet", 0.015)],
            when=[c_present("@ahmet")]),
        out("boss_angry", [call("scold", target="actor", reason="email", prio=62, delay=3), log("log.reply_all_boss", 2, "boss")],
            score=[s_trait("@ahmet", "temper", 1.0), s_stress("@ahmet", 0.01)], when=[c_present("@ahmet")]),
        out("no_boss", [], score=[s_const(0.1)]),
    ])

# =====================================================================
# 12. MEETING CRISES
# =====================================================================
L("hijack_line", ["If I may — I think what she's TRYING to say is...", "Let me just jump in here, because the real insight is mine.",
                  "Sorry to interrupt, but I had this idea first."], deniz=["Allow me to rescue this presentation."])
L("hijack_protest", ["Excuse me, I'm not finished.", "I'm PRESENTING, thank you.", "Could you not?"], selin=["I'll take questions at the END."])
L("boss_sides_hijack", ["No, no, let him speak. Interesting.", "Go on, Deniz."])
L("boss_stops_hijack", ["Let her finish.", "Wait your turn.", "Deniz. Sit."])
S_("log.meeting_hijack", "{hijacker} hijacked {actor}'s presentation — and Ahmet let him.")
S_("log.meeting_hijack_stopped", "{hijacker} tried to hijack {actor}'s presentation. Ahmet shut it down.")
ev(id="meeting_hijack", trigger="meeting_present", priority=60, also=True, tier="medium", allow_absent=True,
   roles=[role("hijacker", where=[c_act("self", ["meeting"]), c_is("self", "ahmet", neg=True), c_trait("self", "cunning", gt=0.55),
                                  c_rel("self", "actor", "rivalry", gt=30)],
               score=[s_rel("self", "actor", "rivalry", 0.02)], exclude=["actor", "target"], avail=False)],
   filter={"prepared": True},
   conditions=[c_chance(0.3), c_present("target")],
   effects=[say("hijacker", "hijack_line", delay=3.0), say("actor", "hijack_protest", to="hijacker", delay=4.6), expr("actor", "angry", 6, delay=4.6),
            rel("actor", "hijacker", "rivalry", 12), rel("actor", "hijacker", "friendship", -8)],
   outcomes=[
       out("boss_sides", [say("target", "boss_sides_hijack", delay=6.0), favor("hijacker", 5), favor("actor", -3), mood("actor", -10),
                          mem("actor", "hijacker", "credit_stolen", -0.6, 0.8, "mem.hijacked", 3), plan("actor", "revenge", "hijacker", heat=0.8),
                          log("log.meeting_hijack", 3, "meeting", who=["hijacker", "actor"])],
           score=[s_rel("target", "hijacker", "trust", 0.02), {"s": "favor", "who": "hijacker", "w": 0.02}]),
       out("boss_stops", [say("target", "boss_stops_hijack", delay=6.0), favor("hijacker", -4), mood("hijacker", -6),
                          log("log.meeting_hijack_stopped", 2, "meeting", who=["hijacker", "actor"])],
           score=[s_rel("target", "actor", "trust", 0.02), s_trait("target", "temper", 0.4)]),
   ])
S_("mem.hijacked", "{hijacker} hijacked my presentation.")

L("snore", ["Zzz... hrnk... zzz...", "*snooooore*", "...mmh, five more minutes..."])
L("snore_laugh", ["Is... is someone SNORING?", "Hahaha!", "Shh, let them sleep. It's adorable."])
L("boss_wake_up", ["Are we BORING you?", "Wake up! This is a meeting, not a hotel.", "Coffee. Now."])
S_("log.meeting_snore", "{sleeper} fell asleep in the meeting. Snoring included.")
ev(id="meeting_snore", trigger="meeting_banter", priority=40, also=True, tier="small", allow_absent=True, cooldown_days=2,
   roles=[role("sleeper", where=[c_act("self", ["meeting"]), c_is("self", "ahmet", neg=True), c_any(c_stress("self", gt=40), {"c": "trait", "who": "self", "t": "diligence", "lt": 0.5})],
               score=[s_stress("self", 0.02), s_rand(0.6)], exclude=["actor"], avail=False)],
   conditions=[c_chance(0.45)],
   effects=[say("sleeper", "snore", delay=1.0), each([say("self", "snore_laugh", p=0.4, delay=2.2), emote("self", "cheer", delay=2.2)], exclude=["sleeper", "actor"],
                                                       stagger=0.4, where=[c_act("self", ["meeting"])]),
            say("actor", "boss_wake_up", to="sleeper", delay=3.6), expr("sleeper", "surprised", 4, delay=3.8), stress("sleeper", 6), favor("sleeper", -3),
            rumor("snores", a="sleeper", b="actor", juicy=0.4, knowers=[]), witness([learn("self", "$rumor")], near="sleeper", r=6),
            log("log.meeting_snore", 2, "meeting", who="sleeper")])

L("ringtone", ["♪ Ring-a-ding-ding, answer the thing! ♪", "♪ BAKA BAKA BAKA ♪", "*phone plays a goat screaming*"])
L("ringtone_sorry", ["Sorry! Sorry! My nephew changed it!", "That's not mine. ...It's mine.", "I can explain!"])
S_("log.ringtone", "{joker}'s ringtone went off in the meeting. Everyone heard it.")
ev(id="meeting_ringtone", trigger="meeting_banter", priority=38, also=True, tier="small", allow_absent=True, cooldown_days=2,
   roles=[role("joker", where=[c_act("self", ["meeting"]), c_is("self", "ahmet", neg=True)],
               score=[s_trait("self", "humor", 1.0), s_trait("self", "clumsiness", 0.8), s_rand(0.5)], exclude=["actor"], avail=False)],
   conditions=[c_chance(0.35)],
   effects=[say("joker", "ringtone", delay=1.0), sfx("phone", delay=1.0), say("joker", "ringtone_sorry", delay=2.6), emote("joker", "sweat", delay=2.6),
            each([emote("self", "cheer", delay=2.0)], exclude=["joker", "actor"], where=[c_act("self", ["meeting"])]),
            expr("actor", "angry", 4, delay=3.0), favor("joker", -2), log("log.ringtone", 1, "meeting", who="joker")])

L("room_mine", ["Excuse me, I booked this room.", "I have this room until eleven.", "This room is reserved. For me."])
L("room_no_mine", ["No, I booked it. Check the calendar.", "I've had this booked since Monday!", "Then the calendar is lying."])
L("room_share", ["Fine. You take the left half.", "Okay, okay — ten minutes each.", "Let's not make this a thing."])
L("room_fight", ["I'm not moving.", "Neither am I.", "This is ridiculous."])
S_("log.room_double", "{actor} and {target} both booked the meeting room. Neither will leave.")
S_("log.room_share", "{actor} and {target} double-booked the meeting room and agreed to share it.")
initiative("room_double_booked", "medium", cooldown_days=2, scope="global",
    roles=[actor([c_any(c_meeting("ended", True), c_time(before="10:00"))], [s_trait("self", "ambition", 0.5), s_trait("self", "diligence", 0.3)]),
           role("target", where=[c_avail("self"), c_is("self", "ahmet", neg=True)], score=[s_rel("actor", "self", "rivalry", 0.02), s_rand(0.6)])],
    effects=[meetup("room_scene", area="meeting", ttl=30)])
scene("room_scene",
noise=0.8,
    effects=[hold(["actor", "target"], 5), say("actor", "room_mine", to="target"), say("target", "room_no_mine", to="actor", delay=1.6)],
    outcomes=[
        out("fight", [say("actor", "room_fight", to="target", delay=3.2), expr("actor", "angry", 5, delay=3.2), expr("target", "angry", 5, delay=1.6),
                      rel("actor", "target", "friendship", -6, both=True), rel("actor", "target", "rivalry", 6, both=True), stat("arguments"),
                      log("log.room_double", 2, "meeting")],
            score=[s_trait("actor", "temper", 0.8), s_trait("target", "temper", 0.8), s_rel("actor", "target", "rivalry", 0.015)]),
        out("share", [say("actor", "room_share", to="target", delay=3.2), rel("actor", "target", "friendship", 3, both=True), log("log.room_share", 1, "meeting")],
            score=[s_trait("actor", "empathy", 0.8), s_trait("target", "empathy", 0.8)]),
    ])

# =====================================================================
# 13. BLAMING EACH OTHER / 16. PROTECTING EACH OTHER  (hooks into scoldings)
# =====================================================================
L("blame_shift", ["To be fair, Ahmet Bey, {suspect} never sent me the data.", "I was waiting on {suspect}. Ask them.", "It's not my fault — {suspect} dropped the ball."],
  deniz=["I hate to say it, but {suspect} has been... unreliable lately."])
L("blame_shift_heard", ["EXCUSE me?!", "Are you kidding me?", "That is a flat-out lie!"])
S_("log.blame_shift", "{target} got scolded — and blamed {suspect} for it. {suspect} had nothing to do with it.")
S_("mem.blamed_me", "{target} blamed me for their mistake in front of Ahmet.")
ev(id="blame_shift", trigger="scolded", priority=55, also=True, tier="medium", allow_absent=True,
   vars=[var("suspect", "suspect", of="target", optional=True)],
   conditions=[c_any({"c": "all", "of": [c_trait("target", "cunning", gt=0.3), c_trait("target", "honesty", lt=0.7)]}, c_stress("target", gt=55)),
               c_filled("$suspect"), c_same("$suspect", "actor", neg=True), c_same("$suspect", "target", neg=True), c_present("$suspect"), c_chance(0.55)],
   effects=[say("target", "blame_shift", to="actor", delay=3.2), rel("actor", "$suspect", "trust", -8), favor("$suspect", -4), favor("target", 2),
            rumor("blamed", a="$suspect", b="target", juicy=0.5, truth=False, knowers=["actor"], origin="target"),
            say("$suspect", "blame_shift_heard", delay=4.8, when=[{"c": "near", "a": "$suspect", "b": "target", "lt": 6.0}]),
            learn("$suspect", "$rumor", when=[{"c": "near", "a": "$suspect", "b": "target", "lt": 6.0}]),
            mem("$suspect", "target", "falsely_accused", -0.7, 0.9, "mem.blamed_me", 3, when=[{"c": "near", "a": "$suspect", "b": "target", "lt": 6.0}]),
            plan("$suspect", "revenge", "target", heat=1.0, when=[{"c": "near", "a": "$suspect", "b": "target", "lt": 6.0}, c_trait("$suspect", "forgiveness", lt=0.6)]),
            log("log.blame_shift", 3, "blame", who=["target", "$suspect"])])

L("shield_line", ["Ahmet Bey, that's partly on me. I gave them the wrong numbers.", "Go easy — they were covering my work this morning.",
                  "With respect, that wasn't entirely their fault."], ceren=["Ahmet Bey, the schedule change came from me."])
L("boss_softens", ["...Fine. Both of you, fix it.", "Hm. Alright. Don't let it happen again.", "Next time, tell me sooner."])
S_("log.shield", "{friend} stepped in to take part of the blame when Ahmet scolded {target}.")
S_("mem.shielded", "{friend} stood up for me in front of Ahmet.")
ev(id="shield_from_boss", trigger="scolded", priority=54, also=True, tier="medium", allow_absent=True,
   roles=[role("friend", where=[c_avail("self"), c_is("self", "ahmet", neg=True), c_any(c_aff("self", "target", gt=40), c_bond("self", "target", "alliance"),
                                                                                       c_bond("self", "target", "mentor"))],
               score=[s_aff("self", "target", 0.02), s_trait("self", "empathy", 1.0), s_bond("self", "target", "mentor", 1.5)], near="target", r=6.5)],
   conditions=[c_chance(0.55)],
   effects=[say("friend", "shield_line", to="actor", delay=3.0), say("actor", "boss_softens", delay=4.6), favor("target", 2), favor("friend", -1),
            rel("target", "friend", "friendship", 12), rel("target", "friend", "trust", 10), mood("target", 5),
            mem("target", "friend", "defended_me", 0.8, 0.9, "mem.shielded", 3), stat("defenses"),
            log("log.shield", 3, "protect", who=["friend", "target"])])

# =====================================================================
# 14. SECRET ALLIANCES
# =====================================================================
L("pact_offer", ["We both know {enemy} is a problem. Maybe we help each other.", "You and me against {enemy}. Think about it.",
                 "I've got information. You've got access. Partners?"], deniz=["Let's be practical. {enemy} is in our way. Together, we move faster."])
L("pact_yes", ["...I'm listening.", "Deal. But this conversation never happened.", "Partners. Quietly."])
L("pact_no", ["I'm not getting involved in your schemes.", "No. And I'd stop if I were you.", "Leave me out of this."])
S_("log.alliance", "{actor} and {target} made a secret pact against {enemy} in the archive.")
S_("log.alliance_refused", "{actor} proposed a secret pact against {enemy}. {target} said no — and now knows what {actor} is up to.")
initiative("alliance_pact", "medium", cooldown_days=3,
    roles=[actor([c_trait("self", "cunning", gt=0.4)], [s_trait("self", "cunning", 1.2), s_trait("self", "ambition", 0.5)]),
           role("target", where=[c_avail("self"), c_aff("actor", "self", gt=5), c_bond("actor", "self", "alliance", neg=True)],
                score=[s_aff("actor", "self", 0.02), s_trait("self", "cunning", 0.8)])],
    vars=[var("enemy", "common_enemy")],
    effects=[emote("actor", "idea"), meetup("alliance_scene", area="archive", ttl=35)])
scene("alliance_scene",
noise=0.8,
    effects=[hold(["actor", "target"], 5.5), emote("actor", "whisper"), say("actor", "pact_offer", to="target")],
    outcomes=[
        out("yes", [say("target", "pact_yes", to="actor", delay=1.8), bond("actor", "target", "alliance"), plan("actor", "undermine", "$enemy", heat=1.2),
                    plan("target", "undermine", "$enemy", heat=0.8), rel("actor", "target", "trust", 10, both=True),
                    rumor("alliance", juicy=0.7, knowers=["actor", "target"]), log("log.alliance", 3, "alliance")],
            score=[s_trait("target", "cunning", 1.2), s_aff("target", "actor", 0.015), s_aff("target", "$enemy", -0.015)]),
        out("no", [say("target", "pact_no", to="actor", delay=1.8), rel("target", "actor", "trust", -10),
                   rumor("scheme", a="actor", b="$enemy", juicy=0.8, knowers=["target"]), log("log.alliance_refused", 3, "alliance")],
            score=[s_trait("target", "honesty", 1.2), s_aff("target", "$enemy", 0.015)]),
    ])

L("intel_trade", ["Here's what I know...", "Fresh intel. Listen.", "You didn't hear this from me."])
L("intel_nod", ["Useful. Very useful.", "Interesting...", "Now we're talking."])
S_("log.intel", "Secret allies {actor} and {target} met in the archive to trade information.")
initiative("alliance_intel", "small", cooldown=200,
    roles=[actor([c_bond("self", "*", "alliance")], [s_trait("self", "cunning", 1.0)]),
           role("target", where=[c_avail("self"), c_bond("actor", "self", "alliance")], score=[s_rand(1.0)])],
    vars=[var("fact", "any_secret", knower="actor", **{"not": "target"}, optional=True), var("fact2", "any_secret", knower="target", **{"not": "actor"}, optional=True)],
    effects=[meetup("intel_scene", area="archive", ttl=35)])
scene("intel_scene",
    effects=[hold(["actor", "target"], 5), emote("actor", "whisper"), say("actor", "intel_trade", to="target"), say("target", "intel_nod", to="actor", delay=1.6),
             learn("target", "$fact", frm="actor", when=[c_filled("$fact")]), learn("actor", "$fact2", frm="target", when=[c_filled("$fact2")]),
             rel("actor", "target", "trust", 4, both=True), log("log.intel", 2, "alliance")])

# =====================================================================
# 15. COMIC ACCIDENTS
# =====================================================================
L("chair_sink", ["Whoa— whoa— WHOA.", "Why is my chair sinking?!", "*slowly sinks below the desk*"])
L("chair_laugh", ["HAHAHA, where did you go?", "Man overboard!", "Someone get a crane!"], mert=["Captain going down with the ship!"])
L("chair_laugh_self", ["...I meant to do that.", "Well. That's my dignity gone.", "Hahaha, okay, that was funny."])
S_("log.chair_sink", "{actor}'s chair slowly sank until only their eyebrows were visible.")
initiative("chair_sink", "small", cooldown_days=1, scope="global",
    roles=[actor([c_act("self", ["work"])], [s_trait("self", "clumsiness", 1.0), s_rand(0.6)])],
    effects=[expr("actor", "surprised", 4), say("actor", "chair_sink"), fx("shake", "actor"), sfx("thump"),
             witness([say("self", "chair_laugh", p=0.5, delay=1.4), emote("self", "cheer", delay=1.4), mood("self", 3)], r=5.5),
             say("actor", "chair_laugh_self", delay=3.0, when=[c_trait("actor", "humor", gt=0.45)]),
             mood("actor", -4), log("log.chair_sink", 1, "accident")])

L("fridge_steal_think", ["Nobody will miss ONE yogurt.", "Whose börek is this? ...Mine now.", "Finders keepers."])
L("lunch_gone", ["WHO ATE MY LUNCH?!", "My börek! It had my NAME on it!", "Someone ate my food. I'm going to scream."],
  ahmet=["Whoever ate my lunch: I will find you."], burak=["...My sandwich. My one joy."])
L("lunch_suspect", ["It was {suspect}. I'm sure of it.", "I bet {suspect} did it.", "{suspect} was hovering by the fridge earlier..."])
S_("log.fridge_raid", "{actor} quietly ate {target}'s lunch from the fridge.")
S_("log.lunch_gone", "{target} discovered their lunch was eaten — and suspects {suspect}. (It was {actor}.)")
S_("log.lunch_gone_right", "{target} discovered their lunch was eaten — and correctly suspects {actor}.")
initiative("fridge_raid", "small", cooldown_days=2,
    roles=[actor([c_time(after="10:20", before="12:10"), c_trait("self", "honesty", lt=0.72)], [s_trait("self", "honesty", -1.0), s_trait("self", "humor", 0.3), s_rand(0.4)]),
           role("target", where=[c_present("self"), c_is("self", "actor", neg=True)], score=[s_aff("actor", "self", -0.01), s_rand(1.0)], avail=False)],
    effects=[go_place("actor", "fridge", "fridge_raid_scene", prio=50, ttl=25, roles={"target": "target"})])
scene("fridge_raid_scene", allow_absent=True, conditions=[c_present("actor")],
    effects=[emote("actor", "whisper"), say("actor", "fridge_steal_think"), call("take_lunch", target="target"),
             rumor("stole_lunch", a="actor", b="target", juicy=0.5, knowers=["actor"]), log("log.fridge_raid", 2, "accident")])
ev(id="lunch_gone", trigger="lunch_stolen", priority=55, allow_absent=True, tier="small",
   vars=[var("suspect", "suspect", of="target", loc="kitchen", optional=True)],
   conditions=[c_avail("target")],
   effects=[expr("target", "angry", 6), emote("target", "anger"), say("target", "lunch_gone"), mood("target", -10), npcflag("target", "lunch_victim")],
   outcomes=[
       out("right", [say("target", "lunch_suspect", delay=1.8), learn("target", "$rumor", when=[c_filled("$rumor")]), rel("target", "actor", "trust", -10),
                     setv("incident", "lunch"), visit("target", "actor", "accusation", prio=58, ttl=45, delay=3), log("log.lunch_gone_right", 2, "accident")],
           score=[s_const(5)], when=[c_same("$suspect", "actor"), c_present("actor")]),
       out("wrong", [say("target", "lunch_suspect", delay=1.8), rel("target", "$suspect", "trust", -8), setv("incident", "lunch"),
                     visit("target", "$suspect", "accusation", prio=58, ttl=45, delay=3), log("log.lunch_gone", 2, "misunderstanding")],
           score=[s_const(1)], when=[c_filled("$suspect"), c_present("$suspect")]),
       out("nobody", [say("target", "coffee_sad", delay=1.8)], score=[s_const(0.2)]),
   ])

L("kick_me_stick", ["*pat pat* Great work today, buddy!", "Hey, nice shirt. *pats back*", "Good job, champ. *slap on the back*"])
L("kick_me_giggle", ["*snort*", "Pfff— nothing! Nothing.", "Hahaha, did you see his back?"])
L("kick_me_found", ["Is there something on my— \"KICK ME\"?! MERT!", "Very funny. VERY funny.", "How long has THIS been on my back?!"])
L("kick_me_laugh", ["...Okay, I respect the commitment.", "Hah. You'll pay for this. Lovingly."])
S_("log.kick_me", "{actor} stuck a \"KICK ME\" note on {target}'s back. Half the office has seen it.")
S_("log.kick_me_found", "{target} finally found the note on their back.")
initiative("kick_me_note", "small", cooldown_days=2,
    roles=[actor([c_trait("self", "humor", gt=0.8)], [s_trait("self", "humor", 1.0)]),
           by_fn("target", "best_of", lim=20)],
    effects=[visit("actor", "target", "kick_me_scene", prio=50, ttl=30)])
scene("kick_me_scene", conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 3), say("actor", "kick_me_stick", to="target"), emote("actor", "whisper", delay=1.2),
             witness([say("self", "kick_me_giggle", p=0.5, delay=2.0)], near="target", r=5),
             rumor("prank", juicy=0.4, knowers=["actor"]), log("log.kick_me", 1, "accident"),
             chain("kick_me_found", delay=22, roles={"actor": "target", "target": "actor"})])
ev(id="kick_me_found", noise=0.8, trigger="", priority=50, allow_absent=True, conditions=[c_avail("actor")],
   effects=[expr("actor", "surprised", 4), say("actor", "kick_me_found"), log("log.kick_me_found", 1, "accident")],
   outcomes=[
       out("laugh", [say("actor", "kick_me_laugh", delay=1.8), rel("actor", "target", "friendship", 2)], score=[s_trait("actor", "humor", 1.2)]),
       out("mad", [expr("actor", "angry", 5), rel("actor", "target", "friendship", -6), plan("actor", "revenge", "target", heat=0.6)],
           score=[s_trait("actor", "temper", 1.0), s_stress("actor", 0.01)]),
   ])

L("bonk", ["OW! Who put a glass wall there?!", "*BONK*", "...That door wasn't open. Noted."])
L("bonk_laugh", ["Oof! You okay?", "That's going to leave a mark.", "Ten out of ten, would watch again."])
S_("log.bonk", "{actor} walked face-first into the meeting room glass.")
initiative("glass_bonk", "small", cooldown_days=2, scope="global",
    roles=[actor([c_zone("self", ["meeting", "workspace"])], [s_trait("self", "clumsiness", 1.2), s_stress("self", 0.01)])],
    effects=[sfx("thump"), fx("shake", "actor"), say("actor", "bonk"), expr("actor", "surprised", 4), emote("actor", "sweat"),
             witness([say("self", "bonk_laugh", p=0.55, delay=1.2)], r=6), mood("actor", -3), log("log.bonk", 1, "accident")])

L("keyboard_spill", ["NO NO NO, not the keyboard!", "My tea! My KEYBOARD!", "Why is my keyboard... crunchy?"])
S_("log.keyboard_spill", "{actor} spilled tea all over their keyboard.")
initiative("keyboard_spill", "small", cooldown_days=2,
    roles=[actor([c_act("self", ["work"]), c_trait("self", "clumsiness", gt=0.25)], [s_trait("self", "clumsiness", 1.5)])],
    effects=[fx("spill", "actor"), sfx("splash"), expr("actor", "surprised", 5), say("actor", "keyboard_spill"), stress("actor", 8), work("actor", -5),
             setv("obj", "keyboard"), log("log.keyboard_spill", 1, "accident"),
             visit("actor", "@burak", "help_request", prio=58, ttl=45, delay=2, roles={"requester": "actor"},
                   when=[c_is("actor", "burak", neg=True), c_present("@burak")])])

L("cake_announce", ["I baked! Kitchen! Everyone!", "Homemade cake in the kitchen. Come quick before Mert finds it.", "Cake! I made cake!"],
  ece=["I made a cake! It's a bit lopsided but it's FULL of love!"])
L("cake_yum", ["Oh my god, this is amazing.", "Can I have the recipe?", "Best part of my week.", "Is this... carrot? I love it."],
  mert=["I'm taking a second piece. For research."], ahmet=["...Acceptable. Very acceptable."])
S_("log.cake", "{actor} brought homemade cake. The kitchen filled up in seconds.")
initiative("cake_day", "small", cooldown_days=3, scope="global",
    roles=[actor([c_trait("self", "empathy", gt=0.6), c_time(after="10:00", before="16:00")], [s_trait("self", "empathy", 1.0)])],
    effects=[say("actor", "cake_announce"), emote("actor", "cheer"),
             {"e": "meetup", "who": "all", "area": "kitchen", "event": "cake_scene", "ttl": 35, "prio": 52, "need": 3,
              "roles": {"actor": "actor"}}])
scene("cake_scene",
    effects=[each([say("self", "cake_yum", p=0.5, delay=0.8), emote("self", "love", delay=0.6), mood("self", 6), stress("self", -4),
                   rel("self", "actor", "friendship", 4)], exclude=["actor"], stagger=0.5, where=[c_zone("self", ["kitchen"])]),
             expr("actor", "happy", 6), emote("actor", "cheer"), log("log.cake", 2, "celebration")])

# =====================================================================
# 17. TAKING CREDIT / SHARING CREDIT
# =====================================================================
L("share_credit", ["Honestly, {target} did half of that work.", "Ahmet Bey — I couldn't have done it without {target}.", "The credit goes to {target} too."])
L("credit_shared_thanks", ["You didn't have to say that. Thank you.", "Wow. Thanks for that.", "That means a lot."])
S_("log.share_credit", "{actor} made sure {target} got credit for helping.")
S_("mem.shared_credit", "{actor} gave me credit in front of everyone.")
initiative("share_credit", "small", cooldown_days=1,
    roles=[actor([c_trait("self", "honesty", gt=0.6), c_mem("self", "praised", days=0)], [s_trait("self", "honesty", 1.0)]),
           role("target", where=[c_avail("self"), c_any(c_mem("actor", "helped_deadline", about="self", days=1), c_mem("actor", "helped_me", about="self", days=1))],
                score=[s_aff("actor", "self", 0.02)])],
    effects=[visit("actor", "target", "share_credit_scene", prio=50, ttl=40)])
scene("share_credit_scene", conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 4), say("actor", "share_credit", to="target"), say("target", "credit_shared_thanks", to="actor", delay=1.6),
             emote("target", "love", delay=1.6), favor("target", 3), morale("target", 4), rel("target", "actor", "trust", 10), rel("target", "actor", "friendship", 8),
             mem("target", "actor", "recognized", 0.7, 0.8, "mem.shared_credit", 2), log("log.share_credit", 2, "credit")])

# =====================================================================
# 19. CELEBRATIONS
# =====================================================================
L("deal_cheer", ["YES! YES! CLOSED IT!", "WHO'S THE BEST? I'M THE BEST!", "Signed! SIGNED! Someone get me cake!"],
  mert=["THE BIG ONE! I CLOSED THE BIG ONE!"])
L("deal_clap", ["Woo! Go Mert!", "Nice!", "Speech! Speech!", "Drinks are on you!"])
L("boss_deal_praise", ["THAT is how it's done!", "Excellent. Excellent!", "Finally, some good news."])
L("deal_jealous", ["Luck. Pure luck.", "Must be nice.", "Hm. Good for him."], deniz=["The client would've signed anyway."])
S_("log.deal_closed", "{actor} closed a big deal and celebrated loudly. The whole office clapped.")
initiative("deal_closed", "medium", cooldown_days=3,
    roles=[actor([c_is("self", "mert"), c_act("self", ["work", "phone"]), c_time(after="11:00")], [s_goal("self", "hit_sales", 1.0), s_mood("self", 0.01)])],
    effects=[expr("actor", "happy", 8), emote("actor", "cheer"), say("actor", "deal_cheer"), sfx("crowd"), mood("actor", 20), morale("actor", 6),
             each([say("self", "deal_clap", p=0.5, delay=1.2), emote("self", "cheer", delay=1.0)], exclude=["actor", "@ahmet", "@deniz"], stagger=0.4),
             say("@ahmet", "boss_deal_praise", delay=3.2, when=[c_present("@ahmet")]), favor("actor", 6),
             mem("actor", "@ahmet", "praised", 0.6, 0.7, "mem.praised", 2, when=[c_present("@ahmet")]),
             say("@deniz", "deal_jealous", delay=4.0, when=[c_present("@deniz")]), rel("@deniz", "actor", "rivalry", 6, when=[c_present("@deniz")]),
             stat("praises"), log("log.deal_closed", 3, "celebration")])

# =====================================================================
# 20. SECRETS COMING OUT
# =====================================================================
L("audit_find", ["These numbers don't add up...", "Wait. Who signed off on this?", "Zeynep's report has a hole the size of a truck."])
L("audit_summon", ["Zeynep. My office.", "Zeynep! Bring your spreadsheets."])
L("audit_confess", ["...It was a mistake. I meant to fix it before anyone saw.", "Okay. Yes. I messed up. I'll fix it."])
L("audit_deflect", ["That's... probably Ece's data entry.", "Someone must have changed my file!", "I'll look into who did this."])
L("boss_audit_angry", ["You'll fix it. Tonight.", "This stays between us. For now.", "I expected better."])
S_("log.audit_confess", "Ahmet found the hole in Zeynep's numbers. She confessed.")
S_("log.audit_deflect", "Ahmet found the hole in Zeynep's numbers. She blamed Ece.")
S_("mem.audit", "Ahmet caught my accounting mistake.")
initiative("audit", "medium", cooldown_days=4, scope="global",
    roles=[actor([c_is("self", "ahmet"), c_day(gte=2), {"c": "fact_exists", "fact": "zeynep_mistake"}, c_knows("self", "zeynep_mistake", neg=True),
                  c_present("@zeynep")], [s_trait("self", "diligence", 1.0)])],
    effects=[expr("actor", "surprised", 5), say("actor", "audit_find"), learn("actor", "zeynep_mistake", c=0.8), reveal("zeynep_mistake"),
             say("actor", "audit_summon", delay=2.0),
             meetup("audit_scene", who=["actor", "@zeynep"], area="boss", roles={"actor": "actor", "target": "@zeynep"}, ttl=40, delay=2)])
scene("audit_scene", noise=0.8, conditions=[c_present("target")],
    effects=[hold(["actor", "target"], 5.5), expr("actor", "angry", 6), stress("target", 18)],
    outcomes=[
        out("confess", [say("target", "audit_confess", to="actor", delay=1.4), say("actor", "boss_audit_angry", to="target", delay=3.0),
                        favor("target", -6), rel("actor", "target", "trust", 4), mem("target", "actor", "scolded", -0.5, 0.7, "mem.audit", 3),
                        log("log.audit_confess", 3, "secret")],
            score=[s_trait("target", "honesty", 1.2), s_rel("target", "actor", "trust", 0.02)]),
        out("deflect", [say("target", "audit_deflect", to="actor", delay=1.4), say("actor", "boss_audit_angry", to="target", delay=3.0),
                        rel("actor", "@ece", "trust", -6), rumor("blamed", a="@ece", b="target", juicy=0.6, truth=False, knowers=["actor"], origin="target"),
                        mem("target", "actor", "scolded", -0.5, 0.7, "mem.audit", 3), log("log.audit_deflect", 3, "blame", who=["target", "@ece"])],
            score=[s_trait("target", "cunning", 1.2), s_const(0.2)]),
    ])

L("slip_line", ["...which is funny, because {fact}", "— oh, like how {fact} Oops.", "Not that anyone knows {fact} Wait. Forget I said that."],
  ece=["Oh! Speaking of which, {fact} ...Was that a secret?"], mert=["Ha, and don't forget {fact} — oh. Oh no."])
L("slip_subject", ["You did NOT just say that.", "I trusted you!", "...Thanks a lot."])
S_("log.secret_slip", "{actor} let a secret slip in front of everyone: \"{fact}\" {subject} heard it.")
S_("mem.slipped", "{actor} blurted out my secret.")
initiative("secret_slip", "medium", cooldown_days=2,
    roles=[actor([c_any(c_trait("self", "gossip", gt=0.4), c_trait("self", "clumsiness", gt=0.5))], [s_trait("self", "gossip", 0.8), s_trait("self", "clumsiness", 0.6)]),
           role("subject", where=[c_avail("self")], near="actor", r=5.0, score=[s_rand(1.0)])],
    vars=[var("fact", "secret_about", knower="actor", about="subject")],
    effects=[hold(["actor", "subject"], 4.5), say("actor", "slip_line"), reveal("$fact"),
             witness([learn("self", "$fact", frm="actor"), emote("self", "exclaim", delay=1.0)], r=5.5, exclude=["actor", "subject"]),
             say("subject", "slip_subject", to="actor", delay=1.8), expr("subject", "angry", 6, delay=1.8), stress("subject", 15),
             rel("subject", "actor", "trust", -25), rel("subject", "actor", "friendship", -12),
             mem("subject", "actor", "betrayed", -0.8, 0.9, "mem.slipped", 3), plan("subject", "revenge", "actor", heat=0.7),
             log("log.secret_slip", 4, "secret", who=["actor", "subject"])])

L("logs_find", ["Huh. Server logs say someone copied a whole folder at midnight.", "Interesting... who has access to Selin's files?", "Well, well. The logs never lie."])
L("logs_tell", ["{target}, I found something in the server logs. You should see this.", "I wasn't snooping. Okay, I was. Look at this."])
L("logs_shock", ["He WHAT?", "I knew it. I KNEW it.", "Can you print that for me?"])
S_("log.logs_found", "Burak found something interesting in the server logs about Deniz.")
S_("log.logs_told", "Burak showed {target} what he found in the server logs about Deniz.")
initiative("logs_discovery", "medium", cooldown_days=4, scope="global", weight=1.4,
    roles=[actor([c_is("self", "burak"), c_act("self", ["work"]), {"c": "fact_exists", "fact": "deniz_shortcut"},
                  c_any(c_knows("self", "deniz_shortcut", neg=True), c_sure("self", "deniz_shortcut", lt=0.85))],
                 [s_trait("self", "curiosity", 1.0), s_rand(0.5)])],
    effects=[emote("actor", "idea"), say("actor", "logs_find"), learn("actor", "deniz_shortcut", c=0.9), log("log.logs_found", 2, "secret")],
    outcomes=[
        out("tell_friend", [visit("actor", "$confidant", "logs_tell_scene", prio=55, ttl=50, delay=2)], score=[s_trait("actor", "honesty", 1.0)],
            when=[c_filled("$confidant"), c_present("$confidant")]),
        out("keep", [plan("actor", "expose", "@deniz", heat=0.8)], score=[s_const(0.6)]),
    ],
    vars=[var("confidant", "best_of", of="actor", lim=15, optional=True)])
scene("logs_tell_scene", conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), emote("actor", "whisper"), say("actor", "logs_tell", to="target"), say("target", "logs_shock", to="actor", delay=1.8),
             learn("target", "deniz_shortcut", frm="actor"), reveal("deniz_shortcut"), rel("target", "actor", "trust", 6), log("log.logs_told", 3, "secret")])

# =====================================================================
# FEUDS, REVENGE AND MAKING UP (things that carry over between days)
# =====================================================================
L("feud_snub", ["...", "Hmph.", "*looks the other way*", "Oh. It's you."], selin=["*pointedly ignores*"], ahmet=["*cold stare*"])
S_("log.feud_snub", "{actor} and {target} walked past each other without a word. Still not speaking.")
ev(id="feud_snub", trigger=["encounter", "chat", "desk_chat"], priority=66, scope="pair", cooldown_days=1, max_day=2, tier="small",
   conditions=[c_bond("actor", "target", "feud"), c_avail("target")],
   effects=[say("actor", "feud_snub"), emote("target", "cloud", delay=1.0), say("target", "feud_snub", delay=1.4, p=0.6),
            expr("actor", "angry", 3), mood("actor", -2), mood("target", -2), log("log.feud_snub", 1, "conflict")])

S_("log.feud_begins", "{actor} and {target} are no longer on speaking terms.")
S_("mem.feud", "{target} and I aren't speaking.")
ev(id="feud_begins", trigger="argument", priority=58, also=True, tier="medium", cooldown=300, allow_absent=True,
   conditions=[c_bond("actor", "target", "feud", neg=True), c_rel("actor", "target", "friendship", lt=-22), c_rel("target", "actor", "friendship", lt=-15),
               c_any(c_rel("actor", "target", "rivalry", gt=30), c_mem("actor", "falsely_accused", days=2), c_mem("target", "falsely_accused", days=2),
                     c_mem("actor", "spread_lies", days=2), c_mem("actor", "gossiped_about_me", days=2)), c_chance(0.7)],
   effects=[bond("actor", "target", "feud"), mem("actor", "target", "feud", -0.5, 0.8, "mem.feud", 3), mem("target", "actor", "feud", -0.5, 0.8, "mem.feud", 3),
            plan("actor", "revenge", "target", heat=1.0, when=[c_trait("actor", "forgiveness", lt=0.45)]),
            plan("target", "revenge", "actor", heat=1.0, when=[c_trait("target", "forgiveness", lt=0.45)]),
            log("log.feud_begins", 3, "conflict", delay=6),
            arc_start("feud_mediation", {"a": "actor", "b": "target"})])

L("revenge_rumor_pitch", ["Want to hear something about {victim}? Total slacker. Sneaks out every afternoon.", "Don't tell anyone, but {victim} trashes you behind your back.",
                          "Between us — {victim} is about to get fired."], deniz=["I hear {victim} has been... cutting corners. Big corners."])
L("revenge_rumor_listen", ["Really?! Huh.", "I did NOT know that.", "Interesting..."], ceren=["I'll want proof before I believe that."])
S_("log.revenge_rumor", "{actor} is getting back at {victim} by feeding {target} a lie about them.")
initiative("revenge_rumor", "medium", cooldown_days=1,
    roles=[actor([c_plan("self", "revenge"), c_trait("self", "honesty", lt=0.7)], [s_plan("self", "revenge", 1.5), s_trait("self", "cunning", 0.8)]),
           by_fn("victim", "plan_target", kind="revenge", avail=False, where=[c_present("self")]),
           role("target", where=[c_avail("self"), c_is("self", "victim", neg=True)], score=[s_trait("self", "gossip", 1.2), s_aff("actor", "self", 0.01)],
                exclude=["actor", "victim"])],
    effects=[visit("actor", "target", "revenge_rumor_scene", prio=55, ttl=40)])
scene("revenge_rumor_scene", conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 4.5), emote("actor", "whisper"), say("actor", "revenge_rumor_pitch", to="target"),
             say("target", "revenge_rumor_listen", to="actor", delay=1.6),
             rumor("slacker", a="victim", b="actor", juicy=0.75, truth=False, knowers=["actor"], origin="actor"),
             learn("target", "$rumor", frm="actor"), plan("actor", "revenge", "victim", heat=-0.6), log("log.revenge_rumor", 3, "scheme", who=["actor", "victim"])])

L("peace_offer", ["Hey. I brought you a coffee. Can we talk?", "I don't want to keep doing this. Truce?", "Look... I'm sorry. Really."],
  ece=["I made you a card. It says sorry in three languages."], mert=["Peace offering: one simit, slightly squashed."])
L("peace_accept", ["...Okay. Truce.", "Thanks. I'm sorry too.", "Fine. Come here."])
L("peace_reject", ["Not yet. Not after that.", "You think coffee fixes this?", "No."])
S_("log.peace_made", "{actor} offered {target} a peace coffee. They're talking again!")
S_("log.peace_rejected", "{actor} tried to make peace with {target}. {target} wasn't ready.")
initiative("peace_offering", "medium", cooldown_days=1, weight=2.6,
    roles=[actor([c_trait("self", "forgiveness", gt=0.25), c_mood("self", gt=-20)], [s_trait("self", "forgiveness", 1.0), s_trait("self", "empathy", 0.6)]),
           role("target", where=[c_avail("self"),
                                 c_any(c_bond("actor", "self", "feud"), c_mem("actor", "argued", about="self", days=3),
                                       c_mem("self", "argued", about="actor", days=3), c_mem("self", "mocked", about="actor", days=3),
                                       c_mem("self", "falsely_accused", about="actor", days=3), c_mem("self", "refused_help", about="actor", days=3),
                                       c_mem("self", "gossiped_about_me", about="actor", days=3))],
                score=[s_bond("actor", "self", "feud", 2.0), s_rand(0.5)])],
    conditions=[c_plan("actor", "revenge", "target", neg=True)],
    effects=[visit("actor", "target", "peace_scene", prio=55, ttl=40)])
scene("peace_scene", noise=0.8, conditions=[c_avail("target")],
    effects=[hold(["actor", "target"], 5), say("actor", "peace_offer", to="target")],
    outcomes=[
        out("accept", [say("target", "peace_accept", to="actor", delay=1.8), emote("actor", "love", delay=1.8), emote("target", "ok", delay=1.8),
                       bond("actor", "target", "feud", v=False), plan("target", "revenge", "actor", v=False),
                       rel("actor", "target", "friendship", 18, both=True), rel("actor", "target", "rivalry", -10, both=True), rel("actor", "target", "trust", 8, both=True),
                       mem("actor", "target", "made_up", 0.6, 0.8, "mem.made_up", 3), mem("target", "actor", "made_up", 0.6, 0.8, "mem.made_up", 3),
                       stat("reconciliations"), log("log.peace_made", 3, "friendship")],
            score=[s_trait("target", "forgiveness", 1.4), s_mood("target", 0.01), s_plan("target", "revenge", -1.2, target="actor")]),
        out("reject", [say("target", "peace_reject", to="actor", delay=1.8), expr("actor", "sad", 5, delay=1.8), mood("actor", -6),
                       log("log.peace_rejected", 2, "conflict")],
            score=[s_trait("target", "forgiveness", -1.0), s_stress("target", 0.01), s_plan("target", "revenge", 1.0, target="actor"), s_const(0.3)]),
    ])

# --- refusing to believe gossip about a close friend
L("defend_friend_rumor", ["No way. Not {subject}. I don't believe it.", "That's not true. I know {subject}.", "Whoever said that doesn't know {subject}."])
S_("log.refuses_rumor", "{actor} heard a rumour about their friend {subject} — and flatly refused to believe it.")
ev(id="refuse_rumor", trigger="fact_learned", priority=40, also=True, tier="small", allow_absent=True, scope="actor", cooldown=300, max_day=2,
   conditions=[c_present("actor"), c_present("subject"), c_aff("actor", "subject", gt=45), c_sure("actor", "$fact", lt=0.8), c_chance(0.25)],
   effects=[say("actor", "defend_friend_rumor"), emote("actor", "cloud"), forget("actor", "$fact"), rel("subject", "actor", "trust", 4),
            log("log.refuses_rumor", 1, "protect", who=["actor", "subject"])])

# --- someone who waited at a meetup alone
L("stood_up", ["...They're not coming, are they.", "I'll just... stand here. Alone. Cool.", "Unbelievable. Stood up by the coffee machine."])
ev(id="stood_up", trigger="stood_up", priority=40, allow_absent=True,
   conditions=[c_present("actor")],
   effects=[say("actor", "stood_up"), emote("actor", "cloud"), mood("actor", -5), rel("actor", "target", "friendship", -4)])

# --- coming back from being out of the office
L("back_from_out", ["I'm back! Did I miss anything?", "Back. Don't ask.", "Okay, where was I?"], burak=["...Dentist. It was the dentist."])
ev(id="returned_generic", trigger="returned", priority=10, allow_absent=True, conditions=[c_present("actor")],
   effects=[say("actor", "back_from_out", p=0.6)])
