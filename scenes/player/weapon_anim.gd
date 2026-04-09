extends AnimationPlayer

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "aim" and speed_scale > 0.0:
		play("waiting_throw")
	elif anim_name == "throw":
		play("cd")
	
	self.speed_scale = 1.0
