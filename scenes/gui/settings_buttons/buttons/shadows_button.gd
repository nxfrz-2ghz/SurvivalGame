extends "res://scenes/gui/settings_buttons/base_button.gd"

func apply(toggled_on: bool) -> void:
	G.time_controller.shadow_enabled = toggled_on
