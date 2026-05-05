extends "res://scenes/gui/settings_sliders/key_slider.gd"

func apply(val: float) -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(val))
