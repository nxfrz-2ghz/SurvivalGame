extends "res://scenes/structures/base_structure.gd"

func _ready() -> void:
	# Генерируем пирамиду из камня высотой 8 блоков
	structure_data = generate_pyramid(8, "brick_block", true)
	# Вызываем базовый спавн
	super()

func generate_pyramid(height: int, block_type: String, hollow: bool = false):
	var data := []
	var size := (height * 2) - 1 # Ширина основания
	
	for y in range(height):
		var layer := []
		# Граница сужается с каждым уровнем вверх
		var margin := y 
		
		for z in range(size):
			var row := []
			for x in range(size):
				# Проверяем, попадает ли координата в текущий квадрат яруса
				var in_bounds := x >= margin and x < size - margin and z >= margin and z < size - margin
				
				if in_bounds:
					if hollow and y < height - 1:
						# Определяем, является ли блок краем текущего квадрата
						var is_edge := x == margin or x == size - margin - 1 or z == margin or z == size - margin - 1
						# Вместо 1 пишем тип блока, вместо 0 — null
						row.append(block_type if is_edge else null)
					else:
						# Сплошное заполнение для вершины или полной пирамиды
						row.append(block_type)
				else:
					# Пустота за пределами пирамиды
					row.append(null)
			layer.append(row)
		data.append(layer)
	
	return data
