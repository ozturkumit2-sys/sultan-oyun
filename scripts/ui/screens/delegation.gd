extends Screen
## Managerial delegation settings.

func page_title() -> String:
	return "Delegation"


func build() -> void:
	var c := G.pc()
	body.add_child(UI.para("Managers act each week using their real skill and your company data. Major decisions — new brands, acquisitions, large investments, IPO and strategic launches — always stay with you.", 19))
	for fn in Delegation.FUNCS:
		var d: Dictionary = Delegation.FUNCS[fn]
		var av := Delegation.available(c, fn)
		var cc := UI.card(body, "dark" if av == "" else "flat")
		cc.add_child(UI.lbl(d["name"], 22, UI.CREAM if av == "" else UI.DIM, "semi"))
		cc.add_child(UI.para(d["desc"], 18))
		if av != "":
			cc.add_child(UI.lbl(av, 18, UI.AMBER))
			continue
		var sk := Staff.best_skill(G.pid(), d["role"])
		cc.add_child(UI.lbl("Manager skill: %d" % int(sk * 100), 18, UI.GOLD2))
		var f2: String = fn
		cc.add_child(UI.seg([["Manual", "manual"], ["Approval required", "approval"], ["Delegated", "delegated"]], Delegation.mode(c, fn), func(v):
			c["delegation"][f2] = v
			rebuild(), 19))
