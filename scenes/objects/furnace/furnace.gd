extends "res://scenes/objects/object.gd"

@onready var cook := $CookComponent

func _ready() -> void:
	super()
	health.died.connect(cook.drop_queue)
