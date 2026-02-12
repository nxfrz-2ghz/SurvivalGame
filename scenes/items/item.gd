extends RigidBody3D

@onready var sprite := $Sprite3D

@export var nname: String


func _ready() -> void:
	sprite.texture = R.items[self.nname]["texture"]
