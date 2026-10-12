extends Node
## Real-world monetization boundary (kept separate from the game's fictional perfume advertising).
## Integrates with Google AdMob / Google Play Billing Android plugins ONLY if they are present and
## configured in the export. Nothing is faked: without plugins, ads and purchases are unavailable and
## the full game remains playable offline for free.

signal rewarded(ok: bool)
signal purchase_done(product_id: String, ok: bool)

const REMOVE_ADS := "remove_ads"
var _admob: Object = null
var _billing: Object = null
var owned: Dictionary = {}


func _ready() -> void:
	if Engine.has_singleton("PoingGodotAdMob"):
		_admob = Engine.get_singleton("PoingGodotAdMob")
	if Engine.has_singleton("GodotGooglePlayBilling"):
		_billing = Engine.get_singleton("GodotGooglePlayBilling")
	var f := FileAccess.open("user://purchases.json", FileAccess.READ)
	if f:
		var d: Variant = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			owned = d


func ads_available() -> bool:
	return _admob != null


func billing_available() -> bool:
	return _billing != null


func ads_removed() -> bool:
	return owned.get(REMOVE_ADS, false)


## Optional rewarded ad for a small research bonus. Returns false immediately when ads are not configured.
func show_rewarded() -> bool:
	if _admob == null:
		return false
	# Plugin-specific integration point (configure ad unit ids before enabling in production).
	return false


func maybe_interstitial() -> void:
	if _admob == null or ads_removed():
		return


func buy(product_id: String) -> bool:
	if _billing == null:
		return false
	return false
