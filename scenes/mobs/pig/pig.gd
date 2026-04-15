extends "res://scenes/mobs/mob.gd"

@onready var idle_sound_timer := $Timers/IdleSoundTimer
@onready var run_timer := $Timers/RunTimer

var last_pos: Vector3 # Безопасное место для побега

enum STATE { IDLE, WALK, RUNAWAY}
var state := STATE.IDLE

func loop(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	if state == STATE.WALK: walk(-global_transform.basis.z, speed)
	elif state == STATE.RUNAWAY: walk(-global_transform.basis.z, speed * 1.5)
	braking()


func _on_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	if G.state_machine != "game": return
	
	if state == STATE.IDLE:
		state = STATE.WALK
		self.rotation.y += randi_range(-200, 200)
		sprite.anim_play.rpc("walk")
	elif state == STATE.WALK:
		state = STATE.IDLE
		sprite.anim_play.rpc("idle")


func _on_idle_sound_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	if state == STATE.RUNAWAY: return
	idle_sound_timer.wait_time = randi_range(8, 15)
	idle_sound_timer.start()
	take_damage_audio.audio_play(R.sounds["idle"]["pig"].pick_random().resource_path)
	last_pos = position


@rpc("authority", "call_local")
func on_damage() -> void:
	super()
	run_timer.start()
	sprite.anim_play("walk")
	state = STATE.RUNAWAY
	look_at(last_pos)


func _on_run_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	state = STATE.IDLE
	sprite.anim_play.rpc("idle")
