extends Node3D
class_name Bouncer
## Invisible bounce trigger placed over an awning (or anything springy).
## Visual squash is applied to an optional target node.

var size := Vector3(3, 0.6, 1.6)
var strength := 15.5
var squash_target: Node3D
var player: Player
var cool := 0.0
var wobble := 0.0


func _process(delta: float) -> void:
	cool -= delta
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Player
		return
	var lp := to_local(player.global_position)
	var inside: bool = abs(lp.x) < size.x * 0.5 + 0.45 and abs(lp.z) < size.z * 0.5 + 0.45 and lp.y > -0.6 and lp.y < size.y + 0.4
	if inside and player.velocity.y <= 0.5 and cool <= 0.0 and not player.dead:
		player.bounce(strength)
		cool = 0.3
		wobble = 1.0
	wobble = max(0.0, wobble - delta * 3.0)
	if squash_target:
		var w := sin(wobble * 18.0) * wobble * 0.18
		squash_target.scale = Vector3(1.0 + w * 0.3, 1.0 - w, 1.0 + w * 0.3)
