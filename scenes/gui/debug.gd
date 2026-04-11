extends Label

func _physics_process(_delta: float) -> void:
	if !visible: return
	if G.state_machine != "game": return
	if not G.player: return
	
	text = "FPS: " + str(Engine.get_frames_per_second())
	
	text += "\nPosition\n"
	text += "X: " + str(G.player.position.x) + "\n"
	text += "Y: " + str(G.player.position.y) + "\n"
	text += "Z: " + str(G.player.position.z) + "\n"
	text += "Rotation\n"
	text += "X: " + str(G.player.rotation.y) + "\n"
	text += "Y: " + str(G.player.head.rotation.x) + "\n"
	
	text += "Health: " + str(G.player.health.current_health) + "\n"
	text += "Hunger: " + str(G.player.hunger.current_hunger) + "\n"
	text += "Fear: " + str(G.player.fear.current_fear) + "\n"
