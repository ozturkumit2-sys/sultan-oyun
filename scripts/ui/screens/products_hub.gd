extends Screen
## Portfolio overview.

var filter := "active"
var brand_f := ""


func page_title() -> String:
	return "Products"


func build() -> void:
	var c := G.pc()
	var all := G.company_products(G.pid(), ["active", "dev", "discontinued"])
	var u4 := 0
	var inv := 0
	for p in all:
		inv += int(p["inv"])
		for x in p["wk"].slice(maxi(0, p["wk"].size() - 4)):
			u4 += int(x[1])
	var g := UI.hbox(10)
	g.add_child(UI.stat("Active", str(G.company_products(G.pid()).size())))
	g.add_child(UI.stat("Units (4 wks)", G.group_int(u4)))
	g.add_child(UI.stat("In stock", G.group_int(inv)))
	body.add_child(g)
	var qa := UI.grid(2, 10)
	qa.add_child(UI.btn("+ Launch product", func(): Router.go("launch", {}), "primary", 21, 72))
	qa.add_child(UI.btn("Production", func(): Router.go("production"), "secondary", 21, 72))
	qa.add_child(UI.btn("Reviews", func(): Router.go("reviews"), "secondary", 21, 72))
	qa.add_child(UI.btn("Awards", func(): Router.go("awards"), "secondary", 21, 72))
	body.add_child(qa)
	body.add_child(UI.seg([["Active", "active"], ["In development", "dev"], ["Discontinued", "discontinued"], ["All", "all"]], filter, func(v):
		filter = v
		rebuild()))
	var bs := G.company_brands(G.pid())
	if bs.size() > 1:
		var bo: Array = [["All brands", ""]]
		for b in bs:
			bo.append([b["name"], b["id"]])
		body.add_child(UI.seg(bo, brand_f, func(v):
			brand_f = v
			rebuild()))
	var list: Array = []
	for p in all:
		if (filter == "all" or p["status"] == filter) and (brand_f == "" or p["brand"] == brand_f):
			list.append(p)
	list.sort_custom(func(a, b): return float(a["st"]["rev"]) > float(b["st"]["rev"]))
	if list.is_empty():
		UI.empty(body, "No products in this view.")
	for p in list:
		ProductRow.add(body, p)
