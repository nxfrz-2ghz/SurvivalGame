extends AnimatedSprite3D

# Предварительно загрузите ваши ресурсы SpriteFrames в инспекторе или через load
@export var frames_forward : SpriteFrames
@export var frames_back : SpriteFrames
@export var frames_side : SpriteFrames

func _physics_process(_delta: float) -> void:
	update_sprite_logic()

@rpc("authority", "call_local")
func anim_play(anim: String) -> void:
	play(anim)

func update_sprite_logic():
	var camera = get_viewport().get_camera_3d()
	if not camera: return

	var forward_3d = global_transform.basis.z
	var dir_to_camera_3d = camera.global_position - global_position
	
	var forward_2d = Vector2(forward_3d.x, forward_3d.z).normalized()
	var to_cam_2d = Vector2(dir_to_camera_3d.x, dir_to_camera_3d.z).normalized()
	var angle = forward_2d.angle_to(to_cam_2d)
	
	# Определяем, какой ресурс нам НУЖЕН
	var next_frames : SpriteFrames
	var should_flip = false

	if angle > -PI/4 and angle <= PI/4:
		next_frames = frames_back
	elif angle > PI/4 and angle <= 3*PI/4:
		next_frames = frames_side
		should_flip = true
	elif angle < -PI/4 and angle >= -3*PI/4:
		next_frames = frames_side
	else:
		next_frames = frames_forward

	# ВАЖНО: Меняем frames только если они реально изменились
	if self.sprite_frames != next_frames:
		var current_anim = animation # Сохраняем имя текущей анимации
		var current_frame = frame     # Сохраняем текущий кадр
		var current_progress = frame_progress # И прогресс кадра
		
		self.sprite_frames = next_frames
		
		# Восстанавливаем состояние, чтобы анимация не прыгала в начало
		play(current_anim)
		set_frame_and_progress(current_frame, current_progress)

	self.flip_h = should_flip
