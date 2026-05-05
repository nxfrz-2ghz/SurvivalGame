extends "res://scenes/gui/settings_sliders/key_slider.gd"

func apply(val: float) -> void:
	get_viewport().scaling_3d_scale = val
