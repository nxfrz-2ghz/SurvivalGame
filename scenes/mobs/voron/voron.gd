extends "res://scenes/mobs/mob.gd"


func _ready() -> void:
	super()
	if not is_multiplayer_authority(): return
	position.y = 30.0
	self.look_at(get_target_player().position)
	self.rotation.x = 0
	self.rotation.z = 0

func _physics_process(_delta: float) -> void:
	if S.state_machine != "game": return
	if not is_multiplayer_authority(): return
	
	walk(-global_transform.basis.z, speed)
	braking()
	
	move_and_slide()


func _on_karrrr_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	take_damage_audio.audio_play(R.sounds["idle"]["voron"].pick_random().resource_path)
