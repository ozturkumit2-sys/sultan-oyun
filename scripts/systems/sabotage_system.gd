class_name SabotageSystem
extends RefCounted
## Rakip sabotajları. Her sabotaj önceden uyarılır ve oyuncuya üç anlamlı seçenek sunulur:
## Savun (mini oyun), Uyum Sağla (etkiyi dönüştür), Riski Kabul Et (tam etki ama geri tepme şansı).
## Hiçbir sabotaj kaçınılmaz yenilgiye yol açmaz: en kötü etki bir turda birkaç puandır.

const ABILITIES := {  # i18n
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
	"confetti_prank": {"name": "Konfeti Şakası", "phase": "before_judging", "color": "#ff7ad9", "icon": "confetti",
		"defend": "Konfeti toplarını patlamadan önce durdur!",
		"adapt": "Şakaya ortak ol: tuhaflık artar, sunum -0,5 ama +1 yaratıcılık.",
		"accept": "Yemeğin konfetiye bulanır: tuhaflık artar, sunum -1. (%20 geri tepme şansı)"},
	"tail_whip": {"name": "Kuyruk Darbesi", "phase": "round_start", "color": "#5fbf4a", "icon": "tail",
		"defend": "Kuyruğun önüne kalkan çek, kilerini koru!",
		"adapt": "Dağılanları topla: bir malzemen kaybolur ama yerine Ejder Yumurtası bulursun.",
		"accept": "Kilerin devrilir: iki malzemen bu tur kullanılamaz. (%20 geri tepme şansı)"},
	"smoke_bomb": {"name": "Duman Bombası", "phase": "before_cook", "color": "#8a90a3", "icon": "smoke",
		"defend": "Dumanı dağıtmak için kalkan rünlerine dokun!",
		"adapt": "Dumanı kullan: yemeğe isli bir aroma gelir, lezzet +0,5 ama sunum -0,5.",
		"accept": "Pişirirken mutfak dumanla dolar ve gösterge hızlanır. (%20 geri tepme şansı)"},
	"blizzard": {"name": "Kar Fırtınası", "phase": "before_cook", "color": "#9fe3ff", "icon": "snow",
		"defend": "Kar fırtınasını kalkanla durdur, ellerin donmasın!",
		"adapt": "Buzlu sunum: acılık azalır, tazelik artar, sunum +0,5 ama lezzet -0,5.",
		"accept": "Ellerin üşür: pişirme hedefi daralır, yemeğin acısı ve tatlılığı söner. (%20 geri tepme şansı)"},
	"ancient_curse": {"name": "Bin Yıllık Toz", "phase": "before_judging", "color": "#d9b45a", "icon": "dust",
		"defend": "Antik tozu üfleyip dağıt!",
		"adapt": "Antik tarif: tazelik düşer ama büyü artar ve +1 yaratıcılık.",
		"accept": "Yemeğin bayatlar: tazelik çok düşer, biraz büyü ve zehir sızar. (%20 geri tepme şansı)"},
	"palace_protocol": {"name": "Saray Protokolü", "phase": "before_judging", "color": "#c9302c", "icon": "scroll",
		"defend": "Fermanı okunmadan yakala!",
		"adapt": "Protokole uy: tuhaflık azalır, sunum +0,5 ama yaratıcılık -0,25.",
		"accept": "Saray kuralları: tuhaflık ve büyü bastırılır, yaratıcılık -1. (%20 geri tepme şansı)"},
	"dragon_breath": {"name": "Ejder Nefesi", "phase": "before_cook", "color": "#ff6a2a", "icon": "fire",
		"defend": "Ateşe karşı kalkanını kaldır!",
		"adapt": "Ateşi kucakla: acılık artar ve +1 yaratıcılık.",
		"accept": "Ocak alevlenir: pişirme hızlanır, yemeğin acısı ve patlayıcılığı artar. (%20 geri tepme şansı)"},
}
const PHASES := ["round_start", "before_cook", "before_plating", "before_judging"]
const OBSCURA_POOL := ["hex", "precision_lock", "rotten_surprise", "midnight_kitchen", "gravity_shift", "purify"]
## Kızıl Obscura (Rövanş Ligi) diğer şeflerin yeni sabotajlarını da öğrendi.
const OBSCURA_REVENGE_POOL := ["hex", "precision_lock", "rotten_surprise", "midnight_kitchen", "gravity_shift", "purify",
	"confetti_prank", "smoke_bomb", "blizzard", "ancient_curse", "palace_protocol", "dragon_breath"]
const FERMENTED := ["eye_pickle", "moldy_spirit", "century_pickle"]


## Yeteneğin aktif dile çevrilmiş kopyası.
static func ability(id: String) -> Dictionary:
	var a: Dictionary = ABILITIES.get(id, {}).duplicate()
	for k in ["name", "defend", "adapt", "accept"]:
		if a.has(k):
			a[k] = Loc.t(str(a[k]))
	return a


static func phase_of(id: String) -> String:
	return ABILITIES.get(id, {}).get("phase", "before_cook")


## Sonuç türleri: blocked, reflected, half, full, adapt, backfire
static func result_text(id: String, result: String) -> String:
	var n: String = ability(id).get("name", Loc.t("Sabotaj"))
	match result:
		"blocked":
			return Loc.t("%s engellendi! Kalkanın dimdik.") % n
		"reflected":
			return Loc.t("AYNA KALKANI! %s rakibe geri döndü!") % n
		"half":
			return Loc.t("%s kısmen işledi. Etkisi yarıya indi.") % n
		"full":
			return Loc.t("%s tam isabet!") % n
		"adapt":
			return Loc.t("Uyum sağladın! %s seni farklı bir yöne götürdü.") % n
		"backfire":
			return Loc.t("GERİ TEPTİ! %s rakibin kendi başına patladı!") % n
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
	if id == "smoke_bomb":
		match result:
			"full":
				return {"dark": 0.75, "speed": 1.3}
			"half":
				return {"dark": 0.4, "speed": 1.1}
	if id == "blizzard":
		match result:
			"full":
				return {"zone": 0.7, "jitter": true}
			"half":
				return {"zone": 0.85}
	if id == "dragon_breath":
		match result:
			"full":
				return {"speed": 1.5}
			"half":
				return {"speed": 1.25}
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
					d = FusionEngine.modify(dish, {"toxic": 30, "weird": 25, "magic": 20}, ["cursed", "spooky"], "cursed")
				"half":
					d = FusionEngine.modify(dish, {"toxic": 15, "weird": 12, "magic": 10}, ["cursed"], "cursed")
				"adapt":
					d = FusionEngine.modify(dish, {"toxic": 8, "weird": 20, "magic": 25}, ["cursed", "magic"], "cursed")
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
		"confetti_prank":
			match result:
				"full":
					d = FusionEngine.modify(dish, {"weird": 30}, ["confetti"])
					mods["presentation"] = -1.0
				"half":
					d = FusionEngine.modify(dish, {"weird": 15}, ["confetti"])
					mods["presentation"] = -0.5
				"adapt":
					d = FusionEngine.modify(dish, {"weird": 20}, ["confetti"])
					mods["presentation"] = -0.5
					mods["creativity"] = adapt_bonus
		"smoke_bomb":
			if result == "adapt":
				mods["flavor"] = 0.5
				mods["presentation"] = -0.5
		"blizzard":
			match result:
				"full":
					d = FusionEngine.modify(dish, {"spicy": -25, "sweet": -10, "fresh": 10}, ["frosty"])
				"half":
					d = FusionEngine.modify(dish, {"spicy": -12, "fresh": 5}, ["frosty"])
				"adapt":
					d = FusionEngine.modify(dish, {"spicy": -15, "fresh": 20}, ["frosty"])
					mods["presentation"] = 0.5
					mods["flavor"] = -0.5
		"ancient_curse":
			match result:
				"full":
					d = FusionEngine.modify(dish, {"fresh": -24, "magic": 12, "toxic": 6}, ["ancient"])
				"half":
					d = FusionEngine.modify(dish, {"fresh": -12, "magic": 6}, ["ancient"])
				"adapt":
					d = FusionEngine.modify(dish, {"fresh": -15, "magic": 20}, ["ancient", "magic"])
					mods["creativity"] = adapt_bonus
		"palace_protocol":
			match result:
				"full":
					d = FusionEngine.modify(dish, {"weird": -15, "magic": -10}, [])
					mods["creativity"] = -1.0
				"half":
					d = FusionEngine.modify(dish, {"weird": -8}, [])
					mods["creativity"] = -0.5
				"adapt":
					d = FusionEngine.modify(dish, {"weird": -20}, ["classic"])
					mods["presentation"] = 0.5
					mods["creativity"] = -0.25
		"dragon_breath":
			match result:
				"full":
					d = FusionEngine.modify(dish, {"spicy": 25, "volatile": 15}, ["scorched"])
				"half":
					d = FusionEngine.modify(dish, {"spicy": 12, "volatile": 6}, ["scorched"])
				"adapt":
					d = FusionEngine.modify(dish, {"spicy": 20, "volatile": 5}, ["fire"])
					mods["creativity"] = adapt_bonus
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
		"confetti_prank":
			return {"stats": {"weird": 25}, "presentation": -1.0}
		"tail_whip", "palace_protocol":
			return {"presentation": -1.0, "quality": -0.05}
		"smoke_bomb", "dragon_breath":
			return {"quality": -0.22}
		"blizzard":
			return {"quality": -0.18}
		"ancient_curse":
			return {"stats": {"fresh": -25}, "quality": -0.05}
	return {"quality": -0.15}
