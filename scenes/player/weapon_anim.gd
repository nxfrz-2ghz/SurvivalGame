extends AnimationPlayer

func _on_animation_finished(_anim_name: StringName) -> void:
	self.speed_scale = 1.0
