extends "res://scenes/mobs/mob.gd"

const damage := 2.0
const DETECTION_RADIUS := 16.0
const ATTACK_RADIUS := 4.0

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
	if G.state_machine != "game": return
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
	if not is_multiplayer_authority(): return
	if G.state_machine != "game": return
	target_player = get_target_player()
	var dist := global_position.distance_to(target_player.global_position)
	
	if dist < ATTACK_RADIUS:
		target_player.health.take_damage(damage)
		sprite.anim_play.rpc("attack")
	elif dist < DETECTION_RADIUS:
		state = State.STALK
		sprite.anim_play.rpc("walk")
	else:
		if state == State.STALK: state = State.IDLE
