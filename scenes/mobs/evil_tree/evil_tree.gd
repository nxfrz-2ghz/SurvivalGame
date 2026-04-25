extends "res://scenes/mobs/mob.gd"

const damage := 2.0

var target_player: CharacterBody3D


@rpc("any_peer", "call_local")
func apply_push(direction_vector: Vector3, velocity_power: float) -> void:
	velocity += direction_vector * velocity_power / 10


func _on_attack_cooldown_timeout() -> void:
	if not is_multiplayer_authority(): return
	if S.state_machine != "game": return
	target_player = get_target_player()
	
	var dist := global_position.distance_to(target_player.global_position)
	
	if dist < 3.0:
		target_player.health.take_damage(damage)


func loop(delta: float) -> void:
	if not is_multiplayer_authority(): return
	if is_instance_valid(target_player): walk((target_player.global_position - global_position).normalized(), speed)
	braking()
	
	# x2 gravitation
	if not is_on_floor():
		velocity += get_gravity() * delta
