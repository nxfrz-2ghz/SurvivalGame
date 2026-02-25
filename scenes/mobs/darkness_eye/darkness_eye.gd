extends "res://scenes/mobs/mob.gd"

const damage := 0.1
const speed := 2.0
var target_player: CharacterBody3D

@export var add_damage := 0.0
var last_player_name: String
func _update_damage() -> void: # Если игрок не меняется, то урон растет
	if last_player_name == target_player.name:
		add_damage *= 1.1
	else:
		last_player_name = target_player.name
		add_damage = 0.0

func _on_attack_cooldown_timeout() -> void:
	target_player = get_target_player()
	
	var dist := position.distance_to(target_player.position)
	
	if dist < 50.0:
		target_player.health.take_damage(damage + add_damage)
		_update_damage()


func loop(delta: float) -> void:
	if is_instance_valid(target_player):
		var direction = (target_player.global_position - global_position).normalized()
		velocity.x = move_toward(velocity.x, direction.x * speed, delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, delta)
