extends Node
## Grammar placeholders: Turkish endings, German genitive, gender choices, CJK wrapping.
func _ready():
	var bad := 0
	var cases := []
	Loc.load_lang("tr")
	Loc.strings = {}
	for c in [["Selin", "in", true, "Selin'in"], ["Ece", "in", true, "Ece'nin"], ["Burak", "e", true, "Burak'a"], ["Zeynep", "de", true, "Zeynep'te"],
			["Ahmet", "den", true, "Ahmet'ten"], ["Ece", "le", true, "Ece'yle"], ["Mert", "i", true, "Mert'i"], ["Deniz", "e", true, "Deniz'e"],
			["kupa", "si", false, "kupası"], ["bellek", "si", false, "belleği"], ["kitap", "i", false, "kitabı"], ["gözlük", "e", false, "gözlüğe"],
			["ajanda", "i", false, "ajandayı"], ["top", "u", false, "top"], ["çay", "i", false, "çayı"], ["İstanbul", "de", true, "İstanbul'da"]]:
		var got := Loc.inflect(c[0], c[1], c[2])
		if got != c[3]:
			bad += 1
			print("FAIL tr ", c, " -> ", got)
	Loc.genders = {"Selin": "f", "Mert": "m"}
	var t1 := Loc.fill("{a:in} masası, {b?yorgun|yorgun}", {"a": "Selin", "b": "Mert"})
	if t1 != "Selin'in masası, yorgun":
		bad += 1; print("FAIL fill ", t1)
	if Loc.upper("şirin iş ıslak") != "ŞİRİN İŞ ISLAK":
		bad += 1; print("FAIL upper ", Loc.upper("şirin iş ıslak"))
	Loc.lang = "es"
	var t2 := Loc.fill("{a} está {a?cansado|cansada}; {b} está {b?cansado|cansada}; {x?uno|una}", {"a": "Selin", "b": "Mert"})
	if t2 != "Selin está cansada; Mert está cansado; uno":
		bad += 1; print("FAIL gender ", t2)
	Loc.lang = "de"
	if Loc.fill("{a:s} Tisch / {b:s} Tisch", {"a": "Selin", "b": "Deniz"}) != "Selins Tisch / Deniz’ Tisch":
		bad += 1; print("FAIL de ", Loc.fill("{a:s} Tisch / {b:s} Tisch", {"a": "Selin", "b": "Deniz"}))
	Loc.lang = "zh"
	var toks := Loc.wrap_tokens("塞琳：你好，世界！OK吗？")
	var joined := ""
	for tk in toks:
		joined += str(tk[1]) + str(tk[0])
	if joined != "塞琳：你好，世界！OK吗？" or toks.size() < 6:
		bad += 1; print("FAIL zh wrap ", toks)
	for tk in toks:
		if "，。！？：".find(str(tk[0]).left(1)) >= 0:
			bad += 1; print("FAIL zh line start ", tk)
	Loc.lang = "de"
	Loc.strings = {"gender.Ladegerät": "n", "gender.Lesebrille": "f", "gram.my.Ladegerät": "mein Ladegerät"}
	var t3 := Loc.fill("{a?mein|meine|mein} {a} / {b?mein|meine|mein} {b} / {a:my}", {"a": "Ladegerät", "b": "Lesebrille"})
	if t3 != "mein Ladegerät / meine Lesebrille / mein Ladegerät":
		bad += 1; print("FAIL word gender ", t3)
	Loc.load_lang("en")
	print("LOC TEST: ", "PASS" if bad == 0 else "%d FAILED" % bad)
	get_tree().quit()
