extends Label3D

func _physics_process(_delta: float) -> void:
	self.position.y += 0.01
	self.modulate.a -= 0.02
	if modulate.a <= 0:
		queue_free()
