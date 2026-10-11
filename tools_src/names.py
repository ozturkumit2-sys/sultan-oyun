#!/usr/bin/env python3
"""Hikâyeli yemek isimleri için kelime tablolarını üretir -> data/names.json

Kullanım (proje kökünden):  python3 tools_src/names.py .

Yapı:
- persona_priority: yemeğin "kahramanını" seçmek için etiket önceliği
- role_priority:    kahramanın "mesleğini" seçmek için etiket önceliği
- adj_weights:      sıfatı belirleyen istatistik ağırlıkları
- lang.<kod>:       dile özel şablonlar ve kelimeler
    templates: [{"w": ağırlık, "t": "{adj} {role} {persona}"}]
    persona:   etiket -> [kelime | {"t": kelime, "g": "m|f|n"}]
    role:      etiket -> [kelime]
    adj:       istatistik -> [kelime | {"m": .., "f": .., "n": ..}]
    sequel:    [film devamı tarzı alt başlıklar]
    origin:    etiket -> [köken cümlesi]
    effect:    istatistik -> [etki cümlesi]
    lore:      "{origin} {effect}"
    simple_dish / simple_fusion / simple_one: 1-2 malzemeli isim kalıpları
"""
import json
import os
import sys

PERSONA_PRIORITY = ["ghost", "alien", "robot", "mechanical", "monster", "frog", "insect", "gothic", "sea",
                    "cosmic", "slime", "electric", "fire", "cold", "magic", "flower", "fermented", "luxury",
                    "candy", "meat", "swamp", "crystal", "nature", "fruit", "dough", "dairy", "vegetable",
                    "grain", "sweet", "savory", "animal"]
ROLE_PRIORITY = ["fire", "spicy", "electric", "sea", "luxury", "frog", "insect", "cold", "gothic", "magic",
                 "alien", "mechanical", "robot", "ghost", "monster", "cosmic", "flower", "fermented", "candy",
                 "meat", "crunchy", "crystal", "slime", "swamp", "dough", "dairy", "fruit", "nature", "vegetable"]
ADJ_WEIGHTS = {"spicy": 1.15, "sweet": 1.1, "toxic": 1.1, "magic": 1.0, "weird": 0.9, "volatile": 0.9,
               "fresh": 0.62, "life": 0.75}

LANG = {}

LANG["tr"] = {
    "templates": [{"w": 3, "t": "{adj} {role} {persona}"}, {"w": 2, "t": "{adj} {persona}: {sequel}"}],
    "persona": {
        "ghost": ["Hayalet", "Ruh"], "alien": ["Uzaylı", "Marslı"], "robot": ["Robot", "Android"],
        "mechanical": ["Robot", "Makine"], "monster": ["Canavar", "Yaratık"], "frog": ["Kurbağa", "Bataklık Kralı"],
        "insect": ["Böcek", "Uğur Böceği"], "gothic": ["Vampir", "Yarasa"], "sea": ["Kraken", "Deniz Kızı"],
        "cosmic": ["Kuyruklu Yıldız", "Galaksi"], "slime": ["Jöle", "Balçık"], "electric": ["Şimşek", "Fırtına"],
        "fire": ["Ejder", "Volkan"], "cold": ["Kardan Adam", "Buz Devi"], "magic": ["Büyücü", "Cadı"],
        "flower": ["Peri", "Gül"], "fermented": ["Turşu", "Mumya"], "luxury": ["Kral", "İmparator"],
        "candy": ["Şekerleme", "Lolipop"], "meat": ["Boğa", "Mangal"], "swamp": ["Timsah", "Bataklık"],
        "crystal": ["Kristal", "Elmas"], "nature": ["Ağaç Adam", "Orman"], "fruit": ["Meyve", "Bahçe"],
        "dough": ["Hamur", "Kurabiye"], "dairy": ["İnek", "Peynir"], "vegetable": ["Lahana", "Sebze"],
        "grain": ["Başak", "Pirinç Tanesi"], "sweet": ["Pasta", "Şeker"], "savory": ["Tencere", "Tava"],
        "animal": ["Yaratık", "Hayvan"], "default": ["Gizem", "Şey"],
    },
    "role": {
        "fire": ["Ninja", "Samuray"], "spicy": ["Ninja", "Matador"], "electric": ["Rockçı", "DJ"],
        "sea": ["Korsan", "Kaptan"], "luxury": ["Lord", "Prens"], "frog": ["Prens", "Kovboy"],
        "insect": ["Gladyatör", "Şövalye"], "cold": ["Kayakçı", "Kutup Kâşifi"], "gothic": ["Kont", "Dedektif"],
        "magic": ["Sihirbaz", "Çırak"], "alien": ["Astronot", "Pilot"], "mechanical": ["Siborg", "Mühendis"],
        "robot": ["Siborg", "Mühendis"], "ghost": ["Gölge", "Casus"], "monster": ["Barbar", "Güreşçi"],
        "cosmic": ["Astronot", "Kâşif"], "flower": ["Bahçıvan", "Balerin"], "fermented": ["Simyacı", "Nine"],
        "candy": ["Prenses", "Palyaço"], "meat": ["Kovboy", "Kasap"], "crunchy": ["Karateci", "Ninja"],
        "crystal": ["Prenses", "Kuyumcu"], "slime": ["Hokkabaz", "Palyaço"], "swamp": ["Avcı", "Kâşif"],
        "dough": ["Fırıncı", "Pastacı"], "dairy": ["Çoban", "Sütçü"], "fruit": ["Hokkabaz", "Bahçıvan"],
        "nature": ["İzci", "Bahçıvan"], "vegetable": ["Çiftçi", "Bahçıvan"], "default": ["Süper Kahraman", "Dedektif"],
    },
    "adj": {
        "sweet": ["Tatlı", "Şekerli", "Pembe"], "spicy": ["Acı", "Ateşli", "Kızgın"],
        "fresh": ["Taze", "Serin", "Yemyeşil"], "weird": ["Tuhaf", "Çılgın", "Kaçık"],
        "magic": ["Büyülü", "Gizemli", "Parıltılı"], "toxic": ["Zehirli", "Şüpheli", "Kapkara"],
        "volatile": ["Patlayan", "Fırtınalı", "Gürültücü"], "life": ["Kıpır Kıpır", "Canlı", "Uykusuz"],
    },
    "sequel": ["Geri Dönüş", "Son Lokma", "Mutfak Savaşları", "Gece Yarısı Saldırısı", "Tencerenin İntikamı",
               "Büyük Kaçış", "Efsane Doğuyor", "Tabak Krizi", "Kayıp Tarif", "Fırın Çağı", "Lezzetin Laneti",
               "Son Tadım"],
    "origin": {
        "ghost": ["Gece yarısı boş bir mutfakta kendiliğinden belirdi.", "Eski bir şatonun kilerinde yüzyıllarca saklandı."],
        "alien": ["Mutfağa düşen bir göktaşının içinden çıktı.", "Uzak bir gezegende yasaklanmış bir tarifti."],
        "robot": ["Bir tost makinesinin kısa devresinden doğdu.", "Bir robotun hafızasından silinmiş gizli bir koddu."],
        "monster": ["Tencerenin dibinde büyüdü ve kapağı kendisi açtı.", "Bodrumdaki dondurucudan kaçtı."],
        "frog": ["Bir bataklıkta prens olmayı beklerken tencereye zıpladı.", "Bir cadı kazanından kaçan bir vıraktan doğdu."],
        "insect": ["Bir karınca ordusu onu gizlice mutfağa taşıdı.", "Bir böcek kolonisinin kraliyet ziyafetiydi."],
        "gothic": ["Karanlık bir şatoda dolunayda pişirildi.", "Bir yarasanın sırtında gece yarısı teslim edildi."],
        "sea": ["Batık bir korsan gemisinden çıkarıldı.", "Bir kaptan onu bir kraken'le kâğıt oyununda kazandı."],
        "cosmic": ["Kayan bir yıldız tavaya düştüğünde oluştu.", "Galaksinin en uzak lokantasının menüsünden kaçtı."],
        "slime": ["Bir laboratuvar kazasında kabından taştı.", "Kimse onu yapmadı; kendiliğinden toplandı."],
        "electric": ["Fırtınalı bir gece mutfağa yıldırım düşünce ortaya çıktı.", "Bir pilin içinde yıllarca enerji biriktirdi."],
        "fire": ["Bir ejderin hapşırığıyla piştiği söylenir.", "Bir yanardağın ağzında ısıtıldı."],
        "cold": ["Bir buzulun içinde donmuş hâlde bulundu.", "Bir kardan adamın gizli tarifiydi."],
        "magic": ["Bir büyücünün yanlış okunan büyüsünden doğdu.", "Bir sihir kitabının son sayfasında saklıydı."],
        "flower": ["Bir peri bahçesinde, şafakta toplandı.", "Bir gülün dikenleri arasında büyüdü."],
        "fermented": ["Bir ninenin kilerinde yüz yıl bekledi.", "Bir kavanozun içinde sessizce olgunlaştı."],
        "luxury": ["Bir sarayın ziyafet masasından gizlice alındı.", "Bir lordun vasiyetinde miras bırakıldı."],
        "candy": ["Bir şeker fabrikasındaki makine çıldırınca üretildi.", "Bir doğum günü pastasının rüyasından doğdu."],
        "meat": ["Bir kovboy kampının ateşinde bütün gece pişti.", "Bir mangal ustasının son ve en gizli tarifiydi."],
        "default": ["Kimse nereden geldiğini bilmiyor.", "Bir şefin rüyasında ortaya çıktı.", "Mutfakta tamamen yanlışlıkla icat edildi."],
    },
    "effect": {
        "sweet": ["Bir ısırık, bir hafta gülümseme.", "Dişlerin ona hayran kalacak."],
        "spicy": ["Yiyenin kulaklarından duman çıkarır.", "Jürinin bıyıkları tutuşabilir."],
        "fresh": ["Bir lokmada bahar gelir.", "Yiyenin saçları rüzgârda uçuşur."],
        "weird": ["Yiyen herkes bir süre geri geri yürür.", "Tadını anlatmaya kelimeler yetmez."],
        "magic": ["Yiyenlere kısa süreliğine uçma yeteneği verir.", "Tabak boşalınca bir dilek hakkı doğar."],
        "toxic": ["Yanında bir doktor bulundurmanız önerilir.", "Cesur olmayanlar yalnızca koklamalı."],
        "volatile": ["Çatalla dokunmayın, patlayabilir.", "Her lokmada küçük bir havai fişek gösterisi."],
        "life": ["Tabakta durmuyor, sürekli dans ediyor.", "Yemeden önce ondan izin istemen gerekebilir."],
    },
    "lore": "{origin} {effect}",
}

PERSONA_KEYS = set(PERSONA_PRIORITY) | {"default"}
ROLE_KEYS = set(ROLE_PRIORITY) | {"default"}
ADJ_KEYS = set(ADJ_WEIGHTS)


def check(code, L):
    assert not (PERSONA_KEYS - set(L["persona"])), (code, "persona", PERSONA_KEYS - set(L["persona"]))
    assert not (ROLE_KEYS - set(L["role"])), (code, "role", ROLE_KEYS - set(L["role"]))
    assert not (ADJ_KEYS - set(L["adj"])), (code, "adj", ADJ_KEYS - set(L["adj"]))
    assert not (ADJ_KEYS - set(L["effect"])), (code, "effect")
    assert "default" in L["origin"], (code, "origin default")
    assert len(L["sequel"]) >= 8, (code, "sequel")
    for t in L["templates"]:
        assert "{persona}" in t["t"], (code, t)


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from names_langs import add_langs
    add_langs(LANG)
    for code, L in LANG.items():
        check(code, L)
    out = {"version": 1, "persona_priority": PERSONA_PRIORITY, "role_priority": ROLE_PRIORITY,
           "adj_weights": ADJ_WEIGHTS, "lang": LANG}
    with open(os.path.join(root, "data", "names.json"), "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    print("languages:", ", ".join(LANG.keys()))


if __name__ == "__main__":
    main()
