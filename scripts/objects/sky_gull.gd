extends BirdVisual
## Ambient seagull lazily circling over the rooftops.

var center := Vector3.ZERO
var radius := 12.0
var ang := randf() * TAU
var spd := randf_range(0.18, 0.3)


func _ready() -> void:
	kind = "gull"
	super._ready()
	for n in find_children("*", "MeshInstance3D", true, false):
		(n as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(delta: float) -> void:
	ang += spd * delta
	var p := center + Vector3(cos(ang) * radius, sin(ang * 2.3) * 1.5, sin(ang) * radius)
	var tangent := Vector3(-sin(ang), 0, cos(ang))
	global_position = p
	rotation.y = atan2(tangent.x, tangent.z)
	rotation.z = -0.25
	gliding = fmod(ang * 3.0, TAU) > 2.0
	flap_speed = 7.0
	super._process(delta)
