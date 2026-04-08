extends Area3D


func set_size(size: float) -> void:
	$CollisionShape3D.shape.size.x = size + 50
	$CollisionShape3D.shape.size.z = size + 50

func _on_body_entered(body: Node3D) -> void:
	body.position.y = -body.position.y
	
	if body.is_in_group("players"):
		G.player.progress_controller.add_achievement("ACH_1")
