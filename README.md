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
- Data-driven event engine: 85 events / chains with triggers, filters, conditions, role
  selection, scored branching outcomes, delays, priorities, daily caps and cooldowns
  (`data/events.json`, authored in `_dev/data_src/events.py`).
- Knowledge & rumours: secrets, gossip spreading person to person, rumours created by
  what happens; the player discovers secrets by overhearing them.
- 800+ situation-based speech lines (`data/dialogue_en.json`), recent-line avoidance.
- Day loop 09:00–18:00 (~10 real minutes at 1x), pause / 1x / 2x, end-of-day newspaper with
  real counts and the day's three biggest stories, optional auto-advance.
- Local save (autosave), New Game / Continue, settings, original synthesized music & SFX.
- Replayability: starting relationships, goals, secrets and who knows them are randomized
  per new game.

## Project layout
```
scripts/sim/      simulation (no graphics): SimWorld, NPC, NPCBrain, NPCSchedule, NPCController,
                  EventManager, EventConditionEvaluator, EventConsequenceResolver,
                  DialogueManager, Interventions (InteractionManager), OfficeEnv,
                  MeetingFlow, WorldSpecials, DayStats
scripts/view/     isometric rendering: OfficeView (camera, taps), CharacterView, FurnitureArt,
                  OfficeBackdrop, WallDynamic, FxLayer, ...
scripts/ui/       stationery-themed UI: HUD, sheets, personnel file, gossip board, newspaper...
scripts/autoload/ Game (GameManager + SaveManager), Loc (localization), Audio (AudioManager)
data/             characters, facts, events, dialogue, UI strings (JSON)
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
godot --headless --export-release Android build/OfficeChaos.apk
```
For Google Play, export an AAB with a Gradle build template and an upload keystore
(Play Console → App signing).
