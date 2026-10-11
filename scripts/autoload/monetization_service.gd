extends Node
## MonetizationService — ileride eklenebilecek ödüllü reklam / kozmetik satın alma için arayüz.
## İlk sürümde hiçbir canlı reklam veya ödeme entegrasyonu YOKTUR; tüm çağrılar "kullanılamıyor" döner.
## Temel ilerleme hiçbir zaman reklama bağlı değildir ve kazanmayı satın alan ürün yoktur.

signal rewarded_finished(placement: String, success: bool)

const PRODUCTS := {
	"remove_ads": {"type": "non_consumable", "desc": "Reklamları kaldır (gelecek sürüm)"},
	"theme_pack_neon": {"type": "cosmetic", "desc": "Neon mutfak teması (gelecek sürüm)"},
}


func rewarded_available(_placement: String) -> bool:
	return false


func show_rewarded(placement: String) -> void:
	# Canlı entegrasyon yok: hemen başarısız sonuç bildir.
	rewarded_finished.emit.call_deferred(placement, false)


func purchase_available(_product_id: String) -> bool:
	return false


func ads_removed() -> bool:
	return true
