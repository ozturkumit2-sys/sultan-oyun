extends Node
## BattleManager — üç turlu yemek yarışmasının durumunu sahneler arasında taşır.
## Tur akışı: begin_round → (sabotaj aşamaları) → oyuncu yemeği → judge_round → (tartışma) → finish_round.
## Oyun mantığı burada; görsel sunum KitchenBattle / JudgingStage / Results sahnelerinde.

const ROUND_TITLES := ["Serbest Pişirme", "Gizemli Malzeme", "Büyük Final"]  # i18n
const ROUND_TIME := 120.0
const SHORT_ROUND_TIME := 80.0

var active := false
var mode := "career"         # career | daily
var match_id := ""
var match_data: Dictionary = {}
var league: Dictionary = {}
var opponent: Dictionary = {}
var ai: OpponentAI = null
var difficulty := 1
var rules: Array = []
var themes: Array = []
var mystery_by_round: Dictionary = {}
var round_no := 1
var max_rounds := 3
var seed_value := 0
var rng := RandomNumberGenerator.new()
var mutations: Dictionary = {}
var pending_mutations: Dictionary = {}
var persistent: Dictionary = {}
var rounds: Array = []
var player_total := 0.0
var opp_total := 0.0
var cur: Dictionary = {}
var track: Dictionary = {}
var served: Array = []
var daily: Dictionary = {}
var results: Dictionary = {}
var auto_shield_used := false
## Tekrar oynanan maçlarda: "revenge" (rakip geçen sefer kaybetti, intikam peşinde, daha güçlü)
## ya da "rematch" (oyuncu geçen sefer kaybetti, rövanş). İlk oynayışta boş.
var rematch := ""
const GENERIC_REVENGE := ["Geçen seferki yenilgimin hesabını sormaya geldim!", "Bu sefer hazırlıklıyım. İntikam zamanı!"]  # i18n
const GENERIC_REMATCH := ["Yine mi sen? Sonuç değişmeyecek!", "Bir kere yendim, yine yenerim!"]  # i18n
var seen_mutations: Array = []


func _reset() -> void:
	active = true
	round_no = 1
	rounds.clear()
	player_total = 0.0
	opp_total = 0.0
	mutations.clear()
	pending_mutations.clear()
	persistent.clear()
	served.clear()
	results = {}
	cur = {}
	auto_shield_used = false
	rematch = ""
	seen_mutations.clear()
	mystery_by_round = {}
	track = {"living_caught": 0, "defended": 0, "accepted": 0, "handcrafted": 0, "mutations": [],
		"discovered": 0, "perfect": 0, "round_wins": 0, "best_round": 0.0, "sabotages": 0}


func start_career(mid: String) -> bool:
	if not IngredientDatabase.matches.has(mid):
		return false
	_reset()
	mode = "career"
	match_id = mid
	match_data = IngredientDatabase.matches[mid]
	league = IngredientDatabase.league(int(match_data["league"]))
	opponent = IngredientDatabase.opponents[match_data["opponent"]]
	difficulty = int(match_data.get("difficulty", 1))
	rules = match_data.get("rules", []).duplicate()
	if match_data.get("boss", false):
		var br: String = opponent.get("boss_rule", "")
		if br != "" and not rules.has(br):
			rules.append(br)
	themes = match_data.get("themes", ["sweet_dream", "classic_comfort", "magic_table"]).duplicate()
	max_rounds = 3
	var rec0 := ProgressionManager.match_record(mid)
	var plays: int = rec0["plays"]
	if plays > 0:
		rematch = "revenge" if rec0["last"] == "won" else "rematch"
	seed_value = FusionEngine.fnv(mid + ":" + str(plays))
	rng.seed = seed_value
	ai = OpponentAI.new(opponent, difficulty, seed_value ^ 0x1234567)
	if rematch == "revenge":
		# İntikam modu: rakip biraz daha usta ve daha akıllı oynar
		ai.skill = minf(0.95, ai.skill + 0.03)
		ai.smart = minf(0.95, ai.smart + 0.06)
	var pool: Array = league.get("mystery", ["frog_essence"]).duplicate()
	var m2: String = pool[rng.randi() % pool.size()]
	mystery_by_round[2] = m2
	if rules.has("mystery_twice"):
		pool.erase(m2)
		if not pool.is_empty():
			mystery_by_round[3] = pool[rng.randi() % pool.size()]
	if rules.has("chaos_judges"):
		var cands: Array = []
		for mid2 in IngredientDatabase.mutation_order:
			if IngredientDatabase.mutations[mid2].get("category", "") != "cosmetic":
				cands.append(mid2)
		var j: Dictionary = IngredientDatabase.judges[rng.randi() % IngredientDatabase.judges.size()]
		var mu: String = cands[rng.randi() % cands.size()]
		persistent[j["id"]] = mu
		mutations[j["id"]] = mu
		_seen(mu)
	return true


func start_daily(ch: Dictionary) -> void:
	_reset()
	mode = "daily"
	match_id = "daily"
	daily = ch
	match_data = {}
	league = {}
	opponent = {}
	ai = null
	difficulty = 1
	rules = ch.get("rules", []).duplicate()
	themes = [ch["theme"]]
	max_rounds = 1
	seed_value = FusionEngine.fnv("daily:" + str(ch.get("date", "")))
	rng.seed = seed_value
	var cond: Dictionary = ch.get("condition", {})
	if cond.has("judge") and cond.has("mutation"):
		persistent[cond["judge"]] = cond["mutation"]
		mutations[cond["judge"]] = cond["mutation"]
		_seen(cond["mutation"])


func _seen(mu: String) -> void:
	if not seen_mutations.has(mu):
		seen_mutations.append(mu)


func is_daily() -> bool:
	return mode == "daily"


func round_title() -> String:
	if is_daily():
		return Loc.t("Günlük Meydan Okuma")
	var t: String = Loc.t(str(ROUND_TITLES[clampi(round_no - 1, 0, 2)]))
	if round_no == 3 and mystery_by_round.has(3):
		t += Loc.t(" + Gizem")
	return t


func round_time() -> float:
	return SHORT_ROUND_TIME if rules.has("short_timer") else ROUND_TIME


func banned_methods() -> Array:
	var res: Array = []
	for r in rules:
		var s := str(r)
		if s.begins_with("banned_method:"):
			res.append(s.substr(14))
	return res


func _ai_state() -> Dictionary:
	return {"theme": cur.get("theme", {}), "mutations": mutations.duplicate(), "round": round_no,
		"mystery": cur.get("mystery", ""), "banned": banned_methods(), "rules": rules,
		"player_total": player_total, "opp_total": opp_total}


func begin_round() -> Dictionary:
	var tid: String = themes[clampi(round_no - 1, 0, themes.size() - 1)]
	cur = {"theme_id": tid, "theme": IngredientDatabase.theme(tid), "mystery": str(mystery_by_round.get(round_no, "")),
		"sabotages": [], "results": {}, "stolen": "", "knocked": [], "extra": [], "opp_penalties": [], "player_mods": {},
		"player": {}, "opp_plan": {}, "judged": {}, "fusions_used": 0, "argued": false, "clear_mutations": false}
	if ai != null:
		var st := _ai_state()
		cur["sabotages"] = ai.decide_sabotage(round_no, st)
		cur["opp_plan"] = ai.plan_dish(st)
		track["sabotages"] = int(track["sabotages"]) + cur["sabotages"].size()
	return cur


# ---------------------------------------------------------------- kiler
func player_pantry() -> Dictionary:
	var ing: Array = []
	var fus: Array = []
	if is_daily():
		ing = daily.get("ingredients", []).duplicate()
		for f in RecipeBookManager.known_fusions():
			if _base_subset(f, ing):
				fus.append(f)
	else:
		ing = ProgressionManager.owned_ingredients()
		var maxd := ProgressionManager.max_chain_depth()
		for f in RecipeBookManager.known_fusions():
			if int(FusionEngine.item(f).get("depth", 1)) <= maxd:
				fus.append(f)
	var mys: String = cur.get("mystery", "")
	if mys != "" and not ing.has(mys):
		ing.push_front(mys)
	for e in cur.get("extra", []):
		if not ing.has(e):
			ing.append(e)
	var gone: Array = cur.get("knocked", []).duplicate()
	var stolen: String = cur.get("stolen", "")
	if stolen != "":
		gone.append(stolen)
	for g in gone:
		ing.erase(g)
		var keep: Array = []
		for f in fus:
			if not FusionEngine.contains_ingredient(f, g):
				keep.append(f)
		fus = keep
	return {"ingredients": ing, "fusions": fus}


func _base_subset(item_id: String, allowed: Array) -> bool:
	if IngredientDatabase.ingredients.has(item_id):
		return allowed.has(item_id)
	var it := FusionEngine.item(item_id)
	for inp in it.get("inputs", []):
		if not _base_subset(str(inp), allowed):
			return false
	return true


# ---------------------------------------------------------------- sabotaj
func sabotages_for_phase(phase: String) -> Array:
	var res: Array = []
	for ab in cur.get("sabotages", []):
		if SabotageSystem.phase_of(ab) == phase and not cur["results"].has(ab):
			res.append(ab)
	return res


func theft_target() -> String:
	var p := player_pantry()
	var best := ""
	var best_r := -1.0
	for id in p["ingredients"]:
		if id == cur.get("mystery", ""):
			continue
		var r: float = FusionEngine.item(id)["stats"]["rarity"]
		if r > best_r or (absf(r - best_r) < 0.01 and id < best):
			best_r = r
			best = id
	return best


func _theft_common() -> String:
	var p := player_pantry()
	var best := ""
	var best_r := 999.0
	for id in p["ingredients"]:
		if id == cur.get("mystery", ""):
			continue
		var r: float = FusionEngine.item(id)["stats"]["rarity"]
		if r < best_r or (absf(r - best_r) < 0.01 and id < best):
			best_r = r
			best = id
	return best


## Kuyruk Darbesi: kilerden n malzeme devrilir (gizemli malzeme ve eklenen malzemeler hariç).
func _knock_targets(n: int) -> Array:
	var p := player_pantry()
	var cands: Array = []
	for id in p["ingredients"]:
		if id != cur.get("mystery", "") and not cur.get("extra", []).has(id):
			cands.append(id)
	cands.sort()
	var res: Array = []
	while res.size() < n and cands.size() > 3:
		var pick: String = cands[rng.randi() % cands.size()]
		cands.erase(pick)
		res.append(pick)
	return res


func rotten_pick() -> String:
	return SabotageSystem.FERMENTED[rng.randi() % SabotageSystem.FERMENTED.size()]


## Oyuncunun sabotaja verdiği cevabı çözer. choice: defend | adapt | accept
func resolve_sabotage(ab: String, choice: String, hits := 0, perfect := false, extra := "") -> Dictionary:
	if cur.is_empty() or not cur.has("results"):
		return {"result": "blocked", "text": "", "extra": extra}
	var defender := ProgressionManager.spec_tier("defender")
	var chaos := ProgressionManager.spec_tier("chaos")
	var result := "full"
	var note := ""
	match choice:
		"defend":
			if hits >= 3:
				result = "reflected" if perfect and defender >= 2 else "blocked"
			elif hits == 2:
				result = "half"
			else:
				result = "full"
		"adapt":
			result = "adapt"
		"accept":
			var chance := 0.2 + (0.2 if chaos >= 3 else 0.0)
			result = "backfire" if rng.randf() < chance else "full"
	if result == "full" and defender >= 3 and not auto_shield_used:
		result = "half"
		auto_shield_used = true
		note = Loc.t("Otomatik Kalkan devreye girdi!")
	if ab == "rotten_surprise" and extra == "":
		extra = rotten_pick()
	cur["results"][ab] = {"result": result, "choice": choice, "extra": extra}
	if result == "blocked" or result == "reflected":
		track["defended"] = int(track["defended"]) + 1
		ProgressionManager.add_stat("defended")
	if choice == "accept":
		track["accepted"] = int(track["accepted"]) + 1
	if result == "backfire" or result == "reflected":
		cur["opp_penalties"].append({"id": ab, "pen": SabotageSystem.opponent_penalty(ab)})
		ProgressionManager.add_stat("backfires")
	if ab == "ingredient_theft":
		match result:
			"full":
				cur["stolen"] = theft_target()
			"half":
				cur["stolen"] = _theft_common()
			"adapt":
				cur["stolen"] = theft_target()
				if not cur["extra"].has("pirate_spice"):
					cur["extra"].append("pirate_spice")
	if ab == "tail_whip":
		match result:
			"full":
				cur["knocked"] = _knock_targets(2)
			"half":
				cur["knocked"] = _knock_targets(1)
			"adapt":
				cur["knocked"] = _knock_targets(1)
				if not cur["extra"].has("dragon_egg"):
					cur["extra"].append("dragon_egg")
	var text := SabotageSystem.result_text(ab, result)
	if note != "":
		text = note + Loc.sp() + text
	return {"result": result, "text": text, "extra": extra}


func cooking_mods() -> Dictionary:
	var res := {}
	for ab in cur.get("results", {}).keys():
		var r: Dictionary = cur["results"][ab]
		var m := SabotageSystem.cooking_mods(ab, r["result"])
		for k in m.keys():
			res[k] = m[k]
	return res


func _add_mods(m: Dictionary) -> void:
	var pm: Dictionary = cur["player_mods"]
	for k in m.keys():
		pm[k] = float(pm.get(k, 0.0)) + float(m[k])


## Belirli aşamadaki sabotaj sonuçlarını yemeğe uygular.
func apply_phase(phase: String, dish: Dictionary) -> Dictionary:
	var d := dish
	for ab in cur.get("results", {}).keys():
		if SabotageSystem.phase_of(ab) != phase:
			continue
		var r: Dictionary = cur["results"][ab]
		if r.get("applied", false):
			continue
		r["applied"] = true
		var res := SabotageSystem.apply_to_dish(ab, r["result"], d, r.get("extra", ""), ProgressionManager.spec_tier("chaos"))
		d = res["dish"]
		_add_mods(res["mods"])
		if res["clear_mutations"]:
			cur["clear_mutations"] = true
	return d


func use_fusion() -> bool:
	if int(cur.get("fusions_used", 0)) >= ProgressionManager.max_fusions_per_round():
		return false
	cur["fusions_used"] = int(cur.get("fusions_used", 0)) + 1
	return true


func fusions_left() -> int:
	return ProgressionManager.max_fusions_per_round() - int(cur.get("fusions_used", 0))


func set_player_dish(dish: Dictionary, quality: float, first: bool) -> void:
	cur["player"] = {"dish": dish, "quality": clampf(quality, 0.0, 1.0), "first": first, "living": "none",
		"plate": "classic", "garnish": "none"}
	if first:
		track["discovered"] = int(track["discovered"]) + 1
	if quality >= 0.95:
		track["perfect"] = int(track["perfect"]) + 1


func set_player_dish_only(dish: Dictionary) -> void:
	if cur.get("player", {}).is_empty():
		return
	cur["player"]["dish"] = dish


func set_living(result: String) -> void:
	if cur.get("player", {}).is_empty():
		return
	cur["player"]["living"] = result
	if result == "caught":
		track["living_caught"] = int(track["living_caught"]) + 1
		ProgressionManager.add_stat("living_caught")


func set_plating(plate: String, garnish: String) -> void:
	if cur.get("player", {}).is_empty():
		return
	cur["player"]["plate"] = plate
	cur["player"]["garnish"] = garnish


func mystery_ok(dish: Dictionary) -> bool:
	var mys: String = cur.get("mystery", "")
	if mys == "":
		return true
	return FusionEngine.contains_ingredient(dish["id"], mys)


# ---------------------------------------------------------------- jüri
func _scores(jr: Dictionary) -> Dictionary:
	var s := {}
	for k in jr["judges"].keys():
		s[k] = jr["judges"][k]["score"]
	return s


func _merged_mut() -> Dictionary:
	var m := mutations.duplicate()
	for k in pending_mutations.keys():
		m[k] = pending_mutations[k]
	return m


func judge_round() -> Dictionary:
	var theme: Dictionary = cur.get("theme", {})
	var out := {"order": []}
	if cur.get("clear_mutations", false):
		for k in mutations.keys():
			if not persistent.has(k):
				mutations.erase(k)
		pending_mutations.clear()
		out["mutations_cleared"] = true
	# --- rakip
	if ai != null:
		var plan: Dictionary = cur["opp_plan"]
		var dish: Dictionary = plan["dish"].duplicate(true)
		var q := ai.cook_quality(rules)
		var pres_mod := 0.0
		var pen_notes: Array = []
		for p in cur.get("opp_penalties", []):
			var pen: Dictionary = p["pen"]
			q += float(pen.get("quality", 0.0))
			pres_mod += float(pen.get("presentation", 0.0))
			if pen.has("stats"):
				dish = FusionEngine.modify(dish, pen["stats"], ["cursed"])
			if pen.get("taint", false):
				dish = FusionEngine.taint(dish, rotten_pick(), 0.25)
			pen_notes.append(p["id"])
		q = clampf(q, 0.15, 0.98)
		var living := ai.living_result(dish)
		var plating := ai.best_plating(dish, theme, true)
		var octx := {"theme": theme, "quality": q, "plate": plating["plate"], "garnish": plating["garnish"],
			"living": living, "rules": rules, "mods": {"presentation": pres_mod}, "round": round_no}
		var oev := JudgeSystem.evaluate(dish, octx)
		var ojr := JudgeSystem.judge_all(dish, oev, mutations, {"rules": rules, "round": round_no,
			"charmed": rules.has("judges_charmed"), "living": living})
		JudgeSystem.assign_quips(ojr["judges"], dish, {"mutations": mutations, "living": living,
			"mystery": str(cur.get("mystery", "")) if mystery_ok(dish) else ""})
		var omut := MutationSystem.check(dish, _scores(ojr), _merged_mut(), {"rules": rules, "round": round_no})
		if not omut.is_empty():
			pending_mutations[omut["judge"]] = omut["mutation"]
			_seen(omut["mutation"])
		out["opp"] = {"dish": dish, "quality": q, "living": living, "plate": plating["plate"], "garnish": plating["garnish"],
			"ev": oev, "judges": ojr["judges"], "total": ojr["total"], "mutation": omut, "penalized": pen_notes,
			"argument": JudgeSystem.disagreement(ojr["judges"]) >= 4.0}
		out["order"].append("opp")
	# --- oyuncu
	var pl: Dictionary = cur["player"]
	var pdish: Dictionary = pl["dish"]
	var repeat := served.has(pdish["id"])
	var specs := ProgressionManager.specs()
	var pctx := {"theme": theme, "quality": pl["quality"], "plate": pl["plate"], "garnish": pl["garnish"],
		"living": pl["living"], "first": pl["first"], "repeat": repeat, "specs": specs, "rules": rules,
		"mods": cur.get("player_mods", {}), "round": round_no}
	if not mystery_ok(pdish):
		pctx["mods"] = pctx["mods"].duplicate()
		pctx["mods"]["theme"] = -2.0
	var pev := JudgeSystem.evaluate(pdish, pctx)
	if not mystery_ok(pdish):
		pev["axes"]["theme"] = maxf(0.0, pev["axes"]["theme"] - 3.0)
		pev["notes"].append("no_mystery")
	var pjr := JudgeSystem.judge_all(pdish, pev, mutations, {"rules": rules, "round": round_no, "is_player": true,
		"specs": specs, "first": pl["first"], "repeat": repeat, "living": pl["living"]})
	JudgeSystem.assign_quips(pjr["judges"], pdish, {"mutations": mutations, "living": pl["living"],
		"first": pl["first"], "repeat": repeat, "mystery": str(cur.get("mystery", "")) if mystery_ok(pdish) else ""})
	var pmut := MutationSystem.check(pdish, _scores(pjr), _merged_mut(), {"rules": rules, "round": round_no,
		"is_player": true, "specs": specs})
	if not pmut.is_empty():
		pending_mutations[pmut["judge"]] = pmut["mutation"]
		_seen(pmut["mutation"])
		if not track["mutations"].has(pmut["mutation"]):
			track["mutations"].append(pmut["mutation"])
	out["player"] = {"dish": pdish, "quality": pl["quality"], "living": pl["living"], "plate": pl["plate"],
		"garnish": pl["garnish"], "ev": pev, "judges": pjr["judges"], "total": pjr["total"], "mutation": pmut,
		"first": pl["first"], "repeat": repeat, "mystery_missing": not mystery_ok(pdish),
		"argument": JudgeSystem.disagreement(pjr["judges"]) >= 4.0}
	out["order"].append("player")
	out["mutations_before"] = mutations.duplicate()
	cur["judged"] = out
	return out


## Tartışma: oyuncunun cevabı puanları kontrollü ve adil bir aralıkta (en fazla toplam ±1) etkiler.
func apply_argument(choice: String) -> Dictionary:
	var res: Dictionary = cur["judged"]["player"]
	if cur.get("argued", false):
		return {"text": "", "delta": {}}
	cur["argued"] = true
	var judges: Dictionary = res["judges"]
	var low := ""
	var high := ""
	for k in judges.keys():
		if low == "" or judges[k]["score"] < judges[low]["score"]:
			low = k
		if high == "" or judges[k]["score"] > judges[high]["score"]:
			high = k
	var delta := {}
	var text := ""
	var low_name: String = IngredientDatabase.judge_map[low]["name"]
	var high_name: String = IngredientDatabase.judge_map[high]["name"]
	match choice:
		"defend":
			var w: Dictionary = IngredientDatabase.judge_map[low]["weights"]
			var best_axis := "flavor"
			var best_w := -1.0
			for a in w.keys():
				if float(w[a]) > best_w:
					best_w = float(w[a])
					best_axis = a
			var v: float = res["ev"]["axes"][best_axis]
			if v >= 5.5:
				delta[low] = 1.0
				text = Loc.t("%s ikna oldu: \"Hmm... %s açısından haklı olabilirsin.\"") % [low_name, Loc.t(str(JudgeSystem.AXIS_NAMES[best_axis]))]
			else:
				delta[low] = -0.5
				text = Loc.t("%s daha da sinirlendi: \"%s berbattı, savunma yapma!\"") % [low_name, Loc.t(str(JudgeSystem.AXIS_NAMES[best_axis]))]
		"retaste":
			var others := 0.0
			var n := 0
			for k in judges.keys():
				if k != low:
					others += judges[k]["score"]
					n += 1
			others /= maxf(1.0, n)
			var gain := roundf((others - float(judges[low]["score"])) * 0.35 * 2.0) / 2.0
			delta[low] = clampf(gain, 0.0, 1.0)
			if high != low:
				var rest := 0.0
				var m := 0
				for k in judges.keys():
					if k != high:
						rest += judges[k]["score"]
						m += 1
				rest /= maxf(1.0, m)
				delta[high] = -clampf(roundf((float(judges[high]["score"]) - rest) * 0.15 * 2.0) / 2.0, 0.0, 0.5)
			text = Loc.t("%s bir lokma daha aldı... \"Belki ilk seferde çok sertti.\" %s ise düşünceli.") % [low_name, high_name]
		"explain":
			var dish: Dictionary = res["dish"]
			if dish.get("handcrafted", false) or int(dish.get("depth", 1)) >= 2:
				delta["mira"] = 0.5
				if low != "mira":
					delta[low] = float(delta.get(low, 0.0)) + 0.5
				text = Loc.t("Tarifinin hikâyesini anlattın. Profesör Mira not alıyor, %s yumuşadı.") % low_name
			elif res["ev"]["axes"]["creativity"] >= 6.0:
				delta["mira"] = 0.5
				text = Loc.t("Açıklaman Profesör Mira'yı etkiledi.")
			else:
				text = Loc.t("Açıklaman pek kimseyi etkilemedi. \"Yani... un ve yumurta?\"")
		_:
			text = Loc.t("Tartışmayı kibarca bitirdin. Lord Max monoklünü düzeltti: \"Ne olgun bir davranış.\"")
	var pos := 0.0
	for k in delta.keys():
		if delta[k] > 0:
			pos += delta[k]
	if pos > 1.0:
		for k in delta.keys():
			if delta[k] > 0:
				delta[k] = roundf(delta[k] / pos * 2.0) / 2.0
	var total := 0.0
	for k in judges.keys():
		var nv := clampf(float(judges[k]["score"]) + float(delta.get(k, 0.0)), 0.0, 10.0)
		judges[k]["score"] = nv
		total += nv
	res["total"] = total
	return {"text": text, "delta": delta}


func finish_round() -> String:
	var j: Dictionary = cur["judged"]
	var ptot: float = j["player"]["total"]
	var otot: float = j.get("opp", {}).get("total", 0.0)
	player_total += ptot
	opp_total += otot
	var winner := "tie"
	if ai == null:
		winner = "player"
	elif ptot > otot:
		winner = "player"
	elif otot > ptot:
		winner = "opp"
	if winner == "player":
		track["round_wins"] = int(track["round_wins"]) + 1
	track["best_round"] = maxf(float(track["best_round"]), ptot)
	var pd: Dictionary = j["player"]["dish"]
	if pd.get("handcrafted", false):
		track["handcrafted"] = int(track["handcrafted"]) + 1
	RecipeBookManager.record_score(pd["id"], ptot)
	ProgressionManager.add_stat("dishes")
	if ptot > float(SaveManager.data["stats"].get("best_round", 0.0)):
		SaveManager.data["stats"]["best_round"] = ptot
	if ptot >= 27.0:
		ProgressionManager.unlock_achievement("round_27")
	rounds.append({"round": round_no, "theme": cur["theme_id"], "player": ptot, "opp": otot, "winner": winner,
		"player_dish": pd["name"], "opp_dish": j.get("opp", {}).get("dish", {}).get("name", ""),
		"player_flavor": j["player"]["ev"]["axes"]["flavor"],
		"opp_flavor": j.get("opp", {}).get("ev", {}).get("axes", {}).get("flavor", 0.0)})
	served.append(pd["id"])
	for k in pending_mutations.keys():
		mutations[k] = pending_mutations[k]
	pending_mutations.clear()
	for mu in seen_mutations:
		ProgressionManager.see_mutation(mu)
	round_no += 1
	return winner


func is_over() -> bool:
	return round_no > max_rounds


func _challenge_met() -> bool:
	var ch: Dictionary = match_data.get("challenge", {})
	var v := int(ch.get("value", 1))
	match ch.get("type", ""):
		"handcrafted":
			return int(track["handcrafted"]) >= v
		"defend_sabotage":
			return int(track["defended"]) >= v
		"catch_living":
			return int(track["living_caught"]) >= v
		"round_score":
			return float(track["best_round"]) >= float(v)
		"mutation":
			return track["mutations"].size() >= v
		"discover":
			return int(track["discovered"]) >= v
		"win_all_rounds":
			return int(track["round_wins"]) >= 3
		"perfect_cook":
			return int(track["perfect"]) >= v
		"no_accept":
			return int(track["accepted"]) == 0 and player_total > opp_total
	return false


func finalize() -> Dictionary:
	active = false
	if is_daily():
		return _finalize_daily()
	var won := player_total > opp_total
	var tiebreak := ""
	if absf(player_total - opp_total) < 0.001:
		var p3: float = rounds[rounds.size() - 1]["player"]
		var o3: float = rounds[rounds.size() - 1]["opp"]
		if absf(p3 - o3) > 0.001:
			won = p3 > o3
			tiebreak = Loc.t("Eşitlik! Büyük Final puanı belirleyici oldu.")
		else:
			var pf := 0.0
			var of := 0.0
			for r in rounds:
				pf += float(r["player_flavor"])
				of += float(r["opp_flavor"])
			if absf(pf - of) > 0.001:
				won = pf > of
				tiebreak = Loc.t("Tam eşitlik! Toplam lezzet puanı belirleyici oldu.")
			else:
				won = seed_value % 2 == 0
				tiebreak = Loc.t("İnanılmaz eşitlik! Şef Bruno bıyığını çevirdi ve kararı verdi.")
	var lid := int(match_data["league"])
	var stars := [won, player_total >= float(league.get("score_star", 60)), won and _challenge_met()]
	var rec := ProgressionManager.record_match(match_id, won, player_total, stars)
	var coins := (80 + 30 * lid) if won else (25 + 10 * lid)
	coins += 15 * int(rec["new_stars"])
	var xp := (100 + 20 * lid) if won else (50 + 10 * lid)
	var unlocked: Array = []
	if won:
		ProgressionManager.unlock_achievement("first_win")
		for iid in IngredientDatabase.ingredient_order:
			var u: Dictionary = IngredientDatabase.ingredients[iid].get("unlock", {})
			if u.get("type", "") == "win" and u.get("match", "") == match_id:
				if ProgressionManager.unlock_ingredient(iid):
					unlocked.append({"kind": "ingredient", "id": iid})
	var rm_bonus := 0
	if won and rematch != "":
		rm_bonus = rematch_bonus()
		coins += rm_bonus
		ProgressionManager.unlock_achievement("revenge_win" if rematch == "revenge" else "rematch_win")
	var league_bonus := 0
	if int(rec["league_completed"]) > 0:
		league_bonus = int(league.get("reward", 300))
		coins += league_bonus
		if lid == 1:
			ProgressionManager.unlock_achievement("league_1")
			unlocked.append({"kind": "feature", "id": "third_slot"})
		if lid == 5:
			ProgressionManager.unlock_achievement("league_5")
		if lid == 6:
			ProgressionManager.unlock_achievement("league_6")
		if lid < IngredientDatabase.leagues.size():
			unlocked.append({"kind": "league", "id": str(lid + 1)})
	ProgressionManager.add_coins(coins, "match")
	var levels := ProgressionManager.add_xp(xp)
	var line := ""
	if ai != null:
		line = ai.line("lose") if won else ai.line("win")
	results = {"mode": "career", "won": won, "player_total": player_total, "opp_total": opp_total, "rounds": rounds.duplicate(true),
		"tiebreak": tiebreak, "stars": stars, "new_stars": rec["new_stars"], "coins": coins, "xp": xp, "levels": levels,
		"unlocked": unlocked, "league_completed": rec["league_completed"], "league_bonus": league_bonus,
		"opponent": opponent.get("id", ""), "line": line, "match_id": match_id,
		"rematch": rematch, "rematch_bonus": rm_bonus,
		"challenge": match_data.get("challenge", {}).get("text", ""), "challenge_met": _challenge_met()}
	SaveManager.mark_dirty(true)
	return results


func _finalize_daily() -> Dictionary:
	var info := DailyChallengeManager.record(player_total)
	ProgressionManager.add_xp(40)
	results = {"mode": "daily", "won": player_total >= float(daily.get("target", 18)), "player_total": player_total,
		"opp_total": 0.0, "rounds": rounds.duplicate(true), "best": info["best"], "new_best": info["new_best"],
		"target": daily.get("target", 18), "claimable": DailyChallengeManager.can_claim(), "xp": 40, "coins": 0,
		"stars": [], "unlocked": [], "levels": 0, "line": "", "tiebreak": ""}
	SaveManager.mark_dirty(true)
	return results


## Tekrar maçında rakibin söyleyeceği giriş repliği (rakibe özel yoksa genel).
func rematch_line() -> String:
	if rematch == "":
		return ""
	var arr: Array = opponent.get(rematch, [])
	if arr.is_empty():
		var gen: Array = GENERIC_REVENGE if rematch == "revenge" else GENERIC_REMATCH
		return Loc.t(str(gen[absi(seed_value) % gen.size()]))
	return str(arr[absi(seed_value) % arr.size()])


## Tekrar maçını kazanma bonusu.
func rematch_bonus() -> int:
	if rematch == "" or league.is_empty():
		return 0
	return 20 + 10 * int(league.get("id", 1))


func opponent_name() -> String:
	return opponent.get("name", Loc.t("Günün Jürisi"))
