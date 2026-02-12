extends Node3D


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	if Input.is_action_pressed("right") and self.rotation.z > -0.04:
		self.rotation.z -= 0.005
		_apply_camera_limits()
	if Input.is_action_pressed("left") and self.rotation.z < 0.04:
		self.rotation.z += 0.005
		_apply_camera_limits()
	
	if self.rotation.z > 0:
		self.rotation.z -= 0.001
		_apply_camera_limits()
	if self.rotation.z < 0:
		self.rotation.z += 0.001
		_apply_camera_limits()



func _apply_camera_limits() -> void:
	self.rotation.x = clamp(self.rotation.x, -PI/2, PI/2)
