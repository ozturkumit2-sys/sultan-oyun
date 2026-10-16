# Strings added for the translations: things that used to be written straight into the
# code (signs on the office walls, panel titles), the people's job titles and bios,
# and the language picker.
from iv_helpers import S_
from characters import CHARACTERS

for c in CHARACTERS:
    S_("name." + c["id"], c["name"])
    S_("char.%s.role" % c["id"], c["role"])
    for i, b in enumerate(c["bio"]):
        S_("char.%s.bio%d" % (c["id"], i + 1), b)

S_("ui.language", "Language")
S_("ui.choose_language", "Choose a language")
S_("ui.day_short", "Day {day}")
S_("ui.quote", "“{text}”")
S_("ui.day_label", "DAY")
S_("ui.fast", "FAST x2")
S_("ui.board_staff", "STAFF")
S_("ui.board_gossip", "GOSSIP BOARD")
S_("ui.personnel_file", "PERSONNEL FILE")
S_("ui.leaked", "LEAKED")
S_("paper.edition", "OFFICE EDITION")

# signs and notes inside the office (drawn very small: keep them short)
S_("wall.meeting", "MEETING")
S_("wall.done", "DONE!")
S_("wall.now", "NOW!")
S_("wall.agenda", "AGENDA: {text}")
S_("wall.chair", "CHAIR: {name}")
S_("wall.reception", "RECEPTION")
S_("wall.out", "OUT")
S_("wall.hello", "HELLO")
S_("wall.printer1", "PLEASE DON'T")
S_("wall.printer2", "KICK PRINTER")
S_("wall.fire", "FIRE")
S_("wall.teamwork", "TEAMWORK")
S_("wall.power", "POWER")

# what the ghost can write on the meeting board
for k, v in {"5min": "5 min!", "pizza": "PIZZA!", "client": "CLIENT!", "farewell": "Farewell!", "promotion": "PROMOTION!",
             "restructuring": "RESTRUCTURING Q&A", "acting_boss": "ACTING BOSS"}.items():
    S_("board.t." + k, v)
for k, v in {"layoffs": "LAYOFFS", "romance": "ROMANCE POLICY", "lunch": "LUNCH THIEF", "promo": "PROMOTIONS"}.items():
    S_("board.agenda." + k, v)
