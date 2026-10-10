class_name EventsData
extends RefCounted
## Saray olay şablonları. Koşullar dünya durumuna, ilişkilere ve geçmişe bağlıdır.
## "talk": olay o karakterle konuşulduğunda diyalogda açılır (görüşme talebi).
## fx (etkiler) EventEngine.apply_fx tarafından yorumlanır.

const EVENTS := {
	# ------------------------------------------------------------ ilk gün
	"ilk_gun_valide": {
		"cat": "harem", "talk": "mahinur", "title": "Valide Sultan'ın Nasihati", "expires": 4,
		"text": "Valide Sultan seni dairesine çağırdı: \"Oğlum, baban gözlerini kapadığında bu saray bir anda sessizleşti. Ama sessizlik, sarayda hiçbir zaman huzur demek değildir. Halil Paşa babanın yıllarca mührünü taşıdı; şimdi de seninkini taşımak isteyecek. Ve unutma: tahtın gücü kadar hanedanın geleceği de önemlidir. Feraye zeki, kararlı bir kızdır...\"",
		"options": [
			{"text": "Nasihatini dinleyeceğim, anneciğim.", "fx": [
				{"op": "rel", "a": "mahinur", "b": "sultan", "d": {"sevgi": 5, "siyasi_uyum": 7}},
				{"op": "mem", "who": "mahinur", "type": "destek", "actors": ["sultan"], "emo": 25, "text": "Oğlum nasihatimi dinleyeceğini söyledi.", "key": "valide_nasihat"},
				{"op": "flag", "k": "valide_ittifaki"}],
				"result": "Valide Sultan'ın yüzünde nadir görülen bir gülümseme belirdi."},
			{"text": "Halil Paşa babamın sadrazamıydı; ona da güvenmeliyim.", "fx": [
				{"op": "rel", "a": "mahinur", "b": "sultan", "d": {"siyasi_uyum": -6, "saygi": 2}},
				{"op": "rel", "a": "halil", "b": "sultan", "d": {"guven": 3, "siyasi_uyum": 4}},
				{"op": "mem", "who": "mahinur", "type": "ret", "actors": ["sultan"], "emo": -15, "text": "Oğlum Halil Paşa'yı bana tercih etti.", "key": "valide_nasihat"}],
				"result": "Valide Sultan bir süre sessiz kaldı. \"Babanın oğlusun,\" dedi sadece."},
			{"text": "Kararlarımı kendim vereceğim.", "fx": [
				{"op": "rel", "a": "mahinur", "b": "sultan", "d": {"saygi": 6, "sevgi": -2}},
				{"op": "state", "stat": "legitimacy", "v": 1},
				{"op": "skill", "s": "yonetim", "v": 1}],
				"result": "\"İşte bunu duymak istiyordum,\" dedi Valide Sultan. Ama gözleri hâlâ endişeliydi."},
		]
	},
	"ilk_gun_halil": {
		"cat": "devlet", "talk": "halil", "title": "Sadrazamın Arzı", "expires": 4,
		"text": "Halil Paşa yere kadar eğilip söze girdi: \"Devletlüm, tahtınız mübarek olsun. Hazinede {treasury} var; Sarıkum'da kuraklık başladı ve Karaburç sınırından tedirgin haberler geliyor. Bu ağır yükün gündelik işlerini yaşlı kulunuza bırakırsanız, siz de büyük meselelere vakit ayırırsınız.\"",
		"options": [
			{"text": "Gündelik işleri sana bırakıyorum, Paşa.", "fx": [
				{"op": "rel", "a": "halil", "b": "sultan", "d": {"guven": 6, "siyasi_uyum": 8, "saygi": -2}},
				{"op": "flag", "k": "halil_yetki"},
				{"op": "mod", "prov": "*", "stat": "huzur", "v": 2, "days": 120},
				{"op": "rel", "a": "mahinur", "b": "sultan", "d": {"siyasi_uyum": -5}},
				{"op": "mem", "who": "mahinur", "type": "endise", "actors": ["sultan", "halil"], "emo": -20, "text": "Oğlum devletin dizginlerini Halil Paşa'ya bıraktı.", "key": "halil_yetki"}],
				"result": "Halil Paşa'nın gözlerinde kısa bir zafer parıltısı belirip kayboldu."},
			{"text": "Her mühürden haberim olacak.", "fx": [
				{"op": "rel", "a": "halil", "b": "sultan", "d": {"saygi": 5, "guven": -3, "korku": 4}},
				{"op": "skill", "s": "yonetim", "v": 2},
				{"op": "state", "stat": "legitimacy", "v": 2}],
				"result": "\"Elbette, Sultanım,\" dedi Paşa. Sesi yumuşaktı ama bakışları sertleşmişti."},
			{"text": "Önce hazinenin gerçek durumunu görmek isterim.", "fx": [
				{"op": "rel", "a": "halil", "b": "sultan", "d": {"saygi": 3}},
				{"op": "rel", "a": "kemal", "b": "sultan", "d": {"saygi": 4, "guven": 3}},
				{"op": "sched", "event": "kemal_rapor", "days": 0}],
				"result": "Halil Paşa, Hazine Nazırı Kemal Bey'in size defterleri getireceğini bildirdi."},
		]
	},
	"kayip_yuzuk": {
		"cat": "harem", "title": "Kayıp Zümrüt Yüzük", "expires": 3, "default": 2,
		"text": "Feraye Sultan'ın, Valide Sultan'dan hediye aldığı zümrüt yüzüğü kayboldu. Nedimesi Sümbül Hatun, dün akşam Leyla Sultan'ın nedimesi Nergis'i Feraye'nin dairesinin önünde gördüğünü söylüyor. Harem çalkalanıyor.",
		"options": [
			{"text": "Arslan Ağa sessizce araştırsın.", "fx": [
				{"op": "rel", "a": "feraye", "b": "sultan", "d": {"guven": 3}},
				{"op": "rel", "a": "arslan", "b": "sultan", "d": {"guven": 2}},
				{"op": "sched", "event": "yuzuk_sonuc", "days": 2}],
				"result": "Arslan Ağa başını eğdi: \"İki güne kalmaz, Sultanım.\""},
			{"text": "Nergis Hatun sorgulansın.", "fx": [
				{"op": "flag", "k": "nergis_suclandi"},
				{"op": "rel", "a": "nergis", "b": "sultan", "d": {"sevgi": -10, "korku": 12, "guven": -8}},
				{"op": "rel", "a": "leyla", "b": "sultan", "d": {"sevgi": -6, "guven": -6}},
				{"op": "rel", "a": "sumbul", "b": "sultan", "d": {"siyasi_uyum": 4}},
				{"op": "mem", "who": "nergis", "type": "haksizlik", "actors": ["sultan"], "emo": -40, "text": "Hükümdar beni suçsuz yere sorgulattı.", "key": "nergis_sorgu"},
				{"op": "mem", "who": "leyla", "type": "haksizlik", "actors": ["sultan", "nergis"], "emo": -25, "text": "Nergis'ime hırsız muamelesi yapıldı.", "key": "nergis_sorgu"},
				{"op": "sched", "event": "yuzuk_sonuc", "days": 3}],
				"result": "Nergis gözyaşları içinde sorgulandı. Leyla Sultan'ın kapısı o gün kimseye açılmadı."},
			{"text": "Bir yüzük için saray birbirine girmesin; Feraye'ye yenisi yaptırılsın.", "fx": [
				{"op": "treasury", "v": -2500},
				{"op": "rel", "a": "feraye", "b": "sultan", "d": {"sevgi": 4, "saygi": -2}},
				{"op": "flag", "k": "sumbul_rahat"}],
				"result": "Kuyumcubaşı yeni bir yüzük için çağrıldı. Gerçek hırsız ise hiç bulunamadı."},
		]
	},
	"yuzuk_sonuc": {
		"cat": "harem", "talk": "arslan", "title": "Yüzüğün Peşinde", "expires": 4, "default": 1,
		"text": "Arslan Ağa sesini alçalttı: \"Yüzük, Sümbül Hatun'un nakış sandığında, iplik yumaklarının altında bulundu Sultanım. Sümbül 'yerde buldum, iade edecektim' diyor. Ama Nergis'i suçlayan da oydu.\"",
		"options": [
			{"text": "Sümbül haremden uzaklaştırılsın.", "fx": [
				{"op": "gone", "who": "sumbul", "text": "Sümbül Hatun haremden uzaklaştırıldı."},
				{"op": "rel", "a": "feraye", "b": "sultan", "d": {"saygi": 4, "sevgi": -3}},
				{"op": "rel", "a": "nergis", "b": "sultan", "d": {"sevgi": 10, "guven": 8}},
				{"op": "rel", "a": "leyla", "b": "sultan", "d": {"sevgi": 5, "guven": 5}},
				{"op": "rel", "a": "gulbahar", "b": "sultan", "d": {"saygi": 3}},
				{"op": "state", "stat": "justice", "v": 2}],
				"result": "Sümbül Hatun aynı gün eşyalarını toplayıp saraydan ayrıldı. Harem nefesini tuttu."},
			{"text": "Bir uyarı yeter; yüzük Feraye Sultan'a teslim edilsin.", "fx": [
				{"op": "rel", "a": "sumbul", "b": "sultan", "d": {"korku": 18}},
				{"op": "rel", "a": "feraye", "b": "sultan", "d": {"siyasi_uyum": 3}},
				{"op": "mem", "who": "sumbul", "type": "uyari", "actors": ["sultan"], "emo": -15, "text": "Hükümdar beni uyardı; bir dahaki sefere affetmeyecek.", "key": "sumbul_uyari"},
				{"op": "rel", "a": "nergis", "b": "sultan", "d": {"sevgi": 2}}],
				"result": "Sümbül Hatun titreyerek yüzüğü teslim etti. Feraye Sultan nedimesine uzun uzun baktı."},
			{"text": "Nergis'ten herkesin önünde özür dilensin.", "cond": {"flag": "nergis_suclandi"}, "fx": [
				{"op": "rel", "a": "nergis", "b": "sultan", "d": {"sevgi": 14, "guven": 10, "korku": -8}},
				{"op": "resolve", "who": "nergis", "type": "haksizlik"},
				{"op": "resolve", "who": "leyla", "type": "haksizlik"},
				{"op": "rel", "a": "leyla", "b": "sultan", "d": {"sevgi": 8, "guven": 8, "saygi": 4}},
				{"op": "rel", "a": "sumbul", "b": "sultan", "d": {"korku": 12}},
				{"op": "mem", "who": "nergis", "type": "affedilme", "actors": ["sultan"], "emo": 30, "text": "Hükümdar benden herkesin önünde özür diletti.", "key": "nergis_ozur"},
				{"op": "state", "stat": "justice", "v": 3}],
				"result": "Haremde herkesin önünde Nergis'in adı temize çıkarıldı. Leyla Sultan o akşam size bir teşekkür notu gönderdi."},
		]
	},
	"kemal_rapor": {
		"cat": "devlet", "talk": "kemal", "title": "Hazine Nazırının Endişesi", "expires": 5, "once": true,
		"text": "Kemal Bey defterleri önünüze serdi: \"Sultanım, son iki yıldır hesaplarda küçük ama inatçı açıklar var. Her ay birkaç yüz akçe... Kimseye söylemedim, çünkü elimde delil yok. Ama bu böyle giderse açık büyüyecek.\"",
		"options": [
			{"text": "Gizlice bir denetim yap.", "fx": [
				{"op": "flag", "k": "denetim"},
				{"op": "rel", "a": "kemal", "b": "sultan", "d": {"guven": 6, "saygi": 3}},
				{"op": "lore", "who": "kemal", "idx": 1},
				{"op": "sched", "event": "denetim_sonuc", "days": 4}],
				"result": "Kemal Bey rahatlamış görünüyordu: \"Dört güne kadar size kesin bilgi getiririm.\""},
			{"text": "Arslan Ağa da sana yardım etsin, iş çabuk bitsin.", "fx": [
				{"op": "flag", "k": "denetim"},
				{"op": "rel", "a": "kemal", "b": "sultan", "d": {"guven": 4}},
				{"op": "rel", "a": "yusuf", "b": "sultan", "d": {"korku": 20}},
				{"op": "mem", "who": "yusuf", "type": "tehdit", "actors": ["sultan", "kemal"], "emo": -30, "text": "Hazinede denetim başlatıldı. Muhafızlar defterlere bakıyor.", "key": "denetim"},
				{"op": "sched", "event": "denetim_sonuc", "days": 2}],
				"result": "Muhafızların hazineye girdiğini sarayda duymayan kalmadı."},
			{"text": "Küçük eksikler... Önemli işlerimiz var.", "fx": [
				{"op": "rel", "a": "kemal", "b": "sultan", "d": {"saygi": -5, "guven": -4}},
				{"op": "flag", "k": "denetim_yok"},
				{"op": "sched", "event": "acik_buyudu", "days": 20}],
				"result": "Kemal Bey defterleri sessizce topladı."},
		]
	},
	"acik_buyudu": {
		"cat": "devlet", "talk": "kemal", "title": "Açık Büyüdü", "expires": 6, "once": true,
		"text": "Kemal Bey'in yüzü bembeyaz: \"Sultanım, uyarmıştım. Bu ay hazineden tam 6.000 akçe kayıp. Artık bu bir hata değil, açıkça hırsızlık.\"",
		"options": [
			{"text": "Hemen denetim başlat!", "fx": [
				{"op": "treasury", "v": -6000},
				{"op": "flag", "k": "denetim"},
				{"op": "rel", "a": "kemal", "b": "sultan", "d": {"guven": 2}},
				{"op": "sched", "event": "denetim_sonuc", "days": 2}],
				"result": "Kayıp akçe geri gelmedi; ama denetim başladı."},
			{"text": "Bu senin sorumluluğundaydı, Kemal Bey!", "fx": [
				{"op": "treasury", "v": -6000},
				{"op": "rel", "a": "kemal", "b": "sultan", "d": {"sevgi": -8, "saygi": -4, "korku": 8}},
				{"op": "mem", "who": "kemal", "type": "haksizlik", "actors": ["sultan"], "emo": -30, "text": "Uyardığım hâlde suç bana yıkıldı.", "key": "kemal_suc"}],
				"result": "Kemal Bey hiçbir şey söylemedi. Söyleyecek bir şey kalmamıştı."},
		]
	},
	"denetim_sonuc": {
		"cat": "devlet", "talk": "kemal", "title": "Denetimin Sonucu", "expires": 5, "once": true, "cond": {"alive": "yusuf"},
		"text": "Kemal Bey bir dosyayı masaya bıraktı: \"Açıklar Yusuf Efendi'nin kayıtlarından geçiyor. Mutfak çıraklarının anlattığına göre ağır kumar borçları varmış. Kendisi her şeyi itiraf etti, Sultanım. Kararınızı bekliyor.\"",
		"options": [
			{"text": "Zindana atılsın, malına el konsun.", "fx": [
				{"op": "gone", "who": "yusuf", "text": "Hazine Kâtibi Yusuf Efendi zindana atıldı."},
				{"op": "treasury", "v": 4000},
				{"op": "state", "stat": "justice", "v": 3},
				{"op": "rel", "a": "kemal", "b": "sultan", "d": {"saygi": 5, "guven": 4}},
				{"op": "rel", "a": "dogan", "b": "sultan", "d": {"sevgi": -5, "korku": 8}},
				{"op": "flag", "k": "denetim_bitti"}],
				"result": "Yusuf'un mallarından 4.000 akçe hazineye geri döndü."},
			{"text": "Görevden alınsın ama cezalandırılmasın; borcunu ödesin.", "fx": [
				{"op": "gone", "who": "yusuf", "text": "Yusuf Efendi görevden alındı ve saraydan ayrıldı."},
				{"op": "treasury", "v": 2000},
				{"op": "state", "stat": "justice", "v": 1},
				{"op": "rel", "a": "nurettin", "b": "sultan", "d": {"saygi": 3}},
				{"op": "rel", "a": "kemal", "b": "sultan", "d": {"saygi": 3}},
				{"op": "flag", "k": "denetim_bitti"}],
				"result": "Yusuf saraydan ayrılırken arkasına bakmadı."},
			{"text": "Affedilsin; ona son bir şans tanıyorum.", "fx": [
				{"op": "rel", "a": "yusuf", "b": "sultan", "d": {"sevgi": 15, "borcluluk": 40, "guven": 10}},
				{"op": "mem", "who": "yusuf", "type": "affedilme", "actors": ["sultan"], "emo": 45, "text": "Hükümdar beni affetti. Bunu asla unutmayacağım.", "key": "yusuf_af"},
				{"op": "rel", "a": "kemal", "b": "sultan", "d": {"saygi": -6}},
				{"op": "flag", "k": "yusuf_affedildi"},
				{"op": "flag", "k": "denetim_bitti"},
				{"op": "sched", "event": "yusuf_tekrar", "days": 40}],
				"result": "Yusuf ayaklarınıza kapandı. Kemal Bey ise başını iki yana salladı."},
		]
	},
	"yusuf_tekrar": {
		"cat": "devlet", "talk": "kemal", "title": "Eski Alışkanlıklar", "expires": 5, "once": true, "cond": {"alive": "yusuf", "rel_lt": ["yusuf", "sultan", "borcluluk", 55]},
		"text": "Kemal Bey: \"Sultanım, affettiğiniz Yusuf yine kumar masasında görülmüş. Hesaplarda yeni bir açık yok... henüz.\"",
		"options": [
			{"text": "Bu sefer affetmeyeceğim. Saraydan çıkarılsın.", "fx": [
				{"op": "gone", "who": "yusuf", "text": "Yusuf Efendi saraydan çıkarıldı."},
				{"op": "rel", "a": "kemal", "b": "sultan", "d": {"saygi": 4}}],
				"result": "Kemal Bey rahat bir nefes aldı."},
			{"text": "Kendisiyle ben konuşacağım.", "fx": [
				{"op": "rel", "a": "yusuf", "b": "sultan", "d": {"korku": 15, "borcluluk": 10}},
				{"op": "mem", "who": "yusuf", "type": "uyari", "actors": ["sultan"], "emo": -10, "text": "Hükümdar beni son kez uyardı.", "key": "yusuf_uyari"}],
				"result": "Yusuf bir daha kumar masasına oturmayacağına yemin etti."},
		]
	},
	# ------------------------------------------------------------ ordu ve diplomasi
	"tolga_butce": {
		"cat": "devlet", "talk": "tolga", "title": "Serdarın Talebi", "expires": 5, "once": true, "cond": {"min_day": 1},
		"text": "Tolga Paşa sert bir selam verdi: \"Korvath sınırda at sürüyor, Sultanım. Askerin ulufesi az, silahı eski. Ordunun bütçesi artırılmazsa Karaburç'u tutamam!\"",
		"options": [
			{"text": "Ordunun bütçesi artırılsın.", "fx": [
				{"op": "army", "v": 2},
				{"op": "rel", "a": "tolga", "b": "sultan", "d": {"saygi": 6, "siyasi_uyum": 8, "sevgi": 4}},
				{"op": "rel", "a": "kemal", "b": "sultan", "d": {"siyasi_uyum": -5}},
				{"op": "state", "stat": "prestige", "v": 2}],
				"result": "Ordu ocaklarında davullar çalındı. Kemal Bey ise hesap defterine eğildi."},
			{"text": "Önce Selim Efendi'nin sınır raporunu dinleyelim.", "fx": [
				{"op": "rel", "a": "tolga", "b": "sultan", "d": {"siyasi_uyum": -2}},
				{"op": "rel", "a": "selim", "b": "sultan", "d": {"saygi": 3}},
				{"op": "sched", "event": "selim_rapor", "days": 1}],
				"result": "Tolga Paşa dişlerini sıktı ama boyun eğdi."},
			{"text": "Hazine buna dayanamaz. Talep reddedildi.", "fx": [
				{"op": "rel", "a": "tolga", "b": "sultan", "d": {"sevgi": -6, "siyasi_uyum": -6}},
				{"op": "mem", "who": "tolga", "type": "ret", "actors": ["sultan"], "emo": -25, "text": "Hükümdar ordunun ihtiyaçlarını hiçe saydı.", "key": "tolga_ret"},
				{"op": "rel", "a": "kemal", "b": "sultan", "d": {"saygi": 3}}],
				"result": "Tolga Paşa selam vermeden çıktı."},
		]
	},
	"selim_rapor": {
		"cat": "diplomasi", "talk": "selim", "title": "Sınırdan Gelen Rapor", "expires": 5, "once": true,
		"text": "Selim Efendi bir mektubu uzattı: \"Korvath'ın Karaburç karşısında asker topladığı doğru, Sultanım. Ama bence bu bir saldırı hazırlığı değil, bir pazarlık kozu. Tolga Paşa'nın bunu savaş bahanesi yapmasından korktuğum için raporu bekletiyordum.\"",
		"options": [
			{"text": "Karaburç'a takviye gönderilsin.", "fx": [
				{"op": "treasury", "v": -8000},
				{"op": "prov", "id": "karaburc", "stat": "guvenlik", "v": 10},
				{"op": "prov", "id": "karaburc", "stat": "asker", "v": 8},
				{"op": "rel", "a": "tolga", "b": "sultan", "d": {"saygi": 4, "siyasi_uyum": 4}},
				{"op": "nb", "id": "korvath", "stat": "attitude", "v": -3}],
				"result": "Karaburç kalesine 2.000 asker gönderildi."},
			{"text": "Korvath elçisiyle görüşülsün; gerginlik azaltılsın.", "fx": [
				{"op": "treasury", "v": -3000},
				{"op": "nb", "id": "korvath", "stat": "attitude", "v": 6},
				{"op": "rel", "a": "selim", "b": "sultan", "d": {"saygi": 5, "siyasi_uyum": 6}},
				{"op": "rel", "a": "tolga", "b": "sultan", "d": {"siyasi_uyum": -3}},
				{"op": "skill", "s": "diplomasi", "v": 1}],
				"result": "Selim Efendi kendi eliyle bir mektup yazdı. Sınırda gerginlik bir parça azaldı."},
			{"text": "Bu raporu benden neden sakladınız?", "fx": [
				{"op": "rel", "a": "selim", "b": "sultan", "d": {"korku": 10, "saygi": 2, "guven": -4}},
				{"op": "lore", "who": "selim", "idx": 2}],
				"result": "Selim Efendi özür diledi: \"Bir daha olmayacak, Sultanım.\""},
		]
	},
	"edric_hediye": {
		"cat": "diplomasi", "talk": "edric", "title": "Varenya'nın Hediyesi", "expires": 6, "once": true, "cond": {"min_day": 1},
		"text": "Kont Edric, zarif bir mekanik saati huzurunuza getirdi: \"Kralım Aldemar, yeni Sultan'ın saltanatının saatleri gibi düzenli ve uzun olmasını diliyor. Ve... Demirkapı'dan geçen tüccarlarımız için bir anlaşma umuyor.\"",
		"options": [
			{"text": "Hediyeyi kabul et ve elçi şerefine ziyafet ver.", "fx": [
				{"op": "treasury", "v": -1500},
				{"op": "nb", "id": "varenya", "stat": "attitude", "v": 6},
				{"op": "state", "stat": "prestige", "v": 2},
				{"op": "rel", "a": "edric", "b": "sultan", "d": {"sevgi": 6, "saygi": 4}},
				{"op": "rel", "a": "selim", "b": "sultan", "d": {"siyasi_uyum": 3}}],
				"result": "Ziyafet gece yarısına kadar sürdü. Kont Edric kralına coşkulu bir mektup yazdı."},
			{"text": "Hediyeyi kabul et, ama mesafeyi koru.", "fx": [
				{"op": "nb", "id": "varenya", "stat": "attitude", "v": 2},
				{"op": "rel", "a": "edric", "b": "sultan", "d": {"saygi": 2}}],
				"result": "Saat, taht salonunun bir köşesine yerleştirildi."},
			{"text": "Önce Demirkapı gümrüğündeki kaçakçılık konuşulsun.", "fx": [
				{"op": "rel", "a": "edric", "b": "sultan", "d": {"saygi": 5, "sevgi": -2}},
				{"op": "nb", "id": "varenya", "stat": "attitude", "v": -2},
				{"op": "prov", "id": "demirkapi", "stat": "ticaret", "v": 2},
				{"op": "skill", "s": "diplomasi", "v": 1}],
				"result": "Kont Edric gülümsedi: \"Sultan'ın ticarete bu kadar hâkim olduğunu bilmiyordum.\""},
		]
	},
	# ------------------------------------------------------------ saray siyaseti
	"valide_halil": {
		"cat": "saray", "title": "Valide ile Sadrazam Arasında", "expires": 4, "once": true, "chance": 0.35,
		"cond": {"min_day": 3, "rel_gt": ["mahinur", "halil", "rekabet", 60], "alive": "halil"},
		"text": "Valide Sultan, harem masraflarının kısılması emrini Halil Paşa'nın verdiğini öğrendi. Divan koridorunda yüksek sesle tartıştıkları duyuldu. İkisi de sizin hakemliğinizi bekliyor.",
		"options": [
			{"text": "Valide Sultan'ı destekle.", "fx": [
				{"op": "rel", "a": "mahinur", "b": "sultan", "d": {"sevgi": 5, "siyasi_uyum": 6}},
				{"op": "rel", "a": "halil", "b": "sultan", "d": {"siyasi_uyum": -6, "guven": -3}},
				{"op": "mem", "who": "halil", "type": "ret", "actors": ["sultan", "mahinur"], "emo": -20, "text": "Hükümdar beni Valide'nin önünde küçük düşürdü.", "key": "valide_halil"}],
				"result": "Harem masrafları eski düzeyine döndü. Halil Paşa'nın sessizliği her şeyden yüksekti."},
			{"text": "Halil Paşa'yı destekle.", "fx": [
				{"op": "rel", "a": "halil", "b": "sultan", "d": {"siyasi_uyum": 6, "guven": 4}},
				{"op": "rel", "a": "mahinur", "b": "sultan", "d": {"sevgi": -4, "siyasi_uyum": -7}},
				{"op": "mem", "who": "mahinur", "type": "ret", "actors": ["sultan", "halil"], "emo": -25, "text": "Oğlum Halil'in yanında durdu.", "key": "valide_halil"},
				{"op": "treasury", "v": 800}],
				"result": "Valide Sultan dairesine çekildi ve o akşam yemeğe inmedi."},
			{"text": "İkiniz de bu sarayın direklerisiniz. Uzlaşın.", "fx": [
				{"op": "rel", "a": "mahinur", "b": "sultan", "d": {"saygi": 2}},
				{"op": "rel", "a": "halil", "b": "sultan", "d": {"saygi": 2}},
				{"op": "rel", "a": "mahinur", "b": "halil", "d": {"rekabet": -5}},
				{"op": "rel", "a": "halil", "b": "mahinur", "d": {"rekabet": -5}},
				{"op": "skill", "s": "diplomasi", "v": 1}],
				"result": "Soğuk bir ateşkes ilan edildi. Kimse memnun değildi, ama kimse de kırılmadı."},
		]
	},
	"arslan_tolga": {
		"cat": "saray", "talk": "arslan", "title": "Eski Bir Yara", "expires": 5, "once": true, "chance": 0.25,
		"cond": {"min_day": 5, "rel_gt": ["arslan", "tolga", "rekabet", 62], "alive": "tolga"},
		"text": "Arslan Ağa her zamankinden gergin: \"Sultanım, Tolga Paşa'nın adamları ocaklarda 'genç Sultan savaştan korkuyor' diye dolaşıyor. Askeri kışkırtıyorlar. Bunu yüzüne söyleyecek kadar cesaretim var; size söylemek ise borcum.\"",
		"options": [
			{"text": "Sessizce araştır ve bana kanıt getir.", "fx": [
				{"op": "rel", "a": "arslan", "b": "sultan", "d": {"guven": 5}},
				{"op": "lore", "who": "tolga", "idx": 2},
				{"op": "lore", "who": "arslan", "idx": 2},
				{"op": "rel", "a": "tolga", "b": "sultan", "d": {"korku": 6}}],
				"result": "Arslan Ağa size eski seferin hikâyesini anlattı. Bazı yaralar hiç kapanmıyor."},
			{"text": "Kişisel kinini devlet işine karıştırma, Ağa.", "fx": [
				{"op": "rel", "a": "arslan", "b": "sultan", "d": {"sevgi": -6, "saygi": 2}},
				{"op": "mem", "who": "arslan", "type": "ret", "actors": ["sultan"], "emo": -20, "text": "Hükümdar uyarımı kişisel kin saydı.", "key": "arslan_ret"},
				{"op": "rel", "a": "tolga", "b": "sultan", "d": {"siyasi_uyum": 3}}],
				"result": "Arslan Ağa başını eğdi ve sustu."},
			{"text": "İkisini de çağırın. Bu kin bugün bitecek.", "fx": [
				{"op": "rel", "a": "arslan", "b": "tolga", "d": {"rekabet": -12}},
				{"op": "rel", "a": "tolga", "b": "arslan", "d": {"rekabet": -10}},
				{"op": "rel", "a": "tolga", "b": "sultan", "d": {"saygi": 4}},
				{"op": "rel", "a": "arslan", "b": "sultan", "d": {"saygi": 3}},
				{"op": "skill", "s": "diplomasi", "v": 2}],
				"result": "İki eski asker uzun süre birbirine baktı. Sonunda Tolga elini uzattı."},
		]
	},
	"bora_golge": {
		"cat": "saray", "talk": "bora", "title": "Gece Gölgesi", "expires": 4, "once": true, "chance": 0.3,
		"cond": {"min_day": 2, "not_flag": "denetim_bitti", "alive": "yusuf"},
		"text": "Muhafız Bora, gece nöbetinden sonra huzurunuza çıktı: \"Gece yarısından sonra hazine dairesinin önünde bir gölge gördüm, Sultanım. Seslendiğimde kaçtı. Kâtip cübbesi gibiydi...\"",
		"options": [
			{"text": "Hazinede hemen denetim başlatılsın.", "fx": [
				{"op": "flag", "k": "denetim"},
				{"op": "rel", "a": "bora", "b": "sultan", "d": {"saygi": 3, "sevgi": 4}},
				{"op": "rel", "a": "kemal", "b": "sultan", "d": {"guven": 3}},
				{"op": "sched", "event": "denetim_sonuc", "days": 2}],
				"result": "Kemal Bey hazine defterlerini yeniden açtı."},
			{"text": "Aferin Bora. Gözlerini dört aç; işte sana bir kese.", "fx": [
				{"op": "treasury", "v": -300},
				{"op": "rel", "a": "bora", "b": "sultan", "d": {"sevgi": 8, "borcluluk": 10}},
				{"op": "mem", "who": "bora", "type": "odul", "actors": ["sultan"], "emo": 25, "text": "Hükümdar beni bizzat ödüllendirdi.", "key": "bora_odul"}],
				"result": "Bora keseyi alıp coşkuyla selam verdi."},
			{"text": "Uykusuzluktan hayal görmüşsün.", "fx": [
				{"op": "rel", "a": "bora", "b": "sultan", "d": {"sevgi": -5, "saygi": -2}}],
				"result": "Bora utanarak geri çekildi."},
		]
	},
	"riza_dedikodu": {
		"cat": "saray", "talk": "riza", "title": "Kâtibin Kulağı", "expires": 3, "chance": 0.3, "cooldown": 4,
		"cond": {"min_day": 1},
		"text": "Rıza Efendi elinde bir tomar kâğıtla yaklaştı ve sesini alçalttı: \"Sultanım, saray koridorlarında son günlerde bazı şeyler konuşuluyor. Bilmek ister misiniz?\"",
		"options": [
			{"text": "Anlat bakalım.", "fx": [
				{"op": "reveal", "n": 3},
				{"op": "rel", "a": "riza", "b": "sultan", "d": {"guven": 2, "arkadaslik": 2}}],
				"result": "Rıza Efendi duyduklarını bir bir sıraladı. (Günlük'e eklendi.)"},
			{"text": "Anlat; bu da emeğin karşılığı.", "fx": [
				{"op": "treasury", "v": -200},
				{"op": "reveal", "n": 4},
				{"op": "rel", "a": "riza", "b": "sultan", "d": {"sevgi": 4, "borcluluk": 6}}],
				"result": "Rıza Efendi keseyi cübbesine sakladı ve anlatmaya başladı. (Günlük'e eklendi.)"},
			{"text": "Dedikoduyla değil, gerçeklerle yönetirim.", "fx": [
				{"op": "rel", "a": "riza", "b": "sultan", "d": {"saygi": 3, "arkadaslik": -2}},
				{"op": "rel", "a": "nurettin", "b": "sultan", "d": {"saygi": 2}}],
				"result": "Rıza Efendi kâğıtlarını toplayıp eğildi."},
		]
	},
	"nedime_kavga": {
		"cat": "harem", "talk": "gulbahar", "title": "Haremde Kavga", "expires": 3, "chance": 0.25, "cooldown": 15,
		"cond": {"min_day": 3, "alive": "sumbul", "rel_gt": ["sumbul", "nergis", "rekabet", 58]},
		"text": "Kethüda Gülbahar Hatun huzurunuza geldi: \"Sümbül ile Nergis bu sabah hamamda saç saça baş başa kavga ettiler, Sultanım. İkisi de diğerinin başladığını söylüyor. Haremde düzen bozulmasın.\"",
		"options": [
			{"text": "Haremin düzeni senin işin, Gülbahar Hatun. Sen karar ver.", "fx": [
				{"op": "rel", "a": "gulbahar", "b": "sultan", "d": {"saygi": 3, "guven": 3}},
				{"op": "rel", "a": "sumbul", "b": "nergis", "d": {"rekabet": 4}}],
				"result": "Gülbahar Hatun ikisine de birer hafta mutfak hizmeti verdi."},
			{"text": "Sümbül haksız; Nergis'e dokunulmasın.", "fx": [
				{"op": "rel", "a": "sumbul", "b": "sultan", "d": {"sevgi": -6}},
				{"op": "rel", "a": "feraye", "b": "sultan", "d": {"siyasi_uyum": -2}},
				{"op": "rel", "a": "nergis", "b": "sultan", "d": {"sevgi": 6, "guven": 4}},
				{"op": "rel", "a": "leyla", "b": "sultan", "d": {"sevgi": 2}}],
				"result": "Sümbül öfkeyle dairesine çekildi."},
			{"text": "Nergis haksız; Sümbül'e dokunulmasın.", "fx": [
				{"op": "rel", "a": "nergis", "b": "sultan", "d": {"sevgi": -6}},
				{"op": "rel", "a": "leyla", "b": "sultan", "d": {"sevgi": -3}},
				{"op": "rel", "a": "sumbul", "b": "sultan", "d": {"sevgi": 6}},
				{"op": "rel", "a": "feraye", "b": "sultan", "d": {"siyasi_uyum": 2}}],
				"result": "Nergis'in gözleri doldu; Leyla Sultan onu teselli etti."},
		]
	},
	# ------------------------------------------------------------ gönül işleri
	"leyla_gazel": {
		"cat": "harem", "title": "Bir Gazel", "expires": 4, "once": true, "chance": 0.35,
		"cond": {"min_day": 2, "rel_gt": ["leyla", "sultan", "romantik", 34], "not_married": "leyla"},
		"text": "Nergis Hatun utangaç bir tavırla katlanmış bir kâğıt uzattı. İmzasız bir gazel: \"Bir kandil yanar sarayın uzak köşesinde / ışığı dokunmaz kimseye, kimse bilmez kimin için yandığını.\" Kimden geldiğini sormanıza gerek yok.",
		"options": [
			{"text": "Kendi elimle bir cevap yazacağım.", "fx": [
				{"op": "rel", "a": "leyla", "b": "sultan", "d": {"romantik": 9, "sevgi": 4}},
				{"op": "mem", "who": "leyla", "type": "jest", "actors": ["sultan"], "emo": 35, "text": "Hükümdar gazelime kendi eliyle cevap yazdı.", "key": "leyla_gazel"},
				{"op": "skill", "s": "ilim", "v": 1}],
				"result": "Cevabınızı Nergis götürdü. O gece Leyla Sultan'ın odasında ud sesi geç saatlere kadar sürdü."},
			{"text": "Gazeli ona bizzat okuyacağım.", "fx": [
				{"op": "rel", "a": "leyla", "b": "sultan", "d": {"romantik": 6, "guven": 4}},
				{"op": "override", "who": "leyla", "room": "harem_bahce", "activity": "gezinti", "minutes": 240},
				{"op": "mem", "who": "leyla", "type": "jest", "actors": ["sultan"], "emo": 25, "text": "Hükümdar gazelimi okumak için beni bulacak.", "key": "leyla_gazel"}],
				"result": "Nergis, Leyla Sultan'ın bu öğleden sonra Harem Bahçesi'nde olacağını fısıldadı."},
			{"text": "Sessiz kal.", "fx": [
				{"op": "rel", "a": "leyla", "b": "sultan", "d": {"romantik": -4}},
				{"op": "mood", "who": "leyla", "v": -8}],
				"result": "Gazelin cevapsız kaldığını bilen tek kişi Nergis'ti."},
		]
	},
	"feraye_davet": {
		"cat": "harem", "title": "Gün Batımında Davet", "expires": 1, "once": true, "chance": 0.35,
		"cond": {"min_day": 2, "rel_gt": ["feraye", "sultan", "romantik", 34], "not_married": "feraye", "hour_lt": 16},
		"text": "Sümbül Hatun bir davetle geldi: \"Feraye Sultan, bu akşam gün batarken Harem Bahçesi'ndeki köşkte sizi bekleyecek. Size Sahmir'den getirttiği bir şeyi göstermek istiyor.\"",
		"options": [
			{"text": "Orada olacağım.", "fx": [
				{"op": "flag", "k": "feraye_randevu", "v": "$day"},
				{"op": "override", "who": "feraye", "room": "harem_bahce", "activity": "dinlenme", "minutes": 420}],
				"result": "Harem Bahçesi'ndeki köşke akşam 18:00 ile 20:00 arasında gitmeyi unutmayın."},
			{"text": "Devlet işlerim var; başka bir zaman.", "fx": [
				{"op": "rel", "a": "feraye", "b": "sultan", "d": {"romantik": -3, "saygi": 2}}],
				"result": "Sümbül hayal kırıklığını gizlemeye çalışarak çekildi."},
		]
	},
	"feraye_bulusma": {
		"cat": "harem", "talk": "feraye", "title": "Köşkte Gün Batımı", "expires": 1, "once": true,
		"text": "Feraye Sultan, köşkün sedirinde, elinde gümüş işlemeli bir usturlapla bekliyordu: \"Sahmirli denizciler bununla yıldızlardan yol bulur. Ben de saraydaki yolumu böyle buluyorum, Sultanım: gökyüzüne bakarak ve hiç pes etmeyerek. Ailem bir kervan baskınında her şeyini kaybettiğinde bana sadece bu kaldı.\"",
		"options": [
			{"text": "Yolunu bulduğun yer burası olsun; yanımda.", "fx": [
				{"op": "rel", "a": "feraye", "b": "sultan", "d": {"romantik": 12, "sevgi": 6, "guven": 4}},
				{"op": "lore", "who": "feraye", "idx": 1},
				{"op": "mem", "who": "feraye", "type": "jest", "actors": ["sultan"], "emo": 40, "text": "Gün batımında köşkte bana yanında olmamı istediğini söyledi.", "key": "feraye_kosk"}],
				"result": "Güneş denizin ardında kaybolurken Feraye ilk kez sizinle hiç hesap yapmadan konuştu."},
			{"text": "Hırsın beni hem etkiliyor hem korkutuyor.", "fx": [
				{"op": "rel", "a": "feraye", "b": "sultan", "d": {"romantik": -2, "saygi": 4, "guven": 5}},
				{"op": "lore", "who": "feraye", "idx": 1}],
				"result": "Feraye güldü: \"Korkmayın. Hırsım sizin için çalışırsa, size zarar vermez.\""},
			{"text": "Sahmir'e yazdığın mektuplardan bahset bana.", "cond": {"lore": ["feraye", 2]}, "fx": [
				{"op": "rel", "a": "feraye", "b": "sultan", "d": {"korku": 10, "saygi": 6}},
				{"op": "flag", "k": "feraye_ag"},
				{"op": "nb", "id": "sahmir", "stat": "attitude", "v": 4}],
				"result": "Feraye bir an dondu, sonra gözlerinin içine bakarak itiraf etti: kuzeni aracılığıyla Sahmir sarayının sırlarını öğreniyordu. \"Bu ağ artık sizin,\" dedi."},
		]
	},
	"valide_evlilik": {
		"cat": "aile", "talk": "mahinur", "title": "Hanedanın Geleceği", "expires": 6, "once": true, "chance": 0.3,
		"cond": {"min_day": 6, "no_wife": true},
		"text": "Valide Sultan: \"Oğlum, tahtın bir vârisi olmalı. Bu sarayda gözünün içine bakan iki kız var; biri şiir yazıyor, öteki dünyayı okuyor. Ben Feraye'yi seçerdim. Ama karar senin.\"",
		"options": [
			{"text": "Feraye'yi düşüneceğim.", "fx": [
				{"op": "rel", "a": "mahinur", "b": "sultan", "d": {"sevgi": 4, "siyasi_uyum": 4}},
				{"op": "rel", "a": "feraye", "b": "sultan", "d": {"romantik": 4}},
				{"op": "rel", "a": "leyla", "b": "feraye", "d": {"kiskanclik": 6}}],
				"result": "Valide Sultan memnun bir şekilde başını salladı."},
			{"text": "Gönlüm Leyla'ya akıyor.", "cond": {"rel_gt": ["leyla", "sultan", "romantik", 38]}, "fx": [
				{"op": "rel", "a": "mahinur", "b": "sultan", "d": {"siyasi_uyum": -4, "saygi": 2}},
				{"op": "rel", "a": "leyla", "b": "sultan", "d": {"romantik": 5}},
				{"op": "rel", "a": "feraye", "b": "leyla", "d": {"kiskanclik": 10, "rekabet": 6}},
				{"op": "mem", "who": "feraye", "type": "kiskanclik", "actors": ["sultan", "leyla"], "emo": -25, "text": "Hükümdarın gönlünün Leyla'ya kaydığını duydum.", "key": "gonul_leyla"}],
				"result": "Valide Sultan iç çekti: \"Leyla iyi bir kızdır. Ama sarayda iyilik yetmez.\""},
			{"text": "Evlilik için acele etmeyeceğim.", "fx": [
				{"op": "rel", "a": "mahinur", "b": "sultan", "d": {"saygi": 2, "sevgi": -2}}],
				"result": "\"Zaman da bir hükümdar kadar sabırsızdır, oğlum,\" dedi Valide Sultan."},
		]
	},
	# ------------------------------------------------------------ Davud Bey davası
	"davud_dosyasi": {
		"cat": "saray", "talk": "riza", "title": "Mühürlü Dosya", "expires": 7, "once": true,
		"cond": {"any_lore": [["leyla", 2], ["riza", 2], ["halil", 2], ["nurettin", 2]]},
		"text": "Rıza Efendi kütüphanenin en arka rafından tozlu bir dosya çıkardı: \"Kuzeyhan valisi Davud Bey'in idam dosyası, Sultanım. Yanması emredilmişti. Ama içindeki tanık ifadelerinden ikisi aynı kâtibin elinden çıkma... ve tarihleri tutmuyor.\"",
		"options": [
			{"text": "Kadıasker Nurettin Efendi davayı yeniden görsün.", "fx": [
				{"op": "flag", "k": "davud_acildi"},
				{"op": "rel", "a": "nurettin", "b": "sultan", "d": {"saygi": 10, "sevgi": 6}},
				{"op": "rel", "a": "riza", "b": "sultan", "d": {"guven": 4, "korku": 4}},
				{"op": "crime", "who": "halil", "type": "iftira", "v": 35, "note": "Davud Bey dosyasında tarihleri tutmayan tanık ifadeleri."},
				{"op": "rel", "a": "halil", "b": "sultan", "d": {"korku": 10, "siyasi_uyum": -6}},
				{"op": "mem", "who": "halil", "type": "tehdit", "actors": ["sultan"], "emo": -30, "text": "Hükümdar Davud dosyasını yeniden açtırdı.", "key": "davud_acildi"},
				{"op": "sched", "event": "davud_sonuc", "days": 7}],
				"result": "Nurettin Efendi dosyayı alırken elleri titriyordu: \"Yedi gün içinde gerçeği önünüze koyacağım.\""},
			{"text": "Dosyayı bana bırak; sessizce inceleyeceğim.", "fx": [
				{"op": "flag", "k": "davud_gizli"},
				{"op": "lore", "who": "halil", "idx": 2},
				{"op": "rel", "a": "riza", "b": "sultan", "d": {"guven": 5}}],
				"result": "Dosyayı gece boyu okudunuz. Halil Paşa'nın mührü her sayfada."},
			{"text": "Geçmişi kurcalamayalım.", "fx": [
				{"op": "flag", "k": "davud_kapandi"},
				{"op": "rel", "a": "riza", "b": "sultan", "d": {"sevgi": -4}}],
				"result": "Rıza Efendi dosyayı yerine kaldırdı. Tozu bile bozulmadı."},
		]
	},
	"davud_sonuc": {
		"cat": "saray", "talk": "nurettin", "title": "Davud Bey'in Hakkı", "expires": 7, "once": true,
		"text": "Nurettin Efendi derin bir nefes aldı: \"Sultanım, Davud Bey'e karşı kullanılan mektuplar sahte. Halil Paşa onları hazırlatmadı belki ama sahte olduklarını bile bile fermanı mühürledi. Kuzeyhan'ın isyankâr valisinden kurtulmak işine geliyordu. Hüküm sizindir.\"",
		"options": [
			{"text": "Davud Bey'in adı herkesin önünde temize çıksın. Halil Paşa azledilsin.", "fx": [
				{"op": "dismiss", "post": "sadrazam", "text": "Halil Paşa, Davud Bey davası nedeniyle sadrazamlıktan azledildi."},
				{"op": "rel", "a": "leyla", "b": "sultan", "d": {"sevgi": 18, "guven": 18, "romantik": 10, "borcluluk": 30}},
				{"op": "mem", "who": "leyla", "type": "adalet", "actors": ["sultan"], "emo": 60, "text": "Hükümdar babamın adını temize çıkardı.", "key": "davud_adalet"},
				{"op": "lore", "who": "leyla", "idx": 1},
				{"op": "prov", "id": "kuzeyhan", "stat": "sadakat", "v": 15},
				{"op": "prov", "id": "kuzeyhan", "stat": "huzur", "v": 8},
				{"op": "crime", "who": "halil", "type": "iftira", "v": 50, "note": "Kadıasker'in incelemesi: Davud Bey'e karşı kullanılan mektuplar sahte; ferman bile bile mühürlenmiş."},
				{"op": "state", "stat": "justice", "v": 8},
				{"op": "rel", "a": "mahinur", "b": "sultan", "d": {"saygi": 6}},
				{"op": "rel", "a": "nurettin", "b": "sultan", "d": {"saygi": 8, "sevgi": 6}},
				{"op": "flag", "k": "davud_temize"}],
				"result": "Kuzeyhan'da Davud Bey için mevlit okundu. Sadrazamlık makamı boş; Divan'da yeni bir sadrazam atamalısınız."},
			{"text": "Adı temize çıksın; ama Halil Paşa görevde kalsın.", "fx": [
				{"op": "rel", "a": "leyla", "b": "sultan", "d": {"sevgi": 10, "guven": 10, "borcluluk": 15}},
				{"op": "mem", "who": "leyla", "type": "adalet", "actors": ["sultan"], "emo": 35, "text": "Babamın adı temize çıktı; ama onu öldüren hâlâ divanda oturuyor.", "key": "davud_adalet"},
				{"op": "prov", "id": "kuzeyhan", "stat": "sadakat", "v": 10},
				{"op": "crime", "who": "halil", "type": "iftira", "v": 50, "note": "Kadıasker'in incelemesi: Davud Bey'e karşı kullanılan mektuplar sahte; ferman bile bile mühürlenmiş."},
				{"op": "rel", "a": "halil", "b": "sultan", "d": {"korku": 15, "sevgi": -8, "siyasi_uyum": -8}},
				{"op": "mem", "who": "halil", "type": "tehdit", "actors": ["sultan"], "emo": -35, "text": "Hükümdar beni rezil etti ama görevden almadı. Neden?", "key": "davud_sonuc"},
				{"op": "state", "stat": "justice", "v": 4},
				{"op": "flag", "k": "davud_temize"}],
				"result": "Halil Paşa ilk kez Divan'a geç geldi."},
			{"text": "Devletin istikrarı için dosya mühürlensin.", "fx": [
				{"op": "rel", "a": "leyla", "b": "sultan", "d": {"guven": -18, "sevgi": -10}},
				{"op": "mem", "who": "leyla", "type": "ihanet", "actors": ["sultan"], "emo": -50, "text": "Hükümdar gerçeği bildiği hâlde babamın dosyasını mühürledi.", "key": "davud_muhur", "if_lore": ["leyla", 2]},
				{"op": "rel", "a": "nurettin", "b": "sultan", "d": {"saygi": -10}},
				{"op": "rel", "a": "halil", "b": "sultan", "d": {"borcluluk": 20, "siyasi_uyum": 10}},
				{"op": "state", "stat": "justice", "v": -5},
				{"op": "flag", "k": "davud_muhurlendi"}],
				"result": "Dosya yeniden mühürlendi. Bu sefer üzerinde sizin mührünüz var."},
		]
	},
	# ------------------------------------------------------------ saray yaşamı
	"bekir_ziyafet": {
		"cat": "saray", "talk": "bekir", "title": "Mutfaktan Bir Teklif", "expires": 4, "chance": 0.18, "cooldown": 40,
		"cond": {"min_day": 4},
		"text": "Usta Bekir, önlüğünü düzelterek eğildi: \"Sultanım, saray halkı yeni Sultan'ın sofrasından bir lokma tatmak ister. İzin verirseniz bu akşam avluda bütün hizmetkârlara bir ziyafet sofrası kurayım.\"",
		"options": [
			{"text": "Kur sofrayı, Usta! Kimse aç kalmasın.", "fx": [
				{"op": "treasury", "v": -1200},
				{"op": "relall", "group": "hizmet", "d": {"sevgi": 4}},
				{"op": "moodall", "v": 10},
				{"op": "state", "stat": "people_rep", "v": 1}],
				"result": "Avluda kazanlar kaynadı; o gece sarayda kahkaha eksik olmadı."},
			{"text": "Şimdi sırası değil.", "fx": [
				{"op": "rel", "a": "bekir", "b": "sultan", "d": {"sevgi": -3}}],
				"result": "Bekir Usta, kazanlarının başına döndü."},
		]
	},
	"lokman_ates": {
		"cat": "saray", "talk": "lokman", "title": "Hekimin Uyarısı", "expires": 3, "chance": 0.1, "cooldown": 50,
		"cond": {"min_day": 5},
		"text": "Saray Hekimi Lokman Efendi kaygılı: \"Mutfak çıraklarından üçünde yüksek ateş var, Sultanım. Henüz salgın demek için erken. Ama tedbir alınmazsa Şahriyar'a yayılabilir.\"",
		"options": [
			{"text": "Hastalar ayrılsın, ne gerekiyorsa yapılsın.", "fx": [
				{"op": "treasury", "v": -800},
				{"op": "rel", "a": "lokman", "b": "sultan", "d": {"saygi": 5, "guven": 4}},
				{"op": "prov", "id": "sahriyar", "stat": "saglik", "v": 2}],
				"result": "Lokman Efendi şuruplarını hazırlarken mutfak geçici olarak bahçeye taşındı."},
			{"text": "Abartıyorsun, Lokman Efendi.", "fx": [
				{"op": "rel", "a": "lokman", "b": "sultan", "d": {"saygi": -4}},
				{"op": "sched", "event": "salgin", "days": 6, "chance": 0.6}],
				"result": "Lokman Efendi başını salladı ama çantasını kapatmadı."},
		]
	},
	"salgin": {
		"cat": "devlet", "title": "Şahriyar'da Humma", "expires": 4, "once": false, "default": 1,
		"text": "Saray mutfağındaki ateş Şahriyar'ın mahallelerine yayıldı. Lokman Efendi şifahanelerin dolduğunu bildiriyor.",
		"options": [
			{"text": "Hazineden şifahanelere yardım gönderilsin.", "fx": [
				{"op": "treasury", "v": -4000},
				{"op": "prov", "id": "sahriyar", "stat": "saglik", "v": -4},
				{"op": "prov", "id": "sahriyar", "stat": "huzur", "v": -2},
				{"op": "state", "stat": "people_rep", "v": 2}],
				"result": "Salgın kontrol altına alındı; ama birkaç hafta sürecek."},
			{"text": "Şehir kapıları kapansın, kendi kendine sönsün.", "fx": [
				{"op": "prov", "id": "sahriyar", "stat": "saglik", "v": -10},
				{"op": "prov", "id": "sahriyar", "stat": "huzur", "v": -8},
				{"op": "prov", "id": "sahriyar", "stat": "ticaret", "v": -4},
				{"op": "state", "stat": "people_rep", "v": -3}],
				"result": "Kapılar kapandı. Çarşılar sustu."},
		]
	},
	"kamil_kubbe": {
		"cat": "saray", "talk": "kamil", "title": "Nakkaşın Hayali", "expires": 5, "once": true, "chance": 0.2,
		"cond": {"min_day": 5},
		"text": "Nakkaşbaşı Kâmil Usta çizimlerini önünüze serdi: \"Taht salonunun kubbesi rutubetten soldu, Sultanım. İzin verirseniz onu baştan nakşedeyim: laleler, karanfiller ve sizin tuğranız. Elçiler başlarını kaldırdıklarında ağızları açık kalsın.\"",
		"options": [
			{"text": "Hazineden 6.000 akçe ayrılsın.", "fx": [
				{"op": "treasury", "v": -6000},
				{"op": "state", "stat": "prestige", "v": 4},
				{"op": "rel", "a": "kamil", "b": "sultan", "d": {"sevgi": 10, "borcluluk": 10}},
				{"op": "flag", "k": "kubbe_nakis"}],
				"result": "Kâmil Usta iskelelerini kurdu. Taht salonu birkaç hafta boya kokacak."},
			{"text": "Hazine buna hazır değil.", "fx": [
				{"op": "rel", "a": "kamil", "b": "sultan", "d": {"sevgi": -3}}],
				"result": "Kâmil Usta çizimlerini rulo yapıp koltuğunun altına aldı."},
		]
	},
	"omer_lale": {
		"cat": "saray", "talk": "omer", "title": "Yeni Bir Lale", "expires": 6, "once": true, "chance": 0.22,
		"cond": {"min_day": 7},
		"text": "Ömer Ağa toprağa bulanmış ellerini önlüğüne sildi: \"Sultanım, yedi yıldır uğraştığım lale nihayet açtı. Kenarları altın, içi gece mavisi. Ona bir isim vermenizi isterim.\"",
		"options": [
			{"text": "Senin adını taşısın: 'Ömer Ağa Lalesi'.", "fx": [
				{"op": "rel", "a": "omer", "b": "sultan", "d": {"sevgi": 12, "borcluluk": 10}},
				{"op": "state", "stat": "people_rep", "v": 1}],
				"result": "Ömer Ağa'nın gözleri doldu. Laleler sarayın dışına da yayıldı."},
			{"text": "'Valide Lalesi' olsun.", "fx": [
				{"op": "rel", "a": "omer", "b": "sultan", "d": {"sevgi": 5}},
				{"op": "rel", "a": "mahinur", "b": "sultan", "d": {"sevgi": 6}}],
				"result": "Valide Sultan dairesine bir saksı lale gönderildi."},
			{"text": "'Leyla' adını taşısın.", "cond": {"alive": "leyla"}, "fx": [
				{"op": "rel", "a": "omer", "b": "sultan", "d": {"sevgi": 5}},
				{"op": "rel", "a": "leyla", "b": "sultan", "d": {"romantik": 8, "sevgi": 5}},
				{"op": "rel", "a": "feraye", "b": "leyla", "d": {"kiskanclik": 10}},
				{"op": "mem", "who": "feraye", "type": "kiskanclik", "actors": ["sultan", "leyla"], "emo": -20, "text": "Hükümdar yeni laleye Leyla'nın adını verdi.", "key": "lale_leyla"}],
				"result": "Bütün saray yeni laleyi konuşuyor."},
			{"text": "'Feraye' adını taşısın.", "cond": {"alive": "feraye"}, "fx": [
				{"op": "rel", "a": "omer", "b": "sultan", "d": {"sevgi": 5}},
				{"op": "rel", "a": "feraye", "b": "sultan", "d": {"romantik": 8, "sevgi": 5}},
				{"op": "rel", "a": "leyla", "b": "feraye", "d": {"kiskanclik": 8}},
				{"op": "mem", "who": "leyla", "type": "kiskanclik", "actors": ["sultan", "feraye"], "emo": -15, "text": "Hükümdar yeni laleye Feraye'nin adını verdi.", "key": "lale_feraye"}],
				"result": "Bütün saray yeni laleyi konuşuyor."},
		]
	},
	"sahmir_mektup": {
		"cat": "saray", "talk": "arslan", "title": "Yakalanan Mektuplar", "expires": 5, "once": true, "chance": 0.25,
		"cond": {"min_day": 8, "not_flag": "feraye_ag", "alive": "feraye"},
		"text": "Arslan Ağa mühürlü üç mektup çıkardı: \"Saray kapısında Sahmir'e giden bir ulaktan aldık, Sultanım. Feraye Sultan'ın mührü var. Açmadım.\"",
		"options": [
			{"text": "Mektupları aç ve oku.", "fx": [
				{"op": "lore", "who": "feraye", "idx": 2},
				{"op": "rel", "a": "arslan", "b": "sultan", "d": {"guven": 2}}],
				"result": "Mektuplar Sahmir sarayının iç işlerine dair ayrıntılarla dolu. Feraye bilgi topluyor... ama kimin için?"},
			{"text": "Mektupları açmadan Feraye'ye geri ver.", "fx": [
				{"op": "rel", "a": "feraye", "b": "sultan", "d": {"guven": 10, "sevgi": 5, "borcluluk": 15}},
				{"op": "mem", "who": "feraye", "type": "guven", "actors": ["sultan"], "emo": 30, "text": "Hükümdar mektuplarımı açmadan bana geri verdi.", "key": "mektup_iade"},
				{"op": "rel", "a": "arslan", "b": "sultan", "d": {"saygi": -2}}],
				"result": "Feraye mektuplara uzun uzun baktı, sonra size. Hiçbir şey söylemedi; söylemesine gerek yoktu."},
			{"text": "Ulağın yoluna devam etmesine izin ver; gözetlensin.", "fx": [
				{"op": "rel", "a": "arslan", "b": "sultan", "d": {"saygi": 3}},
				{"op": "flag", "k": "feraye_izleniyor"}],
				"result": "Arslan Ağa'nın adamları ulağı Güneyyurt sınırına kadar izleyecek."},
		]
	},
	"lale_senligi": {
		"cat": "saray", "talk": "omer", "title": "Lale Şenliği", "expires": 6, "once": true, "chance": 0.25,
		"cond": {"min_day": 9, "month_in": [3, 4]},
		"text": "Ömer Ağa ve Usta Bekir birlikte geldiler: \"Laleler tam açtı, Sultanım. Bahçede bir şenlik yapsak: kandiller, kaplumbağaların sırtında mumlar, helvalar, saz...\"",
		"options": [
			{"text": "Görkemli bir şenlik olsun!", "fx": [
				{"op": "treasury", "v": -6000},
				{"op": "state", "stat": "prestige", "v": 5},
				{"op": "state", "stat": "people_rep", "v": 3},
				{"op": "moodall", "v": 15},
				{"op": "relall", "group": "hepsi", "d": {"sevgi": 2}}],
				"result": "Saray bahçesi binlerce kandille aydınlandı. Şahriyar'da günlerce bu şenlik konuşuldu."},
			{"text": "Sade bir akşam yemeği yeter.", "fx": [
				{"op": "treasury", "v": -1500},
				{"op": "moodall", "v": 5}],
				"result": "Bahçede sakin, güzel bir akşam geçti."},
			{"text": "Bu yıl şenlik yok.", "fx": [
				{"op": "rel", "a": "omer", "b": "sultan", "d": {"sevgi": -3}},
				{"op": "rel", "a": "bekir", "b": "sultan", "d": {"sevgi": -2}}],
				"result": "Laleler kimseye gösterilmeden soldu."},
		]
	},
	"kuzeyhan_ayan": {
		"cat": "devlet", "title": "Kuzeyhan'dan Şikâyet", "expires": 5, "chance": 0.15, "cooldown": 45,
		"cond": {"min_day": 8, "prov_lt": ["kuzeyhan", "sadakat", 45]},
		"text": "Kuzeyhan ayanlarından bir heyet saraya geldi. Vali Bayram Paşa'nın ağır vergi topladığından, Davud Bey zamanından kalan kinle halka eziyet ettiğinden yakınıyorlar.",
		"options": [
			{"text": "Vali değiştirilsin.", "fx": [
				{"op": "treasury", "v": -2000},
				{"op": "prov", "id": "kuzeyhan", "stat": "sadakat", "v": 10},
				{"op": "prov", "id": "kuzeyhan", "stat": "huzur", "v": 6},
				{"op": "governor", "prov": "kuzeyhan", "name": "Vali Kerem Bey"}],
				"result": "Kuzeyhan'a yeni bir vali, Kerem Bey gönderildi."},
			{"text": "Bir yıl vergi indirimi yapılsın.", "fx": [
				{"op": "exempt", "prov": "kuzeyhan", "months": 6},
				{"op": "mod", "prov": "kuzeyhan", "stat": "huzur", "v": 10, "days": 180},
				{"op": "mod", "prov": "kuzeyhan", "stat": "sadakat", "v": 6, "days": 180}],
				"result": "Kuzeyhan altı ay vergiden muaf tutulacak."},
			{"text": "Ayanlar haddini bilsin.", "fx": [
				{"op": "prov", "id": "kuzeyhan", "stat": "sadakat", "v": -6},
				{"op": "prov", "id": "kuzeyhan", "stat": "huzur", "v": -4}],
				"result": "Heyet sessizce geri döndü. Kuzeyhan'da öfke büyüyor."},
		]
	},
	"dugun": {
		"cat": "aile", "title": "Düğün Hazırlıkları", "expires": 5, "default": 1,
		"text": "Saray, {bride_name} ile düğününüz için hazırlanıyor. Kethüda Gülbahar Hatun düğünün nasıl olacağını soruyor: Şahriyar halkı da şenliğe katılsın mı, yoksa sade bir nikâh mı kıyılsın?",
		"options": [
			{"text": "Görkemli bir düğün: yedi gün yedi gece şenlik!", "fx": [
				{"op": "treasury", "v": -12000},
				{"op": "marry", "who": "$bride"},
				{"op": "state", "stat": "prestige", "v": 6},
				{"op": "state", "stat": "people_rep", "v": 3},
				{"op": "moodall", "v": 8}],
				"result": "Şahriyar'da yedi gün boyunca kazanlar kaynadı, gökyüzü fişeklerle aydınlandı. Hanedan yeni bir dönemin eşiğinde."},
			{"text": "Sade bir nikâh yeterli.", "fx": [
				{"op": "treasury", "v": -2000},
				{"op": "marry", "who": "$bride"}],
				"result": "Valide Sultan'ın dairesinde sade ama içten bir nikâh kıyıldı."},
		]
	},
	"varenya_cevap": {
		"cat": "diplomasi", "talk": "edric", "title": "Varenya'nın Cevabı", "expires": 6, "once": true,
		"text": "Kont Edric memnun görünüyor: \"Kralım, Demirkapı yolunun masrafının yarısını üstlenmeyi kabul etti, Sultanım. Tüccarlarımız sabırsızlanıyor.\"",
		"options": [
			{"text": "Anlaşma tamam; yol yapılsın (9.000 akçe).", "fx": [
				{"op": "treasury", "v": -9000},
				{"op": "project_free", "prov": "demirkapi", "type": "yol"},
				{"op": "nb", "id": "varenya", "stat": "attitude", "v": 6},
				{"op": "rel", "a": "edric", "b": "sultan", "d": {"sevgi": 5, "saygi": 5}},
				{"op": "rel", "a": "selim", "b": "sultan", "d": {"saygi": 4}},
				{"op": "skill", "s": "diplomasi", "v": 2}],
				"result": "Demirkapı geçidinde kazmalar işlemeye başladı."},
			{"text": "Fikrimi değiştirdim.", "fx": [
				{"op": "nb", "id": "varenya", "stat": "attitude", "v": -6},
				{"op": "rel", "a": "edric", "b": "sultan", "d": {"saygi": -5}}],
				"result": "Kont Edric kibarca eğildi ama hayal kırıklığı yüzünden okunuyordu."},
		]
	},
	# ------------------------------------------------------------ hanedan
	"hamile_mujde": {
		"cat": "hanedan", "talk": "lokman", "title": "Hekimbaşının Müjdesi", "expires": 4, "default": 0,
		"text": "Hekimbaşı Lokman Efendi gülümseyerek eğildi: \"Müjdemi isterim, Sultanım! {mother_name} hamile. Allah izin verirse, yedi sekiz ay sonra hanedan yeni bir fidanla şenlenecek.\"",
		"options": [
			{"text": "Ona çok iyi bakılsın; en iyi ebeler hazır olsun.", "fx": [
				{"op": "treasury", "v": -800},
				{"op": "announce", "who": "$mother"},
				{"op": "rel", "a": "lokman", "b": "sultan", "d": {"sevgi": 3, "saygi": 2}},
				{"op": "rel", "a": "$mother", "b": "sultan", "d": {"sevgi": 6, "guven": 4}}],
				"result": "Lokman Efendi her sabah bizzat yoklayacağına söz verdi."},
			{"text": "Bütün saray bu müjdeyi kutlasın; şerbetler dağıtılsın!", "fx": [
				{"op": "treasury", "v": -2000},
				{"op": "announce", "who": "$mother"},
				{"op": "moodall", "v": 5},
				{"op": "state", "stat": "people_rep", "v": 1},
				{"op": "rel", "a": "$mother", "b": "sultan", "d": {"sevgi": 8}}],
				"result": "Haremden mutfağa, avludan kapılara kadar herkes müjde şerbeti içti."},
			{"text": "Şimdilik kimse duymasın.", "fx": [
				{"op": "announce_quiet", "who": "$mother"},
				{"op": "rel", "a": "lokman", "b": "sultan", "d": {"guven": 3}}],
				"result": "Lokman Efendi parmağını dudaklarına götürdü: \"Sır, sırdır Sultanım.\""},
		]
	},
	"dogum": {
		"cat": "hanedan", "title": "Hanedana Yeni Bir Fidan", "expires": 6, "default": 0,
		"text": "{mother_name}, {cocuk} dünyaya getirdi!{ilk} Ebeler bebeği kundaklayıp Hasodabaşı Cafer Ağa'nın kollarına verdi. Şimdi herkes ad koymanızı bekliyor.",
		"options": [
			{"text": "Adı {n1} olsun.", "fx": [{"op": "rename", "who": "$child", "name": "$n1"}, {"op": "rel", "a": "$mother", "b": "sultan", "d": {"sevgi": 3}}],
				"result": "Ezan okunarak adı kulağına fısıldandı: {n1}."},
			{"text": "Adı {n2} olsun.", "fx": [{"op": "rename", "who": "$child", "name": "$n2"}, {"op": "rel", "a": "$mother", "b": "sultan", "d": {"sevgi": 3}}],
				"result": "Ezan okunarak adı kulağına fısıldandı: {n2}."},
			{"text": "Adı {n3} olsun.", "fx": [{"op": "rename", "who": "$child", "name": "$n3"}, {"op": "rel", "a": "$mother", "b": "sultan", "d": {"sevgi": 3}}],
				"result": "Ezan okunarak adı kulağına fısıldandı: {n3}."},
		]
	},
	"harem_kavga": {
		"cat": "harem", "talk": "gulbahar", "title": "Haremde Kavga", "expires": 4, "default": 3,
		"text": "Kethüda Gülbahar Hatun'un sabrı tükenmiş: \"Sultanım, {a_name} ile {b_name} hamamda birbirine girdi. Harem ikiye bölündü; birini tutarsanız öbürü küsecek.\"",
		"options": [
			{"text": "{a_name} haklı.", "fx": [
				{"op": "rel", "a": "$a", "b": "sultan", "d": {"sevgi": 6, "romantik": 3}},
				{"op": "rel", "a": "$b", "b": "sultan", "d": {"sevgi": -8, "romantik": -4}},
				{"op": "mem", "who": "$b", "type": "ret", "actors": ["sultan", "$a"], "emo": -25, "text": "Hükümdar kavgada {a_name} tarafını tuttu.", "key": "kavga"},
				{"op": "rel", "a": "$b", "b": "$a", "d": {"kiskanclik": 10, "rekabet": 10}}],
				"result": "{a_name} başını dik tuttu; {b_name} ise kapısını kimseye açmadı."},
			{"text": "{b_name} haklı.", "fx": [
				{"op": "rel", "a": "$b", "b": "sultan", "d": {"sevgi": 6, "romantik": 3}},
				{"op": "rel", "a": "$a", "b": "sultan", "d": {"sevgi": -8, "romantik": -4}},
				{"op": "mem", "who": "$a", "type": "ret", "actors": ["sultan", "$b"], "emo": -25, "text": "Hükümdar kavgada {b_name} tarafını tuttu.", "key": "kavga"},
				{"op": "rel", "a": "$a", "b": "$b", "d": {"kiskanclik": 10, "rekabet": 10}}],
				"result": "{b_name} gülümsedi; {a_name} ise o akşam yemeğe inmedi."},
			{"text": "İkisine de birer hediye verilsin; barışsınlar.", "fx": [
				{"op": "treasury", "v": -1200},
				{"op": "rel", "a": "$a", "b": "$b", "d": {"kiskanclik": -12, "rekabet": -10, "sevgi": 4}},
				{"op": "rel", "a": "$b", "b": "$a", "d": {"kiskanclik": -12, "rekabet": -10, "sevgi": 4}},
				{"op": "rel", "a": "$a", "b": "sultan", "d": {"sevgi": 2}},
				{"op": "rel", "a": "$b", "b": "sultan", "d": {"sevgi": 2}}],
				"result": "İki hanım aynı sofrada, aynı hediyelerle göründü. Barış ne kadar sürer, bilinmez."},
			{"text": "Kethüda ikisini de cezalandırsın.", "fx": [
				{"op": "rel", "a": "gulbahar", "b": "sultan", "d": {"saygi": 3}},
				{"op": "rel", "a": "$a", "b": "sultan", "d": {"korku": 8, "sevgi": -3}},
				{"op": "rel", "a": "$b", "b": "sultan", "d": {"korku": 8, "sevgi": -3}}],
				"result": "İkisi de bir hafta haremin bahçesine çıkamayacak."},
		]
	},
	# ------------------------------------------------------------ suç ve soruşturma
	"rusvet_ihbar": {
		"cat": "adalet", "talk": "arslan", "title": "Rüşvet İhbarı", "expires": 5, "default": 2,
		"text": "Arslan Ağa sesini alçalttı: \"Sultanım, çarşıdaki tüccarlar {who_name} hakkında konuşuyor. Saray tedariklerini kendi adamlarına vermek için kese kese akçe aldığı söyleniyor. Söylenti mi, gerçek mi, henüz bilmiyorum.\"",
		"options": [
			{"text": "Gizlice araştır; bana kesin bilgi getir.", "fx": [
				{"op": "sched_if", "event_true": "rusvet_var", "event_false": "rusvet_yok", "days": 3},
				{"op": "rel", "a": "arslan", "b": "sultan", "d": {"guven": 2}}],
				"result": "Arslan Ağa başını eğdi: \"Üç güne kalmaz.\""},
			{"text": "Doğrudan Kadıasker'e bildirilsin.", "fx": [
				{"op": "crime", "who": "$who", "type": "rusvet", "v": 35, "note": "Çarşı esnafının ihbarı: tedarik işlerinde rüşvet."},
				{"op": "rel", "a": "$who", "b": "sultan", "d": {"korku": 8, "sevgi": -4}}],
				"result": "İhbar Kadıasker'in defterine geçti."},
			{"text": "Esnaf dedikodusuyla uğraşamam.", "fx": [{"op": "state", "stat": "justice", "v": -1}],
				"result": "Arslan Ağa bir şey demedi; ama gözleri her şeyi söyledi."},
		]
	},
	"rusvet_var": {
		"cat": "adalet", "talk": "arslan", "title": "Soruşturmanın Sonucu", "expires": 5, "default": 0,
		"text": "Arslan Ağa elinde bir defterle döndü: \"Suç sabit, Sultanım. {who_name} tüccarlardan aldığı akçeyi bir sandıkta saklıyormuş; sandık da defteri de elimizde.\"",
		"options": [
			{"text": "Dosya Kadıasker'e gitsin.", "fx": [{"op": "crime", "who": "$who", "type": "rusvet", "v": 70, "note": "Arslan Ağa'nın soruşturması: rüşvet sandığı ve defteri bulundu."}],
				"result": "Delil sandığı mühürlenip Kadıasker'e gönderildi."},
			{"text": "Akçeyi hazineye iade etsin; bir uyarı yeter.", "fx": [
				{"op": "treasury", "v": 1500},
				{"op": "rel", "a": "$who", "b": "sultan", "d": {"korku": 15, "borcluluk": 12}},
				{"op": "mem", "who": "$who", "type": "uyari", "actors": ["sultan"], "emo": -15, "text": "Hükümdar rüşvetimi biliyor; son kez uyarıldım.", "key": "rusvet_uyari"}],
				"result": "1.500 akçe hazineye geri döndü."},
		]
	},
	"rusvet_yok": {
		"cat": "adalet", "talk": "arslan", "title": "Soruşturmanın Sonucu", "expires": 5, "default": 0,
		"text": "Arslan Ağa: \"İhbar asılsız, Sultanım. {who_name} hakkında söylenenler, ihaleyi kaybeden bir tüccarın iftirasıymış.\"",
		"options": [
			{"text": "İyi ki kimseyi suçlamadık.", "fx": [{"op": "clearcase", "who": "$who", "type": "rusvet"}, {"op": "state", "stat": "justice", "v": 1}],
				"result": "Mesele kapandı."},
			{"text": "İftiracı tüccar uyarılsın.", "fx": [{"op": "clearcase", "who": "$who", "type": "rusvet"}, {"op": "state", "stat": "justice", "v": 2},
				{"op": "rel", "a": "$who", "b": "sultan", "d": {"sevgi": 5, "guven": 4}}],
				"result": "Tüccar Divan'a çağrılıp azarlandı."},
		]
	},
	"zehir_supheli": {
		"cat": "saray", "talk": "bekir", "title": "Şüpheli Şerbet", "expires": 4, "default": 1,
		"text": "Usta Bekir'in yüzü bembeyaz: \"Sultanım, akşam sofranıza giden şerbetin rengi bozuktu; tadına bakan çırak hastalandı. Mutfağa o saatte {who_name} uğramıştı... Belki tesadüf, belki değil.\"",
		"options": [
			{"text": "Arslan Ağa derhal araştırsın.", "fx": [
				{"op": "sched_if", "event_true": "zehir_var", "event_false": "zehir_yok", "days": 2},
				{"op": "rel", "a": "bekir", "b": "sultan", "d": {"guven": 3}}],
				"result": "Arslan Ağa mutfağın kapısına iki muhafız dikti."},
			{"text": "Bundan sonra yemeklerim tadımcıdan geçsin.", "fx": [
				{"op": "flag", "k": "upkeep_tadimci", "v": 300},
				{"op": "rel", "a": "bekir", "b": "sultan", "d": {"saygi": 2}}],
				"result": "Sofranıza artık önce tadımcıbaşı oturuyor (ayda 300 akçe)."},
			{"text": "{who_name} Kadıasker'e sevk edilsin.", "fx": [
				{"op": "crime", "who": "$who", "type": "suikast", "v": 25, "note": "Şüpheli şerbet olayı: olay saatinde mutfağa girdiği görüldü."},
				{"op": "rel", "a": "$who", "b": "sultan", "d": {"korku": 12, "sevgi": -10}},
				{"op": "mem", "who": "$who", "type": "haksizlik", "actors": ["sultan"], "emo": -30, "text": "Hükümdar beni zehircilikle suçladı.", "key": "zehir_suclama"}],
				"result": "Saray bu suçlamayı konuşuyor."},
		]
	},
	"zehir_var": {
		"cat": "saray", "talk": "arslan", "title": "Mutfaktaki Ağu", "expires": 5, "default": 0,
		"text": "Arslan Ağa'nın sesi boğuk: \"Sultanım, {who_name} adına kayıtlı sandıktan bir şişe ağu çıktı. Mutfak çırağı, şerbete bir şey katıldığını gördüğünü yeminle söylüyor.\"",
		"options": [
			{"text": "Dosya derhal Kadıasker'e!", "fx": [{"op": "crime", "who": "$who", "type": "suikast", "v": 80, "note": "Arslan Ağa'nın soruşturması: sandıkta ağu şişesi, çırağın yeminli tanıklığı."}],
				"result": "Dosya mühürlenip Kadıasker'e götürüldü."},
			{"text": "Önce yüzüne ben bakacağım.", "fx": [
				{"op": "crime", "who": "$who", "type": "suikast", "v": 80, "note": "Arslan Ağa'nın soruşturması: sandıkta ağu şişesi, çırağın yeminli tanıklığı."},
				{"op": "mem", "who": "$who", "type": "uyari", "actors": ["sultan"], "emo": -30, "text": "Hükümdar her şeyi biliyor.", "key": "zehir_yuz"},
				{"op": "rel", "a": "$who", "b": "sultan", "d": {"korku": 25}}],
				"result": "Dosya Kadıasker'de; hüküm sizin."},
		]
	},
	"zehir_yok": {
		"cat": "saray", "talk": "arslan", "title": "Bozuk Şerbet", "expires": 5, "default": 0,
		"text": "Arslan Ağa rahatlamış: \"Sultanım, şerbetin bozulmasının sebebi eskimiş gül suyuymuş. {who_name} mutfağa sadece su içmeye gelmiş.\"",
		"options": [
			{"text": "Bekir Usta erzaka dikkat etsin.", "fx": [{"op": "clearcase", "who": "$who", "type": "suikast"}, {"op": "rel", "a": "bekir", "b": "sultan", "d": {"korku": 4}}],
				"result": "Mutfakta eski gül suları döküldü."},
			{"text": "İyi ki kimseyi suçlamadık.", "fx": [{"op": "clearcase", "who": "$who", "type": "suikast"}, {"op": "state", "stat": "justice", "v": 1}],
				"result": "Mesele kapandı."},
		]
	},
	"harem_hirsizlik": {
		"cat": "harem", "talk": "gulbahar", "title": "Kayıp Gerdanlık", "expires": 4, "default": 2,
		"text": "Kethüda Gülbahar Hatun dertli: \"Sultanım, harem hazinesinden bir inci gerdanlık kayboldu. Sandık odasının anahtarına dün en son {who_name} dokunmuş.\"",
		"options": [
			{"text": "Sessizce araştırın.", "fx": [{"op": "sched_if", "event_true": "hirsizlik_var", "event_false": "hirsizlik_yok", "days": 2}],
				"result": "Gülbahar Hatun anahtarları kendi kuşağına bağladı."},
			{"text": "{who_name} Kadıasker'e sevk edilsin.", "fx": [
				{"op": "crime", "who": "$who", "type": "hirsizlik", "v": 30, "note": "Kayıp gerdanlık: sandık odasının anahtarına en son dokunan."},
				{"op": "rel", "a": "$who", "b": "sultan", "d": {"korku": 10, "sevgi": -8}}],
				"result": "Haremde fısıltılar başladı."},
			{"text": "Gerdanlığın yenisi yapılsın; kimse suçlanmasın.", "fx": [{"op": "treasury", "v": -1500}],
				"result": "Kuyumcubaşı çağrıldı."},
		]
	},
	"hirsizlik_var": {
		"cat": "harem", "talk": "gulbahar", "title": "Gerdanlık Bulundu", "expires": 5, "default": 0,
		"text": "Gülbahar Hatun: \"Gerdanlık, {who_name} adına kayıtlı yastığın içine dikilmiş hâlde bulundu, Sultanım.\"",
		"options": [
			{"text": "Dosya Kadıasker'e gitsin.", "fx": [{"op": "crime", "who": "$who", "type": "hirsizlik", "v": 75, "note": "Gerdanlık, yastığına dikilmiş hâlde bulundu."}],
				"result": "Kadıasker dosyayı aldı."},
			{"text": "Gerdanlık geri alınsın; bir uyarı yeter.", "fx": [
				{"op": "mem", "who": "$who", "type": "uyari", "actors": ["sultan"], "emo": -15, "text": "Hükümdar hırsızlığımı affetti; son kez.", "key": "hirsizlik_uyari"},
				{"op": "rel", "a": "$who", "b": "sultan", "d": {"korku": 12, "borcluluk": 15}}],
				"result": "Gerdanlık sandığına döndü."},
		]
	},
	"hirsizlik_yok": {
		"cat": "harem", "talk": "gulbahar", "title": "Gerdanlık Bulundu", "expires": 5, "default": 0,
		"text": "Gülbahar Hatun gülümsüyor: \"Gerdanlık bulundu, Sultanım: kuyumcuya tamire verilmiş, deftere yazılmamış. {who_name} suçsuz.\"",
		"options": [
			{"text": "İyi. Deftere yazmayı unutanı uyarın.", "fx": [{"op": "clearcase", "who": "$who", "type": "hirsizlik"}],
				"result": "Mesele kapandı."},
		]
	},
}

## Yeni oyunda ilk gün sıradaki olaylar
const STARTING := ["ilk_gun_valide", "ilk_gun_halil", "kayip_yuzuk"]
## Rastgele/koşullu değerlendirilecek olaylar
const RANDOM_POOL := ["tolga_butce", "edric_hediye", "valide_halil", "arslan_tolga", "bora_golge", "riza_dedikodu",
	"nedime_kavga", "leyla_gazel", "feraye_davet", "valide_evlilik", "davud_dosyasi", "bekir_ziyafet", "lokman_ates",
	"kamil_kubbe", "omer_lale", "sahmir_mektup", "lale_senligi", "kuzeyhan_ayan"]
