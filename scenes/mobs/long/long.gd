extends "res://scenes/mobs/mob.gd"

@onready var attack_area := $AttackArea
var target_player: CharacterBody3D


func _ready() -> void:
	if not is_multiplayer_authority(): return
	super()
	G.time_controller.day_come.connect(entity.despawn)
	health.on_damage.connect(tp_near_player)


func tp_near_player() -> void:
	if !target_player: return
	if health.current_health < health.max_health / 5: return
	
	self.position = G.mob_spawner.get_random_spawn_position(target_player.position, health.current_health, health.current_health)
	_on_rotate_cooldown_timeout()


func _on_update_enemy_cooldown_timeout() -> void:
	if not is_multiplayer_authority(): return
	if S.state_machine != "game": return
	target_player = get_target_player()
	
	var dist := global_position.distance_to(target_player.global_position)
	
	if dist < 3.0:
		attack_area.attack()
		tp_near_player()


func loop(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	if is_instance_valid(target_player): walk((-global_transform.basis.z).normalized(), speed)
	braking()


func _on_rotate_cooldown_timeout() -> void:
	if !target_player: return
	self.look_at(target_player.position)
	self.rotation.x = 0
	self.rotation.z = 0
