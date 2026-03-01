extends AnimatedSprite3D

@rpc("any_peer", "call_local")
func update_animation(current_health: float, max_health: float) -> void:
	var health_noramlized: float = current_health / max_health
	if health_noramlized > 0.66:
		play("100")
	elif health_noramlized > 0.33:
		play("66")
	elif health_noramlized > 0.0:
		play("33")


@rpc("any_peer", "call_local")
func anim_play(anim: String) -> void:
	play(anim)
