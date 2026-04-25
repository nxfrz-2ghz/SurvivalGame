extends "res://scenes/mobs/mob.gd"

@onready var attack_area := $AttackArea
var target_player: CharacterBody3D

func _ready() -> void:
	if not is_multiplayer_authority(): return
	super()
	G.time_controller.day_come.connect(entity.despawn)


func _on_attack_cooldown_timeout() -> void:
	if not is_multiplayer_authority(): return
	if S.state_machine != "game": return
	target_player = get_target_player()
	
	var dist := global_position.distance_to(target_player.global_position)
	
	if dist < 8.0:
		attack_area.attack()


func loop(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	if is_instance_valid(target_player):
		look_at(target_player.position)
		walk(-global_transform.basis.z, speed)
	braking()
