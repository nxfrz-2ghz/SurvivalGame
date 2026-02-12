extends Node3D


func _ready() -> void:
	if not is_multiplayer_authority():
		self.queue_free()
