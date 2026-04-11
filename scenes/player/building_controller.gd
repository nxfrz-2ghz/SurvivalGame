extends Node

const MESHES := {
	"block": preload("res://scenes/building/block/_meshes/full_box.tres"),
	"wall": preload("res://scenes/building/wall/_meshes/wall_mesh.tres"),
}

const SHAPES := {
	"block": preload("res://scenes/building/block/_shapes/full_box.tres"),
	"wall": preload("res://scenes/building/wall/_shapes/wall_shape.tres"),
}

const STEPS := {
	"block": 1.0,
	"wall": 0.5,
}

@onready var area := $BuildArea

var type: String
var step: float
var max_attempts := 6

func set_item(nname: String) -> void:
	if R.items[nname].has("is_building"):
		type = R.items[nname]["build_type"]
		step = STEPS[type]
		area.mesh.mesh = MESHES[type]
		area.shape.shape = SHAPES[type]
		
		area.visible = true
	else:
		area.visible = false


func _physics_process(_delta: float) -> void:
	if area.visible:
		# 1. Позиционирование и вращение (Ваш базовый код)
		area.global_position.x = snappedf(G.player.weapon.actions.global_position.x, step)
		area.global_position.z = snappedf(G.player.weapon.actions.global_position.z, step)
		area.global_rotation_degrees.x = snappedf(G.player.head.rotation_degrees.x, 90.0)
		
		var is_vertical = (area.global_rotation_degrees.x == 0.0)
		
		if type == "wall":
			if is_vertical:
				area.global_rotation_degrees.y = snappedf(G.player.rotation_degrees.y, 90.0)
				area.global_rotation_degrees.z = 0.0
				area.global_position.y = snappedf(G.player.weapon.actions.global_position.y, 0.5) + 1.0
			else:
				area.global_rotation_degrees.y = 0.0
				area.global_rotation_degrees.z = snappedf(G.player.rotation_degrees.y, 90.0)
				area.global_position.y = snappedf(G.player.weapon.actions.global_position.y, 0.5)
		elif type == "block":
			area.global_position.y = snappedf(G.player.weapon.actions.global_position.y, 0.5)
		
		if Input.is_action_pressed("R"):
			area.global_rotation_degrees.x = -45.0
		
		# 2. Логика динамического смещения
		if area.is_colliding():
			var start_pos = area.global_position
			
			var forward = area.global_transform.basis.z.normalized()
			var right = area.global_transform.basis.x.normalized()

			# ОПРЕДЕЛЯЕМ ПОРЯДОК ПРОВЕРОК
			var check_order = []
			if type == "wall":
				if is_vertical:
					check_order = ["right", "left", "forward"]
				else:
					check_order = ["forward", "right", "left"]
			elif type == "block":
				check_order = ["forward", "right", "left"]
			
			# Цикл по выбранному порядку
			for direction in check_order:
				if !area.is_colliding(): break
				
				area.global_position = start_pos # Сброс перед каждой новой осью
				
				for i in range(max_attempts):
					if !area.is_colliding(): break
					
					# Применяем вектор в зависимости от текущего шага проверки
					match direction:
						"forward": area.global_position += forward * step
						"right":   area.global_position += right * step
						"left":    area.global_position -= right * step
