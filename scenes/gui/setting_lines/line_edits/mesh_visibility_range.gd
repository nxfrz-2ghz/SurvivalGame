extends "res://scenes/gui/setting_lines/key_line.gd"

func apply(val: String) -> void:
	G.world.terrain_visible_range = val
