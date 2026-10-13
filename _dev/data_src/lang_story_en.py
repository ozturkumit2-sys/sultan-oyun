# Strings for the living-office story layer -> data/lang/en.json
from lang_en import s as _s, S


def s(k, v):
    assert k not in S, "string key already defined: " + k
    _s(k, v)

# rumours ({a} ... {b})
for k, v in {
    "rumor.fistfight": "{a} and {b} nearly came to blows!",
    "rumor.getting_fired": "{a} is about to be fired.",
    "rumor.slacker": "{a} sneaks out every afternoon and nobody notices.",
    "rumor.sabotage": "{a} sabotaged {b}'s work on purpose.",
    "rumor.engaged": "{a} and {b} are secretly ENGAGED!",
    "rumor.crush": "{a} has a huge crush on {b}.",
    "rumor.interview": "{a} has a job interview somewhere else.",
    "rumor.job_hunting": "{a} is looking for another job.",
    "rumor.resigning": "{a} is about to resign.",
    "rumor.layoffs": "There are going to be layoffs by Friday.",
    "rumor.nepotism_hint": "{a} might be related to {b}...",
    "rumor.alliance": "{a} and {b} are secretly plotting together.",
    "rumor.lost_file": "{a} deleted the shared folder.",
    "rumor.stole_lunch": "{a} has been eating other people's lunch from the fridge.",
    "rumor.snores": "{a} fell asleep and snored in the meeting.",
    "rumor.raise": "{a} secretly got a raise.",
    "rumor.boss_pet": "{a} is sucking up to Ahmet. Shamelessly.",
    "rumor.threat": "{a} threatened {b}.",
    "rumor.prank": "{a} has been pranking {b}.",
}.items():
    s(k, v)

# story titles (gossip board / newspaper)
for k, v in {
    "arc.stolen_idea": "The Stolen Idea",
    "arc.office_romance": "Office Romance",
    "arc.headhunted": "Headhunted",
    "arc.resignation": "The Resignation Letter",
    "arc.missing_contract": "The Missing Contract",
    "arc.deleted_folder": "The Deleted Folder",
    "arc.layoff_panic": "Layoff Panic",
    "arc.secret_alliance": "The Secret Alliance",
    "arc.birthday": "Surprise Party",
    "arc.blame_game": "The Blame Game",
    "arc.mentor_protect": "Covering for the Kid",
    "arc.promotion_push": "Gunning for Team Lead",
    "arc.revenge_plot": "Revenge Is Sweet",
    "arc.feud_mediation": "Not on Speaking Terms",
    "arc.boss_clash": "Boss vs. Employee",
    "arc.niece_secret": "The Boss's Niece",
}.items():
    s(k, v)

for k, v in {
    "obj.keyboard": "keyboard",
    "task.urgent_report": "Urgent report for HQ",
    "task.kaya_pitch": "Kaya account pitch",
    "ui.storylines": "Storylines",
    "ui.story_chapter": "Part {n}",
    "ui.story_done": "Wrapped up",
    "ui.no_stories": "No big stories brewing… yet.",
    "ui.morale": "Job satisfaction",
    "ui.beliefs": "What they've heard",
    "ui.no_beliefs": "Hasn't heard anything juicy.",
    "ui.sure": "sure",
    "ui.heard": "heard it",
    "ui.not_sure": "not sure",
    "ui.debunked": "turned out false",
    "ui.bonds": "Ties & plans",
    "ui.no_bonds": "Nothing brewing.",
    "bond.feud": "Not speaking to {name}",
    "bond.alliance": "Secret ally of {name}",
    "bond.romance": "Seeing {name}",
    "bond.mentor": "Looks out for {name}",
    "plan.revenge": "Wants revenge on {name}",
    "plan.undermine": "Working against {name}",
    "plan.job_search": "Looking for another job",
    "plan.prove_self": "Determined to prove themselves",
    "plan.expose": "Wants to expose {name}",
    "plan.apologize": "Owes {name} an apology",
    "paper.continued": "TO BE CONTINUED",
    "paper.concluded": "STORY CONCLUDED",
    "stat.debunked": "Rumours debunked",
}.items():
    s(k, v)

# teasers: shown on a story card until its first scene has happened
for k, v in {
    "arc.stolen_idea.teaser": "{thief} has been eyeing {victim}'s client proposal...",
    "arc.office_romance.teaser": "{lover} keeps glancing at {crush}. Something's brewing.",
    "arc.headhunted.teaser": "{seeker} keeps checking their phone. A recruiter, maybe?",
    "arc.resignation.teaser": "{quitter} looks like they've had enough of this place.",
    "arc.missing_contract.teaser": "{owner} is about to discover something important is missing...",
    "arc.deleted_folder.teaser": "{culprit} is clicking things they really shouldn't.",
    "arc.layoff_panic.teaser": "{ear} is hovering near Ahmet's office, listening...",
    "arc.secret_alliance.teaser": "{schemer} wants a quiet word with {partner}.",
    "arc.birthday.teaser": "It's {bday}'s birthday — and {organizer} has a plan.",
    "arc.blame_game.teaser": "Ahmet's phone is ringing. It sounds like an angry client.",
    "arc.mentor_protect.teaser": "{protege} is about to make a mistake in {mentor}'s report.",
    "arc.promotion_push.teaser": "{climber} is working up the nerve to ask Ahmet about team lead.",
    "arc.revenge_plot.teaser": "{avenger} hasn't forgiven {victim}. Not even close.",
    "arc.feud_mediation.teaser": "{a} and {b} have stopped talking. Will anyone step in?",
    "arc.boss_clash.teaser": "Ahmet keeps hovering over {rebel}'s desk. {rebel} is losing patience.",
    "arc.niece_secret.teaser": "Ece has a secret. And she's terrible at keeping it.",
}.items():
    s(k, v)
