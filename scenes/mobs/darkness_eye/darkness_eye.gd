extends "res://scenes/mobs/mob.gd"

const damage := 0.1
const jump_velocity := 4.0
var target_player: CharacterBody3D


func _ready() -> void:
	if not is_multiplayer_authority(): return
	super()
	G.time_controller.day_come.connect(entity.despawn)


func _on_attack_cooldown_timeout() -> void:
	if not is_multiplayer_authority(): return
	if G.state_machine != "game": return
	target_player = get_target_player()
	
	var dist := global_position.distance_to(target_player.global_position)
	
	if dist < 3.0:
		target_player.health.take_damage(damage)


func loop(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	if is_instance_valid(target_player): walk((target_player.global_position - global_position).normalized(), speed)
	braking()
