extends "res://scenes/mobs/mob.gd"

@onready var idle_sound_timer := $Timers/IdleSoundTimer

var is_walk := false

func loop(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	if is_walk: walk(-global_transform.basis.z, speed)
	braking()


func _on_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	if G.state_machine != "game": return
	is_walk = !is_walk
	
	if is_walk:
		self.rotation.y += randi_range(-200, 200)
		sprite.anim_play.rpc("walk")
	else:
		sprite.anim_play.rpc("idle")


func _on_idle_sound_timer_timeout() -> void:
	idle_sound_timer.wait_time = randi_range(8, 15	)
	idle_sound_timer.start()
	take_damage_audio.audio_play(R.sounds["idle"]["pig"].pick_random().resource_path)
