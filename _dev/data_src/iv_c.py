# Interventions — C. Meetings & calendar (meeting board on the wall, meeting room table)
from iv_common import *  # noqa: F401,F403
S_("task.retreat_plan", "Team retreat planning")

BOARD = dict(obj="meeting_board", cat="C")
TABLE = dict(obj="meeting_table", cat="C")
BEFORE = [r_meeting_pending(), r_meeting_not_started()]
def soon(mins=8):
    return why({"c": "meeting", "key": "started", "eq": False}, "meeting_started")

# --- C02 invite someone who shouldn't be there ------------------------------------
L("wrong_invitee_boss", ["{target}? What are you doing in this meeting?", "Did someone invite {target}? Why?"])
L("wrong_invitee_contrib", ["Well, since I'm here — I have an idea about that.", "Actually, I can help with this."])
L("wrong_invitee_leave", ["I got an invite! ...I'll go.", "Sorry! I'll just... leave."])
S_("log.wrong_invitee_contrib", "{target} was invited to the meeting by mistake — and had the best idea in the room.")
S_("log.wrong_invitee_leave", "{target} turned up to a meeting they were never meant to attend. Ahmet sent them away.")
scene("iv_wrong_invitee", allow_absent=True, conditions=[c_present("target"), c_present("actor")],
      effects=[say("actor", "wrong_invitee_boss", to="target"), emote("target", "sweat", delay=1.2)],
      outcomes=[out("contrib", [say("target", "wrong_invitee_contrib", delay=1.8), emote("target", "idea", delay=1.8), rel("actor", "target", "respect", 10),
                                favor("target", 5), morale("target", 4), log("log.wrong_invitee_contrib", 3, "meeting", who=["target"])],
                    score=[s_trait("target", "ambition", 0.8), s_trait("target", "diligence", 0.6), s_trait("target", "sociability", 0.3)]),
                out("leave", [say("target", "wrong_invitee_leave", delay=1.8), expr("target", "sad", 4, delay=1.8), mood("target", -6),
                              call("meeting_cancel_belief", who="target"), log("log.wrong_invitee_leave", 2, "meeting", who=["target"])],
                    score=[s_trait("actor", "temper", 0.8), s_const(0.4)])])
iv("C02", "invite_wrong", title="Invite someone who isn't supposed to come", desc="Add a name to today's meeting. Ahmet will notice.",
   log="The ghost added {target} to today's meeting invite.", **BOARD, needs="person", icon="people",
   pick=[{"c": "attends", "who": "self", "not": True}, c_is("self", "ahmet", neg=True), c_present("self")], conds=BEFORE,
   state=[mtg("add", who="target")], react=[on_trap("meeting_start", "iv_wrong_invitee", who="@ahmet", key="wronginv")])

# --- C03 uninvite someone -----------------------------------------------------------
L("uninv_notice", ["Where's {target}? They're always here.", "Has anyone seen {target}?"])
L("uninv_find_out", ["I was taken off the invite list?! By whom?", "So there was a meeting. Without me. Nice."])
S_("log.uninvited", "{target} was quietly removed from the meeting invite — and found out afterwards.")
S_("mem.uninvited", "I was left out of the meeting on purpose.")
scene("iv_uninvited_notice", allow_absent=True, conditions=[c_present("actor")],
      effects=[say("actor", "uninv_notice"), chain("iv_uninvited_learn", delay=35)])
scene("iv_uninvited_learn", allow_absent=True, conditions=[c_present("target")],
      vars=[var("suspect", "suspect", of="target", optional=True)],
      effects=[expr("target", "angry", 5), say("target", "uninv_find_out"), mood("target", -10), morale("target", -4),
               mem("target", "@ceren", "excluded", -0.4, 0.7, "mem.uninvited", 2), rel("target", "@ceren", "suspicion", 14),
               rel("target", "$suspect", "suspicion", 10, when=[c_filled("$suspect")]), log("log.uninvited", 3, "meeting", who=["target"]),
               visit("target", "@ceren", "ivm_accuse", prio=56, ttl=60, delay=3, when=[c_present("@ceren"), c_is("target", "ceren", neg=True), c_trait("target", "temper", gt=0.45)])])
iv("C03", "uninvite", title="Remove someone from the meeting invite", desc="They won't know there's a meeting. Until later.",
   log="The ghost removed {target} from today's meeting invite.", **BOARD, needs="person", icon="people",
   pick=[{"c": "attends", "who": "self"}, c_is("self", "ahmet", neg=True)], conds=BEFORE,
   state=[mtg("remove", who="target")], react=[on_trap("meeting_start", "iv_uninvited_notice", who="@ahmet", key="uninv")])

# --- C04 change the presentation order --------------------------------------------
L("first_shine", ["Oh — me first? Okay. Here's where we are...", "Right. Let's do this.", "First? Perfect, I'm ready."])
L("first_bomb", ["Me? FIRST? I... wasn't ready to be first.", "Um. Can I go last? No? Okay..."])
S_("log.first_shine", "{actor} was moved to the top of the presentation list — and nailed it.")
S_("log.first_bomb", "{actor} was suddenly first on the presentation list. They weren't ready. It showed.")
scene("iv_first_presenter", noise=0.6, allow_absent=True, conditions=[c_present("actor")],
      effects=[hold(["actor"], 4)],
      outcomes=[out("shine", [say("actor", "first_shine"), emote("actor", "idea", delay=1.5), favor("actor", 6), morale("actor", 4),
                              witness([rel("self", "actor", "respect", 6)], r=6), log("log.first_shine", 3, "meeting")],
                    score=[s_const(3)], when=[c_var("prepared", eq=True)]),
                out("bomb", [say("actor", "first_bomb"), expr("actor", "sad", 5), emote("actor", "sweat"), favor("actor", -5), stress("actor", 12),
                             witness([rel("self", "actor", "respect", -4)], r=6), mem("actor", "", "humiliated", -0.5, 0.8, "mem.slides_humiliated", 2),
                             log("log.first_bomb", 3, "meeting")], score=[s_const(1)])])
iv("C04", "present_first", title="Move someone to the top of the presentation list", desc="Ready or not, they're up first.",
   log="The ghost put {target} first on today's presentation list.", **BOARD, needs="person", icon="board",
   pick=[{"c": "attends", "who": "self"}, c_is("self", "ahmet", neg=True)], conds=BEFORE,
   state=[mtg("first", "%target")], react=[on_trap("meeting_present", "iv_first_presenter", who="target", key="first", replace=True)])

# --- C05 change the meeting agenda ---------------------------------------------------
L("agenda_layoffs", ["'Agenda: Layoffs'?!", "Why does the board say LAYOFFS?", "Layoffs. On the agenda. Today."])
L("agenda_romance", ["'New office romance policy'? Uh-oh.", "Romance policy?! Who's that aimed at?"])
L("agenda_lunch", ["'Agenda: Who's been stealing lunches?' Finally!", "Lunch thief on the agenda. Somebody's sweating."])
L("agenda_promo", ["'Promotions' on the agenda? Today?!", "Promotions! Okay. Okay. Be cool."])
L("agenda_boss", ["Who wrote THAT on my agenda?!", "That is NOT my agenda. Who touched my board?"])
S_("log.agenda_read", "{actor} read today's meeting agenda on the board — someone had changed it.")
S_("log.agenda_boss", "Ahmet found someone had rewritten his meeting agenda. He wants a name.")
scene("iv_agenda_read", noise=0.6, allow_absent=True, conditions=[c_present("actor")],
      effects=[expr("actor", "surprised", 4), log("log.agenda_read", 1, "meeting")],
      outcomes=[out("layoffs", [say("actor", "agenda_layoffs"), stress("actor", 10), rumor("layoffs", a="@ahmet", b="actor", juicy=0.9, truth=False, knowers=["actor"], c=0.7),
                                witness([learn("self", "$rumor", frm="actor")], r=5)], score=[s_const(5)], when=[c_var("agenda", eq="layoffs")]),
                out("romance", [say("actor", "agenda_romance"), stress("actor", 8, when=[{"c": "bond", "a": "actor", "b": "*", "kind": "romance"}]),
                                emote("actor", "sweat")], score=[s_const(5)], when=[c_var("agenda", eq="romance")]),
                out("lunch", [say("actor", "agenda_lunch"), emote("actor", "exclaim")], score=[s_const(5)], when=[c_var("agenda", eq="lunch")]),
                out("promo", [say("actor", "agenda_promo"), emote("actor", "idea"), plan("actor", "prove_self", "", heat=0.6, when=[c_trait("actor", "ambition", gt=0.6)])],
                    score=[s_const(5)], when=[c_var("agenda", eq="promo")])])
scene("iv_agenda_boss", allow_absent=True, conditions=[c_present("actor")],
      effects=[expr("actor", "angry", 5), say("actor", "agenda_boss"), ghost(), log("log.agenda_boss", 2, "meeting"),
               each([stress("self", 4)], exclude=["actor"], where=[c_act("self", ["meeting"])])])
iv("C05", "agenda", title="Rewrite today's meeting agenda", desc="Everyone reads the board on the way past.",
   log="The ghost rewrote today's meeting agenda.", **BOARD, needs="choice", icon="board", conds=BEFORE,
   choices=[choice("layoffs", "'Layoffs'"), choice("romance", "'New office romance policy'"), choice("lunch", "'Who's stealing lunches?'"), choice("promo", "'Promotions — today'")],
   state=[oset("board.agenda", "$choice")],
   react=[on_trap("agenda_seen", "iv_agenda_read", key="agenda", uses=3), on_trap("meeting_start", "iv_agenda_boss", who="@ahmet", key="agenda_boss")])

# --- C06 move the meeting to another room ----------------------------------------------
L("room_boss", ["Why are we having a meeting next to the fridge?!", "Who moved my meeting to the lounge?", "This is a kitchen. Not a boardroom."])
L("room_fun", ["I kind of like it here, Ahmet Bey.", "Snacks within reach. Best meeting ever."], mert=["Best meeting room ever. Fridge access."])
S_("log.room_moved", "The board said the meeting was in the {what} today. Everyone — including Ahmet — trooped over there.")
what("room_kitchen", "kitchen")
what("room_lounge", "lounge")
scene("iv_room_moved", allow_absent=True, conditions=[c_present("actor")],
      effects=[expr("actor", "surprised", 4), say("actor", "room_boss"), log("log.room_moved", 3, "meeting"),
               witness([say("self", "room_fun", p=0.3, delay=2), mood("self", 3, when=[c_trait("self", "humor", gt=0.5)])], r=5)])
iv("C06", "move_room", title="Move the meeting to another room", desc="The board will say the meeting is somewhere else today.",
   log="The ghost moved today's meeting to the {what}.", **BOARD, needs="choice", icon="home", conds=BEFORE,
   choices=[choice("kitchen", "The kitchen"), choice("lounge", "The lounge")],
   state=[mtg("room", "$choice"), setf("what", "room_{choice}")], react=[on_trap("meeting_start", "iv_room_moved", who="@ahmet", key="room")])

# --- C07 delete the meeting invite -------------------------------------------------------
L("empty_room", ["Where IS everybody?!", "I'm here. Alone. In my own meeting.", "Is it a holiday? Nobody told me."])
L("cancelled_think", ["The meeting's been cancelled? Great, more time!", "Meeting cancelled? Wonderful."])
S_("log.empty_room", "Someone deleted the meeting invite. Ahmet sat in the meeting room almost alone — and he is furious.")
scene("iv_empty_meeting", allow_absent=True, conditions=[c_present("actor")],
      effects=[expr("actor", "angry", 6), emote("actor", "anger"), say("actor", "empty_room"), stress("actor", 10), log("log.empty_room", 4, "meeting"),
               rel("actor", "@ceren", "trust", -8)])
iv("C07", "delete_invite", title="Delete the meeting invite", desc="Most people will think it's cancelled. Ahmet won't.",
   log="The ghost deleted today's meeting invite.", **BOARD, icon="close", conds=BEFORE,
   state=[each([meet("self", "cancel"), say("self", "cancelled_think", p=0.3)], exclude=["@ahmet"],
               where=[{"c": "attends", "who": "self"}, c_trait("self", "diligence", lt=0.85)])],
   react=[on_trap("meeting_start", "iv_empty_meeting", who="@ahmet", key="emptymeet")])

# --- C08 double-book the meeting -----------------------------------------------------------
L("double_where", ["Hello? Where's everyone? Is this the right meeting?", "We're the 'budget sync'... in the kitchen... right?"])
L("double_realise", ["Wait. There's no budget sync. The real meeting started!", "We're in the wrong meeting! RUN!"])
S_("log.double", "A second 'meeting' appeared in the calendar at the same time. {actor} and {target} sat in the kitchen waiting for it — then ran to the real one, late.")
scene("iv_double_start", allow_absent=True, conditions=[c_present("d1"), c_present("d2")],
      effects=[meetup("iv_double_kitchen", who=("d1", "d2"), area="kitchen", roles={"actor": "d1", "target": "d2"}, ttl=25)])
scene("iv_double_kitchen", noise=0.5, conditions=[c_present("actor"), c_present("target")],
      effects=[hold(["actor", "target"], 4), say("actor", "double_where"), say("target", "double_realise", delay=1.8), emote("target", "exclaim", delay=1.8),
               meet(["actor", "target"], "board"), {"e": "meeting", "key": "belief", "who": ["actor", "target"], "d": -60},
               rel("actor", "target", "friendship", 3, both=True), log("log.double", 3, "meeting")])
iv("C08", "double_book", title="Double-book the meeting slot", desc="A fake 'budget sync' in the kitchen at the same time. Two people will pick the wrong one.",
   log="The ghost booked a fake 'budget sync' in the kitchen at the same time as the real meeting.", **BOARD, icon="calendar", conds=BEFORE,
   state=[pick_role("d1", "worst_of", of="@ahmet", lim=99), pick_role("d2", "best_of", of="d1", lim=-99, **{"not": "@ahmet"}),
          meet(["d1", "d2"], "cancel")],
   react=[on_trap("meeting_start", "iv_double_start", who="@ahmet", key="double")])

# --- C09 make someone else look like the meeting chair --------------------------------------
L("chair_open", ["Right, everyone! Let's begin. I'm chairing today.", "Okay! Since I'm running this meeting — first item!"],
  deniz=["Ladies and gentlemen. Let's make this efficient."], ece=["Um, hi! I'm... apparently the chair? Let's go!"])
L("chair_boss", ["Excuse me. Since when do YOU run my meetings?", "{target}. That's my chair. Literally."])
L("chair_proud", ["The board said so, Ahmet Bey. I was just following instructions.", "Someone had to start it."])
L("chair_shrink", ["Sorry! Sorry. The board said... never mind.", "I'll just... sit over here."])
S_("log.chair_open", "The board named {actor} as today's meeting chair. {actor} started the meeting without Ahmet.")
S_("log.chair_clash", "Ahmet walked in to find {target} running HIS meeting. {target} didn't back down. Tension.")
S_("log.chair_shrink", "Ahmet walked in to find {target} running his meeting. {target} shrank back into a chair.")
ev(id="iv_wrong_chair", trigger="meeting_wrong_chair", priority=70,
   effects=[say("actor", "chair_open"), emote("actor", "cheer"), favor("actor", 2), log("log.chair_open", 3, "meeting"),
            witness([emote("self", "question")], r=6)])
ev(id="iv_boss_chair", trigger="boss_finds_chair", priority=70, noise=0.8,
   effects=[hold(["actor", "target"], 5), expr("actor", "angry", 5), say("actor", "chair_boss", to="target")],
   outcomes=[out("clash", [say("target", "chair_proud", to="actor", delay=1.8), rel("actor", "target", "trust", -10), rel("actor", "target", "respect", 6),
                           rel("actor", "target", "rivalry", 10), favor("target", -4), log("log.chair_clash", 4, "boss")],
                 score=[s_trait("target", "ambition", 1.0), s_trait("target", "cunning", 0.6)]),
             out("shrink", [say("target", "chair_shrink", to="actor", delay=1.8), expr("target", "sad", 4, delay=1.8), mood("target", -6),
                            log("log.chair_shrink", 3, "boss")], score=[s_trait("target", "empathy", 0.6), s_const(0.5)])])
iv("C09", "wrong_chair", title="Name someone else as the meeting chair", desc="The board will say who runs today's meeting.",
   log="The ghost wrote '{target}' as today's meeting chair.", **BOARD, needs="person", icon="star",
   pick=[{"c": "attends", "who": "self"}, c_is("self", "ahmet", neg=True)], conds=BEFORE,
   state=[mtg("chair", "%target"), oset("board.chair", "%target")], watch=["iv_wrong_chair", "iv_boss_chair"])

# --- C10 reveal Ahmet's secret meeting to someone ---------------------------------------------
L("secret_mtg_see", ["'Private: HR review — {subject}'? In Ahmet's calendar?", "Ahmet and Ceren are meeting about {subject}... in secret?"])
S_("log.secret_mtg", "{target} noticed a private meeting in Ahmet's calendar: 'HR review — {subject}'.")
scene("iv_secret_mtg", allow_absent=True, conditions=[c_present("target")],
      effects=[expr("target", "surprised", 4), say("target", "secret_mtg_see"), learn("target", "$fact", c=0.8), log("log.secret_mtg", 3, "secret", who=["target", "subject"]),
               chain("ivm_secret", delay=1.5, roles={"actor": "target"})])
iv("C10", "leak_secret_meeting", title="Show someone Ahmet's secret meeting", desc="'Private: HR review — (someone).' It means nothing. They won't know that.",
   log="The ghost let {target} see a private 'HR review' meeting in Ahmet's calendar.", **BOARD, needs="person", icon="calendar",
   pick=[c_is("self", "ahmet", neg=True), c_present("self")],
   state=[pick_role("subject", "worst_of", of="@ahmet", lim=99, **{"not": "target"}),
          rumor("getting_fired", a="subject", b="target", juicy=0.8, truth=False, knowers=[], key="fact")],
   react=[chain("iv_secret_mtg", delay=2)])

# --- C11 lock the meeting room door ----------------------------------------------------------
L("door_rattle", ["The door's locked?!", "Why is the meeting room locked?", "Hello? Is anyone in there?"], ahmet=["MY meeting room. LOCKED."])
L("door_fetch", ["I'll get the key.", "Hang on, I know where the spare key is."], burak=["Stand back. I'll deal with it."])
L("door_open", ["Got it! It was locked from the INSIDE. How?!", "Open! ...But who locked it? Nobody was in there."])
S_("log.door_locked", "The meeting room was locked. People piled up outside while {fixer} went for the key.")
S_("log.door_open", "{actor} unlocked the meeting room. It had been locked from the inside — with nobody in it.")
ev(id="iv_door_locked", trigger="meeting_door_locked", priority=70,
   roles=[role("fixer", where=[c_avail("self")], score=[s_is("self", "burak", 2.0), s_is("self", "ceren", 1.6), s_trait("self", "diligence", 0.4), s_rand(0.3)],
               exclude=[], optional=True)],
   effects=[say("actor", "door_rattle"), emote("actor", "question"), say("fixer", "door_fetch", delay=1.6), log("log.door_locked", 2, "meeting"),
            go_place("fixer", "board_view", "iv_door_open", prio=86, ttl=30, delay=2), oset("door.locked", False, delay=14)])
scene("iv_door_open", allow_absent=True, conditions=[c_present("actor")],
      effects=[oset("door.locked", False), say("actor", "door_open"), emote("actor", "question"), ghost(), call("ghost_theory"), sfx("pop"), log("log.door_open", 2, "ghost")])
iv("C11", "lock_door", title="Lock the meeting room door", desc="From the inside. With nobody in there.",
   log="The ghost locked the meeting room door.", **TABLE, icon="lock", conds=BEFORE + [why(c_os("door.locked", neg=True), "already_locked")],
   state=[oset("door.locked")], watch=["iv_door_locked", "iv_door_open"], test={"minutes": 260})

# --- C12 swap the name cards on the meeting seats ---------------------------------------------
L("seats_hiss", ["Why am I sitting next to YOU?", "Of all the seats...", "Move your elbow."])
L("seats_hiss2", ["Believe me, I didn't choose this either.", "Name cards. Not my idea."])
L("seats_boss_shush", ["Would you two like to share with the class?!", "Quiet! Both of you!"])
L("seats_truce", ["...Fine. Truce for one hour.", "Let's just survive this meeting."])
L("seats_sweet", ["Oh! Hi. We're... neighbours today.", "Funny, the name cards put us together."])
S_("log.seats_fight", "The meeting name cards put {a} right next to {b}. They bickered until Ahmet snapped at both of them.")
S_("log.seats_truce", "The meeting name cards seated {a} beside {b}. They called a truce. A small miracle.")
S_("log.seats_sweet", "The meeting name cards put {a} next to {b}. Lots of shy smiling.")
ev(id="iv_seats", trigger="", priority=60, allow_absent=True,
   vars=[var("a", "seat_pair", optional=True)],
   conditions=[c_filled("$a"), c_present("$a"), c_present("$b")],
   effects=[hold(["$a", "$b"], 5)],
   outcomes=[out("fight", [say("$a", "seats_hiss", to="$b"), say("$b", "seats_hiss2", to="$a", delay=1.6), sfx("argue", delay=1.6),
                           say("actor", "seats_boss_shush", delay=3.2), expr("actor", "angry", 4, delay=3.2), favor("$a", -2), favor("$b", -2),
                           rel("$a", "$b", "friendship", -5, both=True), log("log.seats_fight", 3, "conflict", who=["$a", "$b"])],
                 score=[s_trait("$a", "temper", 1.0), s_rel("$a", "$b", "rivalry", 0.02)], when=[c_var("pairkind", eq="rivals")]),
             out("truce", [say("$a", "seats_hiss", to="$b"), say("$b", "seats_truce", to="$a", delay=1.6), rel("$a", "$b", "rivalry", -6, both=True),
                           rel("$a", "$b", "respect", 4, both=True), log("log.seats_truce", 3, "friendship", who=["$a", "$b"])],
                 score=[s_trait("$b", "empathy", 1.0), s_trait("$a", "forgiveness", 0.6)], when=[c_var("pairkind", eq="rivals")]),
             out("sweet", [say("$a", "seats_sweet", to="$b"), emote("$a", "love", delay=1.0), emote("$b", "love", delay=2.0), rel("$a", "$b", "romance", 8, both=True),
                           log("log.seats_sweet", 3, "romance", who=["$a", "$b"])], score=[s_const(5)], when=[c_var("pairkind", eq="crush")])])
iv("C12", "swap_seats", title="Swap the name cards on the meeting seats", desc="Seat the worst possible pair side by side. (Or the best.)",
   log="The ghost rearranged the name cards in the meeting room.", **TABLE, icon="people", conds=BEFORE,
   state=[oset("door.cards", True)], react=[on_trap("meeting_start", "iv_seats", who="@ahmet", key="seats")])

# --- C13 make the meeting "5 minutes" ---------------------------------------------------------------
L("walkout_leave", ["The board said five minutes. I have work.", "Five-minute meeting, right? Bye!"])
L("walkout_boss", ["WHERE do you think you're going?!", "Sit DOWN. This meeting is over when I say it's over!"])
S_("log.walkout", "The board said today's meeting was '5 minutes'. After ten, people started walking out on Ahmet.")
ev(id="iv_walkout", trigger="meeting_walkout", priority=70,
   effects=[say("target", "walkout_leave"), say("actor", "walkout_boss", delay=1.6), expr("actor", "angry", 6, delay=1.6), emote("actor", "anger", delay=1.6),
            stress("actor", 12), favor("target", -5), call("scold", target="target", reason="meeting", prio=62, delay=10), log("log.walkout", 4, "meeting")])
iv("C13", "short_meeting", title="Write '5 minutes' on the meeting", desc="People will take the board at its word.",
   log="The ghost wrote 'max 5 minutes!' on today's meeting.", **BOARD, icon="board", conds=BEFORE,
   state=[mtg("short", True), oset("board.title", "5 min!")], watch=["iv_walkout"])

# --- C14 promise free pizza at the meeting --------------------------------------------------------
L("pizza_hype", ["Free pizza at the meeting! I'm going early.", "Pizza?! Best meeting ever."], mert=["PIZZA. I'll be first."])
L("pizza_none", ["Where's the pizza?", "There's... no pizza?", "We were promised pizza!"], mert=["I skipped breakfast for this."])
L("pizza_boss", ["What pizza? Nobody ordered pizza!", "There is no pizza. There was never any pizza."])
S_("log.pizza", "The meeting board promised free pizza. Everyone showed up early and hungry. There was no pizza.")
scene("iv_no_pizza", allow_absent=True, conditions=[c_present("actor")],
      effects=[say("actor", "pizza_boss"), each([say("self", "pizza_none", p=0.4, delay=1.2), mood("self", -8)], exclude=["actor"], where=[c_act("self", ["meeting"])], stagger=0.5),
               log("log.pizza", 3, "meeting"), rel("@mert", "@ceren", "suspicion", 6)])
iv("C14", "pizza", title="Promise free pizza at the meeting", desc="Everyone will arrive early. Hungry.",
   log="The ghost wrote 'FREE PIZZA!' next to today's meeting.", **BOARD, icon="coffee", conds=BEFORE,
   state=[oset("board.title", "PIZZA!"), each([say("self", "pizza_hype", p=0.4), mood("self", 4), {"e": "meeting", "key": "belief", "who": "self", "d": -10}],
                                              exclude=["@ahmet"], where=[{"c": "attends", "who": "self"}])],
   react=[on_trap("meeting_start", "iv_no_pizza", who="@ahmet", key="pizza")])

# --- C15 break the projector ------------------------------------------------------------------------
L("proj_dead", ["...The projector's dead.", "Nothing on the screen? Nothing at all?", "Of course. The projector picked today."])
L("proj_improv", ["Fine. I'll draw it on the whiteboard.", "Who needs slides? Gather round."])
L("proj_panic", ["I can't present without slides!", "My whole talk is IN the slides!"])
S_("log.proj_improv", "The projector died just as {actor} started presenting. {actor} drew everything by hand. Impressive.")
S_("log.proj_panic", "The projector died as {actor} started presenting. {actor} fell apart.")
scene("iv_projector_dead", noise=0.6, allow_absent=True, conditions=[c_present("actor")],
      effects=[hold(["actor"], 4), say("actor", "proj_dead"), expr("actor", "surprised", 4), call("fix_intent", who="@burak", obj="projector", requester="actor", prio=60, delay=2)],
      outcomes=[out("improv", [say("actor", "proj_improv", delay=1.8), emote("actor", "idea", delay=1.8), favor("actor", 5), witness([rel("self", "actor", "respect", 6)], r=6),
                               log("log.proj_improv", 3, "meeting")], score=[s_trait("actor", "diligence", 0.8), s_trait("actor", "sociability", 0.5)]),
                out("panic", [say("actor", "proj_panic", delay=1.8), emote("actor", "sweat", delay=1.8), favor("actor", -4), stress("actor", 12),
                              log("log.proj_panic", 3, "meeting")], score=[s_stress("actor", 0.02), s_const(0.4)])])
iv("C15", "break_projector", title="Break the projector", desc="It'll die the moment someone starts presenting.",
   log="The ghost broke the meeting room projector.", **TABLE, icon="bulb", conds=BEFORE + [why(c_os("projector.broken", neg=True), "already_broken", "It's already broken.")],
   state=[oset("projector.broken")], react=[on_trap("meeting_present", "iv_projector_dead", key="projector", replace=True)])

# --- C16 fake meeting minutes: "X volunteered to organise the team retreat" ---------------------------------
L("minutes_thank", ["Thanks for organising the team retreat, {target}! So excited!", "You're organising the retreat? You're a hero, {target}."])
L("minutes_what", ["The WHAT? I never volunteered for anything!", "Retreat? Me? Since when?"])
L("minutes_own_it", ["...Yes. Yes, I am. It'll be amazing.", "That's right. Leave it to me."])
L("minutes_refuse", ["Someone wrote that in the minutes. Not me. I'm not doing it.", "No. Absolutely not. Find another volunteer."])
S_("log.minutes_own", "The meeting minutes say {target} volunteered to organise the team retreat. {target} decided to own it.")
S_("log.minutes_refuse", "The meeting minutes say {target} volunteered to organise a retreat. {target} absolutely did not.")
scene("iv_minutes_fan", allow_absent=True, conditions=[c_present("target")],
      roles=[role("fan", where=[c_avail("self"), c_not(c_same("self", "target"))], score=[s_trait("self", "sociability", 1.0), s_aff("self", "target", 0.02)], exclude=["target"])],
      effects=[visit("fan", "target", "iv_minutes_scene", prio=58, ttl=60)])
scene("iv_minutes_scene", noise=0.8, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 5), say("actor", "minutes_thank", to="target"), say("target", "minutes_what", to="actor", delay=1.6)],
      outcomes=[out("own", [say("target", "minutes_own_it", to="actor", delay=3.2), call("extra_work", target="target", units=18, task="retreat_plan"), favor("target", 3),
                            rel("actor", "target", "respect", 6), flag("retreat_planner", "target"), log("log.minutes_own", 3, "work")],
                    score=[s_trait("target", "ambition", 0.8), s_trait("target", "sociability", 0.6)]),
                out("refuse", [say("target", "minutes_refuse", to="actor", delay=3.2), rel("target", "@ceren", "suspicion", 12), mood("actor", -4),
                               log("log.minutes_refuse", 2, "misunderstanding")], score=[s_trait("target", "temper", 0.6), s_const(0.4)])])
iv("C16", "fake_minutes", title="Add a line to the meeting minutes", desc="'(Someone) volunteered to organise the team retreat.' Pick who.",
   log="The ghost added '{target} volunteered to organise the team retreat' to the meeting minutes.", **TABLE, needs="person", icon="papers",
   pick=[c_is("self", "ahmet", neg=True), c_present("self")], state=[oset("board.minutes", "%target")], react=[chain("iv_minutes_fan", delay=6)])

# --- C17 put a golf game in Ahmet's calendar during the meeting ---------------------------------------------------
L("golf_go", ["Golf with the regional director? Now? ...Right. Ceren, run my morning.", "Oh! The golf thing. I completely forgot. I'm off."])
L("golf_takeover", ["Ahmet's not coming. Fine — I'll run this meeting.", "No boss? Then let's do it properly. Item one."])
L("golf_follow", ["Okay, boss.", "Sure, why not.", "Fine by me."])
L("golf_resist", ["Who made you the boss?", "Nice try."])
S_("log.golf_away", "A golf game appeared in Ahmet's calendar. He left the office. Right before his own meeting.")
S_("log.golf_takeover", "With Ahmet off playing golf, {actor} took charge of the meeting. Not everyone liked it.")
scene("iv_golf_seen", allow_absent=True, conditions=[c_present("@ahmet")],
      effects=[say("@ahmet", "golf_go"), away("@ahmet", 70, "golf", delay=1.5), log("log.golf_away", 3, "boss")])
ev(id="iv_golf_takeover", trigger="", priority=60, allow_absent=True,
   roles=[role("leader", where=[c_avail("self"), c_is("self", "ahmet", neg=True)], score=[s_trait("self", "ambition", 1.2), s_trait("self", "cunning", 0.4), s_rand(0.3)], exclude=[])],
   effects=[say("leader", "golf_takeover"), emote("leader", "idea"), favor("leader", 2), log("log.golf_takeover", 3, "meeting", who=["leader"]),
            each([say("self", "golf_follow", p=0.4, delay=1.6), rel("self", "leader", "respect", 5)], exclude=["leader"], where=[c_aff("self", "leader", gt=10)], stagger=0.4),
            each([say("self", "golf_resist", p=0.6, delay=1.6), rel("self", "leader", "rivalry", 8)], exclude=["leader"], where=[c_aff("self", "leader", lt=-5)], stagger=0.4)])
iv("C17", "boss_golf", title="Put a golf game in Ahmet's calendar", desc="He'll leave — right before his own meeting.",
   log="The ghost added 'Golf with the regional director' to Ahmet's calendar.", **BOARD, icon="calendar",
   conds=BEFORE + [r_present("@ahmet")],
   state=[oset("board.golf", True)],
   react=[chain("iv_golf_seen", delay=2), on_trap("meeting_wait_timeout", "iv_golf_takeover", key="golf_take")])

# --- C18 schedule a surprise performance review ---------------------------------------------------------------
L("review_call", ["{actor}. My office. Your performance review is now.", "Ah, {actor}. Sit. It's review time, apparently."])
L("review_nervous", ["N-now? I didn't prepare anything!", "My review? Today?!"])
L("review_good", ["Honestly? You've been excellent. Keep it up.", "Strong work this quarter. I've noticed."])
L("review_bad", ["Frankly, I expected more from you.", "Your numbers worry me. A lot."])
S_("log.review_good", "{actor} was dragged into a surprise performance review. It went brilliantly.")
S_("log.review_bad", "{actor} was dragged into a surprise performance review. It went badly.")
S_("mem.review_bad", "Ahmet gave me a terrible surprise review.")
S_("mem.review_good", "Ahmet praised me in a surprise review.")
scene("iv_review", noise=0.6, conditions=[c_avail("target")],
      effects=[hold(["actor", "target"], 6), say("target", "review_call", to="actor"), say("actor", "review_nervous", to="target", delay=1.6), emote("actor", "sweat", delay=1.6),
               stress("actor", 10)],
      outcomes=[out("good", [say("target", "review_good", to="actor", delay=3.4), emote("actor", "cheer", delay=3.6), morale("actor", 8), mood("actor", 14),
                             mem("actor", "target", "praised", 0.6, 0.8, "mem.review_good", 3), log("log.review_good", 3, "boss")],
                    score=[{"s": "favor", "who": "actor", "w": 0.05}, s_rel("target", "actor", "respect", 0.02)]),
                out("bad", [say("target", "review_bad", to="actor", delay=3.4), expr("actor", "sad", 6, delay=3.4), morale("actor", -10), mood("actor", -14),
                            mem("actor", "target", "scolded", -0.6, 0.9, "mem.review_bad", 3), rel("actor", "target", "resentment", 10),
                            plan("actor", "job_search", "", heat=0.7, when=[c_morale("actor", lt=50)]), log("log.review_bad", 3, "boss")],
                    score=[s_const(2.6), s_rel("target", "actor", "trust", -0.02)])])
iv("C18", "surprise_review", title="Book a surprise performance review", desc="Put a 1:1 review for someone into Ahmet's calendar — starting now.",
   log="The ghost booked a surprise performance review for {target} in Ahmet's calendar.", **BOARD, needs="person", icon="calendar",
   pick=[c_is("self", "ahmet", neg=True), c_present("self")], conds=[r_present("@ahmet"), why(c_busy_meeting("@ahmet"), "boss_busy", "Ahmet is in a meeting.")],
   state=[oset("board.review", "%target")], react=[summon("target", "iv_review", delay=2)])

# --- C19 announce a client visit -----------------------------------------------------------------------------
L("client_tidy", ["A client visit? Today?! Clean everything!", "Client at two! Hide the mess!"], ahmet=["Everyone! Look busy! LOOK. BUSY."])
L("client_none", ["Where's the client? It's past two!", "So... no client then?"], ahmet=["Ceren! Where is my client?!"])
L("client_ceren", ["What client? There's nothing in the calendar.", "I didn't book any visit, Ahmet Bey."])
S_("log.client_tidy", "The board announced a client visit. The whole office is tidying and working at double speed.")
S_("log.client_none", "The 'client visit' never happened. Nobody knows who wrote it on the board. Everyone tidied for nothing.")
scene("iv_client_prep", allow_absent=True,
      effects=[each([say("self", "client_tidy", p=0.4, delay=1.0), stress("self", 6), emote("self", "exclaim")], stagger=0.4), log("log.client_tidy", 3, "work")])
scene("iv_client_none", allow_absent=True, conditions=[c_present("@ahmet")],
      effects=[say("@ahmet", "client_none"), say("@ceren", "client_ceren", delay=1.6, when=[c_present("@ceren")]), flag("client_visit", False, day=True),
               each([mood("self", -4)], stagger=0.2), ghost(), call("ghost_theory"), log("log.client_none", 3, "misunderstanding")])
iv("C19", "client_visit", title="Announce a client visit", desc="'Important client at 14:00!' Watch everyone tidy and work twice as hard.",
   log="The ghost wrote 'IMPORTANT CLIENT VISIT TODAY' on the board.", **BOARD, icon="people", conds=[r_time(before="14:00")],
   state=[flag("client_visit", True, day=True), oset("board.title", "CLIENT!")], react=[chain("iv_client_prep", delay=1), chain("iv_client_none", delay=60)])

# --- C20 rename the meeting: "(Someone)'s farewell" ------------------------------------------------------------------
L("farewell_sad", ["{target} is LEAVING?!", "Farewell meeting for {target}? Nobody told me!", "We'll miss you, {target}!"])
L("farewell_speech", ["{target}, you've been... honestly, the best. We'll miss you.", "To {target}! The office won't be the same."])
L("farewell_not", ["I'm not leaving! Who wrote that?!", "Farewell? I'm not going anywhere!"])
L("farewell_moved", ["...You'd really miss me? I didn't know that.", "I'm not leaving, but... thank you. Really."])
L("farewell_maybe", ["...Actually. Maybe it's a sign.", "Hm. Leaving doesn't sound that bad."])
S_("log.farewell_moved", "The board called today's meeting '{target}'s farewell'. {target} isn't leaving — but heard how much people would miss them.")
S_("log.farewell_maybe", "The board called today's meeting '{target}'s farewell'. {target} isn't leaving... but now they're thinking about it.")
scene("iv_farewell", noise=0.8, allow_absent=True, conditions=[c_present("target")],
      effects=[say("target", "farewell_not"), emote("target", "question"), debunk("$fact", who=["actor"], by="target")],
      outcomes=[out("moved", [each([say("self", "farewell_speech", p=0.5, delay=1.6)], exclude=["target"], where=[c_aff("self", "target", gt=20)], stagger=0.6),
                              say("target", "farewell_moved", delay=4), emote("target", "love", delay=4), morale("target", 10), mood("target", 12),
                              log("log.farewell_moved", 3, "friendship", who=["target"])], score=[s_morale("target", 0.03), s_const(0.4)]),
                out("maybe", [say("target", "farewell_maybe", delay=3), plan("target", "job_search", "", heat=1.0), log("log.farewell_maybe", 3, "drama", who=["target"])],
                    score=[s_morale("target", -0.04), s_goal("target", "find_new_job", 1.5)])])
iv("C20", "farewell_meeting", title="Rename the meeting '(Someone)'s farewell'", desc="Everyone will think they're leaving. Including, maybe, them.",
   log="The ghost renamed today's meeting to '{target}'s farewell'.", **BOARD, needs="person", icon="star", conds=BEFORE,
   pick=[c_is("self", "ahmet", neg=True), {"c": "attends", "who": "self"}],
   state=[oset("board.title", "Farewell!"), rumor("resigning", a="target", b="target", juicy=0.8, truth=False, knowers=[], key="fact"),
          each([learn("self", "$fact", c=0.65), say("self", "farewell_sad", p=0.3, delay=1.0)], exclude=["target"], stagger=0.5)],
   react=[on_trap("meeting_start", "iv_farewell", who="@ahmet", key="farewell")])
