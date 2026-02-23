extends PanelContainer

var game: bool = false

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("esc") and game:
		if visible:
			visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			G.state_machine = "game"
		else:
			visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			G.state_machine = "game_menu"


func _on_save_pressed() -> void:
	var world := G.world.get_node("World")
	world.save_world()


func _on_exit_without_save_pressed() -> void:
	get_tree().reload_current_scene()


func _on_exit_pressed() -> void:
	var world := G.world.get_node("World")
	world.save_world()
	get_tree().reload_current_scene()
