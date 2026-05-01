extends "res://scenes/gui/settings_buttons/base_button.gd"

func apply(toggled_on: bool) -> void:
	G.world.weather.env.environment.volumetric_fog_enabled = toggled_on
