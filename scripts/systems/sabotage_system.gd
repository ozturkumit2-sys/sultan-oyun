class_name SabotageSystem
extends RefCounted
## Rakip sabotajları. Her sabotaj önceden uyarılır ve oyuncuya üç anlamlı seçenek sunulur:
## Savun (mini oyun), Uyum Sağla (etkiyi dönüştür), Riski Kabul Et (tam etki ama geri tepme şansı).
## Hiçbir sabotaj kaçınılmaz yenilgiye yol açmaz: en kötü etki bir turda birkaç puandır.

const ABILITIES := {
	"hex": {"name": "Lanetli Malzeme", "phase": "before_cook", "color": "#a25cff", "icon": "hex",
		"defend": "Büyü rünlerine zamanında dokun ve laneti engelle!",
		"adapt": "Laneti kucakla: daha az zehir, daha çok büyü ve +1 yaratıcılık.",
		"accept": "Yemeğin lanetlenir: zehir ve tuhaflık artar. (%20 geri tepme şansı)"},
	"precision_lock": {"name": "Hassasiyet Kilidi", "phase": "before_cook", "color": "#4ad6ff", "icon": "lock",
		"defend": "Sinyal düğümlerine dokunarak kilidi kır!",
		"adapt": "Otomatik pişirme: mini oyun atlanır, kalite sabit %70.",
		"accept": "Pişirme göstergesi hızlanır ve hedef daralır. (%20 geri tepme şansı)"},
	"rotten_surprise": {"name": "Çürük Sürpriz", "phase": "before_cook", "color": "#8fbf3a", "icon": "jar",
		"defend": "Kavanozları zamanında yakala ve geri yolla!",
		"adapt": "Hangi kavanozun ekleneceğini sen seç: +1 yaratıcılık.",
		"accept": "Rastgele bir fermente malzeme yemeğine karışır. (%20 geri tepme şansı)"},
	"midnight_kitchen": {"name": "Gece Yarısı Mutfağı", "phase": "before_cook", "color": "#5a3a7a", "icon": "moon",
		"defend": "Yarasaları kovalayıp ışıkları açık tut!",
		"adapt": "Mum yak: görüş tam ama sunum -0,5 (mum damlası!).",
		"accept": "Pişirme sırasında mutfak kararır. (%20 geri tepme şansı)"},
	"ingredient_theft": {"name": "Malzeme Hırsızlığı", "phase": "round_start", "color": "#ff9b3d", "icon": "hook",
		"defend": "Kancayı zamanında vur ve malzemeni koru!",
		"adapt": "Takas et: malzemen gider ama yerine Korsan Baharatı gelir.",
		"accept": "En değerli malzemen bu tur için çalınır. (%20 geri tepme şansı)"},
	"gravity_shift": {"name": "Yerçekimi Kayması", "phase": "before_plating", "color": "#7cff6b", "icon": "orbit",
		"defend": "Uçan malzemeleri yakalayıp yere indir!",
		"adapt": "Sıfır yerçekimi sunumu: sunum -0,5 ama +1 yaratıcılık.",
		"accept": "Tabak havada savrulur: sunum -1,5. (%20 geri tepme şansı)"},
	"purify": {"name": "Arındırma", "phase": "before_judging", "color": "#ffb8ec", "icon": "leaf",
		"defend": "Arındırma tozunu üfleyerek dağıt!",
		"adapt": "Yarı arınma: etkiler yarıya iner ve jüri mutasyonları korunur.",
		"accept": "Büyü, tuhaflık ve zehir azalır; jüri mutasyonları silinir. (%20 geri tepme şansı)"},
}
const PHASES := ["round_start", "before_cook", "before_plating", "before_judging"]
const OBSCURA_POOL := ["hex", "precision_lock", "rotten_surprise", "midnight_kitchen", "gravity_shift", "purify"]
const FERMENTED := ["eye_pickle", "moldy_spirit", "century_pickle"]


static func ability(id: String) -> Dictionary:
	return ABILITIES.get(id, {})


static func phase_of(id: String) -> String:
	return ABILITIES.get(id, {}).get("phase", "before_cook")


## Sonuç türleri: blocked, reflected, half, full, adapt, backfire
static func result_text(id: String, result: String) -> String:
	var n: String = ABILITIES.get(id, {}).get("name", "Sabotaj")
	match result:
		"blocked":
			return "%s engellendi! Kalkanın dimdik." % n
		"reflected":
			return "AYNA KALKANI! %s rakibe geri döndü!" % n
		"half":
			return "%s kısmen işledi. Etkisi yarıya indi." % n
		"full":
			return "%s tam isabet!" % n
		"adapt":
			return "Uyum sağladın! %s seni farklı bir yöne götürdü." % n
		"backfire":
			return "GERİ TEPTİ! %s rakibin kendi başına patladı!" % n
	return n


## Pişirme mini oyunu için zorluk etkileri
static func cooking_mods(id: String, result: String) -> Dictionary:
	if id == "precision_lock":
		match result:
			"full":
				return {"speed": 1.6, "zone": 0.6, "jitter": true}
			"half":
				return {"speed": 1.3, "zone": 0.8}
			"adapt":
				return {"auto": 0.7}
	if id == "midnight_kitchen":
		match result:
			"full":
				return {"dark": 1.0}
			"half":
				return {"dark": 0.55}
	return {}


## Pişen yemeğe uygulanan değişiklikler. Döndürür: {dish, mods(presentation/creativity), clear_mutations}
static func apply_to_dish(id: String, result: String, dish: Dictionary, choice_extra: String, chaos_tier: int) -> Dictionary:
	var d := dish
	var mods := {}
	var clear_mut := false
	var adapt_bonus := 1.0 + (0.5 if chaos_tier >= 1 else 0.0)
	match id:
		"hex":
			match result:
				"full":
					d = FusionEngine.modify(dish, {"toxic": 30, "weird": 25, "magic": 20}, ["cursed", "spooky"], "Lanetli ")
				"half":
					d = FusionEngine.modify(dish, {"toxic": 15, "weird": 12, "magic": 10}, ["cursed"], "Lanetli ")
				"adapt":
					d = FusionEngine.modify(dish, {"toxic": 8, "weird": 20, "magic": 25}, ["cursed", "magic"], "Lanetli ")
					mods["creativity"] = adapt_bonus
		"rotten_surprise":
			var ferm: String = choice_extra if FERMENTED.has(choice_extra) else str(FERMENTED[FusionEngine.fnv(str(dish["id"])) % 3])
			match result:
				"full":
					d = FusionEngine.taint(dish, ferm, 0.25)
				"half":
					d = FusionEngine.taint(dish, ferm, 0.12)
				"adapt":
					d = FusionEngine.taint(dish, ferm, 0.2)
					mods["creativity"] = adapt_bonus
		"midnight_kitchen":
			if result == "adapt":
				mods["presentation"] = -0.5
		"gravity_shift":
			match result:
				"full":
					mods["presentation"] = -1.5
				"half":
					mods["presentation"] = -0.75
				"adapt":
					mods["presentation"] = -0.5
					mods["creativity"] = adapt_bonus
		"purify":
			match result:
				"full":
					d = FusionEngine.modify(dish, {"magic": -30, "weird": -20, "toxic": -30, "volatile": -20}, ["purified"])
					clear_mut = true
				"half", "adapt":
					d = FusionEngine.modify(dish, {"magic": -15, "weird": -10, "toxic": -15, "volatile": -10}, ["purified"])
	return {"dish": d, "mods": mods, "clear_mutations": clear_mut}


## Geri tepen ya da yansıyan sabotajın rakibe etkisi
static func opponent_penalty(id: String) -> Dictionary:
	match id:
		"precision_lock", "midnight_kitchen":
			return {"quality": -0.22}
		"gravity_shift", "ingredient_theft":
			return {"presentation": -1.5}
		"hex":
			return {"stats": {"toxic": 25, "weird": 15}, "quality": -0.08}
		"rotten_surprise":
			return {"taint": true, "quality": -0.05}
		"purify":
			return {"stats": {"magic": -25, "weird": -15}, "presentation": -0.5}
	return {"quality": -0.15}
