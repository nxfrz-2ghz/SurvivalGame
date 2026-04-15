extends Node

func _ready() -> void:
	Input.set_custom_mouse_cursor(
		load("res://res/cursors/default.png")
	)
	
	Input.set_custom_mouse_cursor(
		load("res://res/cursors/wait.png"),
		Input.CURSOR_WAIT
	)
	
	#Input.set_custom_mouse_cursor(
	#	load("res://res/cursors/drag.png"),
	#	Input.CURSOR_DRAG
	#)
	
	#Input.set_custom_mouse_cursor(
	#	load("res://res/cursors/forbidden.png"),
	#	Input.CURSOR_FORBIDDEN
	#)
	
	Input.set_custom_mouse_cursor(
		load("res://res/cursors/i-beam.png"),
		Input.CURSOR_IBEAM
	)
