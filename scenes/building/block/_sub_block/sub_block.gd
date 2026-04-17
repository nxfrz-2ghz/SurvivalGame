extends StaticBody3D

@onready var mesh := $MeshInstance3D
@onready var collision := $CollisionShape3D

@export var nname: String
@export var size: Vector3

func _ready() -> void:
	mesh.mesh.size = size
	collision.shape.size = size
