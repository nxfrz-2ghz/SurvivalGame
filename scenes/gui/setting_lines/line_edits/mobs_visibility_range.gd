extends "res://scenes/gui/setting_lines/base_line.gd"

func apply(val: String) -> void:
	G.world.mobs_visible_range = val
