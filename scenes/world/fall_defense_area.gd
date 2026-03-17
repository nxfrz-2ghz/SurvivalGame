extends Area3D


func set_size(size: float) -> void:
	$CollisionShape3D.shape.size.x = size
	$CollisionShape3D.shape.size.z = size

func _on_body_entered(body: Node3D) -> void:
	body.position.y = -body.position.y
