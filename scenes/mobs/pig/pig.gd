extends "res://scenes/mobs/mob.gd"

var is_walk := false

func loop(_delta: float) -> void:
	if is_walk: walk(-global_transform.basis.z, speed)
	braking()


func _on_timer_timeout() -> void:
	if G.state_machine != "game": return
	is_walk = !is_walk
	
	if is_walk:
		self.rotation.y += randi_range(-200, 200)
		sprite.play("walk")
	else:
		sprite.play("idle")
