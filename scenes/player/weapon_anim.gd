extends AnimationPlayer

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "aim" and speed_scale > 0.0:
		play("waiting_throw")
	elif anim_name == "throw":
		play("cd")
	elif anim_name == "first_view_cam":
		G.player.sprite.set_layer_mask_value(1, false)
		G.player.sprite.set_layer_mask_value(6, true)
		G.player.label3d.set_layer_mask_value(1, false)
		G.player.label3d.set_layer_mask_value(6, true)
	
	self.speed_scale = 1.0
