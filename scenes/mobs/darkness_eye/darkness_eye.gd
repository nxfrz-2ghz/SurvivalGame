extends "res://scenes/mobs/mob.gd"

const damage := 0.1
const speed := 1.0
var target_player: CharacterBody3D


func _ready() -> void:
	if not is_multiplayer_authority(): return
	super()
	G.time_controller.day_come.connect(despawn)


func _on_attack_cooldown_timeout() -> void:
	target_player = get_target_player()
	
	var dist := global_position.distance_to(target_player.global_position)
	
	if dist < 20.0:
		target_player.health.take_damage(damage)


func moving() -> void:
	if is_instance_valid(target_player) and is_on_floor():
		var direction = (target_player.global_position - global_position).normalized()
		velocity.x += direction.x * speed
		velocity.z += direction.z * speed


func loop(_delta: float) -> void:
	moving()
	braking()
