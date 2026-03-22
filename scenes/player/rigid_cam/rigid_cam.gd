extends RigidBody3D

func despawn() -> void:
	G.player.camera.current = true
	G.player.camera.fov = 120.0
	queue_free()

func _on_timer_timeout() -> void:
	despawn()

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	despawn()
