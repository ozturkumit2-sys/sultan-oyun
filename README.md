# OFFICE CHAOS

A portrait Android sandbox / social simulation: you are an invisible force in a small
office of 8 coworkers. You never control anyone — you meddle with objects, emails,
the meeting board, the thermostat, the lights, the promotion file and people's
belongings, and watch the consequences ripple through a living office.

> **Engine note.** The original brief asked for Unity 6.3 LTS. Unity can't be installed or
> licensed in the build environment and the project owner works from a phone, so the game
> was built with **Godot 4.7 (GDScript)**, which can be compiled to an APK here and needs
> no PC. Every gameplay requirement of the brief is implemented; Unity-specific items
> (Editor menu automation) are not applicable — the whole scene is built in code at runtime,
> so there is nothing to set up by hand.

## What's in the game
- Isometric single-floor office: open workspace (6 desks), manager's office, meeting room,
  kitchen & coffee corner, printer/archive nook, lounge, reception & entrance.
- 8 characters with distinct looks, 5 facial expressions, walk/sit/type/phone/coffee/eat/
  read/fix/search/talk/react animations and emote icons.
- Rule-based NPC AI: daily routine (arrival, meeting, lunch, leaving), utility-based choice
  of activities from personality traits, needs (coffee, social), stress, mood, tasks &
  deadlines, goals, relationships (trust / friendship / rivalry) and memories.
- 12 interventions (+ "lights back on"): break / secretly fix the coffee machine, jam the
  printer, send someone's private draft to everyone, redirect their next email, move the
  meeting, doctor the promotion file, mess up a desk, fake phone notifications (boss summons,
  free cake, meeting cancelled, secret admirer), change the AC, kill the lights, move an
  important item. Most are latent: they only trigger when someone actually runs into them.
- Data-driven event engine: 282 event definitions with triggers, filters, conditions, role
  selection, scored branching outcomes, delays, priorities, daily caps, cooldowns (minutes
  or days) and pacing tiers (`data/events.json`, authored in `_dev/data_src/`).
- **A living office (v1.1).** Characters start things on their own — 58 "initiative"
  events picked by the `StoryDirector` from personality, goals, mood, relationships,
  plans and memories (gossip huddles in the kitchen, asking for a raise, sabotaging a
  rival's desk, peace offerings, secret pacts, office pranks, fridge thefts, cake days...).
- **16 multi-stage story arcs** (3–6 stages, branching, often spanning several days):
  the stolen idea, office romance, headhunted, the resignation letter, the missing
  contract, the deleted folder, layoff panic, the secret alliance, surprise birthday,
  the blame game, covering for the kid, gunning for team lead, revenge, not on speaking
  terms (mediation), boss vs. employee, the boss's niece (`data/arcs.json`, `_dev/data_src/arcs.py`).
  Each stage walks people somewhere (to a desk, the kitchen, the archive, the meeting
  room or Ahmet's office) and its outcome decides the next stage, a detour or the ending.
- **Pacing:** each day aims for ~5–8 small social moments, 1–3 medium incidents and one
  big story starting or moving forward; recent events are faded out so days don't repeat.
- **Beliefs, not just facts:** people know different things with different certainty.
  Hearsay gets shakier with every retelling, gossips exaggerate (an argument becomes a
  "fistfight"), false rumours exist and can be checked, debunked and traced to whoever
  started them — and spreading lies costs trust.
- **Things carry over:** memories (big ones fade slowly), feuds, secret alliances,
  romances, revenge plans, job hunting and job satisfaction (morale) persist across days
  and through save/load.
- 2000+ situation-based speech lines (`data/dialogue_en.json`), recent-line avoidance.
- Day loop 09:00–18:00 (~10 real minutes at 1x), pause / 1x / 2x, end-of-day newspaper with
  real counts, the day's three biggest stories and the running storylines, optional auto-advance.
- Gossip board shows running storylines; the personnel file shows ties & plans, what the
  person has heard (and how sure they are) and their job satisfaction.
- Local save (autosave), New Game / Continue, settings, original synthesized music & SFX.
- Replayability: starting relationships, goals, secrets and who knows them are randomized
  per new game.

## Project layout
```
scripts/sim/      simulation (no graphics): SimWorld, NPC, NPCBrain, NPCSchedule, NPCController,
                  EventManager, EventConditionEvaluator, EventConsequenceResolver,
                  DialogueManager, Interventions (InteractionManager), OfficeEnv,
                  MeetingFlow, WorldSpecials, DayStats, StoryDirector (pacing, initiative, arcs,
                  meetups)
scripts/view/     isometric rendering: OfficeView (camera, taps), CharacterView, FurnitureArt,
                  OfficeBackdrop, WallDynamic, FxLayer, ...
scripts/ui/       stationery-themed UI: HUD, sheets, personnel file, gossip board, newspaper...
scripts/autoload/ Game (GameManager + SaveManager), Loc (localization), Audio (AudioManager)
data/             characters, facts, events, arcs, rumour kinds, dialogue, UI strings (JSON)
_dev/             data sources & validator, audio synthesizer (not exported)
tests/            headless simulation tests, scenario tests, UI bot, screenshot harness
```

## Adding a language
Copy `data/lang/en.json` and `data/dialogue_en.json` to e.g. `tr.json` / `dialogue_tr.json`,
translate the values, then call `Loc.load_lang("tr")`.

## Building
```
python3 _dev/data_src/build_data.py          # validate + regenerate data/*.json
python3 _dev/audio/make_audio.py              # regenerate audio (optional)
godot --headless --path . res://tests/sim_test.tscn -- days=6
godot --headless --path . res://tests/scenario_test.tscn
godot --headless --path . res://tests/story_test.tscn        # story system: 9 tests
godot --headless --path . res://tests/coverage_test.tscn -- seeds=16 days=12 meddle=0
godot --headless --export-release Android build/OfficeChaos.apk
```
For Google Play, export an AAB with a Gradle build template and an upload keystore
(Play Console → App signing).
