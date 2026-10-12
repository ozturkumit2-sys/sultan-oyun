"""Builds one original illustration per ingredient (assets/art/ing/<id>.svg)."""
import json, os, math
from lib import SVG, light, mix
import motifs as M

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "assets", "art", "ing")


def place(fn, x=100, y=104, k=1.0, *args, **kw):
    return (fn, x, y, k, args, kw)


def single(fn, *args, **kw):
    return [place(fn, 100, 104, 1.25, *args, **kw)]


def big(k, fn, *args, **kw):
    return [place(fn, 100, 100, k, *args, **kw)]


# id -> (wash colour, [ops], badge)
def motif_list():
    syn, acc = "synth", "accord"
    C = M.citrus
    return {
        "bergamot": ("#eef3c8", single(C, "#b8c94a", "#e3e07a"), None),
        "lemon": ("#fbf2c2", single(C, "#f3d83b", "#f6e88a"), None),
        "orange": ("#fde3c4", single(C, "#f3962b", "#f7b44c"), None),
        "grapefruit": ("#fbdcd2", single(C, "#f2b06a", "#ef6f6a"), None),
        "mandarin": ("#fde0c0", single(C, "#f0861f", "#f7a440", True, True), None),
        "lavender": ("#ece4f7", single(M.lavender), None),
        "pink_pepper": ("#f9dbe2", big(1.4, M.peppercorns), None),
        "cardamom": ("#e8f0d6", big(1.4, M.cardamom), None),
        "aldehyde_c12": ("#f6f1e2", single(M.bubbles), syn),
        "calone": ("#ddeff4", [place(M.wave, 100, 112, 1.2), place(M.melon_slice, 128, 74, 0.9, 0, 0, 1)], syn),
        "dihydromyrcenol": ("#e1f1ec", [place(M.oil_drops, 70, 100, 0.7, "#cfe9f2"), place(C, 118, 108, 0.9, "#9fcf4a", "#d6ef8a", False)], syn),
        "galbanum": ("#e6f0d4", single(M.galbanum), None),
        "linalool": ("#efe8f4", [place(M.coriander, 100, 96, 1.55)], syn),
        "rose_absolute": ("#f9d9de", [place(M.rose, 100, 98, 1.3, "#c8304f")], None),
        "rose_otto": ("#fbe2e6", [place(M.rose, 92, 98, 1.2, "#ef8aa0"), place(M.drop, 150, 132, 1.0, 0, 0, 12, "#f6d27a", 0.9)], None),
        "pea": ("#fbe4e8", big(1.35, M.rose_petals), syn),
        "jasmine_abs": ("#f6f2e6", single(M.jasmine), None),
        "hedione": ("#eef3ec", [place(M.star_flower, 96, 100, 1.45, 0, 0, 48), place(M.drop, 150, 132, 1.0, 0, 0, 9, "#dcefff", 0.8), place(M.drop, 58, 140, 1.0, 0, 0, 6, "#dcefff", 0.8)], syn),
        "neroli": ("#fbf0e2", single(M.neroli), None),
        "ionones": ("#ece2f6", single(M.violets), syn),
        "violet_leaf": ("#e2efdc", single(M.violet_leaves), None),
        "geranium": ("#f6e0e6", single(M.geranium), None),
        "orris_butter": ("#ece6f6", single(M.iris), None),
        "citronellol": ("#eef3df", [place(M.lemongrass, 78, 96, 1.15), place(M.rose, 128, 126, 0.75, "#e7708d", False)], syn),
        "geraniol": ("#f6e6ea", [place(M.geranium, 100, 104, 1.1)], syn),
        "benzyl_salicylate": ("#fbf2dc", [place(M.sun_rays, 100, 96, 1.0, 0, 0, 80, "#f2c94a", 0.45), place(M.star_flower, 100, 96, 1.0, 0, 0, 44)], syn),
        "clove": ("#f2e2d6", big(1.45, M.cloves), None),
        "ylang": ("#f6f2cf", [place(M.ylang, 100, 110, 1.45)], None),
        "muguet_accord": ("#e8f2e2", single(M.lily_of_valley), acc),
        "tuberose": ("#f7efea", single(M.tuberose), None),
        "peach_lactone": ("#fde4d6", single(M.peach), syn),
        "cassis_base": ("#ece0ee", single(M.berries), acc),
        "ethyl_maltol": ("#fbe8d2", big(1.35, M.caramel), syn),
        "safraleine": ("#f9e2da", big(1.55, M.saffron), syn),
        "patchouli": ("#e2ecd8", single(M.patchouli), None),
        "vetiver": ("#eaefd8", single(M.vetiver), None),
        "sandalwood_nat": ("#f6ead6", single(M.sandalwood), None),
        "javanol": ("#f6ead6", single(M.sandalwood), syn),
        "cedarwood": ("#f3e2d4", single(M.cedar), None),
        "iso_e_super": ("#f1e6dc", big(1.3, M.wood_ribbon), syn),
        "oud_natural": ("#efe2d6", single(M.oud), None),
        "oud_accord": ("#efe2d6", single(M.oud), acc),
        "vanilla_abs": ("#f7efd8", single(M.vanilla), None),
        "vanillin": ("#f7efe0", [place(M.vanilla, 100, 92, 1.0), place(M.crystals, 100, 140, 0.9)], syn),
        "tonka_abs": ("#f1e4d6", big(1.4, M.tonka), None),
        "coumarin": ("#f4ecd8", [place(M.tonka, 100, 88, 1.25), place(M.crystals, 112, 142, 0.9, "#fffbe8")], syn),
        "amber_accord": ("#fbe6c6", single(M.amber_gem), acc),
        "labdanum": ("#f1e2d8", big(1.4, M.labdanum), None),
        "benzoin": ("#fbe8cc", big(1.45, M.benzoin), None),
        "olibanum": ("#f6f0dc", big(1.45, M.olibanum), None),
        "ambroxan": ("#e8eef0", single(M.ambergris), syn),
        "cashmeran": ("#f6e8e0", big(1.3, M.cashmere), syn),
        "ambrette": ("#f6f0d6", big(1.4, M.ambrette), None),
        "galaxolide": ("#f8eaf0", single(M.powder_puff), syn),
        "ethylene_brassylate": ("#f2eef4", single(M.cotton), syn),
        "muscenone": ("#f2ecf6", single(M.silk), syn),
        "leather_base": ("#f1e0d2", single(M.leather), acc),
        "oakmoss_accord": ("#e4ecdc", single(M.oakmoss), acc),
        "coffee_co2": ("#efe2d6", big(1.45, M.coffee), None),
        "ethanol": ("#e8f1f6", big(1.4, M.lab_bottle, "#cfe6f2", 0.7), None),
        "dpg": ("#eaf2f6", [place(M.pipette_drop, 100, 116, 1.35)], None),
        "tec": ("#eef4ec", [place(M.pipette_drop, 86, 112, 1.3), place(C, 140, 140, 0.7, "#f3d83b", "#f6e88a", False)], None),
        "benzyl_benzoate": ("#f6f0dc", big(1.5, M.oil_drops, "#f2e3a6"), None),
        "ipm": ("#f2f2ea", big(1.5, M.oil_drops, "#e8dfb8"), None),
        "jojoba": ("#f6ecd4", [place(M.seeds, 96, 104, 1.8, "#8a6a48", 9, 2), place(M.drop, 128, 82, 1.0, 0, 0, 22, "#f0c860", 0.92)], None),
        "glycerin": ("#eef2f6", big(1.5, M.spoon_drop), None),
        "bht": ("#e8f2e2", single(M.shield, "leaf"), None),
        "uv_absorber": ("#fbf2dc", single(M.shield, "sun"), None),
    }


def build():
    os.makedirs(OUT, exist_ok=True)
    data = json.load(open(os.path.join(ROOT, "data", "ingredients.json")))
    ml = motif_list()
    missing = [i["id"] for i in data["ingredients"] if i["id"] not in ml]
    if missing:
        raise SystemExit("missing art for: %s" % missing)
    for iid, (wash, ops, badge) in ml.items():
        S = SVG(200, 200, 240, 240)
        S.circle(100, 100, 92, S.rad([(0, light(wash, 0.35)), (0.75, wash), (1, wash, 0)]))
        for fn, x, y, k, args, kw in ops:
            if fn in (M.drop, M.star_flower, M.sun_rays):
                with S.g("translate(%s %s) scale(%s)" % (x, y, k)):
                    fn(S, *args, **kw)
            else:
                with S.g("translate(%s %s) scale(%s)" % (x, y, k)):
                    fn(S, *args, **kw)
        if badge == "synth":
            M.badge_synth(S)
        elif badge == "accord":
            M.badge_accord(S)
        S.save(os.path.join(OUT, iid + ".svg"))
    return len(ml)


if __name__ == "__main__":
    print("ingredient art:", build())
