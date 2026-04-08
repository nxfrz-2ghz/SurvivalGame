extends StaticBody3D

@onready var mesh_instance := $MeshInstance3D
@onready var collision := $CollisionShape3D

func set_mesh(mesh: Mesh) -> void:
	mesh_instance.mesh = mesh
	collision.shape = mesh_instance.mesh.create_trimesh_shape()
