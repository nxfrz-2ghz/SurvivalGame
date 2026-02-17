extends DirectionalLight3D

const min_energy := 0.0
var max_energy := 1.0

var time_speed = 1.0 # Скорость смены дня

func _ready() -> void:
	rotation_degrees.x = -150 # Early day

func _physics_process(delta: float) -> void:
	rotation_degrees.x += time_speed * delta
	
	#if rotation_degrees.x > 0:
	#	visible = false
	#else:
	#	visible = true
	
	if rotation_degrees.x > 180:
		rotation_degrees.x = -rotation_degrees.x
		max_energy = randf_range(0.8, 1.5)
	
	# Контроль яркости солнца
	# Вычисляем яркость
	# Используем sin() от радианов. 
	# На -90 градусах (PI/2) sin даст 1, на 0 и -180 даст 0.
	var multiplier := -sin(rotation.x) # Инвертируем, так как идем в минус
	
	# Устанавливаем энергию, ограничивая её снизу (чтобы ночью не было света)
	self.light_energy = clamp(multiplier * max_energy, min_energy, max_energy)
	
	var color: float= clamp(multiplier * 1.0, 0.1, 1.0)
	$CanvasModulate.color = Color(color, color, color)
	$"../WorldEnvironment".environment.background_energy_multiplier = clamp(multiplier * max_energy/2, min_energy, max_energy/2)
