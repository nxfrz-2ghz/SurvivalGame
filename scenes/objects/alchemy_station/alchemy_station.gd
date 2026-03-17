extends "res://scenes/objects/object.gd"

@onready var craft := $CraftComponent

func _ready() -> void:
	super()
	health.died.connect(craft.drop_queue)
