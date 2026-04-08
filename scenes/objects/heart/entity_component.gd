extends EntityComponent

func despawn() -> void:
	if randf() < 0.3: G.player.progress_controller.add_achievement("ACH_8")
	super()
