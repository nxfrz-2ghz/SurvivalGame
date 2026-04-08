extends "res://scenes/objects/object.gd"

const mesh := preload("res://res/models/grass/grass_mesh.tscn")

func _ready() -> void:
	super()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(name)
	
	for i in rng.randi_range(1, 3):
		var grass_mesh := mesh.instantiate()
		grass_mesh.position.x = rng.randf_range(-0.4, 0.4)
		grass_mesh.position.z = rng.randf_range(-0.4, 0.4)
		grass_mesh.rotation.y = rng.randf()
		var scl := rng.randf_range(0.4,0.8)
		grass_mesh.scale = Vector3(scl,scl,scl)
		self.add_child(grass_mesh)
