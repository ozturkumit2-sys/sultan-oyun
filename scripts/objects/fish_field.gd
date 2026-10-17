extends Node3D
class_name FishField
## All collectible fish in one MultiMesh (silver hamsi) + one for golden fish.
## Collection is a cheap distance test against the player.

const FISH := preload("res://assets/models/fish.glb")
const SOLID := preload("res://shaders/toon_solid.gdshader")

var positions: PackedVector3Array = []
var golden: PackedByteArray = []
var alive: PackedByteArray = []
var mm_silver: MultiMeshInstance3D
var mm_gold: MultiMeshInstance3D
var idx_map: PackedInt32Array = []   # fish index -> instance index within its multimesh
var player: Player
var t := 0.0
var pop := {}   # index -> remaining pop time (collect animation)
var burst: CPUParticles3D


func add(p: Vector3, gold := false) -> void:
	positions.append(p)
	golden.append(1 if gold else 0)
	alive.append(1)


func total_value() -> int:
	var v := 0
	for g in golden:
		v += 5 if g == 1 else 1
	return v


func line(a: Vector3, b: Vector3, n: int) -> void:
	for i in n:
		add(a.lerp(b, (i + 0.5) / n if n > 1 else 0.5))


func arc(a: Vector3, b: Vector3, height: float, n: int) -> void:
	for i in n:
		var tt := float(i) / maxf(1.0, n - 1.0)
		add(a.lerp(b, tt) + Vector3(0, sin(tt * PI) * height, 0))


func ring(c: Vector3, r: float, n: int) -> void:
	for i in n:
		var a := TAU * i / n
		add(c + Vector3(cos(a) * r, 0, sin(a) * r))


func build() -> void:
	var silver_mesh := ModelUtil.bake(FISH, func(mname: String, m: Color) -> Color:
		match mname:
			"Dark":
				return Color(0.02, 0.02, 0.03)
			"Highlight":
				return Color(1, 1, 1)
		var base := Color("b9d7e6").srgb_to_linear()
		var back := Color("3f78a8").srgb_to_linear()
		var belly := Color("f4fbff").srgb_to_linear()
		return base.lerp(back, smoothstep(0.3, 0.6, m.g)).lerp(belly, smoothstep(0.3, 0.6, m.b)))
	var gold_mesh := ModelUtil.bake(FISH, func(mname: String, m: Color) -> Color:
		match mname:
			"Dark":
				return Color(0.02, 0.02, 0.03)
			"Highlight":
				return Color(1, 1, 1)
		var base := Color("ffcf4a").srgb_to_linear()
		var back := Color("e98a1e").srgb_to_linear()
		var belly := Color("fff2b0").srgb_to_linear()
		return base.lerp(back, smoothstep(0.3, 0.6, m.g)).lerp(belly, smoothstep(0.3, 0.6, m.b)))
	var ms := ShaderMaterial.new()
	ms.shader = SOLID
	ms.set_shader_parameter("use_vertex", 1.0)
	ms.set_shader_parameter("gloss", 0.9)
	ms.set_shader_parameter("rim_strength", 0.6)
	ms.set_shader_parameter("emission_amount", 0.12)
	var mg := ms.duplicate()
	mg.set_shader_parameter("emission_amount", 0.35)
	silver_mesh.surface_set_material(0, ms)
	gold_mesh.surface_set_material(0, mg)
	var ns := 0
	var ng := 0
	idx_map.resize(positions.size())
	for i in positions.size():
		if golden[i] == 1:
			idx_map[i] = ng
			ng += 1
		else:
			idx_map[i] = ns
			ns += 1
	mm_silver = _mm(silver_mesh, ns)
	mm_gold = _mm(gold_mesh, ng)
	burst = CPUParticles3D.new()
	burst.emitting = false
	burst.one_shot = true
	burst.amount = 10
	burst.lifetime = 0.5
	burst.explosiveness = 1.0
	burst.spread = 180.0
	burst.initial_velocity_min = 2.0
	burst.initial_velocity_max = 3.5
	burst.gravity = Vector3(0, -3, 0)
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	sm.radial_segments = 6
	sm.rings = 3
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.albedo_color = Color(1.0, 0.95, 0.7)
	sm.material = bm
	burst.mesh = sm
	add_child(burst)
	_update(0.0)


func _mm(mesh: Mesh, count: int) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return mmi


func _process(delta: float) -> void:
	t += delta
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Player
	if player and not player.dead:
		var pp := player.global_position + Vector3(0, 0.5, 0)
		for i in positions.size():
			if alive[i] == 1 and positions[i].distance_squared_to(pp) < 0.95:
				_collect(i)
	_update(delta)


func _collect(i: int) -> void:
	alive[i] = 0
	pop[i] = 0.25
	if golden[i] == 1:
		GameState.add_fish(5)
		Sfx.play("fish_gold", 1.0, -2.0)
		GameState.vibrate(20)
	else:
		GameState.add_fish(1)
		Sfx.fish()
	burst.global_position = positions[i]
	burst.restart()


func _update(delta: float) -> void:
	for i in positions.size():
		var mm: MultiMesh = mm_gold.multimesh if golden[i] == 1 else mm_silver.multimesh
		var s := 1.0
		var p := positions[i]
		if alive[i] == 0:
			if pop.has(i):
				pop[i] -= delta
				var k: float = pop[i] / 0.25
				s = k * 1.4
				p += Vector3(0, (1.0 - k) * 1.2, 0)
				if pop[i] <= 0.0:
					pop.erase(i)
			else:
				s = 0.0
		var gs := 1.6 if golden[i] == 1 else 1.0
		var spin := t * 2.6 + i * 0.37
		var bob := sin(t * 3.0 + i * 0.9) * 0.08
		var xf := Transform3D(Basis(Vector3.UP, spin).scaled(Vector3.ONE * max(s * gs, 0.0001)), p + Vector3(0, bob, 0))
		mm.set_instance_transform(idx_map[i], xf)
