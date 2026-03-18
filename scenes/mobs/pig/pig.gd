extends "res://scenes/mobs/mob.gd"

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
