extends "res://scenes/gui/settings_sliders/base_slider.gd"

func apply(val: float) -> void:
	if val == 0:
		get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		$"../Label".text = "upscale: no"
	if val == 1:
		get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
		$"../Label".text = "upscale: FSR"
	if val == 2:
		get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
		$"../Label".text = "upscale: FSR2"
