extends StaticBody3D

@onready var light := $OmniLight3D

@export var energy: float = 1.0
@export var color: Color = Color.WHITE

func _ready() -> void:
	light.light_energy = energy
	light.light_color = color
