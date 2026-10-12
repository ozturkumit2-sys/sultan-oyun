extends Screen
## CEO inbox: decisions and notices.

func page_title() -> String:
	return "Inbox"


func build() -> void:
	var open := G.inbox_open()
	var props = G.s["proposals"].filter(func(p): return p["company"] == G.pid() and p["status"] == "open").size()
	if props > 0:
		UI.row_card(body, "%d perfumer proposal%s waiting" % [props, "s" if props > 1 else ""], "Approve, revise, research or reject", "", func(): Router.go("proposals"), UI.icon("lab", 44))
	if open.is_empty() and props == 0:
		UI.empty(body, "Inbox zero. Nothing needs your decision.")
	for i in range(open.size() - 1, -1, -1):
		var m: Dictionary = open[i]
		var mid: String = m["id"]
		var t := str(m.get("text", ""))
		UI.row_card(body, str(m["title"]), (t.substr(0, 120) + ("…" if t.length() > 120 else "")) + "\n" + G.date_str(int(m["w"])), "", func(): Inbox.open_item(mid))
	var done = G.s["inbox"].filter(func(m): return m.get("done", false))
	if not done.is_empty():
		UI.section(body, "Handled")
		for i in range(done.size() - 1, maxi(-1, done.size() - 10), -1):
			body.add_child(UI.para("%s — %s" % [G.short_date(int(done[i]["w"])), done[i]["title"]], 18, UI.DIM))
