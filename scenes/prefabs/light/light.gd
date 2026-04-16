extends Area3D

@onready var light := $OmniLight3D

@export var energy: float = 1.0:
	set(value):
		energy = value
		update()

@export var color: Color = Color.WHITE:
	set(value):
		color = value
		update()

func _ready() -> void:
	update()

func update() -> void:
	if !light: return
	light.light_energy = energy
	light.light_color = color
