extends "res://scenes/mobs/mob.gd"

const damage := 0.1
var target_player: CharacterBody3D

func _find_target_player():
	var players = get_tree().get_nodes_in_group("players")
	var closest_dist = INF
	var closest_player: Node3D = null
	
	for player in players:
		if not is_instance_valid(player):
			continue
		var dist = global_position.distance_to(player.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_player = player

	target_player = closest_player

@export var add_damage := 0.0
var last_player_name: String
func _update_damage() -> void: # Если игрок не меняется, то урон растет
	if last_player_name == target_player.name:
		add_damage += 0.1
		add_damage *= 1.5
	else:
		last_player_name = target_player.name
		add_damage = 0.0

func _on_attack_cooldown_timeout() -> void:
	_find_target_player()
	_update_damage()
	
	var dist := position.distance_to(target_player.position)
	
	if dist < 50.0:
		target_player.health.take_damage(damage + add_damage)
