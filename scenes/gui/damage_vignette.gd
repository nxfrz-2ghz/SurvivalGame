extends TextureRect

func on_damage() -> void:
	$AnimationPlayer.play("default")
