# UI strings for the v1.2 update: new objects, desk tabs, reasons, the Discovery
# Journal and the extra relationship / memory fields in the personnel file.
from iv_helpers import S_, CATS

SPOTS = {
    "fridge": "Fridge", "water_cooler": "Water cooler", "kitchen_table": "Kitchen table", "microwave": "Microwave",
    "file_cabinet": "Filing cabinets", "supply_shelf": "Supply shelf", "server_box": "Server cupboard", "meeting_table": "Meeting room table",
    "hr_cabinet": "HR cabinet", "sofa": "Lounge sofa", "coat_rack": "Coat rack", "plant": "Office plant", "front_door": "Front door",
    "noticeboard": "Cork noticeboard", "wall_clock": "Wall clock", "speaker": "Office speaker", "alarm_panel": "Fire alarm panel",
}
for k, v in SPOTS.items():
    S_("spot." + k, v)

for k, v in {"pc": "Computer", "mail": "Inbox", "phone": "Phone", "papers": "Desk"}.items():
    S_("tab." + k, v)

for k, v in CATS.items():
    S_("cat." + k, v)

S_("state.coffee_odd", "Working… mostly")
S_("state.no_paper", "Out of paper")
S_("state.clock", "Shows {time}")
S_("state.alarm_on", "RINGING")
S_("state.alarm_off", "Quiet")
S_("state.music_off", "Silent")
S_("state.music", "Playing {what}")
S_("state.pins", "{n} notes pinned")

S_("ui.found_here", "Found here: {n} / {total}")
S_("ui.secrets_here", "{n} secret")
S_("ui.nothing_here", "Nothing to meddle with here right now.")
S_("ui.secret_combo", "SECRET COMBINATION")
S_("ui.new_tag", "NEW")
S_("ui.picked", "For {name} — now choose how")

S_("why.owner_absent", "They're not at their desk today.")
S_("why.cooldown", "Too soon — someone might notice the pattern.")
S_("why.used_today", "Already done today.")
S_("why.not_now", "Not possible right now.")

S_("ui.journal", "Discovery Journal")
S_("journal.meddles", "Meddles")
S_("journal.stories", "Stories")
S_("journal.moments", "Moments")
S_("journal.records", "Records")
S_("journal.meddles_found", "meddles discovered")
S_("journal.undiscovered", "{n} still undiscovered. Some only appear when the right things line up…")
S_("journal.found_pct", "{n}  ·  {pct}%")
S_("journal.all_categories", "All categories")
S_("journal.used", "Used {n}× · first on day {day}")
S_("journal.outcomes", "{n} different outcomes seen")
S_("journal.unknown_left", "{n} more to discover in this category")
S_("journal.secrets_left", "{n} secret combinations still hidden")
S_("journal.stories_done", "stories seen to the end")
S_("journal.endings", "{n} different endings discovered")
S_("journal.story_line", "Seen {n}× · endings: {ends}")
S_("journal.stories_left", "{n} stories nobody has lived through yet")
S_("journal.moments_seen", "special moments witnessed")
S_("journal.moments_hint", "Big moments the office will be talking about for weeks.")
S_("journal.moment_unrecorded", "(It happened. Nobody wrote it down.)")
S_("journal.biggest", "Biggest chain reaction")
S_("journal.no_biggest", "Nothing has snowballed yet. Give it time.")
S_("journal.biggest_line", "'{what}' (day {day}) set off {n} consequences.")
S_("journal.biggest_arcs", "It even started: {arcs}")
S_("journal.r_meddles", "Meddles discovered")
S_("journal.r_outcomes", "Different outcomes seen")
S_("journal.r_secrets", "Secret combinations found")
S_("journal.r_stories", "Stories finished")
S_("journal.r_endings", "Different endings")
S_("journal.r_moments", "Special moments")

S_("ui.respect", "Respect")
S_("ui.romance", "Crush")
S_("ui.suspicion", "Suspicion")
S_("ui.resentment", "Grudge")
S_("ui.mem_sure", "sure")
S_("ui.mem_heard", "heard it")
S_("ui.mem_doubt", "not sure")
for k, v in {"joy": "happy", "pride": "proud", "love": "touched", "relief": "relieved", "anger": "angry", "hurt": "hurt", "shame": "embarrassed",
             "fear": "scared", "jealousy": "jealous", "sad": "sad", "surprise": "surprised", "neutral": "",
             "annoyed": "annoyed", "grateful": "grateful", "pleased": "pleased"}.items():
    S_("emo." + k, v)
S_("mem.raw", "{text}")
