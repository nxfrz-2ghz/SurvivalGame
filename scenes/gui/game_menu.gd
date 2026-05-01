extends PanelContainer

signal reload()

var game: bool = false

func _input(_event: InputEvent) -> void:
	if S.state_machine in ["book", "upgrade_table"]: return
	
	if Input.is_action_just_pressed("esc"):
		if visible and S.state_machine == "game_menu":
			visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			S.state_machine = "game"
		elif !visible and S.state_machine == "game":
			visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			S.state_machine = "game_menu"


func _on_continue_pressed() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	S.state_machine = "game"

func _on_save_pressed() -> void:
	G.world.save_world()
	G.player.save_character()

func _on_exit_without_save_pressed() -> void:
	reload.emit()

func _on_exit_pressed() -> void:
	G.world.save_world()
	G.player.save_character()
	reload.emit()
