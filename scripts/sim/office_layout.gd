class_name OfficeLayout
extends RefCounted
## Static description of the office floor plan, shared by the simulation
## (walkability, places) and the view (drawing, hotspots).
## Grid: x grows down-right on screen, y grows down-left. (0,0) is the back corner.

const W := 14
const H := 14

# Facing: direction a person/front of furniture looks at.
# SE = +x, SW = +y, NW = -x, NE = -y

static func zones() -> Array:
	# [zone_id, x0, y0, x1, y1]  (inclusive)
	return [
		["meeting", 0, 0, 4, 4],
		["boss", 9, 0, 13, 4],
		["archive", 5, 0, 8, 3],
		["lounge", 0, 5, 4, 8],
		["kitchen", 0, 9, 4, 13],
		["reception", 11, 5, 13, 13],
		["workspace", 5, 4, 10, 13],
	]


static func zone_of(cell: Vector2i) -> String:
	for z in zones():
		if cell.x >= z[1] and cell.x <= z[3] and cell.y >= z[2] and cell.y <= z[4]:
			return z[0]
	return "workspace"


static func furniture() -> Array:
	var f: Array = []
	# --- Meeting room ---
	f.append({"id": "meeting_table", "type": "meeting_table", "cells": [[1, 1], [2, 1], [1, 2], [2, 2], [1, 3], [2, 3]], "block": true})
	var mchairs := [[0, 1, "SE"], [0, 2, "SE"], [0, 3, "SE"], [1, 0, "SW"], [2, 0, "SW"], [3, 1, "NW"], [3, 2, "NW"], [3, 3, "NW"]]
	var mcol := ["#B9A7E0", "#F2A97E", "#8FD3C1", "#F6C85F", "#F28FA5", "#9CC5F0", "#B9A7E0", "#F2A97E"]
	for i in mchairs.size():
		var c = mchairs[i]
		f.append({"id": "mchair%d" % i, "type": "chair", "cells": [[c[0], c[1]]], "facing": c[2], "block": false, "color": mcol[i]})
	f.append({"id": "plant_meet", "type": "plant_tall", "cells": [[0, 4]], "block": true})
	# --- Archive / printer nook ---
	f.append({"id": "shelf", "type": "shelf", "cells": [[5, 0]], "facing": "SW", "block": true})
	f.append({"id": "printer", "type": "printer", "cells": [[6, 0]], "facing": "SW", "block": true})
	f.append({"id": "cabinet1", "type": "file_cabinet", "cells": [[7, 0]], "facing": "SW", "block": true})
	f.append({"id": "cabinet2", "type": "file_cabinet", "cells": [[8, 0]], "facing": "SW", "block": true})
	f.append({"id": "boxes", "type": "boxes", "cells": [[5, 3]], "block": true})
	# --- Manager office ---
	f.append({"id": "boss_desk", "type": "boss_desk", "cells": [[11, 2], [12, 2]], "facing": "SW", "block": true, "owner": "ahmet"})
	f.append({"id": "boss_chair", "type": "boss_chair", "cells": [[11, 1]], "seat": [12.0, 1.5], "facing": "SW", "block": false})
	f.append({"id": "bookcase", "type": "bookcase", "cells": [[12, 0], [13, 0]], "facing": "SW", "block": true})
	f.append({"id": "plant_boss", "type": "plant_tall", "cells": [[9, 0]], "block": true})
	f.append({"id": "guest_chair", "type": "chair", "cells": [[11, 3]], "facing": "NE", "block": false, "color": "#8E9AAF"})
	f.append({"id": "plant_boss2", "type": "plant_small", "cells": [[13, 4]], "block": true})
	# --- Lounge ---
	f.append({"id": "water_cooler", "type": "water_cooler", "cells": [[0, 5]], "facing": "SE", "block": true})
	f.append({"id": "sofa", "type": "sofa", "cells": [[0, 6], [0, 7]], "facing": "SE", "block": false, "color": "#E98A8A"})
	f.append({"id": "coffee_table", "type": "coffee_table", "cells": [[1, 6], [1, 7]], "block": true})
	f.append({"id": "plant_lounge", "type": "plant_tall", "cells": [[2, 8]], "block": true})
	f.append({"id": "armchair", "type": "armchair", "cells": [[3, 7]], "facing": "NW", "block": false, "color": "#7FB7BE"})
	# --- Kitchen ---
	f.append({"id": "fridge", "type": "fridge", "cells": [[0, 9]], "facing": "SE", "block": true})
	f.append({"id": "coffee_counter", "type": "coffee_counter", "cells": [[0, 10]], "facing": "SE", "block": true})
	f.append({"id": "sink", "type": "counter", "variant": "sink", "cells": [[0, 11]], "facing": "SE", "block": true})
	f.append({"id": "counter_mw", "type": "counter", "variant": "microwave", "cells": [[0, 12]], "facing": "SE", "block": true})
	f.append({"id": "counter_fruit", "type": "counter", "variant": "fruit", "cells": [[0, 13]], "facing": "SE", "block": true})
	f.append({"id": "kitchen_table", "type": "round_table", "cells": [[2, 12]], "block": true})
	var kchairs := [[2, 11, "SW"], [3, 12, "NW"], [2, 13, "NE"], [1, 12, "SE"]]
	var kcol := ["#F6C85F", "#8FD3C1", "#F28FA5", "#9CC5F0"]
	for i in kchairs.size():
		var k = kchairs[i]
		f.append({"id": "kchair%d" % i, "type": "stool", "cells": [[k[0], k[1]]], "facing": k[2], "block": false, "color": kcol[i]})
	f.append({"id": "plant_kitchen", "type": "plant_small", "cells": [[4, 13]], "block": true})
	# --- Workstations ---
	for ws in workstations():
		var chair: Array = ws["chair"]
		var d0: Array = ws["desk"][0]
		var d1: Array = ws["desk"][1]
		f.append({"id": "chair_" + ws["owner"], "type": "office_chair", "cells": [chair], "facing": ws["facing"], "block": false, "color": ws["chair_color"]})
		f.append({"id": "desk_" + ws["owner"], "type": ws["type"], "cells": [d0, d1], "facing": ws["facing"], "block": true, "owner": ws["owner"]})
	# --- Reception ---
	f.append({"id": "plant_rec", "type": "plant_tall", "cells": [[13, 5]], "block": true})
	f.append({"id": "plant_rec2", "type": "plant_small", "cells": [[11, 5]], "block": true})
	f.append({"id": "coat_rack", "type": "coat_rack", "cells": [[13, 13]], "block": true})
	f.append({"id": "plant_rec3", "type": "plant_tall", "cells": [[11, 13]], "block": true})
	return f


static func workstations() -> Array:
	return [
		{"owner": "selin", "chair": [5, 5], "desk": [[6, 5], [6, 6]], "facing": "SE", "type": "desk", "chair_color": "#F28FA5"},
		{"owner": "deniz", "chair": [5, 8], "desk": [[6, 8], [6, 9]], "facing": "SE", "type": "desk", "chair_color": "#B9A7E0"},
		{"owner": "ece", "chair": [5, 11], "desk": [[6, 11], [6, 12]], "facing": "SE", "type": "desk", "chair_color": "#F6C85F"},
		{"owner": "mert", "chair": [8, 5], "desk": [[9, 5], [9, 6]], "facing": "SE", "type": "desk", "chair_color": "#9CC5F0"},
		{"owner": "zeynep", "chair": [8, 8], "desk": [[9, 8], [9, 9]], "facing": "SE", "type": "desk", "chair_color": "#F2A97E"},
		{"owner": "burak", "chair": [8, 11], "desk": [[9, 11], [9, 12]], "facing": "SE", "type": "desk", "chair_color": "#8FD3C1"},
		{"owner": "ceren", "chair": [11, 8], "desk": [[12, 8], [12, 9]], "facing": "SE", "type": "reception_desk", "chair_color": "#7FB7BE"},
	]


## Thin glass partitions. "v" x y = wall between (x-1,y) and (x,y).  "h" x y = between (x,y-1) and (x,y).
static func partitions() -> Array:
	var p: Array = []
	for y in range(0, 5):
		p.append(["v", 5, y])
		p.append(["v", 9, y])
	for x in [0, 1, 2, 3]:
		p.append(["h", x, 5])
	for x in [9, 11, 12, 13]:
		p.append(["h", x, 5])
	return p


## Wall decorations. side "R" = back-right wall (y=0 edge, positions along x),
## side "L" = back-left wall (x=0 edge, positions along y).
static func wall_decor() -> Array:
	return [
		{"type": "window", "side": "R", "a": 0.35, "b": 2.55},
		{"type": "board", "side": "R", "a": 2.75, "b": 4.7},
		{"type": "alarm", "side": "R", "a": 5.3, "b": 5.85},
		{"type": "sign", "side": "R", "a": 6.15, "b": 6.85},
		{"type": "ac", "side": "R", "a": 7.05, "b": 8.45},
		{"type": "thermostat", "side": "R", "a": 8.55, "b": 8.9},
		{"type": "window", "side": "R", "a": 9.55, "b": 11.6},
		{"type": "window", "side": "L", "a": 0.35, "b": 2.3},
		{"type": "clock", "side": "L", "a": 2.75, "b": 3.65},
		{"type": "poster", "side": "L", "a": 4.2, "b": 4.85},
		{"type": "window", "side": "L", "a": 5.6, "b": 7.7},
		{"type": "breaker", "side": "L", "a": 8.1, "b": 8.85},
		{"type": "speaker", "side": "L", "a": 9.05, "b": 9.75},
		{"type": "cabinets", "side": "L", "a": 9.95, "b": 13.95},
	]


## Interaction anchors for characters.
static func places() -> Array:
	var p: Array = []
	for ws in workstations():
		var ch: Array = ws["chair"]
		p.append({"id": "desk_" + ws["owner"], "cell": ch, "seat": [ch[0] + 0.5, ch[1] + 0.5], "facing": ws["facing"], "pose": "sit", "tags": ["desk"], "owner": ws["owner"]})
	p.append({"id": "desk_ahmet", "cell": [11, 1], "seat": [12.0, 1.5], "facing": "SW", "pose": "sit", "tags": ["desk"], "owner": "ahmet"})
	p.append({"id": "coffee", "cell": [1, 10], "facing": "NW", "pose": "stand", "tags": ["coffee"]})
	p.append({"id": "fridge", "cell": [1, 9], "facing": "NW", "pose": "stand", "tags": ["fridge"]})
	p.append({"id": "water", "cell": [1, 5], "facing": "NW", "pose": "stand", "tags": ["water", "social"]})
	p.append({"id": "printer", "cell": [6, 1], "facing": "NE", "pose": "stand", "tags": ["printer"]})
	p.append({"id": "archive", "cell": [7, 1], "facing": "NE", "pose": "stand", "tags": ["archive"]})
	p.append({"id": "thermostat", "cell": [8, 1], "facing": "NE", "pose": "stand", "tags": ["thermostat"]})
	p.append({"id": "breaker", "cell": [0, 8], "facing": "NW", "pose": "stand", "tags": ["breaker"]})
	p.append({"id": "board_view", "cell": [4, 1], "facing": "NE", "pose": "stand", "tags": ["board"]})
	p.append({"id": "sofa1", "cell": [0, 6], "facing": "SE", "pose": "sit", "tags": ["rest", "lunch"]})
	p.append({"id": "sofa2", "cell": [0, 7], "facing": "SE", "pose": "sit", "tags": ["rest", "lunch"]})
	p.append({"id": "armchair", "cell": [3, 7], "facing": "NW", "pose": "sit", "tags": ["rest"]})
	p.append({"id": "k1", "cell": [2, 11], "facing": "SW", "pose": "sit", "tags": ["lunch", "rest"]})
	p.append({"id": "k2", "cell": [3, 12], "facing": "NW", "pose": "sit", "tags": ["lunch", "rest"]})
	p.append({"id": "k3", "cell": [2, 13], "facing": "NE", "pose": "sit", "tags": ["lunch"]})
	p.append({"id": "k4", "cell": [1, 12], "facing": "SE", "pose": "sit", "tags": ["lunch", "rest"]})
	var ms := [[1, 0, "SW"], [0, 1, "SE"], [0, 2, "SE"], [0, 3, "SE"], [2, 0, "SW"], [3, 1, "NW"], [3, 2, "NW"], [3, 3, "NW"]]
	for i in ms.size():
		var m = ms[i]
		p.append({"id": "m%d" % (i + 1), "cell": [m[0], m[1]], "facing": m[2], "pose": "sit", "tags": ["meeting"]})
	p.append({"id": "boss_guest", "cell": [11, 3], "facing": "NE", "pose": "sit", "tags": ["boss_guest"]})
	p.append({"id": "boss_front", "cell": [12, 3], "facing": "NE", "pose": "stand", "tags": ["boss_front"]})
	p.append({"id": "entrance", "cell": [13, 11], "facing": "NW", "pose": "stand", "tags": ["entrance"]})
	p.append({"id": "announce", "cell": [7, 7], "facing": "SE", "pose": "stand", "tags": ["announce"]})
	# huddle spots: where people meet to talk in private (kitchen, lounge, archive nook, hallway)
	var huddles := [["hk1", 2, 10, "SE"], ["hk2", 3, 10, "SW"], ["hk3", 3, 11, "NW"], ["hl1", 2, 6, "SE"], ["hl2", 3, 6, "SW"],
		["ha1", 7, 2, "SE"], ["ha2", 8, 2, "SW"], ["hh1", 11, 7, "SE"], ["hh2", 12, 7, "SW"]]
	for hd in huddles:
		p.append({"id": hd[0], "cell": [hd[1], hd[2]], "facing": hd[3], "pose": "stand", "tags": ["huddle"]})
	# reception gathering spots (fire drills, deliveries, waiting at the door)
	var rec := [["hr1", 12, 10, "SE"], ["hr2", 11, 11, "SE"], ["hr3", 13, 10, "SW"], ["hr4", 11, 12, "NE"], ["hr5", 13, 12, "NW"]]
	for hd in rec:
		p.append({"id": hd[0], "cell": [hd[1], hd[2]], "facing": hd[3], "pose": "stand", "tags": ["huddle", "reception"]})
	p.append({"id": "micro", "cell": [1, 12], "facing": "NW", "pose": "stand", "tags": ["microwave"]})
	p.append({"id": "server", "cell": [6, 3], "facing": "NW", "pose": "stand", "tags": ["server"]})
	p.append({"id": "supplies", "cell": [6, 1], "facing": "NW", "pose": "stand", "tags": ["supplies"]})
	p.append({"id": "hr_files", "cell": [12, 1], "facing": "NE", "pose": "stand", "tags": ["hr"]})
	p.append({"id": "notice", "cell": [1, 4], "facing": "NW", "pose": "stand", "tags": ["notice"]})
	p.append({"id": "coats", "cell": [12, 13], "facing": "SE", "pose": "stand", "tags": ["coats"]})
	p.append({"id": "plant", "cell": [3, 8], "facing": "NW", "pose": "stand", "tags": ["plant"]})
	var phones := [[4, 12, "SW"], [7, 3, "NE"], [3, 5, "SE"], [12, 12, "SE"], [13, 6, "SW"]]
	for i in phones.size():
		var ph = phones[i]
		p.append({"id": "phone%d" % i, "cell": [ph[0], ph[1]], "facing": ph[2], "pose": "stand", "tags": ["phone"]})
	var wander := [[7, 7], [10, 7], [7, 10], [10, 10], [4, 6], [4, 10], [12, 6], [12, 11], [7, 13], [10, 13], [3, 9], [8, 3], [10, 3], [1, 4], [12, 4]]
	for i in wander.size():
		var w = wander[i]
		p.append({"id": "w%d" % i, "cell": [w[0], w[1]], "facing": ["SE", "SW", "NE", "NW"][i % 4], "pose": "stand", "tags": ["wander"]})
	return p


## Where a movable item is drawn when it sits at a given location.
## Returns [x, y, height_px] in grid/continuous space.
static func item_spot(loc: String) -> Array:
	match loc:
		"desk_ahmet": return [11.55, 2.35, 26]
		"desk_selin": return [6.45, 6.55, 26]
		"desk_deniz": return [6.45, 9.55, 26]
		"desk_ece": return [6.45, 12.55, 26]
		"desk_mert": return [9.45, 6.55, 26]
		"desk_zeynep": return [9.45, 9.55, 26]
		"desk_burak": return [9.45, 12.55, 26]
		"desk_ceren": return [12.45, 9.55, 30]
		"kitchen": return [0.55, 12.6, 30]
		"archive": return [7.5, 0.6, 44]
		"meeting": return [1.9, 2.4, 24]
		"lounge": return [1.5, 7.3, 14]
	return [7.0, 7.0, 0]


static func item_locations() -> Array:
	return ["desk_ahmet", "desk_selin", "desk_deniz", "desk_ece", "desk_mert", "desk_zeynep", "desk_burak", "desk_ceren", "kitchen", "archive", "meeting", "lounge"]


## Which place a person stands at to pick up an item from a location.
static func item_pick_place(loc: String) -> String:
	match loc:
		"kitchen": return "k4"
		"archive": return "archive"
		"meeting": return "m3"
		"lounge": return "sofa2"
	return loc


static func hotspots() -> Array:
	var h: Array = [
		{"id": "coffee_machine", "kind": "coffee", "cells": [[0, 10]], "h": 56},
		{"id": "printer", "kind": "printer", "cells": [[6, 0]], "h": 58},
		{"id": "meeting_board", "kind": "board", "wall": "R", "a": 2.75, "b": 4.7, "z0": 30, "z1": 84},
		{"id": "ac", "kind": "ac", "wall": "R", "a": 7.0, "b": 8.95, "z0": 40, "z1": 92},
		{"id": "lights", "kind": "lights", "wall": "L", "a": 7.9, "b": 9.0, "z0": 24, "z1": 76},
		{"id": "promo_file", "kind": "promo", "cells": [[12, 2]], "h": 34},
		{"id": "fridge", "kind": "fridge", "cells": [[0, 9]], "h": 70},
		{"id": "water_cooler", "kind": "water", "cells": [[0, 5]], "h": 56},
		{"id": "kitchen_table", "kind": "table", "cells": [[2, 12]], "h": 28},
		{"id": "microwave", "kind": "microwave", "cells": [[0, 12]], "h": 44},
		{"id": "file_cabinet", "kind": "cabinet", "cells": [[7, 0], [8, 0]], "h": 54},
		{"id": "supply_shelf", "kind": "shelf", "cells": [[5, 0]], "h": 62},
		{"id": "server_box", "kind": "server", "cells": [[5, 3]], "h": 30},
		{"id": "meeting_table", "kind": "meeting", "cells": [[1, 1], [2, 1], [1, 2], [2, 2], [1, 3], [2, 3]], "h": 24},
		{"id": "hr_cabinet", "kind": "hr", "cells": [[12, 0], [13, 0]], "h": 64},
		{"id": "sofa", "kind": "sofa", "cells": [[0, 6], [0, 7]], "h": 30},
		{"id": "coat_rack", "kind": "coats", "cells": [[13, 13]], "h": 66},
		{"id": "plant", "kind": "plant", "cells": [[2, 8]], "h": 60},
		{"id": "front_door", "kind": "door", "cells": [[13, 11]], "h": 8},
		{"id": "noticeboard", "kind": "notice", "wall": "L", "a": 4.15, "b": 4.9, "z0": 56, "z1": 96},
		{"id": "wall_clock", "kind": "clock", "wall": "L", "a": 2.75, "b": 3.65, "z0": 62, "z1": 94},
		{"id": "speaker", "kind": "speaker", "wall": "L", "a": 9.0, "b": 9.8, "z0": 58, "z1": 90},
		{"id": "alarm_panel", "kind": "alarm", "wall": "R", "a": 5.25, "b": 5.9, "z0": 50, "z1": 84},
	]
	for ws in workstations():
		h.append({"id": "ws_" + ws["owner"], "kind": "workstation", "owner": ws["owner"], "cells": ws["desk"], "h": 46})
	h.append({"id": "ws_ahmet", "kind": "workstation", "owner": "ahmet", "cells": [[11, 2]], "h": 46})
	return h
