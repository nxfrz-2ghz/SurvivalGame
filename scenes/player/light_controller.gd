extends Area3D

@onready var canvas_modulate := $CanvasModulate

# Параметры затухания света
@export var light_radius: float = 5.0   # Максимальный радиус влияния (для расчета яркости)
@export var light_power: float = 1.0    # Общая яркость источников

var color: Color

func _physics_process(_delta: float) -> void:
	# 1. Получаем базовый цвет (атмосферу/время суток)
	var val = G.time_controller.current_color
	color = Color(val, val, val)
	
	# 2. Перебираем объекты в зоне
	var light_nodes := get_overlapping_areas()
	
	for node in light_nodes:
		# Проверяем, есть ли у узла переменная 'color'
		if "color" in node:
			var node_color: Color = node.color
			var dist := global_position.distance_to(node.global_position)
			
			# Рассчитываем коэффициент затухания (от 1.0 до 0.0)
			var attenuation = clamp(1.0 - (dist / light_radius), 0.0, 1.0)
			
			# Ослабляем цвет узла в зависимости от расстояния и силы
			var light_contribution = node_color * attenuation * light_power
			
			# Добавляем вклад этого источника к общему цвету
			color += light_contribution

	# 3. Применяем итоговый цвет, ограничивая значения (0.0 - 1.0)
	canvas_modulate.color = color.clamp()
