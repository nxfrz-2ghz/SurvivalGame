extends DirectionalLight3D

signal night_come
signal day_come

enum n { FALSE, PEACEFUL, DEFAULT, HORROR }
var night := n.FALSE
const night_chances := [
	n.PEACEFUL,
	n.DEFAULT,
	n.DEFAULT,
	n.DEFAULT,
	n.DEFAULT,
	n.HORROR,
]

@export var min_energy := min_night_energy[n.DEFAULT]
@export var max_energy := 1.0
const min_night_energy := {
	n.PEACEFUL: 0.15,
	n.DEFAULT: 0.05,
	n.HORROR: 0.01,
}

@export var day_counter: int
@export var time_speed = 0.5

var current_color: float

func _ready() -> void:
	G.time_controller = self
	rotation_degrees.x = -150 # Early day


func _physics_process(delta: float) -> void:
	if G.state_machine != "game": return
	
	if is_multiplayer_authority():
	
		rotation_degrees.x += time_speed * delta
		if night:
			rotation_degrees.x += time_speed * delta # X2 SPEED
		
		# In sleeping time speed up x100
		if G.player.state == G.player.STATE.SLEEP:
			for i in range(100):
				rotation_degrees.x += time_speed * delta
	
		if rotation_degrees.x > 180 and night != n.FALSE:
			night = n.FALSE
			rotation_degrees.x = -rotation_degrees.x
			max_energy = randf_range(0.8, 2.5) #Случайная яркость дня
			day_counter += 1
			day_come.emit()
		
		if rotation_degrees.x > 0 and night == n.FALSE:
			night = night_chances.pick_random()
			
			# Первая ночь мирная
			if day_counter == 0: night = n.PEACEFUL
			min_energy = min_night_energy[night]
			
			night_come.emit()
	
	# Контроль яркости солнца
	# Вычисляем яркость
	# Используем sin() от радианов. 
	# На -90 градусах (PI/2) sin даст 1, на 0 и -180 даст 0.
	var multiplier := -sin(rotation.x) # Инвертируем, так как идем в минус
	
	# Устанавливаем энергию, ограничивая её снизу (чтобы ночью не было света)
	self.light_energy = clamp(multiplier * max_energy, min_energy, max_energy)
	
	current_color = clamp(multiplier * 1.0, 0.1, 1.0)
	$"../WorldEnvironment".environment.background_energy_multiplier = clamp(multiplier * max_energy/2, min_energy, max_energy/2)
	$"../WorldEnvironment".environment.fog_light_energy = clamp(multiplier * max_energy/2, 0, max_energy/2)
