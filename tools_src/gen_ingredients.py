"""Authoring helper for data/ingredients.json (the JSON is the editable source of truth used by the game).
Units: cost = USD per kg; ten = evaporation time constant on skin in hours; str = relative odor strength;
diff = diffusion 0..1; fix = fixative effect 0..1; sol = ethanol solubility 0..1; stab = oxidation stability 0..1;
disc = discoloration tendency 0..1; reg.max = fictional max % in finished product (simplified game rule)."""
import json
D = ["citrus","aromatic","green","aquatic","floral","fruity","gourmand","spicy","woody","amber","musk","powdery","animalic"]
def I(id, name, cat, note, odor, st, vol, ten, diff, fix, cost, tier, nat, sup, sol=0.95, stab=0.8, disc=0.0, cryst=False,
      maxp=None, allergen=False, anos=0.0, rough=0.0, avail=0.95, origin="", harvest=0, desc="", role="aromatic"):
    return dict(id=id, name=name, cat=cat, role=role, note=note, odor=odor, str=st, vol=vol, ten=ten, diff=diff, fix=fix,
                cost=cost, tier=tier, nat=nat, sup=sup, sol=sol, stab=stab, disc=disc, cryst=cryst,
                reg={"max": maxp, "allergen": allergen}, anos=anos, rough=rough, avail=avail, origin=origin,
                harvest=harvest, desc=desc)
L = [
# ---------- TOP ----------
I("bergamot","Bergamot Oil (FCF)","Citrus oil","top",{"citrus":.9,"aromatic":.2,"floral":.15},1.0,.92,1.1,.75,0,85,0,True,"natural",stab=.45,allergen=True,origin="Calabria, Italy",harvest=1,desc="Bright, tea-like citrus with a floral lift. Bergaptene-free grade."),
I("lemon","Lemon Oil","Citrus oil","top",{"citrus":1.0,"green":.2},1.1,.97,.7,.8,0,45,0,True,"natural",stab=.35,maxp=2.0,allergen=True,origin="Sicily / Argentina",harvest=11,desc="Sharp zesty lemon peel. Fades fast; oxidizes without antioxidant."),
I("orange","Sweet Orange Oil","Citrus oil","top",{"citrus":.9,"fruity":.35},.8,.95,.8,.7,0,12,0,True,"natural",stab=.35,allergen=True,origin="Brazil",harvest=7,desc="Juicy, sweet and cheerful. Inexpensive but short-lived."),
I("grapefruit","Grapefruit Oil","Citrus oil","top",{"citrus":.9,"fruity":.2,"green":.15},.9,.95,.8,.78,0,70,0,True,"natural",stab=.35,maxp=4.0,origin="Florida, USA",harvest=12,desc="Bitter-fresh pink grapefruit with a sulfurous sparkle."),
I("mandarin","Mandarin Oil","Citrus oil","top",{"citrus":.8,"fruity":.45,"floral":.05},.9,.93,.9,.7,0,65,1,True,"natural",stab=.4,origin="Sicily, Italy",harvest=12,desc="Soft, sweet, slightly floral citrus."),
I("lavender","Lavender Oil","Herbal oil","top",{"aromatic":.85,"floral":.4,"green":.1,"powdery":.05},1.0,.75,2.2,.62,0,110,0,True,"natural",stab=.7,allergen=True,origin="Provence, France",harvest=7,desc="Herbaceous, clean and calming. Backbone of fougère accords."),
I("pink_pepper","Pink Pepper CO2","Spice extract","top",{"spicy":.7,"citrus":.3,"woody":.1},1.2,.85,1.6,.72,0,420,1,True,"natural",stab=.6,origin="Réunion",harvest=6,desc="Rosy, peppery sparkle that lifts an opening."),
I("cardamom","Cardamom Oil","Spice oil","top",{"spicy":.7,"aromatic":.45,"citrus":.1},1.2,.82,1.8,.68,0,380,1,True,"natural",stab=.6,origin="Guatemala",harvest=10,desc="Fresh, camphorous, cool spice."),
I("aldehyde_c12","Aldehyde C-12 MNA","Aroma chemical","top",{"powdery":.4,"citrus":.3,"musk":.25,"aquatic":.1},2.5,.7,3.0,.9,0,70,1,False,"synthetic",stab=.55,rough=.45,desc="Sparkling, waxy-metallic 'clean linen' aldehyde. Harsh when overdosed; softens with maturation."),
I("calone","Calone","Aroma chemical","top",{"aquatic":1.0,"fruity":.2},4.0,.7,5.0,.72,0,260,1,False,"synthetic",cryst=True,desc="Marine, watermelon-ozonic. Extremely powerful: tiny doses suffice."),
I("dihydromyrcenol","Dihydromyrcenol","Aroma chemical","top",{"citrus":.45,"aromatic":.45,"aquatic":.2},1.0,.85,1.8,.82,0,9,0,False,"synthetic",stab=.85,desc="Clean metallic lime-lavender freshness. Workhorse of fresh masculines."),
I("galbanum","Galbanum Oil","Resin oil","top",{"green":1.0,"woody":.1},2.0,.75,2.5,.7,.05,350,1,True,"natural",stab=.6,origin="Iran",harvest=8,desc="Piercing bitter-green, crushed stems and leaves."),
I("linalool","Linalool","Aroma chemical","top",{"floral":.5,"aromatic":.3,"citrus":.3},.6,.8,1.6,.66,0,14,0,False,"synthetic",stab=.7,allergen=True,desc="Light floral-woody freshness, bridges citrus and florals."),
# ---------- HEART ----------
I("rose_absolute","Rose Absolute","Floral absolute","heart",{"floral":1.0,"fruity":.2,"spicy":.1,"gourmand":.05},1.6,.45,5.0,.45,.05,6500,2,True,"natural",sol=.85,stab=.7,disc=.25,allergen=True,rough=.15,avail=.8,origin="Isparta, Türkiye",harvest=5,desc="Deep honeyed rose, rich and full-bodied."),
I("rose_otto","Rose Otto (Rose Oil)","Floral oil","heart",{"floral":1.0,"green":.15,"fruity":.1},1.4,.55,3.5,.55,0,11000,3,True,"natural",sol=.8,stab=.75,allergen=True,avail=.6,origin="Kazanlak, Bulgaria",harvest=6,desc="Luminous dewy rose, lemony and green. Rare and costly."),
I("pea","Phenylethyl Alcohol","Aroma chemical","heart",{"floral":.85,"green":.1,"fruity":.1},.35,.5,3.0,.42,0,8,0,False,"synthetic",stab=.9,desc="Soft fresh rose petal. Cheap, gentle, versatile."),
I("jasmine_abs","Jasmine Grandiflorum Absolute","Floral absolute","heart",{"floral":1.0,"fruity":.2,"animalic":.35},2.0,.4,6.0,.5,.05,5200,2,True,"natural",sol=.85,stab=.7,disc=.6,allergen=True,rough=.15,avail=.75,origin="Grasse / India",harvest=8,desc="Narcotic, indolic white floral. Becomes animalic at high doses."),
I("hedione","Hedione","Aroma chemical","heart",{"floral":.7,"citrus":.2,"green":.1},.35,.45,6.0,.95,0,28,0,False,"synthetic",stab=.92,desc="Transparent airy jasmine. Adds diffusion and radiance rather than loudness."),
I("neroli","Neroli Oil","Floral oil","heart",{"floral":.7,"citrus":.4,"green":.2},1.3,.7,2.0,.75,0,5200,2,True,"natural",stab=.6,allergen=True,avail=.75,origin="Tunisia",harvest=4,desc="Orange blossom distillate: bright, green, honeyed."),
I("ionones","Alpha/Beta Ionones (Violet)","Aroma chemical","heart",{"floral":.6,"powdery":.7,"woody":.2},1.0,.4,8.0,.5,.05,40,0,False,"synthetic",stab=.85,desc="Violet flower and orris-like powder with a woody edge."),
I("violet_leaf","Violet Leaf Absolute","Leaf absolute","heart",{"green":1.0,"aquatic":.2,"floral":.1},2.5,.6,3.5,.55,0,4000,2,True,"natural",sol=.85,stab=.65,origin="Egypt",harvest=3,desc="Cucumber-green, metallic leafy freshness."),
I("geranium","Geranium Oil","Floral oil","heart",{"floral":.7,"aromatic":.3,"green":.2,"citrus":.1},1.2,.6,3.0,.6,0,160,0,True,"natural",stab=.75,allergen=True,origin="Egypt",harvest=6,desc="Rosy-minty and green. An affordable rose companion."),
I("orris_butter","Orris Butter (Iris)","Root butter","heart",{"powdery":1.0,"woody":.2,"floral":.2},1.5,.25,12.0,.35,.2,45000,3,True,"natural",sol=.7,stab=.85,avail=.4,origin="Tuscany, Italy",harvest=8,desc="Cool buttery iris root powder. Among the costliest materials in perfumery."),
I("citronellol","Citronellol","Aroma chemical","heart",{"floral":.9,"citrus":.2},.7,.5,3.5,.55,0,22,0,False,"synthetic",stab=.8,maxp=4.0,allergen=True,desc="Fresh rosy-citrus alcohol, rose backbone."),
I("geraniol","Geraniol","Aroma chemical","heart",{"floral":.8,"citrus":.2,"fruity":.1},.7,.5,3.2,.55,0,20,0,False,"synthetic",stab=.75,maxp=1.5,allergen=True,desc="Sweet rosy-geranium alcohol."),
I("benzyl_salicylate","Benzyl Salicylate","Aroma chemical","base",{"floral":.4,"musk":.2,"powdery":.2},.15,.15,20.0,.25,.25,9,0,False,"synthetic",stab=.95,allergen=True,desc="Faint balsamic-floral; fixes florals and dissolves musks."),
I("clove","Clove Bud Oil","Spice oil","heart",{"spicy":1.0,"woody":.1},1.6,.5,4.0,.55,.05,55,1,True,"natural",stab=.7,disc=.35,maxp=.5,allergen=True,origin="Madagascar",harvest=10,desc="Warm, medicinal clove spice (eugenol-rich)."),
I("ylang","Ylang-Ylang Oil","Floral oil","heart",{"floral":.9,"fruity":.2,"spicy":.1,"gourmand":.1},1.5,.45,4.5,.5,.05,220,0,True,"natural",stab=.75,allergen=True,origin="Comoros",harvest=4,desc="Creamy, banana-like exotic floral."),
I("muguet_accord","Lily of the Valley Accord","Accord","heart",{"floral":1.0,"green":.3,"aquatic":.1},.8,.5,4.0,.7,0,90,0,False,"accord",stab=.9,desc="Fresh green-floral muguet built from modern synthetics."),
I("tuberose","Tuberose Absolute","Floral absolute","heart",{"floral":1.0,"gourmand":.2,"animalic":.2,"green":.1},2.0,.4,7.0,.55,.05,9000,2,True,"natural",sol=.85,stab=.7,disc=.4,allergen=True,avail=.6,origin="Tamil Nadu, India",harvest=9,desc="Creamy, buttery, almost carnal white floral."),
I("peach_lactone","Gamma Decalactone (Peach)","Aroma chemical","heart",{"fruity":1.0,"gourmand":.3},1.5,.35,8.0,.5,0,45,0,False,"synthetic",stab=.85,desc="Velvety ripe peach and apricot."),
I("cassis_base","Blackcurrant (Cassis) Base","Accord","top",{"fruity":1.0,"green":.3},1.5,.75,2.2,.65,0,140,1,False,"accord",stab=.8,desc="Tart blackcurrant buds, juicy and green."),
I("ethyl_maltol","Ethyl Maltol","Aroma chemical","heart",{"gourmand":1.0,"fruity":.3},2.5,.35,9.0,.55,.05,28,0,False,"synthetic",cryst=True,disc=.2,desc="Cotton candy, caramelized sugar. Cloying when overdosed."),
I("safraleine","Safraleine (Saffron-type)","Aroma chemical","heart",{"spicy":.6,"animalic":.4,"woody":.2},3.0,.35,9.0,.55,.05,450,1,False,"synthetic",maxp=1.0,desc="Leathery saffron with a metallic warmth."),
# ---------- BASE ----------
I("patchouli","Patchouli Oil","Wood oil","base",{"woody":.8,"amber":.1,"green":.1,"animalic":.1},1.5,.12,14.0,.4,.35,95,0,True,"natural",stab=.85,disc=.15,rough=.3,origin="Sulawesi, Indonesia",harvest=0,desc="Earthy, dark, camphorous wood. Matures and smooths with time."),
I("vetiver","Vetiver Oil (Haiti)","Root oil","base",{"woody":1.0,"green":.3,"animalic":.1},1.3,.1,15.0,.35,.3,380,1,True,"natural",stab=.85,rough=.15,origin="Haiti",harvest=0,desc="Smoky, earthy, grapefruit-tinged roots."),
I("sandalwood_nat","Sandalwood Oil (Australian)","Wood oil","base",{"woody":.9,"musk":.2,"gourmand":.1},.7,.08,16.0,.25,.3,2400,2,True,"natural",stab=.9,avail=.6,origin="Western Australia",harvest=0,desc="Creamy, milky, soft wood. Subtle, long and expensive."),
I("javanol","Javanol (Sandalwood synthetic)","Aroma chemical","base",{"woody":.9,"musk":.1,"floral":.05},3.0,.06,22.0,.5,.2,650,1,False,"synthetic",stab=.95,desc="Powerful creamy-rosy sandalwood. Very different from the natural oil: brighter, more diffusive."),
I("cedarwood","Virginia Cedarwood Oil","Wood oil","base",{"woody":1.0,"aromatic":.1},.8,.15,11.0,.4,.25,32,0,True,"natural",stab=.9,origin="Virginia, USA",harvest=0,desc="Dry, pencil-shaving cedar."),
I("iso_e_super","Iso E Super","Aroma chemical","base",{"woody":.9,"amber":.3,"musk":.2},.35,.1,14.0,.75,.2,32,0,False,"synthetic",stab=.95,anos=.25,desc="Velvety cedar-amber 'aura'. Radiant; some people barely perceive it."),
I("oud_natural","Agarwood (Oud) Oil","Wood oil","base",{"animalic":.7,"woody":.8,"amber":.2,"spicy":.05},3.0,.05,18.0,.42,.4,32000,3,True,"natural",sol=.85,stab=.85,disc=.3,rough=.5,avail=.3,origin="Assam / Southeast Asia",harvest=0,desc="Fermented, barnyard-animalic, resinous wood. Raw at first; rewards maturation."),
I("oud_accord","Oud Accord (reconstructed)","Accord","base",{"woody":.9,"animalic":.35,"amber":.25},2.0,.08,12.0,.55,.25,220,1,False,"accord",stab=.9,desc="Clean, smoky reconstruction of oud without the farmyard facets."),
I("vanilla_abs","Vanilla Absolute","Pod absolute","base",{"gourmand":1.0,"amber":.2,"woody":.1,"powdery":.1},1.0,.1,14.0,.25,.35,3200,2,True,"natural",sol=.7,stab=.85,disc=.7,avail=.7,origin="Madagascar",harvest=7,desc="Dark, boozy, smoky natural vanilla. Colors the juice."),
I("vanillin","Vanillin","Aroma chemical","base",{"gourmand":1.0,"powdery":.2},2.0,.08,14.0,.3,.3,16,0,False,"synthetic",cryst=True,disc=.8,desc="Classic sweet vanilla. Crystalline; browns over time."),
I("tonka_abs","Tonka Bean Absolute","Bean absolute","base",{"gourmand":.6,"powdery":.4,"amber":.3,"aromatic":.2},1.3,.12,12.0,.3,.3,900,1,True,"natural",sol=.75,stab=.85,disc=.4,maxp=2.5,allergen=True,origin="Venezuela",harvest=2,desc="Almond-hay-vanilla warmth, rich in coumarin."),
I("coumarin","Coumarin","Aroma chemical","base",{"powdery":.6,"gourmand":.4,"aromatic":.4,"green":.1},1.0,.15,10.0,.35,.2,16,0,False,"synthetic",cryst=True,maxp=1.6,allergen=True,desc="Sweet hay and almond. Essential to fougères."),
I("amber_accord","Amber Accord","Accord","base",{"amber":1.0,"gourmand":.3,"powdery":.2},1.2,.1,14.0,.4,.45,140,0,False,"accord",stab=.85,disc=.3,desc="Warm labdanum-vanilla 'oriental' amber base."),
I("labdanum","Labdanum Absolute","Resin absolute","base",{"amber":.9,"animalic":.3,"woody":.2},1.6,.1,16.0,.3,.5,380,1,True,"natural",sol=.6,stab=.85,disc=.4,rough=.25,origin="Andalusia, Spain",harvest=6,desc="Dark, leathery, ambery resin from rockrose."),
I("benzoin","Benzoin Siam Resinoid","Resinoid","base",{"amber":.8,"gourmand":.5},.8,.08,16.0,.2,.5,75,1,True,"natural",sol=.5,stab=.85,disc=.45,origin="Laos",harvest=0,desc="Balsamic vanillic resin. Needs a solvent; excellent fixative."),
I("olibanum","Olibanum (Frankincense) Oil","Resin oil","top",{"amber":.4,"citrus":.3,"woody":.3,"spicy":.2},1.2,.6,4.0,.6,.1,260,1,True,"natural",stab=.7,origin="Somalia / Oman",harvest=0,desc="Lemony, peppery incense smoke."),
I("ambroxan","Ambroxan","Aroma chemical","base",{"amber":.8,"woody":.4,"musk":.4},3.0,.05,22.0,.85,.35,900,1,False,"synthetic",cryst=True,stab=.95,anos=.15,desc="Mineral ambergris: salty, woody, radiant. A little goes a long way."),
I("cashmeran","Cashmeran","Aroma chemical","base",{"woody":.6,"musk":.4,"amber":.3,"spicy":.1},1.2,.12,16.0,.55,.25,140,1,False,"synthetic",stab=.9,desc="Velvety musky wood with a piney, spicy softness."),
I("ambrette","Ambrette Seed Oil","Seed oil","base",{"musk":.8,"fruity":.3,"floral":.2,"animalic":.1},1.2,.2,10.0,.4,.3,9500,3,True,"natural",stab=.8,avail=.4,origin="Ecuador / India",harvest=9,desc="Natural botanical musk: pear-wine, skin-like. Not the same as synthetic musks."),
I("galaxolide","Galaxolide (Polycyclic Musk)","Aroma chemical","base",{"musk":1.0,"floral":.2,"powdery":.2},.6,.04,25.0,.45,.35,10,0,False,"synthetic",stab=.95,maxp=5.0,anos=.1,desc="Clean 'fresh laundry' musk. Cheap and tenacious."),
I("ethylene_brassylate","Ethylene Brassylate","Aroma chemical","base",{"musk":.9,"powdery":.2},.4,.03,28.0,.35,.3,22,0,False,"synthetic",stab=.95,desc="Soft, sweet macrocyclic-style musk."),
I("muscenone","Muscenone (Macrocyclic Musk)","Aroma chemical","base",{"musk":1.0,"animalic":.2,"powdery":.1},1.5,.03,30.0,.5,.35,1500,2,False,"synthetic",stab=.95,desc="Warm, sensual skin musk of great elegance."),
I("leather_base","Leather Base","Accord","base",{"animalic":.8,"woody":.3,"spicy":.2},3.0,.1,12.0,.5,.25,210,1,False,"accord",stab=.85,disc=.25,rough=.3,desc="Smoky birch-tar style leather."),
I("oakmoss_accord","Oakmoss Accord (low-atranol)","Accord","base",{"green":.5,"woody":.6,"animalic":.2},1.5,.12,14.0,.35,.3,180,1,False,"accord",stab=.85,maxp=1.0,allergen=True,desc="Damp, inky forest-floor moss. Heart of the chypre family."),
I("coffee_co2","Coffee CO2 Extract","Extract","heart",{"gourmand":.8,"woody":.2,"spicy":.05},1.8,.35,5.0,.45,.05,600,1,True,"natural",sol=.8,stab=.7,disc=.5,origin="Ethiopia",harvest=11,desc="Roasted, rich coffee beans."),
# ---------- SOLVENTS / CARRIERS / AUXILIARIES ----------
I("ethanol","Perfumer's Ethanol 96%","Solvent","solvent",{},0,1,0,0,0,2.5,0,False,"solvent",role="solvent",desc="Main diluent of alcohol-based perfumes. Controls dilution and the initial evaporation bloom."),
I("dpg","Dipropylene Glycol (DPG)","Solvent","solvent",{},0,0,0,0,0,3,0,False,"solvent",role="solvent",desc="Odorless diluent; dissolves crystals. Dilutes strength; no magical boost."),
I("tec","Triethyl Citrate (TEC)","Solvent","solvent",{},0,0,0,0,.05,6,0,False,"solvent",role="solvent",desc="Odorless solvent, slight fixation, helps solubility."),
I("benzyl_benzoate","Benzyl Benzoate","Solvent","solvent",{"amber":.1},.05,0,30,0,.15,7,0,False,"solvent",role="solvent",allergen=True,desc="Solvent for resins and crystals with a faint balsamic note."),
I("ipm","Isopropyl Myristate (IPM)","Carrier","carrier",{},0,0,0,0,.05,5,0,False,"solvent",role="carrier",desc="Oily carrier. Reduces diffusion; for oil formats."),
I("jojoba","Jojoba Oil","Carrier","carrier",{},0,0,0,0,.05,18,0,True,"natural",role="carrier",desc="Natural liquid wax carrier for perfume oils."),
I("glycerin","Glycerin","Auxiliary","auxiliary",{},0,0,0,0,0,2,0,False,"solvent",role="auxiliary",desc="Humectant. Does not extend longevity; excess feels sticky and dampens diffusion."),
I("bht","BHT (Antioxidant)","Auxiliary","auxiliary",{},0,0,0,0,0,12,0,False,"synthetic",role="auxiliary",maxp=.1,desc="Antioxidant: protects citrus terpenes and aldehydes from oxidation."),
I("uv_absorber","UV Absorber","Auxiliary","auxiliary",{},0,0,0,0,0,30,1,False,"synthetic",role="auxiliary",maxp=.3,desc="Reduces light-induced discoloration in clear glass."),
]
for x in L:
    for k in x["odor"]: assert k in D, (x["id"], k)
json.dump({"dims": D, "ingredients": L}, open("data/ingredients.json","w"), indent=1)
print(len(L), "ingredients;", sum(1 for x in L if x["role"]=="aromatic"), "aromatic;", sum(1 for x in L if x["tier"]==0 and x["role"]=="aromatic"), "starter aromatic")
