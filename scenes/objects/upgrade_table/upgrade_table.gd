extends "res://scenes/objects/object.gd"

@onready var crystall_sprite := $CrystallSprite3D

func _ready() -> void:
	super()
	crystall_sprite.start_floating()
