extends Area3D

# Теперь массив содержит названия ключей из R.objects (String)
# 0 или null — пустота
var structure_data := [
	[ # Z = 0
		["stone_blocks", "stone_blocks", "stone_blocks"], # Y = 0
		["stone_blocks", null,    "stone_blocks"], # Y = 1
		["stone_blocks", "stone_blocks", "stone_blocks"]  # Y = 2
	],
	[ # Z = 1
		[null,    "wood_blocks",  null],
		["wood_blocks",  "wood_blocks",  "wood_blocks"],
		[null,    "wood_blocks",  null]
	]
]

@export var grid_step: float = 1.0

func _ready() -> void:
	# Даем физике один кадр обновиться перед проверкой overlapping
	await get_tree().physics_frame
	if get_overlapping_bodies().is_empty():
		spawn_structure()
	queue_free()

func spawn_structure():
	var offset := global_position
	
	for y in range(structure_data.size()):
		for z in range(structure_data[y].size()):
			for x in range(structure_data[y][z].size()):
				# Проверяем, что в ячейке не пусто (не null и не 0)
				if structure_data[y][z][x] != null:
					var block_type: String = structure_data[y][z][x]
					
					var world_x := offset.x + (x * grid_step)
					var world_z := offset.z + (z * grid_step)
					var world_y := offset.y + (y * grid_step)
					
					var ground_height: float = G.world._get_height(world_x, world_z)
					
					if ground_height > world_y:
						continue
					
					# Спавним блок нужного типа
					create_block(block_type, world_x, world_y, world_z)
					
					# Фундамент вниз до земли (используем тот же тип блока)
					if y == 0:
						var check_y := world_y - grid_step
						while check_y >= ground_height:
							create_block(block_type, world_x, check_y, world_z)
							check_y -= grid_step

func create_block(block_name: String, gx: float, gy: float, gz: float) -> void:
	var scene: PackedScene
	
	if R.buildings.has(block_name): 
		scene = R.buildings[block_name]["scene"]
	elif R.objects.has(block_name): 
		scene = R.objects[block_name]["scene"]
	else:
		push_error("Block " + block_name + " not found!")
	
	var instance := scene.instantiate()
	# Устанавливаем позицию (координаты уже переданы с учетом смещения и сетки)
	instance.position = Vector3(gx, gy, gz)
	G.environment.add_child(instance, true)

func is_block_in_data(x, y, z) -> bool:
	if z < 0 or z >= structure_data.size(): return false
	if y < 0 or y >= structure_data[z].size(): return false
	if x < 0 or x >= structure_data[z][y].size(): return false
	var val = structure_data[z][y][x]
	return val != null and val != 0
