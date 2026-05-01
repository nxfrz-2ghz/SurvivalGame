extends "res://scenes/gui/settings_sliders/base_slider.gd"

func apply(val: float) -> void:
	get_viewport().scaling_3d_scale = val
