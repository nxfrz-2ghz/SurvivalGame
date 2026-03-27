extends AnimatedSprite3D

# Предварительно загрузите ваши ресурсы SpriteFrames в инспекторе или через load
@export var frames_forward : SpriteFrames
@export var frames_back : SpriteFrames
@export var frames_side : SpriteFrames

func _physics_process(_delta: float) -> void:
	update_sprite_logic()

func update_sprite_logic():
	var camera = get_viewport().get_camera_3d()
	if not camera: return

	# Направление взгляда (Z) и вектор на камеру в плоскости XZ
	var forward_3d = global_transform.basis.z
	var dir_to_camera_3d = camera.global_position - global_position
	
	var forward_2d = Vector2(forward_3d.x, forward_3d.z).normalized()
	var to_cam_2d = Vector2(dir_to_camera_3d.x, dir_to_camera_3d.z).normalized()

	# Угол между взглядом и камерой (от -PI до PI)
	var angle = forward_2d.angle_to(to_cam_2d)
	
	# Сбрасываем зеркальное отражение по умолчанию
	self.flip_h = false

	# Логика выбора сторон (4 сектора по 90 градусов)
	if angle > -PI/4 and angle <= PI/4:
		self.sprite_frames = frames_back
	elif angle > PI/4 and angle <= 3*PI/4:
		self.sprite_frames = frames_side
		self.flip_h = true # Зеркалим "право", чтобы получить "лево"
	elif angle < -PI/4 and angle >= -3*PI/4:
		self.sprite_frames = frames_side
	else:
		self.sprite_frames = frames_forward
	
	# Если анимация не запущена автоматически
	if not self.is_playing():
		self.play()
