import json
N = {
 "people": {
  "FR": {"f":["Camille","Élise","Margaux","Inès","Chloé","Juliette","Léa","Manon","Sophie","Amélie","Claire","Hélène"],"m":["Antoine","Julien","Mathieu","Louis","Hugo","Pierre","Olivier","Thibault","Rémi","Lucien","Étienne","Gaspard"],"l":["Delmas","Rousseau","Fontaine","Marchand","Lefèvre","Girard","Moreau","Bonnet","Duval","Laurent","Mercier","Chevalier","Garnier","Blanchet"]},
  "US": {"f":["Emily","Madison","Hannah","Olivia","Grace","Ava","Lauren","Megan","Sarah","Brooke","Kayla","Natalie"],"m":["Ethan","Mason","Jacob","Logan","Ryan","Tyler","Caleb","Nathan","Austin","Carter","Dylan","Owen"],"l":["Carter","Hughes","Bennett","Reed","Brooks","Hayes","Morgan","Parker","Sullivan","Foster","Coleman","Price","Wallace","Bishop"]},
  "GB": {"f":["Charlotte","Amelia","Isla","Poppy","Harriet","Imogen","Freya","Eleanor","Rosie","Matilda"],"m":["Oliver","Harry","George","Alfie","Rupert","Edward","Freddie","Archie","Hugh","Callum"],"l":["Whitfield","Ashworth","Pemberton","Harding","Fairfax","Thornton","Cavendish","Hollis","Prescott","Winslow","Kendall","Marlow"]},
  "DE": {"f":["Lena","Hannah","Lea","Mia","Katharina","Johanna","Sophie","Anika","Greta","Clara"],"m":["Lukas","Jonas","Felix","Maximilian","Tobias","Florian","Niklas","Moritz","Paul","Jan"],"l":["Becker","Hoffmann","Schröder","Wagner","Krüger","Neumann","Brandt","Vogel","Keller","Lindner","Hartmann","Seidel"]},
  "TR": {"f":["Elif","Zeynep","Defne","Ece","Selin","Ayşe","Melis","Derya","Nazlı","İpek","Cansu","Deniz"],"m":["Emre","Can","Mert","Burak","Kerem","Arda","Onur","Kaan","Tolga","Selim","Barış","Efe"],"l":["Yılmaz","Kaya","Demir","Şahin","Çelik","Aydın","Öztürk","Arslan","Doğan","Kılıç","Aksoy","Erdem","Tekin","Güneş"]},
  "JP": {"f":["Yui","Haruka","Aoi","Sakura","Mio","Rina","Natsuki","Emi","Kaori","Yuna"],"m":["Haruto","Ren","Sota","Daiki","Kenta","Yuto","Takumi","Riku","Kaito","Shun"],"l":["Tanaka","Watanabe","Sato","Kobayashi","Nakamura","Yamamoto","Inoue","Kimura","Hayashi","Shimizu","Mori","Fujita"]},
  "BR": {"f":["Ana","Beatriz","Larissa","Camila","Fernanda","Mariana","Juliana","Luana","Isabela","Gabriela"],"m":["Lucas","Rafael","Thiago","Bruno","Gustavo","Felipe","Rodrigo","Mateus","Caio","Diego"],"l":["Silva","Souza","Oliveira","Costa","Almeida","Ferreira","Ribeiro","Carvalho","Rocha","Mendes","Barbosa","Teixeira"]},
  "AE": {"f":["Mariam","Noura","Aisha","Hessa","Layla","Fatima","Sara","Reem","Shamma","Alia"],"m":["Omar","Khalid","Hamdan","Saeed","Rashid","Yousef","Ahmed","Faisal","Majid","Tariq"],"l":["Al Mansouri","Al Hashimi","Al Nuaimi","Al Mazrouei","Al Suwaidi","Al Qassimi","Al Shamsi","Al Ketbi","Al Falasi","Al Marzooqi"]},
  "IT": {"f":["Giulia","Francesca","Chiara","Alessia","Martina","Valentina"],"m":["Marco","Luca","Matteo","Andrea","Davide","Stefano"],"l":["Ricci","Conti","Romano","Esposito","Marino","Ferrari","Galli","Bellini","Rinaldi","Lombardi"]},
  "IN": {"f":["Ananya","Priya","Kavya","Meera","Isha","Diya"],"m":["Arjun","Rohan","Vikram","Aditya","Karan","Nikhil"],"l":["Sharma","Iyer","Kapoor","Mehta","Nair","Reddy","Banerjee","Joshi","Malhotra","Desai"]}
 },
 "name_words": {
  "adj":["Velvet","Golden","Silent","Midnight","Wild","Secret","Liquid","Endless","Bare","Burning","Crystal","Hidden","Electric","Soft","Ivory","Black","White","Sacred","Lost","Infinite","Pale","Gilded","Smoked","Radiant","Second","Morning","Blue","Scarlet","Feral","Quiet","Sun-Kissed","Salted","Iced","Royal","Paper","Glass","Opal","Amber","Copper","Rose"],
  "noun":["Dune","Garden","Ember","Tide","Orchard","Bloom","Reverie","Muse","Horizon","Oasis","Atelier","Promise","Hour","Comet","Lagoon","Veil","Grove","Nocturne","Odyssey","Mirage","Petal","Harbor","Canvas","Ritual","Cathedral","Meadow","Sonata","Desert","Island","Halo","Ballad","Archive","Fable","Prism","Monsoon","Valley","Embrace","Letter","Library","Thread"],
  "french":["Nuit","Lumière","Rêve","Éclat","Ciel","Soie","Âme","Jardin","Ombre","Aube","Flamme","Plume","Brume","Désir","Fleur"],
  "single":["Aurelia","Solenne","Nacre","Elyra","Corvus","Zephyr","Lysandre","Ambra","Noctis","Seraphine","Ondine","Kairos","Vespera","Iridia","Talisman","Aether","Cassia","Orion","Sable","Marisol","Verbena","Halcyon","Oriane","Calypso"]
 },
 "brand_words": ["Maison","Atelier","House of","Studio","Parfums","Laboratoire","Essence","Officine","Le Cabinet","Archive"],
 "partners": {
  "marketplace":["ClickCart","ParfumDirect","ShopNest","Glowbox Online","eScent","BeautyBay Market"],
  "perfumery":["Lumière Parfumerie","The Scent Room","Atelier Nez","Olfactory House","Le Flacon","Essenza Boutique"],
  "beauty":["BeautyHub","GlowCo","Prism Beauty","Velvet & Co.","Bella Store","Radiance Beauty"],
  "dept":["Hautville","Grand Maison","Kingsgate","Royal Arcade","Galeries Orion","Sterling & Hart"],
  "mass":["DailyMart","FreshDrug","ValueBeauty","QuickCare","PharmaPlus","SmartShop"],
  "distributor":["Continental Brands Dist.","Meridian Trade","Atlas Distribution","Silk Road Partners","Nova Import Group","Harbor Brands"]
 },
 "critics":[
  {"name":"Clarisse Moreau","outlet":"Le Nez Moderne","pref":"floral powdery","bias":{"floral":.4,"powdery":.4,"gourmand":-.3},"complexity":.6},
  {"name":"Dan Whitaker","outlet":"Basenotes Weekly","pref":"woody amber","bias":{"woody":.5,"amber":.4,"aquatic":-.2},"complexity":.3},
  {"name":"Yuki Sato","outlet":"Kaori Journal","pref":"minimal musks","bias":{"musk":.5,"green":.3,"animalic":-.4},"complexity":.1},
  {"name":"Rafael Costa","outlet":"Cheiro Crítico","pref":"fresh citrus","bias":{"citrus":.5,"aromatic":.3,"fruity":.2},"complexity":-.1},
  {"name":"Leyla Arslan","outlet":"Esans Review","pref":"oriental and oud","bias":{"amber":.4,"animalic":.4,"spicy":.3},"complexity":.5},
  {"name":"Margot Fairfax","outlet":"The Scent Ledger","pref":"avant-garde","bias":{"green":.2,"animalic":.3,"powdery":.2},"complexity":.9},
  {"name":"Hannah Brooks","outlet":"SweetNotes TV","pref":"gourmand fans","bias":{"gourmand":.6,"fruity":.3},"complexity":-.2}
 ],
 "handles_a":["scent","notes","sillage","nose","fume","bottle","spritz","juice","drydown","atomizer","musky","citrus","velvet","amber","oud"],
 "handles_b":["diaries","daily","lab","queen","king","talks","journal","hunter","addict","club","stories","guru","world","vibes","edit"],
 "celebs":["Aria Vale","Marco Lenz","Sofia Marchetti","Jonah Blake","Lila Moreau","Kenji Arata","Nadia Rahman","Theo Castillo","Isabelle Fontaine","Zara Okafor","Leo Hartmann","Camila Reyes","Elena Sorel","Ryan Ashby"],
 "celeb_roles":["actress","actor","pop singer","football star","supermodel","tennis champion","chef & TV host","film director","jazz musician","Formula racer"],
 "banks":["Northbridge Bank","Atlas Commercial","Crescent Capital Bank","Banque Lumière","Meridian Trust"],
 "funds":["Aurum Ventures","Bluefield Partners","Sable Growth Capital","Lumen Equity","Orchid Holdings","Kestrel Capital"],
 "board":["Victoria Hale","Robert Chen","Amira Haddad","Giles Montague","Sun-Hee Park","Daniel Okoye","Ingrid Larsen","Paolo Ferretti"]
}
json.dump(N, open("data/names.json","w"), ensure_ascii=False, indent=1)
D = ["citrus","aromatic","green","aquatic","floral","fruity","gourmand","spicy","woody","amber","musk","powdery","animalic"]
R = [
 {"id":"delacour","name":"Maison Delacour","home":"FR","cash":38000000,"style":"luxury","mkt":.14,"risk":.3,"offices":["FR","US","GB","AE","JP"],
  "brands":[{"name":"Delacour Paris","posit":"luxury","color":"#c9a55a","prestige":.82,"aw":.38,"family":["floral","powdery","musk"],"n":5},
            {"name":"Atelier Delacour","posit":"niche","color":"#6b4c8a","prestige":.7,"aw":.12,"family":["woody","animalic","spicy"],"n":3}]},
 {"id":"aurelia","name":"Aurelia Beauty Group","home":"US","cash":52000000,"style":"mass","mkt":.18,"risk":.5,"offices":["US","GB","DE","BR","FR"],
  "brands":[{"name":"Aurelia","posit":"mass","color":"#e07a9b","prestige":.42,"aw":.45,"family":["fruity","gourmand","floral"],"n":6},
            {"name":"Bloom & Co","posit":"budget","color":"#f2b45a","prestige":.22,"aw":.35,"family":["fruity","citrus","gourmand"],"n":5}]},
 {"id":"kintsugi","name":"Kintsugi Parfums","home":"JP","cash":9000000,"style":"niche","mkt":.12,"risk":.4,"offices":["JP","FR","US"],
  "brands":[{"name":"Kintsugi","posit":"niche","color":"#2d6a6a","prestige":.66,"aw":.14,"family":["green","musk","woody"],"n":4},
            {"name":"Hana Mist","posit":"mass","color":"#f0a8c0","prestige":.38,"aw":.22,"family":["floral","aquatic","musk"],"n":3}]},
 {"id":"alnoor","name":"House of Al Noor","home":"AE","cash":21000000,"style":"luxury","mkt":.15,"risk":.4,"offices":["AE","TR","GB","FR"],
  "brands":[{"name":"Al Noor","posit":"luxury","color":"#8a5a2b","prestige":.74,"aw":.3,"family":["amber","animalic","woody"],"n":5},
            {"name":"Saba Oud","posit":"premium","color":"#5a3d2b","prestige":.5,"aw":.22,"family":["amber","spicy","gourmand"],"n":4}]},
 {"id":"brightwell","name":"Brightwell & Finch","home":"GB","cash":14000000,"style":"premium","mkt":.12,"risk":.3,"offices":["GB","US","DE"],
  "brands":[{"name":"Brightwell","posit":"premium","color":"#2b4a6b","prestige":.6,"aw":.26,"family":["aromatic","citrus","woody"],"n":5},
            {"name":"Finch Street","posit":"mass","color":"#7aa36b","prestige":.36,"aw":.24,"family":["citrus","floral","fruity"],"n":4}]},
 {"id":"verdana","name":"Verdana Cosmetics","home":"BR","cash":12000000,"style":"mass","mkt":.13,"risk":.5,"offices":["BR","US"],
  "brands":[{"name":"Verdana","posit":"premium","color":"#3f7d4f","prestige":.5,"aw":.3,"family":["green","citrus","floral"],"n":4},
            {"name":"Brisa","posit":"budget","color":"#59b7c9","prestige":.2,"aw":.32,"family":["citrus","fruity","aquatic"],"n":5}]},
 {"id":"nordlicht","name":"Nordlicht Duftwerke","home":"DE","cash":11000000,"style":"premium","mkt":.11,"risk":.3,"offices":["DE","GB","FR"],
  "brands":[{"name":"Nordlicht","posit":"premium","color":"#4a6b8a","prestige":.55,"aw":.24,"family":["aquatic","citrus","aromatic"],"n":4},
            {"name":"Klar","posit":"mass","color":"#9bb8d0","prestige":.32,"aw":.26,"family":["musk","citrus","aquatic"],"n":4}]},
 {"id":"anatolia","name":"Anatolia Esans","home":"TR","cash":6000000,"style":"mass","mkt":.13,"risk":.6,"offices":["TR","AE","DE"],
  "brands":[{"name":"Anatolia","posit":"mass","color":"#b5473a","prestige":.34,"aw":.3,"family":["floral","amber","gourmand"],"n":4},
            {"name":"Lale Atelier","posit":"premium","color":"#7a2f4a","prestige":.5,"aw":.12,"family":["floral","spicy","amber"],"n":3}]}
]
json.dump({"rivals":R}, open("data/competitors.json","w"), ensure_ascii=False, indent=1)
print("ok")
