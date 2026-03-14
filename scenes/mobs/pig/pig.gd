extends "res://scenes/mobs/mob.gd"

var speed := 2.0
var walk := false

func loop(_delta: float) -> void:
	if walk:
		var direction = -global_transform.basis.z
		velocity.x += direction.x * speed
		velocity.z += direction.z * speed
	braking()


func _on_timer_timeout() -> void:
	walk = !walk
	
	if walk:
		self.rotation.y += randi_range(-200, 200)
		sprite.play("walk")
	else:
		sprite.play("idle")
