extends "res://scenes/mobs/mob.gd"

@onready var attack_cooldown := $Timers/AttackCooldown
@onready var dash_cooldown := $Timers/DashCooldown
@onready var attack_area := $AttackArea

const dash_power := 100.0
const jump_velocity := 3.5
const DETECTION_RADIUS := 16.0
const ATTACK_RADIUS := 8.0

enum State {IDLE, WANDER, STALK}
var state: State = State.IDLE

var target_player: CharacterBody3D


func loop(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	if state == State.STALK:
		var look_pos = target_player.global_position
		look_pos.y = global_position.y
		look_at(look_pos)
	
	if state == State.WANDER or state == State.STALK:
		walk(-global_transform.basis.z, speed)
	
	braking()


func _on_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	if S.state_machine != "game": return
	if state == State.IDLE:
		state = State.WANDER
	elif state == State.WANDER:
		state = State.IDLE
	
	if state == State.WANDER:
		self.rotation.y += randi_range(-200, 200)
		sprite.anim_play.rpc("walk")
	else:
		sprite.anim_play.rpc("idle")


func _on_scan_players_timeout() -> void:
	update()


func _on_animated_sprite_3d_animation_finished() -> void:
	if sprite.animation == "attack":
		update()


func update() -> void:
	if not is_multiplayer_authority(): return
	if S.state_machine != "game": return
	target_player = get_target_player()
	var dist := global_position.distance_to(target_player.global_position)
	
	if dist < ATTACK_RADIUS and attack_cooldown.is_stopped():
		attack_area.attack()
		sprite.anim_play.rpc("attack")
		attack_cooldown.start()
	elif dist < DETECTION_RADIUS:
		state = State.STALK
		sprite.anim_play.rpc("walk")
		if dash_cooldown.is_stopped():
			dash()
			dash_cooldown.start()
	else:
		if state == State.STALK: state = State.IDLE


func dash() -> void:
	if is_on_floor():
		velocity += -self.global_transform.basis.z.normalized() * dash_power
	else:
		velocity += -self.global_transform.basis.z.normalized() * dash_power / 20


func _on_despawn_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	queue_free()
