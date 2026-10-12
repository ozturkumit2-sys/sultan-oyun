extends Screen
## Settings.

func page_title() -> String:
	return "Settings"


func build() -> void:
	if not Router.in_game:
		var h := UI.hbox(14)
		h.add_child(UI.btn("‹", func(): Router.back(), "ghost", 40, 70))
		h.add_child(UI.title("Settings", 40))
		body.add_child(h)
	var s := G.settings
	UI.section(body, "Audio")
	var ml := UI.lbl("Music %d%%" % int(float(s["music"]) * 100), 20, UI.TEXT)
	body.add_child(ml)
	body.add_child(UI.slider(0, 1, 0.05, float(s["music"]), func(x):
		s["music"] = x
		ml.text = "Music %d%%" % int(x * 100)
		Snd.music(Router.in_game)
		Save.save_settings()))
	var sl := UI.lbl("Sound effects %d%%" % int(float(s["sfx"]) * 100), 20, UI.TEXT)
	body.add_child(sl)
	body.add_child(UI.slider(0, 1, 0.05, float(s["sfx"]), func(x):
		s["sfx"] = x
		sl.text = "Sound effects %d%%" % int(x * 100)
		Save.save_settings()))
	UI.section(body, "Game")
	body.add_child(UI.chip("Autosave every week: " + ("ON" if s.get("autosave", true) else "OFF"), s.get("autosave", true), func():
		s["autosave"] = not s.get("autosave", true)
		Save.save_settings()
		rebuild()))
	if G.has_game() and Router.in_game:
		body.add_child(UI.btn("Save & return to main menu", func():
			Save.save_game("auto")
			Router.menu(), "secondary", 22))
	UI.section(body, "About")
	body.add_child(UI.para("Perfume Empire is a business simulation. All companies, brands, people, critics, celebrities and regulations (\"FSC\") are fictional. The fragrance model is inspired by perfumery but is not real formulation, safety or regulatory advice.", 18))
	body.add_child(UI.para("Fonts: Playfair Display and Montserrat (SIL Open Font License). Map data: Natural Earth (public domain).", 16, UI.DIM))
