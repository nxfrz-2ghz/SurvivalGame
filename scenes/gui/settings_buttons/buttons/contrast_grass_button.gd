extends "res://scenes/gui/settings_buttons/base_button.gd"

func apply(toggled_on: bool) -> void:
	if toggled_on:
<<<<<<< Updated upstream
		print(1)
=======
>>>>>>> Stashed changes
		var grass_mesh = load("res://res/models/grass/grass.res")
		var mat = grass_mesh.surface_get_material(0)
		mat.set_shader_parameter("color2", Color8(106, 108, 106))
	else:
		var grass_mesh = load("res://res/models/grass/grass.res")
		var mat = grass_mesh.surface_get_material(0)
		mat.set_shader_parameter("color2", Color8(62, 63, 62))
