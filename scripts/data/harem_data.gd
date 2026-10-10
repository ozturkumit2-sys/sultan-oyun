class_name HaremData
extends RefCounted
## Harem, eş adayları ve hanedan çocukları için veri tabloları.
## Not: Hareme katılan herkes yetişkindir (18+); çocuk karakterlerle hiçbir romantik seçenek yoktur.

const MIN_AGE := 18
const MAX_WIVES := 4

## Haremdeki konumlar (rütbeler)
const RANKS := ["cariye", "gozde", "ikbal", "kadin", "haseki"]
const RANK_NAMES := {"cariye": "Cariye", "gozde": "Gözde", "ikbal": "İkbal", "kadin": "Kadın Efendi", "haseki": "Haseki Sultan", "es": "Sultan (eş)"}
const RANK_STATUS := {"cariye": 30, "gozde": 42, "ikbal": 55, "kadin": 70, "haseki": 85}

## Saray seviyesine göre harem kapasitesi (Leyla ve Feraye dahil, eşler dahil)
const CAPACITY := [6, 9, 12]
const UPKEEP_PER_WOMAN := 240.0   # aylık akçe

const CARIYE_NAMES := ["Gülfem", "Mihrişah", "Nakşidil", "Şebsefa", "Dilaşub", "Gülnuş", "Nazperver", "Cevherinaz",
	"Ruhşah", "Nevfidan", "Pertevniyal", "Dilnişin", "Mahfiruz", "Gülbeyaz", "Şevkefza", "Hoşyar", "Gülruh", "Mehtap",
	"Neşerek", "Ruhsar", "Dürrinev", "Nurbanu", "Safiye", "Ferahşad", "Şermi", "Bezmialem", "Tirimüjgan", "Hüsnümelek",
	"Gülcemal", "Perestu", "Lalezar", "Nevres", "Rabia", "Meylişah", "Şemsiruhsar", "Ayşah"]

const ORIGINS := [
	{"t": "Kuzeyhan dağlarındaki bir köyden", "skin": 0, "prov": "kuzeyhan"},
	{"t": "Sahmir sınırındaki bir kervansaray kasabasından", "skin": 1, "nb": "sahmir"},
	{"t": "Varenya'nın kıyı şehirlerinden", "skin": 0, "nb": "varenya"},
	{"t": "Güneyyurt'un hurmalıklarından", "skin": 2},
	{"t": "Şahriyar'ın eski bir tüccar ailesinden", "skin": 1},
	{"t": "Karaburç'ta bir sınır kalesinden", "skin": 1, "prov": "karaburc"},
	{"t": "denizin ötesindeki adalardan", "skin": 1},
	{"t": "Sarıkum ovasında bir çiftlikten", "skin": 2, "prov": "sarikum"},
]

## Yetenekler: [ad, açıklama, sevdiği hediye, beceri artışı]
const TALENTS := [
	["ud", "ud çalar; sesi dinleyeni büyüler", "kitap", {"ilim": 10}],
	["siir", "şiir yazar, divan okur", "kitap", {"ilim": 18}],
	["nakis", "ince nakış ve sırma işler", "kumas", {"ekonomi": 6}],
	["hesap", "hesap kitap bilir, harem defterini tutabilir", "kitap", {"ekonomi": 20, "yonetim": 8}],
	["sifa", "şifalı otları tanır, hekimlik bilir", "cicek", {"ilim": 12}],
	["satranc", "satranç oynar; sabırlı ve hesaplı", "kitap", {"yonetim": 10, "askeri": 6}],
	["hikaye", "hikâye anlatır, herkesi güldürür", "cicek", {"diplomasi": 10}],
	["dil", "birkaç dil konuşur", "kitap", {"diplomasi": 20}],
	["bahce", "çiçek yetiştirmeyi sever", "cicek", {}],
	["binicilik", "ata binmeyi ve ok atmayı bilir", "silah", {"askeri": 15}],
]

## Kişilik tipleri: trait eğilimleri ve kısa tarif
const TEMPERS := [
	{"t": "çekingen ve düşünceli", "tr": {"sosyal": -20, "sabir": 15, "ozguven": -15, "merhamet": 10}},
	{"t": "neşeli ve konuşkan", "tr": {"sosyal": 25, "ozguven": 10, "sabir": -5}},
	{"t": "hırslı ve keskin zekâlı", "tr": {"hirs": 30, "zeka": 15, "kiskanclik": 15, "merhamet": -10}},
	{"t": "yumuşak kalpli ve sadık", "tr": {"merhamet": 25, "sadakat": 20, "hirs": -15}},
	{"t": "gururlu ve kendinden emin", "tr": {"ozguven": 25, "kiskanclik": 10, "sabir": -10}},
	{"t": "meraklı ve hazırcevap", "tr": {"zeka": 15, "sosyal": 10, "cesaret": 10}},
]

## Eş adayları: soylu aileler. Kabul ihtimali ve faydaları.
const NOBLE_HOUSES := [
	{"id": "kuzeyhan_bey", "family": "Kuzeyhan Beyi Turgut Bey'in kızı", "prov": "kuzeyhan", "skin": 0, "title": "Hanım", "dowry": 9000, "fx": "prov", "stat": "sadakat", "v": 14},
	{"id": "sarikum_ayan", "family": "Sarıkum'un en büyük ayanı Hacı Selami Ağa'nın kızı", "prov": "sarikum", "skin": 2, "title": "Hanım", "dowry": 6000, "fx": "prov", "stat": "sadakat", "v": 10},
	{"id": "karaburc_kale", "family": "Karaburç kale komutanı Demir Bey'in kızı", "prov": "karaburc", "skin": 1, "title": "Hanım", "dowry": 7000, "fx": "prov", "stat": "guvenlik", "v": 10},
	{"id": "sahmir_saray", "family": "Sahmir Şahı'nın yeğeni", "nb": "sahmir", "skin": 1, "title": "Hanım", "dowry": 14000, "fx": "nb", "v": 16},
	{"id": "varenya_saray", "family": "Varenya Kralı'nın kuzeni", "nb": "varenya", "skin": 0, "title": "Hanım", "dowry": 14000, "fx": "nb", "v": 16},
	{"id": "sehir_tuccar", "family": "Şahriyar'ın en zengin tüccarı Kasım Çelebi'nin kızı", "skin": 1, "title": "Hanım", "dowry": 4000, "fx": "treasury", "v": 12000},
]

const NOBLE_NAMES := ["Gevherhan", "Hümaşah", "Esmahan", "Şahsultan", "Fatma", "Hanzade", "Raziye", "Mihrimah", "Ayşegül", "Zeynep", "Elora", "Selin", "Nilüfer", "Saliha"]

const SON_NAMES := ["Murad", "Orhan", "Bayezid", "Cem", "Korkut", "Alaeddin", "Ertuğrul", "Kasım", "Mustafa", "Süleyman", "Osman", "Mahmud", "Ahmed", "Kayı", "Oğuz", "Aydın"]
const DAUGHTER_NAMES := ["Hatice", "Mihrimah", "Gevherhan", "Hümaşah", "Esma", "Fatma", "Hanzade", "Şah", "Rukiye", "Saliha", "Emine", "Nazlı", "Şehsuvar", "Zeynep"]

## Şehzade eğitimi odakları
const EDU := {
	"ilim": {"name": "İlim ve edebiyat", "skills": {"ilim": 5, "diplomasi": 2}},
	"askeri": {"name": "Kılıç, ok ve at", "skills": {"askeri": 5, "yonetim": 1}},
	"yonetim": {"name": "Devlet idaresi", "skills": {"yonetim": 4, "ekonomi": 2, "adalet": 1}},
	"diplomasi": {"name": "Diller ve diplomasi", "skills": {"diplomasi": 5, "ilim": 1}},
}

const ROBE_COLORS := ["8e1f2f", "2f5f8f", "1f5a3f", "6a3a6a", "a0605a", "3a5a7a", "7a5a2a", "2a6a6a", "8a3a5a", "5a4a8a", "b07a3a", "4a6a3a"]
const HOTOZ_COLORS := ["8e1f2f", "2a4a8a", "1f5a3f", "6a2a6a", "a05a2a", "2a6a6a"]
