# Speech-bubble lines -> data/dialogue_en.json
# "_" = anyone; per-character lists add personality (picked twice as often).
# Placeholders: {actor} {target} {to} {me} {obj} {item} {suspect} {owner} {gossip} {topic} ...

D = {}
def L(key, generic=None, **per):
    d = {}
    if generic: d["_"] = generic
    for k, v in per.items():
        d[k] = v
    D[key] = d

# ---------------------------------------------------------------- printer
L("printer_dead", ["The printer's dead. Of course it is.", "Why is the printer blinking red?!", "PAPER JAM?! There's no paper in it!", "Come on, come on... print!"],
  ahmet=["This printer is a disgrace."], selin=["I need this printed NOW. Not later. Now."], mert=["Printer's having a moment, huh?"],
  zeynep=["Ugh, it's eating my pages!"], ece=["Did I break it? I didn't touch anything!"], deniz=["Typical."], ceren=["Hm. Out of order."])
L("printer_selffix", ["Who did this to you, buddy? I'll fix it.", "Classic. Give me five minutes."], burak=["Who kicked it this time? ...Fine. I'll fix it."])
L("printer_need_help", ["I need someone who speaks printer.", "{helper}! Can you help me with this thing?"],
  selin=["{helper} will know what to do."], ece=["I'll ask {helper}! Don't panic. I'm not panicking."])
L("printer_kick", ["Work, you useless box!", "*kicks printer*", "Take THAT!"], ahmet=["I said PRINT!"], selin=["Unbelievable!"], burak=["...I'm not proud of that."])
L("witness_kick", ["Did they just kick the printer?", "Easy there, champ.", "That's not how IT works."], mert=["Ten points for style!"], zeynep=["Ooh, someone's in a mood."])
L("printer_giveup", ["Forget it. I'll do it later.", "I give up. I'll show it on my laptop."], ece=["Okay! New plan! ...I have no plan."])
L("ask_help_obj", ["{target}, the {obj} is broken. Can you take a look?", "Hey {target}... any chance you could fix the {obj}?", "{target}, I need your magic. The {obj} died."],
  selin=["{target}, I have a deadline. The {obj} is dead. Help?"], mert=["{target}, my friend, my hero, my {obj} whisperer..."],
  ece=["Sorry sorry sorry — {target}, could you help with the {obj}?"], ahmet=["{target}. The {obj}. Fix it."])
L("agree_help", ["Sure, give me a minute.", "Yeah, I got it.", "On it."], burak=["Sigh. Yes. I'll fix it.", "Did you try turning it off and on? ...Never mind, I'm coming."],
  ece=["Of course! I love helping!"], ceren=["No problem, I'll handle it."])
L("refuse_help", ["Sorry, I'm swamped.", "Not my job.", "Can't right now."], burak=["Not today.", "Open a ticket.", "I'm not your personal tech support."],
  deniz=["Hm. I'd love to, but... no."], selin=["I have my own deadline, sorry."], ahmet=["Do I look like IT to you?"])
L("react_refused", ["Wow. Thanks a lot.", "Fine. FINE.", "I'll remember that."], selin=["I will remember this.", "Noted. Permanently."], mert=["Ouch. Okay."], ece=["Oh... okay. That's fine. Totally fine."])
L("help_later", ["Later, okay? I'm in the middle of something.", "Give me a bit. I'll come by."], burak=["After this ticket. Promise."])
L("fine_wait", ["Okay... I'll wait.", "Don't forget me!"])

# ---------------------------------------------------------------- fixing
L("lights_fixed_me", ["And... let there be light!", "Fixed. You're welcome."], burak=["Breaker tripped. Again. Nobody touch anything."])
L("lights_back", ["Finally!", "Thank you!", "I can see again!", "Oh thank goodness."], mert=["My hero!"], zeynep=["Took long enough."])
L("fixed_it", ["Done. Should work now.", "Fixed it for you.", "Good as new."], burak=["It works. Please stop kicking it."])
L("thanks_fix", ["Thank you so much!", "You're a lifesaver.", "I owe you one."], selin=["Thank you. Really."], mert=["I owe you a kebab."])
L("fixed_solo", ["There. Fixed.", "Back in business."], burak=["Another day, another miracle."])

# ---------------------------------------------------------------- coffee
L("coffee_dead", ["No coffee?! NO COFFEE?!", "The coffee machine is broken...", "Why is it making that noise?"],
  ahmet=["Who broke the coffee machine?!"], mert=["Nooo, my fuel!"], zeynep=["How am I supposed to function?!"], deniz=["Wonderful. Just wonderful."], burak=["...I'm not fixing this."])
L("ece_try_fix", ["I can fix it! I watched a video once!", "Leave it to me! Hold this... no wait."])
L("ece_fix_success", ["IT WORKS! I'm a genius!", "Ta-da! Coffee for everyone!"])
L("praise_ece", ["Wow, nice one Ece!", "Ece, you're a legend.", "The intern saved us!"])
L("ece_fix_fail", ["Oops. Oh no. Oh no no no.", "That... wasn't supposed to spray.", "Why is it all over me?!"])
L("witness_spill", ["Ece, are you okay?", "Someone get a mop!", "Oh dear."])
L("coffee_rage", ["Who DID this?!", "I swear I'll lose it.", "Unbelievable! UNBELIEVABLE!"], ahmet=["This office is falling apart!"], selin=["Someone is going to answer for this."])
L("witness_coffee_rage", ["Yikes.", "Better stay out of their way.", "Someone's grumpy."], mert=["Decaf for that one."])
L("coffee_blame", ["Bet it was {suspect}. Always fiddling with it.", "{suspect} was here last. Coincidence? No.", "I KNOW {suspect} broke it."],
  zeynep=["It was {suspect}, I'd put money on it."], selin=["{suspect} again, I suppose."])
L("coffee_ask_fix", ["Maybe {helper} can fix it...", "I'll go get {helper}."])
L("coffee_sad", ["Today is going to be long.", "No coffee. No joy.", "*sad sigh*"], ece=["It's fine! I'll drink water! ...Sad water."])
L("coffee_works_again", ["Wait. It works again?", "Huh? Someone fixed it?", "The coffee machine is alive!"])
L("coffee_who_fixed", ["Who fixed it? Must've been {credited}.", "{credited} probably fixed it. I should say thanks."])
L("coffee_spooky", ["Nobody touched it. It just... fixed itself.", "Okay, this is creepy.", "This office is haunted. I'm calling it."])
L("thanks_coffee_fix", ["Thanks for fixing the coffee machine, {target}!", "You fixed the coffee? You're the best!"])
L("take_credit", ["Oh, that? Yeah. Anything for the team.", "Heh. You're welcome.", "It was nothing, really."], deniz=["Naturally. I take care of things."])
L("not_me", ["Wasn't me, actually.", "I didn't fix anything...", "Nope. Not me."], burak=["I didn't touch it. Weird."])
L("then_who", ["Then who did?", "Wait... then who?!", "Okay, now I'm scared."])
L("burak_sigh_fix", ["Printer's still dead. Fine. I'll do it.", "Nobody reported it. Of course."])
L("burak_sigh_fix_coffee", ["The coffee machine again? Fine.", "I'll fix the coffee. For the greater good."])

# ---------------------------------------------------------------- lights
L("lights_out_react", ["AAAH!", "Who turned off the lights?!", "Hey! I was typing!", "Did we forget to pay the bill?"],
  ece=["I can't see! Is this a drill?!"], mert=["Ooooh, spooky!"], zeynep=["Someone's playing games..."], ahmet=["What is going on here?!"],
  deniz=["Interesting..."], selin=["My document! Did it save?!"], burak=["...Breaker."], ceren=["Everyone stay calm."])
L("lights_will_fix", ["I'll check the breaker.", "Hang on, I'll fix it.", "Nobody move, I'm on it."], burak=["Breaker. I'll handle it."], ceren=["I'll take care of it."])
L("ece_spill_oops", ["Oh no! I'm so sorry!", "Oops! Your shirt...", "AAH! Sorry sorry sorry!"])
L("spill_forgive", ["It's okay, it's just a shirt.", "Don't worry, accidents happen.", "Ha! I needed a new look anyway."], mert=["Coffee-scented. Very trendy."])
L("spill_angry", ["Are you serious?!", "Watch where you're going!", "This was clean!"], selin=["Ece. Really?"], ahmet=["Be more careful!"])
L("dark_scheme_whisper", ["Perfect timing...", "Nobody's looking...", "Darkness is just opportunity without lighting."])
L("lights_ghost_on", ["The lights came back on by themselves?", "Who... did that?", "Nobody touched the switch!"])
L("dark_scared", ["I don't like this.", "Is it just me or is it creepy in here?", "Stay close, okay?"], ece=["Can I hold your sleeve? Just a little?"])
L("dark_comfort", ["It's okay, I'm here.", "Relax, it's just a blackout.", "Ha, don't worry. I've got you."], mert=["Don't worry, I glow in the dark. Kidding."])

# ---------------------------------------------------------------- temperature
L("too_cold", ["Brrr! Why is it so cold?", "My fingers are freezing!", "Is the AC set to Antarctica?"], zeynep=["I'm turning into an ice sculpture here!"], ece=["I can see my breath!"])
L("too_hot", ["It's boiling in here!", "Who turned on the sauna?", "I'm melting..."], ahmet=["Who touched the AC?!"], burak=["The servers are going to cook."])
L("temp_complain", ["That's it. I'm fixing the thermostat.", "I can't work like this.", "Who keeps changing the temperature?!"])
L("temp_suffer", ["I'll just... suffer quietly.", "*shivers*", "*fans self with a folder*"])
L("thermo_grumble", ["Who touched the thermostat?", "Seriously? Again?", "*mutters about the AC*"])
L("thermo_argue_1", ["Why did you change the temperature?", "Don't touch the thermostat!", "It was perfect before!"], zeynep=["Some of us have blood circulation issues!"])
L("thermo_argue_2", ["It was freezing!", "It was a sauna!", "I'm not the only one who works here!"], ahmet=["I am the manager. I set the temperature."])
L("thermo_argue_3", ["Fine! Wear a sweater!", "Unbelievable.", "This is a war now."])

# ---------------------------------------------------------------- desk / files
L("files_flew", ["My papers just... flew?!", "Did you see that?! The files moved on their own!", "Okay. That's it. Ghosts."])
L("witness_ghost", ["What was THAT?", "I saw it too!", "Nope. Nope nope nope."])
L("who_did_this", ["Who messed up my documents?!", "Who touched my desk?!", "My files! Everything's out of order!"],
  selin=["Who. Touched. My. Files.", "Someone has been at my desk."], ahmet=["Who dared to touch my desk?!"], burak=["My desk. My system. Ruined."],
  zeynep=["Someone's been snooping. And it's not me this time!"], deniz=["Someone's trying to sabotage me."])
L("suspect_named", ["It was {suspect}. I just know it.", "{suspect}... I'm going to have a word.", "This has {suspect} written all over it."])
L("dont_look_at_me", ["Don't look at me!", "I didn't do it!", "Wasn't me!", "I've been at my desk all day!"], mert=["I'm innocent! Mostly."], burak=["I have an alibi. My code."])
L("tidy_sigh", ["*sighs and starts sorting papers*", "Back to square one.", "Fine. I'll just redo it."], ceren=["Let's just tidy up quietly."])
L("ece_offer_tidy", ["Let me help you sort these!", "I'm great at filing! Mostly!"])
L("ece_tidy_thanks", ["Thanks, Ece. You're sweet.", "You didn't have to... thank you.", "Okay, you're officially my favourite."])
L("i_think_i_know", ["I think I know who did it...", "Psst. I saw something.", "Want to know what I saw?"], zeynep=["Oh, I know EXACTLY who did it."])
L("who_was_it", ["Who?!", "Tell me.", "Spill it."])
L("zeynep_accuse", ["{suspect}. I saw them near your desk.", "It was {suspect}. Don't say I told you.", "Let's just say {suspect} looked very suspicious."])

# ---------------------------------------------------------------- accusations
L("accuse_files", ["Did you mess with my desk, {target}?", "Was it you who touched my files?", "{target}. My files. Explain."], selin=["I know it was you, {target}."])
L("accuse_coffee", ["You broke the coffee machine, didn't you?", "{target}, admit it. The coffee machine."])
L("accuse_item", ["Why was my {item} on YOUR desk, {target}?", "{target}, care to explain my {item}?"])
L("accuse_promo", ["You messed with my promotion file, didn't you?", "{target}, did you sabotage my promotion?"], selin=["You doctored that file, {target}. Admit it."])
L("smooth_deny", ["Me? I would never. Must've been the ghost.", "No idea what you're talking about.", "Wow. Paranoid much?"])
L("not_convinced", ["Mm-hm. Sure.", "I'm watching you.", "We'll see."])
L("deny_angry", ["Excuse me?! I didn't do anything!", "How DARE you accuse me!", "Are you serious right now?!"], burak=["Don't you blame me for this!", "I didn't touch it. Stop blaming me!"],
  ahmet=["You're accusing ME?"], deniz=["Wow. Jealous much?"])
L("insist", ["Then who else?!", "You were the only one near my desk!", "Don't lie to me!"])
L("deny_angry2", ["Get out of my face!", "I'm done with this!", "Think whatever you want!"])
L("witness_argument", ["Whoa, whoa...", "Here we go again.", "Should someone stop them?"], zeynep=["Ooh, this is getting good."], mert=["Popcorn, anyone?"])
L("deny_calm", ["It wasn't me, I promise.", "I understand you're upset, but it wasn't me.", "I'd never do that to you."], ceren=["I didn't, but I'll help you find out who did."])
L("sorry_accuse", ["Okay... sorry. I'm just stressed.", "You're right. Sorry.", "My bad. I'm on edge."])
L("take_blame", ["It... it was me. Sorry.", "Okay, I'll take the blame. Let's just move on.", "I'm sorry! Probably my fault!"], ece=["It was probably me! I'm clumsy! I'm so sorry!"])
L("accept_apology", ["...Fine. Just don't do it again.", "Okay. Thanks for being honest.", "Apology accepted. Barely."])
L("defend", ["Leave them alone, it wasn't them.", "Hey! Back off. They didn't do it.", "I was with them the whole time."], mert=["Come on, they'd never do that."], ceren=["Let's not accuse people without proof."])
L("stay_out", ["Stay out of this!", "Nobody asked you.", "Mind your own business."])
L("fight_crowd", ["What's going on?!", "Not again!", "Someone call Ahmet!", "Everybody calm down!"], zeynep=["I'm getting this all in my memory."])
L("boss_outburst", ["ENOUGH! This is an office, not a circus!", "What is going on here?! Back to work, ALL of you!", "One more fight and I'm cancelling everyone's lunch!"])

# ---------------------------------------------------------------- items
L("missing_glasses", ["Where are my glasses?! I can't read a thing!", "Has anyone seen my reading glasses?"])
L("missing_usb", ["My USB stick! My whole presentation is on it!", "Where's my USB?! It was right here!"])
L("missing_mug", ["Where's my lucky mug? I can't drink coffee from a normal cup!", "Who took my mug?!"])
L("missing_planner", ["My planner's gone. My entire life is in that planner.", "Where is my planner?"])
L("missing_charger", ["My charger's gone. Laptop's at 3%.", "Who took my charger? Who does that?"])
L("found_at_desk", ["My {item}... on {owner}'s desk?!", "Why is my {item} at {owner}'s desk?", "So {owner} had my {item} all along."])
L("found_at_friend", ["Ha! {owner}, you thief! Haha.", "My {item} at {owner}'s place? Funny."])
L("found_weird_place", ["How did my {item} end up here?", "I never brought my {item} here...", "Things keep moving in this office."])
L("found_item_relief", ["Found it! Phew.", "There you are!"])
L("pocket_item", ["Finders keepers...", "Hm. This could be useful.", "*quietly slides it into a drawer*"])
L("found_foreign_item", ["Why is {owner}'s {item} on my desk? I'll return it.", "This is {owner}'s {item}... let me bring it back."])
L("whose_is_this", ["Whose is this?", "Not mine. Not my problem."])
L("return_item_line", ["Found your {item} on my desk!", "Here — your {item} was at my place.", "I think this is yours."])
L("thanks_return", ["Oh my god, thank you!", "You're a lifesaver!", "Thank you! I was going crazy!"], selin=["Thank you. Seriously. Thank you."], ahmet=["Hm. Thank you."])

# ---------------------------------------------------------------- email
L("email_oops", ["Wait. Did that go to... EVERYONE?!", "No. No no no no no.", "Undo! UNDO! Where's undo?!"],
  ahmet=["That was NOT meant for the team."], mert=["Oh no. Oh no. I'm moving to another country."], burak=["...I'm going to need a new job. Faster."],
  ece=["I want to disappear."], deniz=["This is... a misunderstanding."], zeynep=["Well. That's awkward."], selin=["This wasn't for everyone."])
L("email_read_all", ["Did everyone just get that email?", "Oh. My. God.", "I'm reading this twice.", "Reply all? Reply ALL?"],
  zeynep=["Best email EVER.", "I'm printing this and framing it."], mert=["Oh this is gold."], ceren=["Oh dear."], ahmet=["What is the meaning of this?"])
L("secret_exposed", ["That was private!", "Everyone knows now. Great.", "How could you?!"])
L("own_secret_out", ["Everyone knows now...", "Great. Just great.", "Well, the cat's out of the bag."])
L("team_complaint_react", ["Lazy? WE'RE lazy?", "Wow. Tell us how you really feel.", "So that's what he thinks of us."])
L("boss_backpedal", ["That was... a draft. A rough draft.", "Let's all pretend that didn't happen."])
L("email_sent_wrong", ["Wait... who did I send that to?", "Did that just go to {target}?!", "Wrong recipient... oh no."])
L("email_redirect_read", ["Uh... {actor}, I don't think this was for me.", "Well, THIS is interesting.", "Hmm. Was I supposed to see this?"],
  ahmet=["{actor}. My office. Now. Actually, I'll come to you."], zeynep=["Ooh, this is juicy."])
L("email_confront", ["I read your email, {target}.", "So THAT'S what you think of me?", "We need to talk about that email."])
L("email_apology", ["I'm sorry. I was venting. I didn't mean it.", "That was out of line. I'm sorry.", "Can we start over?"])
L("email_apology_accept", ["Okay. But it hurt.", "Fine. Let's move on.", "Apology accepted. For now."])
L("email_defiant", ["I meant every word.", "Maybe you needed to hear it.", "Well, it's out there now."])
L("email_furious", ["Unbelievable!", "You're unbelievable!", "We're done talking."])
L("crush_flattered", ["Mert... that was actually kind of sweet.", "So... you like me? That's... nice.", "Well. That's one way to tell me."])
L("mert_blush", ["Haha... yeah... about that...", "I can explain! ...No I can't.", "*turns bright red*"])
L("crush_awkward", ["Mert, we work together. This is... awkward.", "I... need a minute.", "Let's just keep things professional."])
L("tease_crush_line", ["So... Ceren, huh?", "Saw your little love letter, Romeo.", "Ceren? Bold move, my friend."])

# ---------------------------------------------------------------- meeting
L("board_who_moved", ["Who moved the meeting? I didn't change that.", "That's not the time I scheduled...", "Someone's been messing with my calendar."])
L("board_moved_note", ["Oh, the meeting moved?", "New meeting time, noted.", "Huh. Meeting's at a different time now."])
L("tell_boss_meeting_moved", ["Sir, the meeting time was changed on the board.", "Heads up — someone moved today's meeting."])
L("boss_meeting_moved_ok", ["Fine. We'll go with the new time.", "Noted. Thank you, Ceren."])
L("boss_meeting_moved_blame", ["Changed? YOU manage the calendar, Ceren!", "How does a meeting move by itself?!"])
L("board_changed_live", ["Wait... the meeting time just changed?", "Did the board just... change?", "I'm not crazy. That said a different time."])
L("meeting_open", ["Alright, let's begin.", "Everyone sit. We're starting.", "Phones down. Meeting starts now."])
L("boss_finally", ["Finally!", "Look who decided to show up.", "We've been waiting forever."], mert=["The boss is late? Write that down!"])
L("boss_blames_calendar", ["Ceren, why was my calendar wrong?!", "Who scheduled this? Ceren?"])
L("boss_late_laugh", ["Ahem. Let's pretend I was right on time.", "Yes, yes. Even I get busy."])
L("late_excuse", ["Sorry! Sorry I'm late!", "I thought it was later!", "Traffic! Office traffic!"], mert=["I was... networking. At the coffee machine."], ece=["I'm so sorry! I got lost! In the office!"])
L("board_said_other_time", ["The board said a different time!", "But the schedule said later!"])
L("who_changed_board", ["Who keeps changing the board?!", "Someone is messing with the schedule."])
L("boss_scold_late", ["Late. Again.", "Time is money. Yours is running out.", "Do you think this is a café?"])
L("boss_sit_down", ["Sit down. Quickly.", "Just sit."])
L("where_is_everyone", ["Where is everyone?", "Was the meeting cancelled?", "Am I in the wrong room?", "Hello? Meeting?"])
L("scold_meeting", ["You missed the meeting. Explain.", "Where were you during the meeting?"])
L("scold_email", ["About that email of yours...", "I read your email. We need to talk."])
L("scold_deadline", ["You missed your deadline.", "Where's your work? It was due."])
L("scold_general", ["We need to talk about your performance.", "I expect better from you."])
L("sorry_boss", ["Sorry, it won't happen again.", "Yes, sir. Understood.", "I'll fix it."], ece=["Sorry, Uncle— I mean, sir!"])
L("talk_back", ["With respect, that's not fair.", "Maybe if this office worked properly...", "You know what? I'm tired of this."], burak=["Maybe I won't be here much longer anyway."])
L("boss_how_dare", ["Watch your tone!", "Excuse me?!", "Careful."])
L("present_good", ["As you can see, the numbers speak for themselves.", "And that's our plan for next quarter.", "Here are the results. All green."])
L("boss_praise", ["Excellent work.", "Now THAT is what I like to see.", "Very good. Very good."])
L("rival_jealous", ["*rolls eyes*", "Show-off.", "Anyone could have done that."])
L("present_no_usb", ["My presentation was on my USB... and it's gone.", "I... I can't find my slides."])
L("boss_unimpressed", ["Unprepared. Disappointing.", "This is not acceptable.", "Come back when you're ready."])
L("present_bad", ["Um... I'm not quite finished...", "I'll have the full version tomorrow?", "So... rough draft time."])
L("credit_steal_pitch", ["Actually, sir, the core idea was mine. Let me walk you through it.", "I can present that project — I did most of the work anyway.", "Allow me. I know this project inside out."])
L("boss_impressed_thief", ["Impressive, Deniz. Very impressive.", "Now that's initiative.", "Good. I like people who step up."])
L("that_was_my_work", ["That was MY work!", "You just presented my project!", "Are you kidding me?! That's mine!"])
L("prove_it", ["Prove it.", "Funny, I don't see your name on it.", "Teamwork, Selin. Teamwork."])
L("meeting_joke", ["Can we make this meeting an email?", "I have a question: when's lunch?", "Great meeting. Ten out of ten."], mert=["Quick question: are snacks a budget item?"])
L("boss_laughs", ["Ha! Okay, okay.", "Very funny. Now, back to it."])
L("boss_not_funny", ["This is not a comedy club.", "Was that supposed to be funny?"])

# ---------------------------------------------------------------- promotion
L("promo_reading", ["Hmm... I didn't know this person did so much.", "Interesting. Very interesting.", "This changes things."])
L("promo_reading_clean", ["Hm. As expected.", "Good, good."])
L("promo_tip", ["Between us... someone changed your promotion file.", "I saw the file. Your name was taken off the big project."])
L("promo_outraged", ["WHAT?!", "I knew something was off!", "Who would do that?!"])
L("promo_announce", ["Everyone, a moment please. We have a new Team Lead.", "Attention! After careful review, I've decided on the promotion."])
L("award_announce", ["Attention everyone! Employee of the Week is...", "This week's star employee is..."])
L("promo_winner", ["Thank you! I won't let you down!", "Wow... me? Thank you!", "Finally!"], deniz=["Naturally. Thank you, sir."], selin=["Thank you. I've worked so hard for this."])
L("promo_clap", ["Congrats!", "Well deserved... I guess.", "*polite clapping*"], zeynep=["Hmm. Interesting choice."])
L("promo_loser", ["...Unbelievable.", "This is so unfair.", "After everything I did?"], selin=["This is wrong. This is so wrong."], deniz=["This isn't over."])
L("cold_grudge", ["*stares coldly*", "I won't forget this.", "Congratulations. Enjoy it while it lasts."])

# ---------------------------------------------------------------- notifications
L("notif_boss_read", ["'Come to my office. Now.' ...Uh oh.", "The boss wants to see me?!", "Oh no. What did I do?"])
L("notif_food_read", ["Free cake in the kitchen?! Say no more!", "Free food! FREE FOOD!"])
L("notif_cancel_read", ["Meeting cancelled? Nice!", "No meeting today? Best news ever."])
L("notif_admirer_read", ["'A secret admirer says hi'...?!", "Someone here has a crush on me?!", "Ooh, a secret admirer!"])
L("you_wanted_me", ["You wanted to see me?", "I got your message, sir.", "I'm here! What did I do?"])
L("i_didnt_call", ["I didn't call you.", "What message? I sent nothing.", "I never asked for you."])
L("boss_get_back_to_work", ["Stop wasting my time. Back to work.", "Since you're here doing nothing — go work."])
L("boss_since_youre_here", ["Well, since you're here... good job lately.", "Sit, sit. How are things going?"])
L("no_food_here", ["There's no cake...", "Where's the free food?", "It's just old yogurt."])
L("who_pranked", ["Very funny, {suspect}.", "I bet {suspect} sent that.", "Someone's pranking me. And I think I know who."])
L("fridge_sigh", ["*closes fridge sadly*", "Lies. All lies."])
L("admirer_was_it_you", ["So... was it you? The secret admirer?", "Did you send me that message?"])
L("admirer_maybe", ["...Maybe. Would that be so bad?", "Haha, maybe! Who knows?", "A gentleman never tells."])
L("admirer_no", ["What? No! Sorry...", "Uh, no. Definitely not me.", "That's... not me."])

# ---------------------------------------------------------------- secrets
L("boss_job_hunt_discovered", ["Burak is looking for another job? Behind my back?", "So that's why he's always on his phone."])
L("boss_job_hunt_confront", ["I hear you're looking for another job.", "Planning to leave us, Burak?"])
L("boss_counteroffer", ["Look... you're valuable here. What would it take to keep you?", "I'll be honest. I don't want to lose you."])
L("burak_surprised_stay", ["Really? I... didn't expect that.", "Well. Maybe I'll stay a little longer."])
L("burak_defiant", ["Maybe I am. Maybe this place doesn't appreciate anyone.", "I'm allowed to have options."])
L("boss_cold", ["Then don't let the door hit you.", "Fine. We'll see who needs whom."])
L("nepotism_mutter", ["The intern is the boss's NIECE? Of course she is.", "Well, that explains a lot.", "Nepotism. Lovely."])
L("boss_review_shock", ["Headquarters is reviewing ME?!", "My position... is under review?"])
L("secret_call_line", ["*whispers* Yes, Thursday works for the interview...", "*whispers* I can start next month, if the offer's good.", "*whispers* No, my boss doesn't know."])
L("overheard_call", ["Was Burak just talking about an interview?", "Did I just hear that right?!"], zeynep=["Ooh. Ooh! Burak is job hunting!"])

# ---------------------------------------------------------------- gossip & social
L("gossip_open", ["Psst. Come here.", "Did you hear?", "Okay, you did NOT hear this from me..."], zeynep=["Sit down. You'll want to be sitting for this.", "Oh, have I got news for you."])
L("gossip_tell", ["{gossip}", "Apparently... {gossip}", "Don't tell anyone, but {gossip}", "Word is... {gossip}"])
L("gossip_react", ["No way!", "Seriously?!", "I knew it!", "Get out!"])
L("gossip_disapprove", ["We shouldn't be talking about this.", "That's not our business.", "Gossip isn't nice, you know."], ceren=["Let's not spread that around."])
L("gossip_eager", ["Tell me EVERYTHING.", "Ooh, what else?", "I need details!"])
L("flirt_line", ["Ceren, has anyone told you your spreadsheets are beautiful?", "So... coffee later? Just as colleagues. Colleagues who drink coffee.", "You look great today. Not that you don't always."])
L("flirt_charmed", ["Haha, you're ridiculous, Mert.", "Maybe. If you behave.", "You're sweet. Weird, but sweet."])
L("flirt_brush", ["Mert, I'm working.", "Not now, Mert.", "Nice try."])
L("date_ask", ["So... dinner? A real one?", "Would you go out with me? For real?"])
L("date_yes", ["...Yes. But nobody can know.", "Okay. Our little secret."])
L("spotted_secret_friends", ["Well, well. Those two are awfully close.", "Since when are those two friends?", "Interesting... very interesting."])
L("jealous_jab", ["Enjoying the spotlight?", "Must be nice being the boss's favourite.", "Don't get used to it."])
L("jealous_smug", ["Jealous?", "I am enjoying it, thanks.", "Some of us earn it."])
L("jealous_hurt", ["Why would you say that?", "That's not fair.", "...Okay."])
L("apology_offer", ["Hey... about earlier. I'm sorry.", "Can we talk? I think I overreacted.", "Truce?"])
L("apology_accept", ["Yeah. Me too.", "Okay. Truce.", "Let's forget it. Coffee?"])
L("apology_reject", ["Too little, too late.", "I'm not ready.", "No."], selin=["I don't forgive that easily."])
L("grudge_jab", ["Oh. It's you.", "Look who it is.", "Still here?"])
L("grudge_reply", ["What's that supposed to mean?", "Excuse me?", "Got a problem?"])
L("grudge_escalate", ["Yes, actually, I do!", "You know exactly what I mean!", "Don't play innocent!"])
L("walk_away", ["I'm not doing this.", "Whatever.", "Not worth it."])
L("joke", ["Why did the spreadsheet break up with the calculator? Too many issues.", "I'm not lazy, I'm in energy-saving mode.", "My boss told me to have a good day. So I went home.",
           "I told my computer I needed a break. It said 'no problem, I'll go to sleep'.", "Teamwork means never having to take all the blame yourself."],
  mert=["Knock knock. Who's there? Monday. Monday who? Exactly.", "I'm on a seafood diet. I see food, I eat it."])
L("joke_laugh", ["Hahaha!", "Okay, that was good.", "Stop it! Haha!"], ece=["HAHAHA! Wait, I don't get it. HAHAHA!"])
L("joke_groan", ["Ugh.", "Please stop.", "That was terrible."], selin=["I have work to do."], ahmet=["Back to work."])
L("topic_open", ["{topic}"])
L("topic_reply", ["Oh, totally.", "Ha, I know right?", "Don't get me started.", "Same here!", "Hmm, not really."],
  burak=["Mm.", "Sure."], zeynep=["Speaking of which, did you hear about...", "Oh, I have opinions."], ece=["Yes! Oh my god, yes!"], ahmet=["Hm. Indeed."])
L("cold_shoulder", ["...", "I'm busy.", "Mm-hm."])
L("coffee_gift_offer", ["I brought you a coffee!", "Surprise! Coffee, just how you like it. I think.", "Coffee delivery!"])
L("coffee_gift_thanks", ["Aww, thanks Ece!", "You're an angel.", "Exactly what I needed."], ahmet=["Hm. Good girl. I mean, good job."])
L("ceren_brief", ["Your schedule for today, sir.", "A few updates for you.", "Quick briefing, sir."])
L("boss_brief_reply", ["Good. Thank you.", "Keep me informed.", "Mm-hm."])
L("ceren_snitch", ["You should probably know... {gossip}", "One more thing: {gossip}"])
L("deniz_suckup", ["Great tie today, sir.", "Sir, I had a few ideas about the quarterly plan...", "Have I mentioned how much I admire your leadership?"])
L("deniz_snitch", ["Between us, sir... {gossip}", "I thought you should know: {gossip}", "I hate to say it, but {gossip}"])
L("boss_pleased", ["Good, Deniz. Good.", "I like your attitude.", "Keep it up."])
L("boss_too_ambitious", ["Less talking, more working, Deniz.", "Your ambition is showing.", "Is there anything else?"])
L("boss_check_good", ["Good. Keep going.", "Nice progress.", "That's what I like to see."])
L("thanks_boss", ["Thank you, sir.", "Thanks!"])
L("boss_check_idle", ["Is this a holiday?", "Shouldn't you be working?", "I pay you to work, not to chat."])
L("idle_excuse", ["Just a quick break!", "I was just going back!", "It's work-related! Sort of."])
L("boss_check_nag", ["How's it coming along?", "Deadline's today, right?", "Don't forget the report."])
L("yes_boss", ["Yes, sir.", "On it!", "Almost done!"])
L("stress_vent", ["I can't take this place anymore.", "Is it just me or is today a nightmare?", "I need a vacation. Or a new life."])
L("comfort", ["Hey, you've got this.", "Deep breaths. It'll be okay.", "Want me to grab you a coffee?"])
L("not_now", ["Not now, I'm drowning too.", "Can we talk later?", "I have my own problems."])
L("deadline_panic", ["I'm never going to finish in time!", "Deadline in an hour and I'm halfway done!", "Help. Someone. Anyone."], mert=["Why did I leave this to the last minute? Again?"])
L("deadline_alone", ["Fine. Me and caffeine against the world.", "Nobody's coming. Okay."])
L("offer_help_work", ["Need a hand?", "I'll take half of that.", "Give me those, I'll help."])
L("accept_help_work", ["You'd do that? Thank you!", "I didn't expect you of all people... thank you.", "You're saving my life."])
L("deadline_missed_line", ["And... I missed the deadline.", "Well, that's late now.", "Too late. Great."])
L("late_morning", ["Morning! Was I late? I wasn't late.", "Traffic was insane!", "Am I late? Don't answer that."], mert=["The bus was late. And then I was late. Circle of life."])
L("boss_late_morning", ["Good AFTERNOON.", "Look who decided to come to work.", "Do you know what time it is?"])
L("ghost_theory", ["I'm telling you, this office is haunted.", "Things keep moving by themselves. Explain THAT.", "There's something in this office. Something... invisible."])
L("ghost_reply", ["Don't say that! I have to stay late!", "Ghosts aren't real. ...Right?", "Okay, now I'm not sleeping tonight."])
