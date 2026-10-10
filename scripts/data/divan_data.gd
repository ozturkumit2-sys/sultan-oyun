class_name DivanData
extends RefCounted
## Divan gündem maddeleri ve halk dilekçeleri.
## "stance": kişilik özelliklerine göre devlet adamlarının tutumu (özellik-50)*ağırlık
## "roles": makama göre ek tutum (ör. hazine nazırı masraflı kararlara karşı)

const AGENDA := {
	"kuraklik": {
		"title": "{prov:loc} Kuraklık", "bind": {"prov_where": "kuraklik"},
		"text": "{prov} eyaletinde tahıl ambarları boşalıyor ({gida} aylık stok kaldı). Vali yardım istiyor; köylerden şehre göç başladı.",
		"options": [
			{"text": "Hazineden tahıl gönderilsin ({cost_food}).", "fx": [{"op": "treasury", "v": "-$cost_food"}, {"op": "gida", "prov": "$prov", "v": 3.0}, {"op": "prov", "id": "$prov", "stat": "huzur", "v": 8}, {"op": "state", "stat": "people_rep", "v": 2}],
				"stance": {"merhamet": 0.6, "hirs": -0.2}, "roles": {"hazine": -12, "adalet": 8}},
			{"text": "Eyalet altı ay vergiden muaf tutulsun.", "fx": [{"op": "exempt", "prov": "$prov", "months": 6}, {"op": "mod", "prov": "$prov", "stat": "huzur", "v": 12, "days": 180}, {"op": "gida", "prov": "$prov", "v": 0.8}],
				"stance": {"merhamet": 0.4, "zeka": 0.2}, "roles": {"hazine": -6, "sadrazam": 6}},
			{"text": "Ambarlar ve su kanalı yaptırılsın (uzun vadeli).", "fx": [{"op": "project", "prov": "$prov", "type": "ambar"}, {"op": "prov", "id": "$prov", "stat": "huzur", "v": 3}],
				"stance": {"zeka": 0.5, "sabir": 0.4}, "roles": {"sadrazam": 10, "hazine": 4}},
			{"text": "Halk kendi çaresine baksın.", "fx": [{"op": "prov", "id": "$prov", "stat": "huzur", "v": -12}, {"op": "prov", "id": "$prov", "stat": "sadakat", "v": -6}, {"op": "state", "stat": "people_rep", "v": -3}],
				"stance": {"merhamet": -0.6, "hirs": 0.2}, "roles": {"hazine": 10, "adalet": -15}},
		]
	},
	"huzursuzluk": {
		"title": "{prov:loc} Huzursuzluk", "bind": {"prov_lowest": "huzur", "below": 42},
		"text": "{prov} eyaletinde halk huzuru tehlikeli seviyede (%{huzur}). Çarşılarda kapanan dükkânlar, sokaklarda toplanan kalabalıklar var.",
		"options": [
			{"text": "Asker gönderilsin, asayiş sağlansın.", "fx": [{"op": "treasury", "v": -5000}, {"op": "prov", "id": "$prov", "stat": "guvenlik", "v": 15}, {"op": "prov", "id": "$prov", "stat": "huzur", "v": -3}, {"op": "mod", "prov": "$prov", "stat": "huzur", "v": 5, "days": 90}],
				"stance": {"cesaret": 0.5, "merhamet": -0.4}, "roles": {"ordu": 15, "adalet": -6}},
			{"text": "Ayanla müzakere edilsin, talepleri dinlensin.", "fx": [{"op": "treasury", "v": -3000}, {"op": "prov", "id": "$prov", "stat": "sadakat", "v": 8}, {"op": "mod", "prov": "$prov", "stat": "huzur", "v": 8, "days": 120}],
				"stance": {"diplomasi": 0.6, "sabir": 0.3}, "roles": {"diplomasi": 10, "sadrazam": 5}},
			{"text": "Vali azledilsin, yenisi gönderilsin.", "fx": [{"op": "treasury", "v": -1500}, {"op": "prov", "id": "$prov", "stat": "sadakat", "v": 10}, {"op": "prov", "id": "$prov", "stat": "huzur", "v": 5}, {"op": "governor", "prov": "$prov", "name": "Vali Selman Bey"}],
				"stance": {"durustluk": 0.4, "cesaret": 0.2}, "roles": {"adalet": 8, "sadrazam": -4}},
		]
	},
	"ulufe": {
		"title": "Askerin Ulufesi", "bind": {}, "cond": {"min_day": 2},
		"text": "Ocaklardan haber var: askerin üç aylık ulufesi gecikmiş. Tolga Paşa ödeme yapılmazsa söylenmelerin isyana dönebileceğini söylüyor.",
		"options": [
			{"text": "Ulufe derhâl ve bahşişle ödensin.", "fx": [{"op": "treasury", "v": -7000}, {"op": "mod", "prov": "*", "stat": "guvenlik", "v": 4, "days": 120}, {"op": "rel", "a": "tolga", "b": "sultan", "d": {"sevgi": 5}}, {"op": "state", "stat": "legitimacy", "v": 2}],
				"stance": {"cesaret": 0.3, "hirs": 0.2}, "roles": {"ordu": 20, "hazine": -14}},
			{"text": "Sadece borç ödensin, bahşiş yok.", "fx": [{"op": "treasury", "v": -4500}],
				"stance": {"sabir": 0.3, "zeka": 0.3}, "roles": {"hazine": 6, "ordu": -3}},
			{"text": "Hazine boş; asker beklesin.", "fx": [{"op": "mod", "prov": "*", "stat": "guvenlik", "v": -6, "days": 90}, {"op": "rel", "a": "tolga", "b": "sultan", "d": {"sevgi": -8, "siyasi_uyum": -6}}, {"op": "state", "stat": "legitimacy", "v": -3}],
				"stance": {"cesaret": -0.3}, "roles": {"hazine": 12, "ordu": -25}},
		]
	},
	"ticaret_yolu": {
		"title": "Demirkapı Ticaret Yolu", "bind": {}, "cond": {"min_day": 1},
		"text": "Varenya tüccarları Demirkapı geçidinin genişletilmesini istiyor. Yol yapılırsa kervanlar iki katına çıkabilir; Varenya ile ilişkiler de ısınır.",
		"options": [
			{"text": "Yol yapılsın (18.000 akçe, 4 ay).", "fx": [{"op": "project", "prov": "demirkapi", "type": "yol"}, {"op": "nb", "id": "varenya", "stat": "attitude", "v": 5}],
				"stance": {"zeka": 0.4, "diplomasi": 0.4}, "roles": {"diplomasi": 14, "hazine": 4, "ordu": -6}},
			{"text": "Varenya masrafın yarısını üstlenirse olur.", "fx": [{"op": "nb", "id": "varenya", "stat": "attitude", "v": -1}, {"op": "flag", "k": "varenya_pazarlik"}, {"op": "sched", "event": "varenya_cevap", "days": 6}],
				"stance": {"diplomasi": 0.5, "hirs": 0.3}, "roles": {"hazine": 10, "diplomasi": 6}},
			{"text": "Sınırı yabancı kervanlara açmanın zamanı değil.", "fx": [{"op": "nb", "id": "varenya", "stat": "attitude", "v": -4}],
				"stance": {"cesaret": 0.2, "diplomasi": -0.4}, "roles": {"ordu": 10, "diplomasi": -12}},
		]
	},
	"saray_masraf": {
		"title": "Saray Masrafları", "bind": {}, "cond": {"min_day": 4, "palace_ge": 1},
		"text": "Kemal Bey, saray mutfağı ve harem masraflarının hazineyi zorladığını söylüyor. Valide Sultan ise saray görkeminin devletin itibarı olduğunu savunuyor.",
		"options": [
			{"text": "Saray masrafları kısılsın.", "fx": [{"op": "palace", "v": -1}, {"op": "rel", "a": "mahinur", "b": "sultan", "d": {"siyasi_uyum": -6, "sevgi": -2}}, {"op": "rel", "a": "kemal", "b": "sultan", "d": {"saygi": 5, "siyasi_uyum": 6}}],
				"stance": {"durustluk": 0.3, "hirs": -0.3}, "roles": {"hazine": 18, "saray": -15}},
			{"text": "Olduğu gibi kalsın.", "fx": [],
				"stance": {"sabir": 0.2}, "roles": {"saray": 5}},
			{"text": "Aksine, sarayın görkemi artırılsın.", "fx": [{"op": "palace", "v": 1}, {"op": "rel", "a": "mahinur", "b": "sultan", "d": {"siyasi_uyum": 5}}, {"op": "rel", "a": "kemal", "b": "sultan", "d": {"saygi": -5}}],
				"stance": {"hirs": 0.4, "ozguven": 0.3}, "roles": {"hazine": -20, "saray": 15}},
		]
	},
	"kadi_harci": {
		"title": "Mahkeme Harçları", "bind": {}, "cond": {"min_day": 3},
		"text": "Kadıasker Nurettin Efendi, taşra kadılarının keyfî harçlarla halkı soyduğunu, sabit ve düşük bir harç tarifesi konmasını öneriyor.",
		"options": [
			{"text": "Sabit harç tarifesi konsun.", "fx": [{"op": "state", "stat": "justice", "v": 6}, {"op": "mod", "prov": "*", "stat": "huzur", "v": 3, "days": 240}, {"op": "treasury", "v": -2000}],
				"stance": {"durustluk": 0.6, "merhamet": 0.3}, "roles": {"adalet": 22, "hazine": -6}},
			{"text": "Kadılar denetlensin ama harçlar kalsın.", "fx": [{"op": "state", "stat": "justice", "v": 2}],
				"stance": {"sabir": 0.3}, "roles": {"adalet": 4}},
			{"text": "Kadıların işine karışılmasın.", "fx": [{"op": "state", "stat": "justice", "v": -3}, {"op": "rel", "a": "nurettin", "b": "sultan", "d": {"saygi": -4}}],
				"stance": {"durustluk": -0.4}, "roles": {"adalet": -20}},
		]
	},
	"liman": {
		"title": "Deryabent Limanı", "bind": {}, "cond": {"min_day": 6},
		"text": "Deryabent'in kaptanları limanın büyük gemiler için dar kaldığını, Elandor tüccarlarının başka limanlara yöneldiğini söylüyor.",
		"options": [
			{"text": "Liman genişletilsin (32.000 akçe, 6 ay).", "fx": [{"op": "project", "prov": "deryabent", "type": "liman"}, {"op": "nb", "id": "elandor", "stat": "attitude", "v": 4}],
				"stance": {"zeka": 0.4, "hirs": 0.3}, "roles": {"diplomasi": 8, "hazine": -4}},
			{"text": "Şimdilik bekleyelim.", "fx": [],
				"stance": {"sabir": 0.4}, "roles": {"hazine": 8}},
		]
	},
	"korvath_sinir": {
		"title": "Karaburç'ta Sınır Olayı", "bind": {}, "cond": {"min_day": 5},
		"text": "Korvath süvarileri Karaburç yakınında bir köyü yağmaladı. Köylüler intikam istiyor; Korvath ise 'eşkıya işi' diyerek suçu reddediyor.",
		"options": [
			{"text": "Sert bir uyarı mektubu gönderilsin.", "fx": [{"op": "nb", "id": "korvath", "stat": "attitude", "v": -4}, {"op": "state", "stat": "prestige", "v": 2}, {"op": "prov", "id": "karaburc", "stat": "huzur", "v": 3}],
				"stance": {"cesaret": 0.4, "ozguven": 0.3}, "roles": {"ordu": 10, "diplomasi": -4}},
			{"text": "Sınır kaleleri güçlendirilsin.", "fx": [{"op": "treasury", "v": -6000}, {"op": "prov", "id": "karaburc", "stat": "guvenlik", "v": 12}, {"op": "prov", "id": "karaburc", "stat": "huzur", "v": 5}],
				"stance": {"cesaret": 0.3, "sabir": 0.2}, "roles": {"ordu": 16, "hazine": -8}},
			{"text": "Köylülere tazminat ödenip Korvath'la görüşülsün.", "fx": [{"op": "treasury", "v": -2500}, {"op": "nb", "id": "korvath", "stat": "attitude", "v": 5}, {"op": "prov", "id": "karaburc", "stat": "huzur", "v": 6}],
				"stance": {"diplomasi": 0.5, "merhamet": 0.3}, "roles": {"diplomasi": 16, "ordu": -10}},
		]
	},
	"vergi_sikayet": {
		"title": "Esnaf Loncalarının Feryadı", "bind": {}, "cond": {"tax_ge": 3},
		"text": "Şahriyar esnaf loncaları vergilerin ağırlığından yakınıyor. Kapanan dükkânların sayısı artıyor.",
		"options": [
			{"text": "Vergiler bir kademe indirilsin.", "fx": [{"op": "tax", "v": -1}, {"op": "mod", "prov": "*", "stat": "huzur", "v": 4, "days": 120}],
				"stance": {"merhamet": 0.4}, "roles": {"hazine": -14, "adalet": 6}},
			{"text": "Loncalara geçici muafiyet tanınsın.", "fx": [{"op": "exempt", "prov": "sahriyar", "months": 2}, {"op": "prov", "id": "sahriyar", "stat": "huzur", "v": 6}],
				"stance": {"diplomasi": 0.3}, "roles": {"hazine": -8}},
			{"text": "Devletin ihtiyacı var; vergi aynen kalsın.", "fx": [{"op": "prov", "id": "sahriyar", "stat": "huzur", "v": -5}],
				"stance": {"hirs": 0.3, "merhamet": -0.3}, "roles": {"hazine": 12}},
		]
	},
	"ekmek_fiyati": {
		"title": "Ekmek Pahalılığı", "bind": {}, "cond": {"food_price_gt": 1.25},
		"text": "Tahıl fiyatları yükseldi (endeks {fiyat}). Fırınların önünde kuyruklar uzuyor.",
		"options": [
			{"text": "Devlet ambarları açılsın ({cost_grain}).", "fx": [{"op": "treasury", "v": "-$cost_grain"}, {"op": "gida_all", "v": 0.6}, {"op": "mod", "prov": "*", "stat": "huzur", "v": 4, "days": 60}],
				"stance": {"merhamet": 0.5}, "roles": {"hazine": -10, "adalet": 6}},
			{"text": "Narh (azami fiyat) konsun.", "fx": [{"op": "mod", "prov": "*", "stat": "huzur", "v": 5, "days": 90}, {"op": "mod", "prov": "*", "stat": "refah", "v": -3, "days": 90}],
				"stance": {"durustluk": 0.3, "zeka": -0.2}, "roles": {"adalet": 8, "hazine": 2}},
			{"text": "Piyasa kendi dengesini bulsun.", "fx": [{"op": "mod", "prov": "*", "stat": "huzur", "v": -4, "days": 60}],
				"stance": {"zeka": 0.2, "merhamet": -0.4}, "roles": {"hazine": 8}},
		]
	},
	"medrese": {
		"title": "Molla Sadık'ın Medrese Önerisi", "bind": {}, "cond": {"min_day": 8},
		"text": "Molla Sadık, Şahriyar'da hekim, mühendis ve kâtip yetiştirecek yeni bir medrese kurulmasını öneriyor.",
		"options": [
			{"text": "Medrese kurulsun (14.000 akçe).", "fx": [{"op": "project", "prov": "sahriyar", "type": "medrese"}, {"op": "rel", "a": "sadik", "b": "sultan", "d": {"sevgi": 8, "saygi": 5}}],
				"stance": {"zeka": 0.5, "sabir": 0.3}, "roles": {"adalet": 6, "hazine": -6}},
			{"text": "Şimdi değil.", "fx": [{"op": "rel", "a": "sadik", "b": "sultan", "d": {"sevgi": -2}}],
				"stance": {"zeka": -0.2}, "roles": {"hazine": 8}},
		]
	},
	"sifahane": {
		"title": "Lokman Efendi'nin Şifahanesi", "bind": {"prov_lowest": "saglik", "below": 50}, "cond": {"min_day": 6},
		"text": "Saray Hekimi Lokman Efendi, sağlık durumu kötü olan {prov} eyaletinde bir şifahane kurulmasını öneriyor.",
		"options": [
			{"text": "Şifahane kurulsun (15.000 akçe).", "fx": [{"op": "project", "prov": "$prov", "type": "sifahane"}, {"op": "rel", "a": "lokman", "b": "sultan", "d": {"sevgi": 8}}],
				"stance": {"merhamet": 0.5, "zeka": 0.2}, "roles": {"hazine": -6, "adalet": 4}},
			{"text": "Şimdi değil.", "fx": [],
				"stance": {"merhamet": -0.2}, "roles": {"hazine": 8}},
		]
	},
	"eskiya": {
		"title": "{prov:loc} Eşkıyalık", "bind": {"prov_lowest": "guvenlik", "below": 52},
		"text": "{prov} yollarında eşkıyalar kervan basıyor. Tüccarlar yolu değiştiriyor, vergi gelirleri düşüyor.",
		"options": [
			{"text": "Karakollar kurulsun (11.000 akçe).", "fx": [{"op": "project", "prov": "$prov", "type": "kale"}],
				"stance": {"cesaret": 0.3, "zeka": 0.2}, "roles": {"ordu": 10, "hazine": -4}},
			{"text": "Eşkıyaya af ilan edilsin, teslim olanlar askere alınsın.", "fx": [{"op": "prov", "id": "$prov", "stat": "guvenlik", "v": 7}, {"op": "prov", "id": "$prov", "stat": "huzur", "v": 3}, {"op": "prov", "id": "$prov", "stat": "asker", "v": 3}],
				"stance": {"merhamet": 0.4, "diplomasi": 0.3}, "roles": {"adalet": -6, "ordu": 4}},
			{"text": "Valiler kendi başının çaresine baksın.", "fx": [{"op": "prov", "id": "$prov", "stat": "ticaret", "v": -3}, {"op": "prov", "id": "$prov", "stat": "huzur", "v": -3}],
				"stance": {"sabir": 0.2}, "roles": {"hazine": 6}},
		]
	},
	"isyan_riski": {
		"title": "{prov:loc} İsyan Tehlikesi", "bind": {"prov_lowest": "huzur", "below": 25},
		"text": "{prov} eyaletinde halk silaha sarılmak üzere. Vali kaleye kapandı; şehirde ayanlar kendi adamlarını topluyor.",
		"options": [
			{"text": "Ordu gönderilsin; isyan bastırılsın.", "fx": [{"op": "treasury", "v": -9000}, {"op": "prov", "id": "$prov", "stat": "guvenlik", "v": 20}, {"op": "prov", "id": "$prov", "stat": "pop", "v": -3}, {"op": "prov", "id": "$prov", "stat": "sadakat", "v": -6}, {"op": "mod", "prov": "$prov", "stat": "huzur", "v": 10, "days": 60}],
				"stance": {"cesaret": 0.5, "merhamet": -0.5}, "roles": {"ordu": 20, "adalet": -10}},
			{"text": "Taleplere kulak verilsin: vergi affı ve yardım.", "fx": [{"op": "treasury", "v": -6000}, {"op": "exempt", "prov": "$prov", "months": 6}, {"op": "mod", "prov": "$prov", "stat": "huzur", "v": 18, "days": 180}, {"op": "gida", "prov": "$prov", "v": 2.0}],
				"stance": {"merhamet": 0.5, "diplomasi": 0.3}, "roles": {"hazine": -15, "adalet": 10}},
		]
	},
}

## Dilekçeler (Halk Kabul Salonu)
const PETITIONS := {
	"toprak": {
		"text": "{name}, {prov:abl} geldi. Köydeki tarlasını yerel sipahinin zorla elinden aldığını söylüyor. Sipahi ise tarlanın dedesinden kaldığını iddia ediyor.",
		"options": [
			{"text": "Tarla köylüye iade edilsin.", "fx": [{"op": "state", "stat": "justice", "v": 2}, {"op": "prov", "id": "$prov", "stat": "huzur", "v": 3}, {"op": "prov", "id": "$prov", "stat": "sadakat", "v": -1}], "j": 1},
			{"text": "Kadı tapu kayıtlarını incelesin.", "fx": [{"op": "state", "stat": "justice", "v": 1}, {"op": "rel", "a": "nurettin", "b": "sultan", "d": {"saygi": 2}}], "j": 1},
			{"text": "Sipahinin hakkı korunsun.", "fx": [{"op": "prov", "id": "$prov", "stat": "sadakat", "v": 2}, {"op": "prov", "id": "$prov", "stat": "huzur", "v": -2}, {"op": "state", "stat": "justice", "v": -1}], "j": -1},
		]
	},
	"dul": {
		"text": "{name} isimli bir dul kadın, kocasının Karaburç'ta sınır nöbetinde şehit düştüğünü, üç çocuğuyla yalnız kaldığını söylüyor.",
		"options": [
			{"text": "Kendisine ömür boyu maaş bağlansın.", "fx": [{"op": "treasury", "v": -400}, {"op": "state", "stat": "people_rep", "v": 2}, {"op": "prov", "id": "karaburc", "stat": "sadakat", "v": 2}], "j": 1},
			{"text": "Bir kese altın verilsin.", "fx": [{"op": "treasury", "v": -150}, {"op": "state", "stat": "people_rep", "v": 1}], "j": 0},
			{"text": "Devletin buna ayıracak akçesi yok.", "fx": [{"op": "state", "stat": "people_rep", "v": -2}, {"op": "rel", "a": "arslan", "b": "sultan", "d": {"sevgi": -1}}], "j": -1},
		]
	},
	"gumruk": {
		"text": "Tüccar {name}, Demirkapı gümrüğünde memurların resmî tarifenin iki katını aldığından yakınıyor.",
		"options": [
			{"text": "Gümrük memurları soruşturulsun.", "fx": [{"op": "prov", "id": "demirkapi", "stat": "ticaret", "v": 3}, {"op": "state", "stat": "justice", "v": 2}], "j": 1},
			{"text": "Gümrük resmi indirilsin.", "fx": [{"op": "prov", "id": "demirkapi", "stat": "ticaret", "v": 4}, {"op": "mod", "prov": "demirkapi", "stat": "refah", "v": 3, "days": 120}, {"op": "treasury", "v": -800}], "j": 0},
			{"text": "Tüccarlar her zaman şikâyet eder.", "fx": [{"op": "prov", "id": "demirkapi", "stat": "ticaret", "v": -2}], "j": -1},
		]
	},
	"lonca": {
		"text": "{prov} dokumacılar loncasından {name}, şehre gelen yabancı kumaşların loncayı batırdığını, satışlarının yasaklanmasını istiyor.",
		"options": [
			{"text": "Yabancı kumaşa ek vergi konsun.", "fx": [{"op": "prov", "id": "$prov", "stat": "uretim", "v": 3}, {"op": "prov", "id": "$prov", "stat": "ticaret", "v": -2}], "j": 0},
			{"text": "Loncaya düşük faizli kredi verilsin.", "fx": [{"op": "treasury", "v": -1500}, {"op": "prov", "id": "$prov", "stat": "uretim", "v": 2}, {"op": "prov", "id": "$prov", "stat": "issizlik", "v": -1}], "j": 1},
			{"text": "Serbest ticarete dokunulmasın.", "fx": [{"op": "prov", "id": "$prov", "stat": "ticaret", "v": 2}, {"op": "prov", "id": "$prov", "stat": "huzur", "v": -2}], "j": 0},
		]
	},
	"su_kanali": {
		"text": "{prov} köylerinden {name}, köylerinin suyunun bir ağanın değirmeni için kesildiğini, tarlaların kuruduğunu anlatıyor.",
		"options": [
			{"text": "Su yolu açılsın, ağa cezalandırılsın.", "fx": [{"op": "prov", "id": "$prov", "stat": "tarim", "v": 2}, {"op": "prov", "id": "$prov", "stat": "huzur", "v": 3}, {"op": "state", "stat": "justice", "v": 2}], "j": 1},
			{"text": "Köye yeni bir kuyu açtırılsın.", "fx": [{"op": "treasury", "v": -900}, {"op": "prov", "id": "$prov", "stat": "tarim", "v": 1}, {"op": "prov", "id": "$prov", "stat": "huzur", "v": 2}], "j": 0},
			{"text": "Bu kadının işidir.", "fx": [{"op": "prov", "id": "$prov", "stat": "huzur", "v": -1}], "j": -1},
		]
	},
	"tefeci": {
		"text": "Bakırcı esnafından {name}, bir tefecinin kendisinden aylık yüzde yirmi faiz istediğini, dükkânına el koymak üzere olduğunu söylüyor.",
		"options": [
			{"text": "Faize üst sınır konsun.", "fx": [{"op": "state", "stat": "justice", "v": 3}, {"op": "prov", "id": "sahriyar", "stat": "huzur", "v": 2}, {"op": "prov", "id": "sahriyar", "stat": "ticaret", "v": -1}], "j": 1},
			{"text": "Borcu hazine ödesin.", "fx": [{"op": "treasury", "v": -500}, {"op": "state", "stat": "people_rep", "v": 1}], "j": 0},
			{"text": "Borç borçtur.", "fx": [{"op": "state", "stat": "justice", "v": -1}], "j": -1},
		]
	},
	"kadi_sikayet": {
		"text": "{prov:abl} {name}, kasabanın kadısının rüşvet almadan hiçbir davaya bakmadığını söylüyor ve elinde tanıkların imzası var.",
		"options": [
			{"text": "Kadıasker durumu derhâl soruştursun.", "fx": [{"op": "state", "stat": "justice", "v": 3}, {"op": "rel", "a": "nurettin", "b": "sultan", "d": {"saygi": 3}}, {"op": "prov", "id": "$prov", "stat": "sadakat", "v": 2}], "j": 1},
			{"text": "Kadı başka kasabaya sürülsün.", "fx": [{"op": "state", "stat": "justice", "v": 1}, {"op": "prov", "id": "$prov", "stat": "huzur", "v": 1}], "j": 0},
			{"text": "Kadılar arasındaki işlere karışmam.", "fx": [{"op": "state", "stat": "justice", "v": -2}, {"op": "rel", "a": "nurettin", "b": "sultan", "d": {"saygi": -2}}], "j": -1},
		]
	},
	"yetimhane": {
		"text": "{name}, Şahriyar'daki kimsesiz çocuklar yurdunun çatısının çöktüğünü, kışa hazırlanmak için yardım beklediklerini anlatıyor.",
		"options": [
			{"text": "Yurdun bütün masrafını saray üstlensin.", "fx": [{"op": "treasury", "v": -1200}, {"op": "state", "stat": "people_rep", "v": 3}, {"op": "rel", "a": "ayse", "b": "sultan", "d": {"sevgi": 4}}], "j": 1},
			{"text": "Varlıklı tüccarlar bağış yapmaya davet edilsin.", "fx": [{"op": "state", "stat": "people_rep", "v": 1}], "j": 0},
			{"text": "Vakıflar ilgilensin.", "fx": [{"op": "state", "stat": "people_rep", "v": -1}], "j": -1},
		]
	},
	"asker_yagma": {
		"text": "{prov} köylülerinden {name}, sefere giden bir bölüğün köylerinden zorla erzak topladığını, karşılığını ödemediğini söylüyor.",
		"options": [
			{"text": "Köylülerin zararı hazineden ödensin.", "fx": [{"op": "treasury", "v": -1000}, {"op": "prov", "id": "$prov", "stat": "huzur", "v": 4}], "j": 1},
			{"text": "Bölük komutanı cezalandırılsın.", "fx": [{"op": "state", "stat": "justice", "v": 3}, {"op": "prov", "id": "$prov", "stat": "huzur", "v": 2}, {"op": "rel", "a": "tolga", "b": "sultan", "d": {"siyasi_uyum": -3}}], "j": 1},
			{"text": "Asker de ekmek yemeli.", "fx": [{"op": "prov", "id": "$prov", "stat": "huzur", "v": -3}, {"op": "rel", "a": "tolga", "b": "sultan", "d": {"siyasi_uyum": 2}}], "j": -1},
		]
	},
	"cesme": {
		"text": "{prov} mahallelerinden {name}, mahalle çeşmesinin kuruduğunu, kadınların suyu yarım saatlik yoldan taşıdığını anlatıyor.",
		"options": [
			{"text": "Çeşme onarılsın, yanına bir tane daha yapılsın.", "fx": [{"op": "treasury", "v": -700}, {"op": "prov", "id": "$prov", "stat": "huzur", "v": 3}, {"op": "prov", "id": "$prov", "stat": "saglik", "v": 1}], "j": 1},
			{"text": "Vali ilgilensin.", "fx": [{"op": "prov", "id": "$prov", "stat": "huzur", "v": 1}], "j": 0},
		]
	},
	"gocebe": {
		"text": "Sarıkum obalarından {name}, çiftçilerin otlakları sürüp tarla yaptığını, sürülerinin aç kaldığını söylüyor. Çiftçiler ise toprağın kendilerine verildiğini iddia ediyor.",
		"options": [
			{"text": "Otlaklar obalara geri verilsin.", "fx": [{"op": "prov", "id": "sarikum", "stat": "sadakat", "v": 3}, {"op": "prov", "id": "sarikum", "stat": "tarim", "v": -1}], "j": 0},
			{"text": "Çiftçilerin hakkı korunsun.", "fx": [{"op": "prov", "id": "sarikum", "stat": "tarim", "v": 2}, {"op": "prov", "id": "sarikum", "stat": "sadakat", "v": -3}], "j": 0},
			{"text": "Arazi ikiye bölünsün; sınır taşları dikilsin.", "fx": [{"op": "prov", "id": "sarikum", "stat": "huzur", "v": 3}, {"op": "state", "stat": "justice", "v": 2}], "j": 1},
		]
	},
	"balikci": {
		"text": "Mavikıyı balıkçılarından {name}, Elandor gemilerinin ağlarını yırttığını ve kıyıya yakın avlandığını anlatıyor.",
		"options": [
			{"text": "Kıyıya donanma gönderilsin.", "fx": [{"op": "treasury", "v": -2000}, {"op": "prov", "id": "mavikiyi", "stat": "guvenlik", "v": 6}, {"op": "nb", "id": "elandor", "stat": "attitude", "v": -3}], "j": 0},
			{"text": "Elandor'a diplomatik nota verilsin.", "fx": [{"op": "nb", "id": "elandor", "stat": "attitude", "v": -1}, {"op": "prov", "id": "mavikiyi", "stat": "huzur", "v": 2}], "j": 1},
			{"text": "Balıkçılara zararları ödensin.", "fx": [{"op": "treasury", "v": -600}, {"op": "prov", "id": "mavikiyi", "stat": "huzur", "v": 3}], "j": 1},
		]
	},
}

const PETITIONERS := ["Çiftçi Osman", "Hasanoğlu Mehmet", "Fatma Hatun", "Tüccar Yakup", "Dokumacı Rukiye", "Değirmenci Ali",
	"Ayşe Kadın", "Kervancı Selami", "Bakırcı Yusuf", "Hacer Hatun", "Çoban Davut", "Balıkçı Recep", "Zehra Hatun", "Kasap İsmail",
	"Ebe Hatice", "Demirci Halit", "Şerife Hatun", "Nalbant Ömer", "Mahmut Ağa", "Saraç Nuri"]
