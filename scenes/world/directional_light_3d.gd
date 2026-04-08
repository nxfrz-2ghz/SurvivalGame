extends DirectionalLight3D

@onready var parent := get_parent()

signal night_come
signal day_come

var night := false

const min_energy := 0.05
var max_energy := 1.0

var time_speed = 0.6 # Скорость смены дня

func _ready() -> void:
	G.time_controller = self
	rotation_degrees.x = -150 # Early day


func _physics_process(delta: float) -> void:
	if G.state_machine != "game": return
	
	rotation_degrees.x += time_speed * delta
	if night:
		rotation_degrees.x += time_speed * delta # X2 SPEED
	
	if Input.is_action_pressed("X"):
		for i in range(100):
			rotation_degrees.x += time_speed * delta
	
	if rotation_degrees.x > 180 and night:
		night = false
		rotation_degrees.x = -rotation_degrees.x
		max_energy = randf_range(0.8, 1.5)
		
		if !G.player.progress_controller.unlocked_notes.has(G.player.progress_controller.notes["NTK_4"]):
			G.player.progress_controller.add_note("NTK_4")
		
		if parent.server: day_come.emit()
	
	if rotation_degrees.x > 0 and !night:
		night = true
		
		if !G.player.progress_controller.unlocked_notes.has(G.player.progress_controller.notes["NTK_3"]):
			G.player.progress_controller.add_note("NTK_3")
		
		if parent.server: night_come.emit()
	
	# Контроль яркости солнца
	# Вычисляем яркость
	# Используем sin() от радианов. 
	# На -90 градусах (PI/2) sin даст 1, на 0 и -180 даст 0.
	var multiplier := -sin(rotation.x) # Инвертируем, так как идем в минус
	
	# Устанавливаем энергию, ограничивая её снизу (чтобы ночью не было света)
	self.light_energy = clamp(multiplier * max_energy, min_energy, max_energy)
	
	var color: float = clamp(multiplier * 1.0, 0.1, 1.0)
	$CanvasModulate.color = Color(color, color, color)
	$"../WorldEnvironment".environment.background_energy_multiplier = clamp(multiplier * max_energy/2, min_energy, max_energy/2)
	$"../WorldEnvironment".environment.fog_light_energy = clamp(multiplier * max_energy/2, 0, max_energy/2)
