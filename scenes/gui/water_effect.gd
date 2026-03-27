extends ColorRect

func _physics_process(_delta: float) -> void:
	if !G.player: return
	
	visible = G.player.is_underwater()
	
