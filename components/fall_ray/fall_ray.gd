extends RayCast3D

@onready var parent := get_parent()


func _ready() -> void:
	self.global_rotation = self.rotation # Избавляемся от вращения родителя


func _physics_process(_delta: float) -> void:
	if !$Timer.is_stopped(): return
	if not is_colliding():
		parent.global_position.y -= 0.1
		if is_multiplayer_authority() and global_position.y < G.world.WATER_LEVEL:
			parent.global_position.y *= -1
	else:
		self.queue_free()
