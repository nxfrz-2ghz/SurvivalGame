extends "res://scenes/mobs/mob.gd"

const damage := 0.6
const DETECTION_RADIUS := 20.0
const ATTACK_RADIUS := 5.0

enum State {IDLE, WANDER, STALK}
var state: State = State.IDLE

var target_player: CharacterBody3D


func loop(_delta: float) -> void:
	if state == State.STALK:
		var look_pos = target_player.global_position
		look_pos.y = global_position.y
		look_at(look_pos)
	
	if state == State.WANDER or state == State.STALK:
		walk(-global_transform.basis.z, speed)
	
	braking()


func _on_timer_timeout() -> void:
	if G.state_machine != "game": return
	if state == State.IDLE:
		state = State.WANDER
	elif state == State.WANDER:
		state = State.IDLE
	
	if state == State.WANDER:
		self.rotation.y += randi_range(-200, 200)
		sprite.play("walk")
	else:
		sprite.play("idle")


func _on_scan_players_timeout() -> void:
	if G.state_machine != "game": return
	target_player = get_target_player()
	var dist := global_position.distance_to(target_player.global_position)
	
	if dist < ATTACK_RADIUS:
		target_player.health.take_damage(damage)
		sprite.play("attack")
	if dist < DETECTION_RADIUS:
		state = State.STALK
	else:
		if state == State.STALK: state = State.IDLE
