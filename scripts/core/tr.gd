class_name TR
extends RefCounted
## Türkçe ek uyumu yardımcıları (özel isimlere kesme işaretiyle ek getirir).

const VOWELS := "aeıioöuüâîûAEIİOÖUÜÂÎÛ"
const BACK := "aıouâûAIOUÂÛ"
const ROUNDED := "oöuüOÖUÜû"
const HARD := "çfhkpsştÇFHKPSŞT"


static func _last_vowel(s: String) -> String:
	for i in range(s.length() - 1, -1, -1):
		if VOWELS.contains(s[i]):
			return s[i]
	return "e"


static func _ends_vowel(s: String) -> bool:
	return s.length() > 0 and VOWELS.contains(s[s.length() - 1])


static func _ends_hard(s: String) -> bool:
	return s.length() > 0 and HARD.contains(s[s.length() - 1])


static func _two(s: String, back: String, front: String) -> String:
	return back if BACK.contains(_last_vowel(s)) else front


static func _four(s: String) -> String:
	var v := _last_vowel(s)
	var back := BACK.contains(v)
	var round_ := ROUNDED.contains(v)
	if back:
		return "u" if round_ else "ı"
	return "ü" if round_ else "i"


## yönelme: -a / -e (-ya / -ye)
static func dat(s: String) -> String:
	var suf := _two(s, "a", "e")
	if _ends_vowel(s):
		suf = "y" + suf
	return s + "'" + suf


## bulunma: -da / -de / -ta / -te
static func loc(s: String) -> String:
	var d := "t" if _ends_hard(s) else "d"
	return s + "'" + d + _two(s, "a", "e")


## ayrılma: -dan / -den / -tan / -ten
static func abl(s: String) -> String:
	var d := "t" if _ends_hard(s) else "d"
	return s + "'" + d + _two(s, "an", "en")


## belirtme: -ı / -i / -u / -ü (-yı ...)
static func acc(s: String) -> String:
	var suf := _four(s)
	if _ends_vowel(s):
		suf = "y" + suf
	return s + "'" + suf


## tamlayan: -ın / -in / -un / -ün (-nın ...)
static func gen(s: String) -> String:
	var suf := _four(s) + "n"
	if _ends_vowel(s):
		suf = "n" + suf
	return s + "'" + suf


## ile: -la / -le (-yla / -yle)
static func ins(s: String) -> String:
	var suf := _two(s, "la", "le")
	if _ends_vowel(s):
		suf = "y" + suf
	return s + "'" + suf
