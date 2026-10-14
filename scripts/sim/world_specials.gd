class_name WorldSpecials
extends RefCounted
## Code-side helpers that events call by name: variable pickers (who gets blamed,
## which gossip to share), email consequences, and a few multi-step effects.

const TOPICS := ["weekend", "weather", "football", "traffic", "series", "food", "vacation", "cats", "gym", "music", "phones", "lottery"]


static func pick(w, fn: String, spec: Dictionary, ctx: Dictionary):
	var ev: EventConditionEvaluator = w.events.ev
	match fn:
		"suspect":
			var victim := ev.who(spec.get("of", "actor"), ctx)
			var loc := str(ev.val(spec.get("loc", ""), ctx))
			if spec.get("desk", false):
				loc = "desk_" + victim
			return suspect_for(w, victim, ev.who(spec.get("not", ""), ctx), loc)
		"gossip_fact":
			var have = ctx.get("vars", {}).get("fact", "")
			if have != "" and w.fact_exists(str(have)):
				var tgt := ev.who("target", ctx)
				var tn = w.npc(tgt)
				if tn and not tn.knows(str(have)) and w.fact_subject(str(have)) != tgt:
					return have
			return gossip_for(w, ev.who("actor", ctx), ev.who("target", ctx))
		"topic":
			return TOPICS[w.rng.randi() % TOPICS.size()]
		"item_owner":
			var item := str(ctx.get("vars", {}).get("item", ""))
			if w.office.items.has(item):
				return w.office.items[item]["owner"]
			return ""
		"board_time":
			return float(w.office.objects["board"]["time"])
		"own_item":
			return w.office.item_owned_by(ev.who("actor", ctx))
		"crush_target":
			return "ceren"
		"gossip_target":
			var g := best_gossip(w, ev.who("actor", ctx))
			return g.get("to", "")
		"doubtful_rumor":
			return doubtful_rumor(w, ev.who(spec.get("of", "actor"), ctx))
		"doubtful_subject":
			# picks a shaky rumour this person heard and returns who it's about
			var df := doubtful_rumor(w, ev.who(spec.get("of", "actor"), ctx))
			if df == "":
				return ""
			ctx["vars"]["fact"] = df
			return w.fact_subject(df)
		"rumor_subject":
			return w.fact_subject(str(ev.val(spec.get("fact", "$fact"), ctx)))
		"rumor_spreader":
			return rumor_spreader(w, str(ev.val(spec.get("fact", "$fact"), ctx)), ev.who(spec.get("not", "actor"), ctx))
		"crush_of":
			return crush_of(w, ev.who(spec.get("of", "actor"), ctx), spec.get("taken", false))
		"birthday_person":
			return str(w.day_flags.get("birthday", ""))
		"worst_of":
			return extreme_of(w, ev.who(spec.get("of", "actor"), ctx), false, float(spec.get("lim", 0.0)), spec.get("avail", spec.get("available", true)), _excl(ev, spec, ctx))
		"best_of":
			return extreme_of(w, ev.who(spec.get("of", "actor"), ctx), true, float(spec.get("lim", 0.0)), spec.get("avail", spec.get("available", true)), _excl(ev, spec, ctx))
		"plan_target":
			var pn: NPC = w.npc(ev.who(spec.get("of", "actor"), ctx))
			return pn.plan_target(spec["kind"]) if pn else ""
		"mediator":
			return mediator(w, ev.who(spec.get("a", "actor"), ctx), ev.who(spec.get("b", "target"), ctx))
		"low_morale":
			return low_morale(w, float(spec.get("lim", 40.0)), ev.who(spec.get("not", ""), ctx))
		"rival_of":
			return rival_of(w, ev.who(spec.get("of", "actor"), ctx), float(spec.get("lim", 30.0)))
		"secret_about":
			return secret_about(w, ev.who(spec.get("knower", "actor"), ctx), ev.who(spec.get("about", "target"), ctx))
		"any_secret":
			return any_secret(w, ev.who(spec.get("knower", "actor"), ctx), ev.who(spec.get("not", "target"), ctx))
		"common_enemy":
			return common_enemy(w, ev.who(spec.get("a", "actor"), ctx), ev.who(spec.get("b", "target"), ctx))
		"own_item_of":
			return w.office.item_owned_by(ev.who(spec.get("of", "target"), ctx))
		"clumsy_one":
			return clumsy_one(w, ev.who(spec.get("not", "actor"), ctx))
		"now_time":
			return w.minute
		"loves_music", "hates_music":
			var mid := ev.who(spec.get("of", "self"), ctx)
			var mn: NPC = w.npc(mid)
			var genre: String = str(w.office.objects["music"].get("genre", ""))
			if genre == "" and w.office.objects["lights"].get("party", false):
				genre = "disco"
			if mn == null or genre == "":
				return ""
			var taste := float(mn.prefs.get("music", {}).get(genre, 0.0))
			if fn == "loves_music":
				return mid if taste > 0.4 else ""
			return mid if taste < -0.3 else ""
		"false_rumor":
			# a live false rumour with a known origin, about someone who's here
			for f in w.dyn_facts:
				var r: Dictionary = w.dyn_facts[f]
				if bool(r.get("truth", true)) or r.get("debunked", false):
					continue
				var org: String = str(r.get("origin", ""))
				var sub: String = str(r.get("a", ""))
				if org == "" or sub == "" or org == sub or not w.npc(org).present or not w.npc(sub).present:
					continue
				ctx["vars"]["fact"] = f
				ctx["vars"]["origin"] = org
				ctx["vars"]["subject"] = sub
				return f
			return ""
		"alliance_pair":
			for k in w.bonds:
				var p: PackedStringArray = str(k).split("|")
				if p[2] == "alliance" and w.npc(p[0]).present and w.npc(p[1]).present:
					ctx["vars"]["b"] = p[1]
					return p[0]
			return ""
		"rival_pair":
			var best_r := float(spec.get("lim", 25.0))
			var ra := ""
			var rb := ""
			var ids: Array = w.present_ids()
			for i in ids.size():
				for j in range(i + 1, ids.size()):
					var rv: float = maxf(w.npc(ids[i]).get_rel(ids[j], "rivalry"), w.npc(ids[j]).get_rel(ids[i], "rivalry")) \
						+ maxf(w.npc(ids[i]).get_rel(ids[j], "resentment"), 0.0) * 0.5
					if rv > best_r:
						best_r = rv
						ra = ids[i]
						rb = ids[j]
			if ra == "":
				return ""
			ctx["vars"]["b"] = rb
			return ra
		"has_secret":
			# a real secret this person is the subject of
			var hid := ev.who(spec.get("of", "target"), ctx)
			for f2 in w.fact_defs:
				if w.fact_exists(f2) and w.fact_subject(f2) == hid:
					return f2
			return ""
		"upcoming_birthday":
			for id in w.present_ids():
				var bd := int(w.flags.get("bday_" + id, -100))
				if bd > w.day and bd <= w.day + 3:
					return id
			return ""
		"job_seeker":
			# someone secretly applying elsewhere (Burak's known hunt, or anyone with that plan)
			for id in w.present_ids():
				var jn: NPC = w.npc(id)
				if id != "ahmet" and (jn.has_plan("job_search") or (id == "burak" and w.fact_exists("burak_job_hunt") and not w.npc("ahmet").knows("burak_job_hunt"))):
					return id
			return ""
		"promo_day":
			return "yes" if MeetingFlow.promotion_today(w) else ""
		"favored":
			var fid := ev.who(spec.get("of", "self"), ctx)
			return fid if float(w.favor.get(fid, 0.0)) >= 48.0 else ""
		"disfavored":
			var did := ev.who(spec.get("of", "self"), ctx)
			return did if float(w.favor.get(did, 0.0)) < 40.0 else ""
		"seat_pair":
			# the most explosive (or the sweetest) pair sitting in today's meeting
			var room: Array = []
			for id in w.present_ids():
				if id != "ahmet" and w.npc(id).act == "meeting":
					room.append(id)
			var best_s := 25.0
			var pa := ""
			var pb := ""
			var kind := ""
			for i in room.size():
				for j in range(i + 1, room.size()):
					var na: NPC = w.npc(room[i])
					var rv: float = maxf(na.get_rel(room[j], "rivalry"), w.npc(room[j]).get_rel(room[i], "rivalry"))
					var rm: float = minf(na.get_rel(room[j], "romance"), w.npc(room[j]).get_rel(room[i], "romance"))
					if rv > best_s:
						best_s = rv
						pa = room[i]
						pb = room[j]
						kind = "rivals"
					if rm * 1.4 > best_s:
						best_s = rm * 1.4
						pa = room[i]
						pb = room[j]
						kind = "crush"
			if pa == "":
				return ""
			ctx["vars"]["b"] = pb
			ctx["vars"]["pairkind"] = kind
			return pa
		"hater_of":
			# the person who likes X the least (present or not)
			var hx := ev.who(spec.get("of", "target"), ctx)
			var hb := ""
			var hv := float(spec.get("lim", 10.0))
			for id in w.order:
				if id == hx or id == ev.who(spec.get("not", ""), ctx):
					continue
				var hn: NPC = w.npc(id)
				var a: float = hn.affinity(hx) + w.rng.randf() * 3.0
				if a < hv and (hn.present or not spec.get("avail", true)):
					hv = a
					hb = id
			return hb
		"foe_of":
			# someone X has a fresh grudge against (recent conflict, resentment or a feud)
			var fx := ev.who(spec.get("of", "owner"), ctx)
			var fnpc: NPC = w.npc(fx)
			if fnpc == null:
				return ""
			var fb := ""
			var fv := 8.0
			for id in w.order:
				if id == fx:
					continue
				var s2: float = fnpc.get_rel(id, "resentment") - fnpc.mem_bias(id) * 15.0
				if w.has_bond(fx, id, "feud"):
					s2 += 30.0
				if s2 > fv:
					fv = s2
					fb = id
			return fb
		"boss_fav":
			# whoever Ahmet currently favours most (excluding someone)
			var nb := ev.who(spec.get("not", "target"), ctx)
			var bb := ""
			var bv := -1.0
			for id in w.order:
				if id == "ahmet" or id == nb:
					continue
				if float(w.favor.get(id, 0.0)) > bv:
					bv = float(w.favor.get(id, 0.0))
					bb = id
			return bb
		"slides_owner":
			return str(w.meeting.get("swap", {}).get(ev.who(spec.get("of", "actor"), ctx), ""))
		"triangle":
			# X has a crush on C, and someone else (stored as $rival) has one too
			var tx := ev.who(spec.get("of", "actor"), ctx)
			var tn: NPC = w.npc(tx)
			var tc := crush_of(w, tx)
			if tn == null or tc == "" or tn.get_rel(tc, "romance") < float(spec.get("lim", 30.0)):
				return ""
			var trv := ""
			var tbest := float(spec.get("rlim", 20.0))
			for id in w.present_ids():
				if id == tx or id == tc:
					continue
				var rr: float = w.npc(id).get_rel(tc, "romance")
				if rr > tbest:
					tbest = rr
					trv = id
			if trv == "":
				return ""
			ctx["vars"]["rival"] = trv
			return tc
		"unhappy_crowd":
			var uc := 0
			for id in w.present_ids():
				if id != "ahmet" and w.npc(id).morale < float(spec.get("lim", 52.0)):
					uc += 1
			return "yes" if uc >= int(spec.get("n", 3)) else ""
		"signed_count":
			var sc := 0
			for id in w.present_ids():
				if EventConditionEvaluator.truthy(w.npc(id).today_flags.get(str(spec.get("key", "signed")), false)):
					sc += 1
			return "yes" if sc >= int(spec.get("n", 2)) else ""
		"most_curious":
			var mc_not := ev.who(spec.get("not", "actor"), ctx)
			var mc := ""
			var mcv := -1.0
			for id in w.present_ids():
				if id == mc_not or id == "ahmet" or not w.available(id):
					continue
				var cv: float = float(w.npc(id).traits.get("curiosity", 0.5)) + float(w.npc(id).traits.get("gossip", 0.5)) * 0.5 + w.rng.randf() * 0.25
				if cv > mcv:
					mcv = cv
					mc = id
			return mc
		"lunch_culprit":
			# whoever really ate this person's lunch (the fridge raid left a true rumour behind)
			var lv := ev.who(spec.get("of", "victim"), ctx)
			var lc := ""
			var ld := -1
			for f in w.dyn_facts:
				var r: Dictionary = w.dyn_facts[f]
				if r["kind"] != "stole_lunch" or str(r["b"]) != lv or not bool(r.get("truth", true)):
					continue
				var ln: NPC = w.npc(str(r["a"]))
				if ln != null and ln.present and int(r["day"]) >= ld:
					ld = int(r["day"])
					lc = str(r["a"])
			return lc
		"ostate":
			# a person stored in an object's state ("promo.credit", "ws.{owner}.love_note", ...)
			var opath: String = w.events.res.fmt(str(spec.get("path", "")), ctx)
			var ov = C.dict_get_path(w.office.objects, opath)
			if typeof(ov) == TYPE_STRING and w.npc(str(ov)) != null:
				return str(ov)
			return ""
		"iv_who":
			# the owner/target of the most recent use of an intervention
			for i in range(w.iv.used.size() - 1, -1, -1):
				var u: Dictionary = w.iv.used[i]
				if str(u["id"]) == str(spec.get("id", "")) and int(u["day"]) >= w.day - int(spec.get("days", 0)):
					return str(u.get(str(spec.get("field", "target")), ""))
			return ""
		"promo_rightful":
			# the real front-runner for the promotion (not the person the file was changed to)
			var pr_not := ev.who(spec.get("not", "credited"), ctx)
			var prb := ""
			var prf := -1e9
			for c in MeetingFlow.candidates(w):
				if c == pr_not or not w.npc(c).present:
					continue
				if float(w.favor.get(c, 0.0)) > prf:
					prf = float(w.favor.get(c, 0.0))
					prb = c
			return prb
		"top_trait":
			# who here has the most of a trait (optionally not the boss / not someone)
			var tt_not := ev.who(spec.get("not", ""), ctx)
			var ttb := ""
			var ttv := -1e9
			for id in w.present_ids():
				if id == tt_not or (id == "ahmet" and not spec.get("boss", false)):
					continue
				if spec.get("avail", false) and not w.available(id):
					continue
				var tv2: float = float(w.npc(id).traits.get(str(spec.get("trait", "sociability")), 0.5)) + w.rng.randf() * 0.15
				if tv2 > ttv:
					ttv = tv2
					ttb = id
			return ttb
		"most_stressed":
			var ms_not := ev.who(spec.get("not", ""), ctx)
			var msb := ""
			var msv := -1e9
			for id in w.present_ids():
				if id == ms_not or id == "ahmet":
					continue
				var sv: float = w.npc(id).stress + float(w.npc(id).traits.get("temper", 0.5)) * 10.0
				if sv > msv:
					msv = sv
					msb = id
			return msb
		"admirer_of":
			# whoever has the biggest soft spot for X
			var ax := ev.who(spec.get("of", "owner"), ctx)
			var ab := ""
			var av := float(spec.get("lim", 15.0))
			for id in w.present_ids():
				if id == ax:
					continue
				var rv3: float = w.npc(id).get_rel(ax, "romance") + w.rng.randf() * 4.0
				if rv3 > av:
					av = rv3
					ab = id
			return ab
		"partner_of":
			# someone this person has a bond with (romance by default) who is here today
			var po := ev.who(spec.get("of", "actor"), ctx)
			for pid in w.bonds_of(po, str(spec.get("kind", "romance"))):
				if w.npc(pid) != null and w.npc(pid).present:
					return pid
			return ""
		"good_vibes":
			# a party only feels right when people are in a decent mood and the kitchen is free
			if str(w.office.objects["kitchen"].get("reserved", "")) != "":
				return ""
			var gt := 0.0
			var gn := 0
			for id in w.present_ids():
				gt += w.npc(id).mood
				gn += 1
			if gn < 4:
				return ""
			return "yes" if gt / gn > float(spec.get("lim", 5.0)) else ""
	return ""


## A rumour this person heard but isn't sure about, about someone who's here.
static func doubtful_rumor(w, who_id: String) -> String:
	var n: NPC = w.npc(who_id)
	if n == null:
		return ""
	var best := ""
	var bs := 0.0
	for f in n.known:
		if not w.dyn_facts.has(f):
			continue
		var c: float = n.certainty(f)
		if c >= 0.8:
			continue
		var subj: String = w.fact_subject(f)
		if subj == "" or subj == who_id or not w.available(subj):
			continue
		var s: float = w.fact_juice(f) * (1.0 - c) + absf(n.affinity(subj)) * 0.004 + w.rng.randf() * 0.2
		if w.rumor_defs.get(w.dyn_facts[f]["kind"], {}).get("outrageous", false):
			s += 0.3   # stories that sound too wild get double-checked
		if s > bs:
			bs = s
			best = f
	return best


static func rumor_spreader(w, f: String, not_id: String) -> String:
	if not w.dyn_facts.has(f):
		return ""
	var r: Dictionary = w.dyn_facts[f]
	var cands: Array = r.get("spreaders", []).duplicate()
	if r.get("origin", "") != "":
		cands.append(r["origin"])
	for c in cands:
		if c != not_id and c != r.get("a", "") and w.npc(c) != null and w.npc(c).present:
			return c
	return ""


## Who this person has a soft spot for (data "romance" weights + mutual liking).
static func crush_of(w, who_id: String, taken := false) -> String:
	var n: NPC = w.npc(who_id)
	if n == null:
		return ""
	var prefs: Dictionary = n.def.get("romance", {})
	var best := ""
	var bs := 0.0
	for id in prefs:
		var o: NPC = w.npc(id)
		if o == null or not o.present:
			continue
		if taken:
			# only crushes who are already seeing someone else (for heartbreak)
			var partners: Array = w.bonds_of(id, "romance")
			if partners.is_empty() or partners.has(who_id):
				continue
		var s: float = float(prefs[id]) + n.affinity(id) * 0.01 + o.affinity(who_id) * 0.006
		if w.has_bond(who_id, id, "romance"):
			s += 2.0
		if s > bs:
			bs = s
			best = id
	return best


## Ids a picker must skip: its "not" and, when it fills a role, the role's exclusions.
static func _excl(ev, spec: Dictionary, ctx: Dictionary) -> Array:
	var r: Array = []
	var nid: String = ev.who(spec.get("not", ""), ctx)
	if nid != "":
		r.append(nid)
	for x in spec.get("exclude", []):
		var xid: String = ev.who(x, ctx)
		if xid != "":
			r.append(xid)
	return r


static func extreme_of(w, who_id: String, best: bool, lim: float, need_avail: bool, not_ids: Array = []) -> String:
	var n: NPC = w.npc(who_id)
	if n == null:
		return ""
	var pick := ""
	var bv := -1e9
	for id in w.present_ids():
		if id == who_id or id in not_ids or (need_avail and not w.available(id)):
			continue
		var a: float = n.affinity(id) if best else -n.affinity(id)
		a += w.rng.randf() * 4.0
		if a > bv:
			bv = a
			pick = id
	if pick == "":
		return ""
	var real: float = n.affinity(pick)
	if best and real < lim:
		return ""
	if not best and real > lim:
		return ""
	return pick


static func mediator(w, a: String, b: String) -> String:
	var best := ""
	var bs := 0.0
	for id in w.present_ids():
		if id == a or id == b or not w.available(id):
			continue
		var m: NPC = w.npc(id)
		var s: float = minf(m.affinity(a), m.affinity(b)) * 0.03 + m.t("empathy") * 1.2
		if m.goal == "keep_peace":
			s += 1.0
		if minf(m.affinity(a), m.affinity(b)) < 5.0:
			continue
		if s > bs:
			bs = s
			best = id
	return best


static func low_morale(w, lim: float, not_id: String) -> String:
	var best := ""
	var bv := lim
	for id in w.present_ids():
		if id == not_id or id == "ahmet":
			continue
		var n: NPC = w.npc(id)
		if n.morale < bv:
			bv = n.morale
			best = id
	return best


static func rival_of(w, who_id: String, lim: float) -> String:
	var n: NPC = w.npc(who_id)
	if n == null:
		return ""
	var best := ""
	var bv := lim
	for id in w.present_ids():
		if id == who_id:
			continue
		var r: float = n.get_rel(id, "rivalry")
		if r > bv:
			bv = r
			best = id
	return best


## A real secret about `about` that `knower` knows (static facts only).
static func secret_about(w, knower: String, about: String) -> String:
	var n: NPC = w.npc(knower)
	if n == null:
		return ""
	for f in n.known:
		if w.fact_defs.has(f) and w.fact_subject(f) == about and w.fact_exists(f):
			return f
	return ""


static func any_secret(w, knower: String, not_about: String) -> String:
	var n: NPC = w.npc(knower)
	if n == null:
		return ""
	var best := ""
	var bs := 0.0
	for f in n.known:
		if not w.fact_defs.has(f) or not w.fact_exists(f):
			continue
		var subj: String = w.fact_subject(f)
		if subj == knower or subj == not_id_safe(not_about):
			continue
		var s: float = w.fact_juice(f) + w.rng.randf() * 0.3 - n.affinity(subj) * 0.01
		if s > bs:
			bs = s
			best = f
	return best


static func not_id_safe(x: String) -> String:
	return x if x != "" else "#"


static func common_enemy(w, a: String, b: String) -> String:
	var na: NPC = w.npc(a)
	var nb: NPC = w.npc(b)
	if na == null or nb == null:
		return ""
	var best := ""
	var bv := -8.0
	for id in w.order:
		if id == a or id == b or id == "ahmet":
			continue
		var s: float = -(na.affinity(id) + nb.affinity(id)) * 0.5 + na.get_rel(id, "rivalry") * 0.3
		if na.affinity(id) > 12.0 or nb.affinity(id) > 22.0:
			continue
		if s > bv:
			bv = s
			best = id
	return best


static func clumsy_one(w, not_id: String) -> String:
	var best := ""
	var bv := -1e9
	for id in w.present_ids():
		if id == not_id:
			continue
		var n: NPC = w.npc(id)
		var s: float = n.t("clumsiness") * 2.0 + (1.0 - n.t("diligence")) + w.rng.randf() * 0.8
		if s > bv:
			bv = s
			best = id
	return best


## Who does the victim blame? Based on rivalry, distrust, bad memories and who was around.
static func suspect_for(w, victim: String, exclude: String, loc: String) -> String:
	var vn: NPC = w.npc(victim)
	if vn == null:
		return ""
	var spot := Vector2(-100, -100)
	if loc != "":
		spot = w.office.place_pos(OfficeLayout.item_pick_place(loc)) if loc != "printer" and loc != "coffee" else w.office.place_pos(loc)
	var best := ""
	var bs := -1e9
	for id in w.order:
		if id == victim or id == exclude:
			continue
		var o: NPC = w.npc(id)
		var s := vn.get_rel(id, "rivalry") * 0.03 - vn.get_rel(id, "trust") * 0.014 - vn.get_rel(id, "friendship") * 0.008
		s -= vn.mem_bias(id) * 0.5
		if o.present and spot.x > -50.0 and o.pos.distance_to(spot) < 4.0:
			s += 0.5
		if not o.present:
			s -= 0.6
		s += o.t("humor") * 0.25 + o.t("cunning") * 0.2   # pranksters & schemers look guilty
		if loc == "" or loc.begins_with("desk_"):
			s += o.t("clumsiness") * 0.3                  # ...and the clumsy ones lose things
		s += w.rng.randf() * 0.7
		if s > bs:
			bs = s
			best = id
	return best


## Juiciest fact `who` knows that `to` doesn't, isn't about `to`, and `who` is willing to share.
static func gossip_for(w, who_id: String, to: String) -> String:
	var a: NPC = w.npc(who_id)
	var b: NPC = w.npc(to)
	if a == null or b == null:
		return ""
	var best := ""
	var bs := 0.18
	for f in a.known:
		if b.knows(f) or not w.fact_exists(f):
			continue
		var subj: String = w.fact_subject(f)
		if subj == to or subj == who_id:
			continue
		# people don't spread their own secrets, and protect close friends
		var s: float = w.fact_juice(f) * (0.4 + a.t("gossip"))
		if subj != "":
			s -= a.affinity(subj) * 0.006
		if w.dyn_facts.has(f):
			var r: Dictionary = w.dyn_facts[f]
			if r["b"] == to:
				s += 0.25   # "you should know what they said about you"
		if s > bs:
			bs = s
			best = f
	return best


static func best_gossip(w, who_id: String) -> Dictionary:
	var best := {}
	var bs := 0.0
	for id in w.present_ids():
		if id == who_id or not w.available(id):
			continue
		var f := gossip_for(w, who_id, id)
		if f == "":
			continue
		var s: float = w.fact_juice(f) + w.npc(who_id).affinity(id) * 0.004 + w.rng.randf() * 0.2
		if s > bs:
			bs = s
			best = {"fact": f, "to": id, "juice": w.fact_juice(f)}
	return best


static func run(w, fn: String, e: Dictionary, ctx: Dictionary) -> void:
	var ev: EventConditionEvaluator = w.events.ev
	var actor := ev.who(e.get("who", "actor"), ctx)
	var n: NPC = w.npc(actor)
	match fn:
		"search_item":
			if n == null:
				return
			n.add_intent({"type": "search", "target": "", "prio": float(e.get("prio", 58)), "until": w.minute + 120.0, "vars": {"item": ctx["vars"].get("item", "")}, "roles": {}})
		"return_item":
			if n == null:
				return
			var item := str(ctx["vars"].get("item", ""))
			var owner: String = w.office.items[item]["owner"] if w.office.items.has(item) else ""
			if owner == "" or not w.npc(owner).present:
				# just put it back on their desk
				if w.office.items.has(item):
					w.office.items[item]["at"] = w.office.items[item]["home"]
					w.office_changed.emit("items")
				return
			n.add_intent({"type": "return_item", "target": owner, "prio": 52.0, "until": w.minute + 60.0, "vars": {"item": item}, "roles": {}})
		"scold":
			var tgt := ev.who(e.get("target", "target"), ctx)
			var boss: NPC = w.npc("ahmet")
			if boss == null or not boss.present or tgt == "":
				return
			boss.add_intent({"type": "go_npc", "target": tgt, "event": "boss_scold", "prio": float(e.get("prio", 62)), "until": w.minute + 90.0, "vars": {"reason": e.get("reason", ctx["vars"].get("reason", "general"))}, "roles": {}})
		"summon":
			var tgt2 := ev.who(e.get("target", "target"), ctx)
			var t: NPC = w.npc(tgt2)
			if t == null or not t.present:
				return
			t.add_intent({"type": "go_place", "place": "boss_front", "event": e.get("event", "boss_talk"), "prio": float(e.get("prio", 72)), "until": w.minute + 60.0, "target": "", "vars": ctx["vars"].duplicate(true), "roles": {"target": "ahmet"}})
		"share_board":
			var tgt3 := ev.who(e.get("target", "target"), ctx)
			var t3: NPC = w.npc(tgt3)
			if n and t3 and n.meeting_belief >= 0.0 and t3.meeting_belief >= 0.0 and t3.meeting_state == "":
				t3.meeting_belief = n.meeting_belief
		"spread_all":
			var f := str(ev.val(e.get("fact", "$fact"), ctx))
			for id in w.order:
				w.learn(id, f, actor)
		"cliques":
			_cliques(w)
		"lights_fixer":
			var L: Dictionary = w.office.objects["lights"]
			if L["on"] or L.get("fixing", "") != "":
				return
			if n == null:
				return
			L["fixing"] = actor
			w.force_activity(actor, "fix", {"obj": "lights", "prio": 75.0})
		"fix_intent":
			if n == null:
				return
			var obj := str(ev.val(e.get("obj", "$obj"), ctx))
			var req := ev.who(e.get("requester", "actor"), ctx)
			if w.office.objects.has(obj) and w.office.objects[obj].get("fixing", "") == "":
				w.office.objects[obj]["fixing"] = actor
				n.add_intent({"type": "fix", "obj": obj, "prio": float(e.get("prio", 64)), "until": w.minute + 90.0, "roles": {"requester": req}, "vars": {}})
		"meeting_cancel_belief":
			if n:
				n.meeting_belief = -2.0
		"give_up_printing":
			if n:
				n.today_flags["printer_gave_up"] = true
		"thermostat_intent":
			if n:
				n.add_intent({"type": "thermostat", "prio": float(e.get("prio", 50)), "until": w.minute + 40.0, "roles": {}, "vars": {}})
		"npc_move_item":
			var it_id := str(e.get("item", ""))
			if w.office.items.has(it_id):
				w.office.items[it_id]["at"] = str(e.get("to", ""))
				w.office_changed.emit("items")
		"ghost_theory":
			w.flags["ghost_belief"] = int(w.flags.get("ghost_belief", 0)) + 1
		"mess_desk":
			# someone quietly wrecks a desk; the owner will find it (and blame *someone*)
			var vt := ev.who(e.get("target", "target"), ctx)
			var desks: Dictionary = w.office.objects["desks"]
			if desks.has(vt):
				desks[vt]["messed"] = true
				w.flags["desk_culprit_" + vt] = actor
				w.office_changed.emit("desks")
		"hide_item":
			var item_id := str(ev.val(e.get("item", "$item"), ctx))
			if w.office.items.has(item_id):
				w.office.items[item_id]["at"] = str(e.get("to", "archive"))
				w.flags["item_culprit_" + item_id] = actor
				w.office_changed.emit("items")
		"extra_work":
			var et := ev.who(e.get("target", "target"), ctx)
			var en: NPC = w.npc(et)
			if en:
				var u := float(e.get("units", 22.0))
				en.tasks.append({"id": str(e.get("task", "urgent_report")), "total": u, "left": u, "deadline": str(e.get("deadline", "17:15")),
					"print": false, "printed": false, "usb": false, "phone": false, "archive": false})
		"lunch_sync":
			# two people agree to go to lunch together: same time, and they'll pick seats near each other
			var lt2 := ev.who(e.get("target", "target"), ctx)
			var ln2: NPC = w.npc(lt2)
			if n and ln2 and not n.lunch_done and not ln2.lunch_done:
				var at: float = maxf(w.minute + 4.0, minf(n.lunch_at, ln2.lunch_at))
				n.lunch_at = at
				ln2.lunch_at = at + 0.5
		"alarm_timer":
			w.office.objects["alarm"]["on"] = true
			w.office.objects["alarm"]["until"] = w.minute + float(e.get("minutes", 12))
			w.office_changed.emit("alarm")
		"storm_off":
			# someone turns on their heel and marches back to their desk, fuming
			for sid in w.events.res._ids(e.get("who", "actor"), ctx):
				var sn: NPC = w.npc(sid)
				if sn == null or not sn.present or sid == "ahmet" and sn.act == "meeting":
					continue
				sn.set_expr("angry", 6.0)
				sn.hold_until = minf(sn.hold_until, w.minute)
				w.force_activity(sid, "work", {"prio": 80.0, "storm": true})
		"flicker":
			w.office.objects["lights"]["flicker_until"] = w.minute + float(e.get("minutes", 20))
			w.office_changed.emit("lights")
		"clock_time":
			ctx["vars"]["time"] = w.minute + float(w.office.objects["clock"].get("offset", 0))
		"vars_to_roles":
			for k in e.get("keys", []):
				var vv = ctx["vars"].get(k, "")
				if typeof(vv) == TYPE_STRING and vv != "":
					ctx["roles"][k] = vv
		"coffee_late":
			w.office.objects["coffee"]["late_until"] = w.minute + float(e.get("minutes", 40))
			w.office_changed.emit("coffee")
		"swap_favor":
			# two people's performance files trade places
			var sa := ev.who(e.get("a", "owner"), ctx)
			var sb := ev.who(e.get("b", "target"), ctx)
			if sa != "" and sb != "":
				var fa := float(w.favor.get(sa, 40.0))
				w.favor[sa] = float(w.favor.get(sb, 40.0))
				w.favor[sb] = fa
		"pick_role":
			# fill a role at apply time (after the player chose a target)
			var rn: String = e["role"]
			if e.get("keep", false) and str(ctx["roles"].get(rn, "")) != "":
				return
			var pv = pick(w, str(e["pfn"]), e, ctx)
			if pv != null and str(pv) != "":
				ctx["roles"][rn] = str(pv)
		"take_lunch":
			# stolen from the fridge: the victim's afternoon gets worse
			var lt := ev.who(e.get("target", "target"), ctx)
			var ln: NPC = w.npc(lt)
			if ln and not ln.lunch_done:
				ln.today_flags["lunch_stolen"] = actor
		_:
			push_warning("Unknown special: " + fn)


static func _cliques(w) -> void:
	# two people are "close" when they like each other; split the room into camps
	var ids: Array = w.present_ids()
	if ids.size() < 4:
		return
	var groups: Array = []
	var seen := {}
	for id in ids:
		if seen.has(id):
			continue
		var grp: Array = [id]
		seen[id] = true
		var k := 0
		while k < grp.size():
			var a: NPC = w.npc(grp[k])
			for other in ids:
				if seen.has(other):
					continue
				if a.affinity(other) > 32.0 and w.npc(other).affinity(grp[k]) > 32.0:
					grp.append(other)
					seen[other] = true
			k += 1
		if grp.size() >= 2:
			groups.append(grp)
	if groups.size() < 2:
		return
	groups.sort_custom(func(x, y): return x.size() > y.size())
	var g1: Array = groups[0]
	var g2: Array = groups[1]
	# are the camps hostile?
	var hostile := 0.0
	for a in g1:
		for b in g2:
			hostile += w.npc(a).affinity(b)
	hostile /= float(g1.size() * g2.size())
	if hostile > -5.0:
		return
	var names1 := ", ".join(g1.map(func(x): return w.npc(x).name))
	var names2 := ", ".join(g2.map(func(x): return w.npc(x).name))
	w.stats.add("cliques")
	w.log_event("log.cliques", {"roles": {"actor": g1[0], "target": g2[0]}, "vars": {"g1": names1, "g2": names2}}, 3, "cliques", g1 + g2)


# =====================================================================
# Email mishaps (wrong email to everyone / redirected recipient)
# =====================================================================

## Picks what the sender's email actually contains, from their data-defined drafts.
static func email_content(w, sender: String, private_msg: bool) -> Dictionary:
	var n: NPC = w.npc(sender)
	var drafts: Array = n.def.get("drafts", [])
	var valid: Array = []
	for dr in drafts:
		var tp: String = dr["type"]
		match tp:
			"secret":
				var f: String = dr["fact"]
				if w.fact_exists(f) and n.knows(f) and not w.discovered.has(f):
					valid.append({"type": "secret", "fact": f, "about": w.fact_subject(f)})
			"gossip_digest":
				var g := ""
				var gb := 0.0
				for f2 in n.known:
					if not w.fact_defs.has(f2) or w.discovered.has(f2):
						continue
					var subj: String = w.fact_subject(f2)
					if subj == sender or subj == "":
						continue
					if w.fact_juice(f2) > gb:
						gb = w.fact_juice(f2)
						g = f2
				if g != "":
					valid.append({"type": "gossip_digest", "fact": g, "about": w.fact_subject(g)})
			"rant":
				var worst := ""
				var wv := 1e9
				for id in w.order:
					if id == sender:
						continue
					if n.affinity(id) < wv:
						wv = n.affinity(id)
						worst = id
				if worst != "":
					valid.append({"type": "rant", "about": worst})
			"love":
				if w.fact_exists("mert_crush"):
					valid.append({"type": "love", "fact": "mert_crush", "about": "ceren"})
			"complaint_boss":
				valid.append({"type": "complaint_boss", "about": "ahmet"})
			"complaint_team":
				valid.append({"type": "complaint_team", "about": ""})
			"scheme":
				valid.append({"type": "scheme", "about": "selin"})
	if valid.is_empty():
		valid.append({"type": "rant", "about": "ahmet" if sender != "ahmet" else "mert"})
	var pick: Dictionary = valid[0] if w.rng.randf() < 0.7 else valid[w.rng.randi() % valid.size()]
	return pick


## The confidant someone would normally write private messages to.
static func confidant(w, sender: String) -> String:
	var n: NPC = w.npc(sender)
	var best := ""
	var bs := -1e9
	for id in w.order:
		if id == sender:
			continue
		if n.affinity(id) > bs:
			bs = n.affinity(id)
			best = id
	return best


static func send_email(w, sender: String) -> void:
	var o: OfficeEnv = w.office
	if not o.objects["email"].has(sender):
		return
	var sab: Dictionary = o.objects["email"][sender]
	o.objects["email"].erase(sender)
	w.office_changed.emit("email")
	var mode: String = sab.get("mode", "all")
	var content := email_content(w, sender, mode == "redirect")
	var tp: String = content["type"]
	var about: String = content.get("about", "")
	var fact: String = content.get("fact", "")
	var to: String = sab.get("to", "")
	var intended := confidant(w, sender)
	if mode == "redirect" and to == intended:
		intended = ""
	w.stats.add("emails")
	w.sfx.emit("email")
	var ctx := {"roles": {"actor": sender, "target": to, "subject": about}, "vars": {"etype": tp, "intended": intended}}
	if fact != "":
		ctx["vars"]["fact"] = fact
	# who actually reads it
	var readers: Array = []
	if mode == "all":
		for id in w.order:
			if id != sender:
				readers.append(id)
	else:
		readers = [to]
	# --- what readers learn
	match tp:
		"secret", "gossip_digest", "love":
			for id in readers:
				w.learn(id, fact, sender)
			if mode == "all" or to != "":
				w.reveal(fact)
		"rant":
			var rid: String = w.make_rumor("dislikes", sender, about, 0.7)
			ctx["vars"]["rumor"] = rid
			for id in readers:
				w.learn(id, rid, sender)
			w.reveal(rid)
		"scheme":
			var sid: String = w.make_rumor("scheme", sender, about, 0.9)
			ctx["vars"]["rumor"] = sid
			for id in readers:
				w.learn(id, sid, sender)
			w.reveal(sid)
		"complaint_boss":
			if "ahmet" in readers:
				w.change_rel("ahmet", sender, "trust", -22.0)
				w.change_rel("ahmet", sender, "friendship", -12.0)
				w.favor[sender] = clampf(float(w.favor.get(sender, 40.0)) - 10.0, 0, 100)
			for id in readers:
				if id != "ahmet":
					w.change_rel(id, sender, "friendship", 4.0)   # secretly agree
		"complaint_team":
			for id in readers:
				w.change_rel(id, "ahmet", "friendship", -10.0)
				w.change_rel(id, "ahmet", "trust", -6.0)
				var rn: NPC = w.npc(id)
				rn.mood = C.clampf100(rn.mood - 8.0)
	var sn: NPC = w.npc(sender)
	sn.stress = clampf(sn.stress + (22.0 if mode == "all" else 12.0), 0, 100)
	sn.mood = C.clampf100(sn.mood - 14.0)
	# --- log & scene
	var key := "log.email_all.%s" % tp if mode == "all" else "log.email_redirect.%s" % tp
	w.log_event(key, ctx, 4 if mode == "all" else 3, "email", [sender, to, about].filter(func(x): return x != ""))
	var ev_id := "email_all_scene" if mode == "all" else "email_redirect_scene"
	w.events.run_event(ev_id, {"actor": sender, "target": to, "subject": about}, ctx["vars"])
