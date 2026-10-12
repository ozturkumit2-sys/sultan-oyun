"""World map preprocessing: renders the base map PNG and exports simplified polygons for supported markets."""
import json, sys
from shapely.geometry import shape, Polygon, MultiPolygon
from PIL import Image, ImageDraw, ImageFilter
import topojson

SRC = sys.argv[1]
OUT_PNG, OUT_JSON = "assets/map/world.png", "data/world_map.json"
W, H = 2048, 800
LAT_TOP, LAT_BOT = 80.0, -58.0
IDS = {"792": "TR", "250": "FR", "840": "US", "826": "GB", "276": "DE", "784": "AE", "392": "JP", "076": "BR"}

def proj(lon, lat):
    return ((lon + 180.0) / 360.0, (LAT_TOP - lat) / (LAT_TOP - LAT_BOT))

topo = json.load(open(SRC))
gj = topojson.Topology(topo, topology=True).to_geojson() if False else None
# Convert TopoJSON manually (arcs decoding) for robustness
tr = topo.get("transform")
arcs = []
for arc in topo["arcs"]:
    x = y = 0; pts = []
    for p in arc:
        if tr:
            x += p[0]; y += p[1]
            pts.append((x * tr["scale"][0] + tr["translate"][0], y * tr["scale"][1] + tr["translate"][1]))
        else:
            pts.append(tuple(p))
    arcs.append(pts)

def ring(idxs):
    out = []
    for i in idxs:
        a = arcs[i] if i >= 0 else arcs[~i][::-1]
        out.extend(a if not out else a[1:])
    return out

def geom(g):
    polys = []
    if g["type"] == "Polygon":
        polys.append([ring(r) for r in g["arcs"]])
    elif g["type"] == "MultiPolygon":
        for p in g["arcs"]:
            polys.append([ring(r) for r in p])
    return polys

countries = topo["objects"]["countries"]["geometries"]

def unwrap(pts):
    out = []; prev = None
    for lo, la in pts:
        if prev is not None:
            while lo - prev > 180: lo -= 360
            while lo - prev < -180: lo += 360
        out.append((lo, la)); prev = lo
    return out

def draw_ring(dr, ext, fill, outline, width):
    ext = unwrap(ext)
    for off in (-360, 0, 360):
        pts = [(proj(lo + off, la)[0] * W * 2, proj(lo + off, la)[1] * H * 2) for lo, la in ext]
        xs = [p[0] for p in pts]
        if max(xs) < 0 or min(xs) > W * 2:
            continue
        dr.polygon(pts, fill=fill, outline=outline, width=width)
img = Image.new("RGBA", (W * 2, H * 2), (214, 233, 238, 255))
d = ImageDraw.Draw(img)
# soft ocean gradient (light theme)
for yy in range(H * 2):
    t = yy / (H * 2)
    d.line([(0, yy), (W * 2, yy)], fill=(int(226 - 22 * t), int(240 - 16 * t), int(244 - 12 * t), 255))
# graticule
for lon in range(-180, 181, 30):
    x = proj(lon, 0)[0] * W * 2
    d.line([(x, 0), (x, H * 2)], fill=(255, 255, 255, 110), width=2)
for lat in range(-60, 81, 20):
    y = proj(0, lat)[1] * H * 2
    d.line([(0, y), (W * 2, y)], fill=(255, 255, 255, 110), width=2)
out = {"lat_top": LAT_TOP, "lat_bot": LAT_BOT, "countries": {}}
for c in countries:
    for poly in geom(c):
        if len(poly[0]) < 3:
            continue
        draw_ring(d, poly[0], (247, 239, 226, 255), (226, 208, 188, 255), 2)
    cid = str(c.get("id", ""))
    if cid in IDS:
        code = IDS[cid]
        shp = []
        for poly in geom(c):
            try:
                pg = Polygon(poly[0])
            except Exception:
                continue
            if pg.area < 0.6:  # drop tiny islands
                continue
            pg = pg.simplify(0.12, preserve_topology=True)
            if not pg.is_valid or pg.is_empty:
                continue
            coords = [list(map(lambda v: round(v, 5), proj(lo, la))) for lo, la in list(pg.exterior.coords)[:-1]]
            shp.append(coords)
        out["countries"][code] = shp
land = json.load(open(SRC.replace("countries-", "land-")))
tr = land.get("transform"); arcs.clear()
for arc in land["arcs"]:
    x = y = 0; pts = []
    for p in arc:
        x += p[0]; y += p[1]
        pts.append((x * tr["scale"][0] + tr["translate"][0], y * tr["scale"][1] + tr["translate"][1]))
    arcs.append(pts)
for g in land["objects"]["land"]["geometries"]:
    for poly in geom(g):
        for r in poly:
            if len(r) < 3: continue
            ext = unwrap(r)
            for off in (-360, 0, 360):
                pts = [(proj(lo + off, la)[0] * W * 2, proj(lo + off, la)[1] * H * 2) for lo, la in ext]
                d.line(pts + [pts[0]], fill=(196, 168, 138, 235), width=3)
img = img.resize((W, H), Image.LANCZOS)
img.convert("RGB").save(OUT_PNG, optimize=True)
json.dump(out, open(OUT_JSON, "w"), separators=(",", ":"))
for k, v in out["countries"].items():
    print(k, len(v), sum(len(p) for p in v))
