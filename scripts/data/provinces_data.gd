class_name ProvincesData
extends RefCounted
## Zehrâni İmparatorluğu'nun 12 eyaleti ve komşu devletler.
## pop: bin kişi; tarim/uretim/ticaret/altyapi/egitim/saglik/asker/guvenlik/huzur/refah/sadakat: 0-100
## gida: kaç aylık tahıl stoku; issizlik: yüzde

const PROVINCES := [
	{"id": "sahriyar", "name": "Şahriyar", "desc": "Başkent. Liman, çarşılar ve saray burada.", "coastal": true,
		"pop": 420.0, "tarim": 30, "uretim": 62, "ticaret": 85, "gida": 4.0, "refah": 62, "issizlik": 9.0, "guvenlik": 72, "huzur": 64, "sadakat": 78,
		"altyapi": 75, "egitim": 70, "saglik": 60, "asker": 45, "governor": "Şehremini Rüstem Bey"},
	{"id": "kuzeyhan", "name": "Kuzeyhan", "desc": "Kuzeyin sert dağları; maden ocakları ve kararlı insanları.", "coastal": false,
		"pop": 160.0, "tarim": 34, "uretim": 68, "ticaret": 38, "gida": 2.6, "refah": 44, "issizlik": 15.0, "guvenlik": 55, "huzur": 46, "sadakat": 40,
		"altyapi": 40, "egitim": 42, "saglik": 40, "asker": 55, "governor": "Vali Bayram Paşa"},
	{"id": "altinova", "name": "Altınova", "desc": "İmparatorluğun buğday ambarı; uçsuz bucaksız ovalar.", "coastal": false,
		"pop": 280.0, "tarim": 88, "uretim": 35, "ticaret": 45, "gida": 7.0, "refah": 56, "issizlik": 8.0, "guvenlik": 62, "huzur": 60, "sadakat": 66,
		"altyapi": 50, "egitim": 45, "saglik": 50, "asker": 35, "governor": "Vali Sinan Bey"},
	{"id": "deryabent", "name": "Deryabent", "desc": "Büyük liman şehri; tersaneler ve uzak diyarlardan gelen gemiler.", "coastal": true,
		"pop": 230.0, "tarim": 30, "uretim": 58, "ticaret": 86, "gida": 3.5, "refah": 60, "issizlik": 10.0, "guvenlik": 60, "huzur": 58, "sadakat": 62,
		"altyapi": 62, "egitim": 55, "saglik": 58, "asker": 50, "governor": "Kaptan Murtaza Paşa"},
	{"id": "karaburc", "name": "Karaburç", "desc": "Korvath sınırındaki kale şehri; hep tetikte.", "coastal": false,
		"pop": 120.0, "tarim": 40, "uretim": 40, "ticaret": 30, "gida": 2.8, "refah": 38, "issizlik": 18.0, "guvenlik": 66, "huzur": 41, "sadakat": 58,
		"altyapi": 45, "egitim": 35, "saglik": 38, "asker": 82, "governor": "Muhafız Kasım Paşa"},
	{"id": "guneyyurt", "name": "Güneyyurt", "desc": "Çöl kıyısında kervan yolları; Sahmir'e açılan kapı.", "coastal": false,
		"pop": 140.0, "tarim": 32, "uretim": 40, "ticaret": 66, "gida": 2.4, "refah": 47, "issizlik": 13.0, "guvenlik": 50, "huzur": 50, "sadakat": 55,
		"altyapi": 42, "egitim": 38, "saglik": 42, "asker": 45, "governor": "Vali Ferhat Bey"},
	{"id": "yesilvadi", "name": "Yeşilvadi", "desc": "Ormanlar, meyve bahçeleri ve kereste atölyeleri.", "coastal": false,
		"pop": 190.0, "tarim": 66, "uretim": 52, "ticaret": 40, "gida": 5.0, "refah": 55, "issizlik": 9.0, "guvenlik": 64, "huzur": 62, "sadakat": 64,
		"altyapi": 46, "egitim": 48, "saglik": 52, "asker": 35, "governor": "Vali Orhan Bey"},
	{"id": "akdere", "name": "Akdere", "desc": "Nehir vadisi; dokuma tezgâhları ve pirinç tarlaları.", "coastal": false,
		"pop": 210.0, "tarim": 62, "uretim": 66, "ticaret": 50, "gida": 4.5, "refah": 54, "issizlik": 11.0, "guvenlik": 60, "huzur": 57, "sadakat": 60,
		"altyapi": 52, "egitim": 50, "saglik": 50, "asker": 38, "governor": "Vali İlyas Bey"},
	{"id": "ortacesme", "name": "Ortaçeşme", "desc": "Yolların kesiştiği kervansaraylar şehri.", "coastal": false,
		"pop": 150.0, "tarim": 48, "uretim": 45, "ticaret": 72, "gida": 3.8, "refah": 55, "issizlik": 10.0, "guvenlik": 58, "huzur": 58, "sadakat": 62,
		"altyapi": 58, "egitim": 46, "saglik": 46, "asker": 36, "governor": "Vali Hamza Bey"},
	{"id": "demirkapi", "name": "Demirkapı", "desc": "Varenya'ya açılan dağ geçidi ve gümrük kapısı.", "coastal": false,
		"pop": 95.0, "tarim": 30, "uretim": 44, "ticaret": 64, "gida": 2.9, "refah": 50, "issizlik": 12.0, "guvenlik": 62, "huzur": 53, "sadakat": 57,
		"altyapi": 44, "egitim": 40, "saglik": 40, "asker": 60, "governor": "Gümrük Emini Yakup Bey"},
	{"id": "sarikum", "name": "Sarıkum", "desc": "Kurak bozkır; göçebe obalar ve tuz yolları. Bu yıl yağmur yağmadı.", "coastal": false,
		"pop": 85.0, "tarim": 26, "uretim": 28, "ticaret": 34, "gida": 1.2, "refah": 34, "issizlik": 20.0, "guvenlik": 46, "huzur": 38, "sadakat": 50,
		"altyapi": 28, "egitim": 25, "saglik": 30, "asker": 40, "governor": "Vali Cafer Bey", "drought": 4},
	{"id": "mavikiyi", "name": "Mavikıyı", "desc": "Balıkçı kasabaları ve tuzlalar; Elandor kıyılarına komşu.", "coastal": true,
		"pop": 120.0, "tarim": 40, "uretim": 46, "ticaret": 58, "gida": 3.6, "refah": 52, "issizlik": 11.0, "guvenlik": 58, "huzur": 56, "sadakat": 61,
		"altyapi": 48, "egitim": 42, "saglik": 46, "asker": 40, "governor": "Vali Davut Reis"},
]

const NEIGHBORS := [
	{"id": "varenya", "name": "Varenya Krallığı", "ruler": "Kral Aldemar III", "attitude": 55, "strength": 60, "trade": 50,
		"desc": "Batıdaki dağlık krallık. Demirkapı geçidiyle bağlı; ticarete meraklı, temkinli."},
	{"id": "korvath", "name": "Korvath İmparatorluğu", "ruler": "İmparator Vorhan", "attitude": 28, "strength": 80, "trade": 20,
		"desc": "Kuzeydoğudaki güçlü ve yayılmacı imparatorluk. Karaburç sınırında gerginlik var."},
	{"id": "sahmir", "name": "Sahmir Sultanlığı", "ruler": "Sultan Nasreddin", "attitude": 60, "strength": 55, "trade": 65,
		"desc": "Güneydeki zengin kervan sultanlığı. Kültürel bağlar güçlü, rekabet de."},
	{"id": "elandor", "name": "Elandor Prenslikleri", "ruler": "Prensler Meclisi", "attitude": 50, "strength": 40, "trade": 55,
		"desc": "Denizin karşı kıyısındaki tüccar prenslikler. Bölünmüş ama zengin."},
]

## Kamu yatırımları
const PROJECTS := {
	"yol": {"name": "Yol ve Köprü", "cost": 18000, "months": 4, "effects": {"altyapi": 12, "ticaret": 5}, "desc": "Kervanların ve tahılın daha hızlı taşınmasını sağlar."},
	"pazar": {"name": "Kapalı Çarşı / Pazar", "cost": 12000, "months": 3, "effects": {"ticaret": 8, "issizlik": -3}, "desc": "Esnafa yeni dükkânlar, halka iş."},
	"liman": {"name": "Liman Genişletmesi", "cost": 32000, "months": 6, "effects": {"ticaret": 14, "uretim": 4}, "desc": "Sadece kıyı eyaletlerinde. Deniz ticaretini büyütür.", "coastal": true},
	"ambar": {"name": "Tahıl Ambarı", "cost": 9000, "months": 2, "effects": {"gida": 2.0, "ambar": 1}, "desc": "Kıtlıklara karşı stok kapasitesi ve kuraklık direnci."},
	"sifahane": {"name": "Şifahane", "cost": 15000, "months": 4, "effects": {"saglik": 14}, "desc": "Salgın riskini azaltır, nüfus artışını destekler."},
	"medrese": {"name": "Medrese", "cost": 14000, "months": 5, "effects": {"egitim": 12, "uretim": 2}, "desc": "Eğitimli kâtipler, hekimler ve ustalar yetiştirir."},
	"kale": {"name": "Asayiş Karakolları", "cost": 11000, "months": 2, "effects": {"guvenlik": 12}, "desc": "Eşkıyalığı azaltır, vergi toplamayı kolaylaştırır."},
	"su": {"name": "Su Kemeri ve Kanallar", "cost": 16000, "months": 5, "effects": {"tarim": 8, "saglik": 4}, "desc": "Sulama ile verimi artırır, kuraklığa karşı korur."},
}

const TAX_LEVELS := [
	{"name": "Çok Düşük", "rate": 0.08},
	{"name": "Düşük", "rate": 0.12},
	{"name": "Normal", "rate": 0.16},
	{"name": "Yüksek", "rate": 0.21},
	{"name": "Çok Yüksek", "rate": 0.27},
]

const SPEND_LEVELS := ["Mütevazı", "Olağan", "Görkemli"]
const ARMY_LEVELS := ["Azaltılmış", "Olağan", "Güçlendirilmiş"]
