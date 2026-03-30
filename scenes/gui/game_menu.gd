extends PanelContainer

var game: bool = false

func _input(_event: InputEvent) -> void:
	if G.state_machine == "book": return
	
	if Input.is_action_just_pressed("esc"):
		if visible and G.state_machine == "game_menu":
			visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			G.state_machine = "game"
		elif !visible and G.state_machine == "game":
			visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			G.state_machine = "game_menu"


func _on_continue_pressed() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	G.state_machine = "game"

func _on_save_pressed() -> void:
	G.world.save_world()
	G.player.save_character()

func _on_exit_without_save_pressed() -> void:
	get_tree().reload_current_scene()

func _on_exit_pressed() -> void:
	G.world.save_world()
	G.player.save_character()
	get_tree().reload_current_scene()
