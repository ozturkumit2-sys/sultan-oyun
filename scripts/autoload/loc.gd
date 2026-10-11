extends Node
## Loc — çoklu dil desteği.
## Kaynak dil Türkçedir: arayüz ve veri metinlerinin Türkçe hâlleri anahtar olarak kullanılır,
## data/i18n/<dil>.json dosyaları {"Türkçe metin": "çeviri"} eşlemesi içerir.
## Kod içindeki her görünür metin Loc.t("...") ile çevrilir; veri metinleri (malzeme adları, jüri
## yorumları...) IngredientDatabase.apply_language() ile yerinde güncellenir.

signal language_changed(code: String)

const LANGS := ["tr", "en", "es", "de", "ar", "hi", "zh", "ja"]
const NATIVE := {"tr": "Türkçe", "en": "English", "es": "Español", "de": "Deutsch", "ar": "العربية",
	"hi": "हिन्दी", "zh": "简体中文", "ja": "日本語"}

var lang := "tr"
var _translation: Translation = null
var _table: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Kontrollerin metni kendiliğinden çevirmesini kapat: çeviri yalnızca Loc.t ile yapılır
	# (aksi hâlde zaten çevrilmiş bir metin başka bir anahtarla çakışıp ikinci kez çevrilebilir).
	get_tree().root.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var saved: String = str(SaveManager.setting("lang", ""))
	if saved == "" or not LANGS.has(saved):
		saved = detect()
	_load(saved)


## Cihaz diline göre ilk dil seçimi; desteklenmiyorsa İngilizce.
func detect() -> String:
	var l := OS.get_locale_language().to_lower()
	if LANGS.has(l):
		return l
	return "en"


func _load(code: String) -> void:
	if _translation != null:
		TranslationServer.remove_translation(_translation)
		_translation = null
	_table = {}
	lang = code if LANGS.has(code) else "en"
	if lang != "tr":
		var f := FileAccess.open("res://data/i18n/%s.json" % lang, FileAccess.READ)
		if f != null:
			var j := JSON.new()
			if j.parse(f.get_as_text()) == OK and j.data is Dictionary:
				_table = j.data
			f.close()
		_translation = Translation.new()
		_translation.locale = lang
		for k in _table.keys():
			_translation.add_message(k, str(_table[k]))
		TranslationServer.add_translation(_translation)
	TranslationServer.set_locale(lang)


## Dili değiştirir, kaydeder ve veri metinlerini yeniler.
func set_language(code: String) -> void:
	if not LANGS.has(code):
		return
	SaveManager.set_setting("lang", code)
	if code == lang:
		return
	_load(code)
	IngredientDatabase.apply_language()
	FusionEngine.clear_cache()
	language_changed.emit(lang)


## Türkçe kaynak metni aktif dile çevirir (çeviri yoksa kaynak metni döndürür).
func t(s: String) -> String:
	if lang == "tr" or s == "":
		return s
	var v: Variant = _table.get(s)
	return s if v == null else str(v)


## Biçimlendirme kısayolu: Loc.f("%d puan", [5])
func f(s: String, args: Variant) -> String:
	return t(s) % args


func has(s: String) -> bool:
	return lang == "tr" or _table.has(s)


func is_rtl() -> bool:
	return lang == "ar"


## Boşluksuz yazılan diller (isim birleştirme ve satır kırma için).
func is_cjk() -> bool:
	return lang == "zh" or lang == "ja"
