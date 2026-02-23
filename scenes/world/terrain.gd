extends StaticBody3D

@onready var mesh_instance := $MeshInstance3D
@onready var collider := $CollisionShape3D

func set_mesh(mesh: Mesh) -> void:
	mesh_instance.mesh = mesh
	collider.shape = mesh_instance.mesh.create_trimesh_shape()
