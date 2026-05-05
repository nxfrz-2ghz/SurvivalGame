extends "res://scenes/gui/settings_buttons/key_button.gd"

func apply(toggled_on: bool) -> void:
	G.world.weather.env.environment.fog_enabled = toggled_on
