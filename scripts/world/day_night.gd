class_name DayNight
extends Node3D
## Gökyüzü, güneş, ay ve oyun saatine bağlı gün döngüsü.

var env: Environment
var sky_mat: ProceduralSkyMaterial
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var world_env: WorldEnvironment
var _night_w := -1.0
var _t := 0.0


func _ready() -> void:
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sun_angle_max = 25.0
	sky_mat.sun_curve = 0.12
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.75
	env.ambient_light_color = Color(0.75, 0.72, 0.68)
	env.ambient_light_energy = 0.7
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.95
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.1
	env.fog_enabled = true
	env.fog_light_color = Color(0.82, 0.78, 0.72)
	env.fog_density = 0.0012
	env.fog_sky_affect = 0.25
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.06
	world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 40.0
	sun.shadow_blur = 1.2
	sun.light_angular_distance = 0.5
	add_child(sun)
	moon = DirectionalLight3D.new()
	moon.name = "Moon"
	moon.shadow_enabled = false
	moon.light_color = Color(0.55, 0.65, 0.95)
	moon.light_energy = 0.0
	moon.rotation = Vector3(deg_to_rad(-55), deg_to_rad(30), 0)
	moon.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(moon)
	update_now()


func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		_t = 0.25
		update_now()


func update_now() -> void:
	var h: float = GameState.hour_f() if GameState.active else 17.5
	var rise := 6.0
	var set_ := 19.8
	var dayf := clampf((h - rise) / (set_ - rise), 0.0, 1.0)
	var elev_deg := sin(dayf * PI) * 64.0
	var is_day := h > rise - 0.3 and h < set_ + 0.3
	var az := lerpf(-100.0, 100.0, dayf)
	sun.rotation = Vector3(-deg_to_rad(maxf(elev_deg, 2.0)), deg_to_rad(az + 180.0), 0)
	# gün ışığı rengi: öğlen beyaz-sıcak, alacakaranlıkta turuncu
	var low := clampf(1.0 - elev_deg / 25.0, 0.0, 1.0)
	var night := 0.0
	if h < rise:
		night = clampf((rise - h) / 1.0, 0.0, 1.0)
	elif h > set_:
		night = clampf((h - set_) / 1.0, 0.0, 1.0)
	var dawn_fade := clampf(elev_deg / 6.0, 0.0, 1.0) if is_day else 0.0
	sun.light_color = Color(1.0, 0.96, 0.88).lerp(Color(1.0, 0.62, 0.35), low)
	sun.light_energy = 1.35 * dawn_fade * (1.0 - night)
	moon.light_energy = 0.22 * night
	var day_top := Color(0.24, 0.45, 0.78)
	var day_hor := Color(0.75, 0.82, 0.9)
	var dusk_top := Color(0.25, 0.25, 0.48)
	var dusk_hor := Color(0.98, 0.6, 0.38)
	var night_top := Color(0.02, 0.03, 0.08)
	var night_hor := Color(0.08, 0.1, 0.2)
	var top := day_top.lerp(dusk_top, low).lerp(night_top, night)
	var hor := day_hor.lerp(dusk_hor, low).lerp(night_hor, night)
	sky_mat.sky_top_color = top
	sky_mat.sky_horizon_color = hor
	sky_mat.ground_horizon_color = hor.darkened(0.2)
	sky_mat.ground_bottom_color = Color(0.12, 0.11, 0.1).lerp(Color(0.02, 0.02, 0.04), night)
	sky_mat.sky_energy_multiplier = lerpf(1.0, 0.35, night)
	env.ambient_light_color = Color(0.78, 0.76, 0.72).lerp(Color(0.95, 0.7, 0.55), low * 0.6).lerp(Color(0.35, 0.4, 0.6), night)
	env.ambient_light_energy = lerpf(0.75, 0.35, night)
	env.fog_light_color = hor.lerp(Color(0.85, 0.8, 0.72), 0.4)
	var nw := clampf(maxf(night, low * 0.7 if h > 15.0 else (1.0 if h < rise + 0.6 else 0.0)), 0.0, 1.0)
	if absf(nw - _night_w) > 0.02:
		_night_w = nw
		for l in get_tree().get_nodes_in_group("night_lights"):
			l.light_energy = float(l.get_meta("base_energy", 1.0)) * nw
			l.visible = nw > 0.02
		for l2 in get_tree().get_nodes_in_group("room_lights"):
			l2.light_energy = float(l2.get_meta("base_energy", 1.0)) * (0.8 + nw * 0.45)
		var dark := nw > 0.5
		for p in get_tree().get_nodes_in_group("room_probes"):
			p.ambient_color_energy = lerpf(0.55, 0.22, nw)
			if bool(p.get_meta("dark", false)) != dark:
				p.set_meta("dark", dark)
				# gece/gündüz geçişinde yansımayı yeniden çek
				p.intensity = 1.0 if dark else 0.999
