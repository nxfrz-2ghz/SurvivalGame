extends "res://scenes/mobs/mob.gd"

const damage := 0.1
const speed := 1.0
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
	
	var dist := global_position.distance_to(target_player.global_position)
	
	if dist < 40.0:
		target_player.health.take_damage(damage + add_damage)
		_update_damage()


func moving() -> void:
	if is_instance_valid(target_player) and is_on_floor():
		var direction = (target_player.global_position - global_position).normalized()
		velocity.x += direction.x * speed
		velocity.z += direction.z * speed


func braking() -> void:
	if velocity:
		if is_on_floor():
			velocity.x /= 1.5
			velocity.z /= 1.5
		else:
			velocity.x /= 1.01
			velocity.z /= 1.01
		
		if abs(velocity.x) < 0.01:
			velocity.x = 0
		if abs(velocity.z) < 0.01:
			velocity.z = 0


func loop(_delta: float) -> void:
	moving()
	braking()
