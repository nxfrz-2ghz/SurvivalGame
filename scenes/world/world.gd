extends Node3D

@onready var terrain := $Terrain
@onready var time_controller := $DirectionalLight3D 

# Биомы и их параметры
enum Biome { FOREST, MOUNTAINS, PLAINS }

const BIOME_CONFIG = {
	Biome.FOREST: {
		"name": "Forest",
		"noise_threshold": 0.4,
		"objects": {
			"grass": {"weight": 25, "density": 0.08},
			"tree": {"weight": 60, "density": 0.05},
			"stone": {"weight": 5, "density": 0.02},
			"berry_bush" : {"weight": 10, "density": 0.05},
		}
	},
	Biome.MOUNTAINS: {
		"name": "Mountains",
		"noise_threshold": 0.7,
		"objects": {
			"rock": {"weight": 50, "density": 0.08},
			"copper_ore": {"weight": 30, "density": 0.03},
			"iron_ore": {"weight": 20, "density": 0.02},
		}
	},
	Biome.PLAINS: {
		"name": "Plains",
		"noise_threshold": 0.0,
		"objects": {
			"grass": {"weight": 93, "density": 0.06},
			"stone": {"weight": 3, "density": 0.01},
			"tree": {"weight": 2, "density": 0.01},
			"berry_bush" : {"weight": 2, "density": 0.05},
		}
	},
}

var world_seed: int
var noise: FastNoiseLite
var biome_noise: FastNoiseLite

@export var world_size := 500
const spacing := 1.0     # Расстояние между вершинами
# object gen
const OBJ_SPAWN_STEP := 1.5  # Генерируем объекты с шагом (экономит спавны)
# drop gen
const DROP_SPAWN_STEP := 15.0  # Генерируем объекты с шагом (экономит спавны)
# mesh gen
const CHUNK_SIZE := 64  # Размер одного чанка в вершинах
const CHUNK_VERTEX_COUNT := CHUNK_SIZE + 1
const noise_scale := 5.0
const height_max := 10.0
const visible_mesh_range := 120.0
const ground_material := preload("res://scenes/world/world_material.tres")

var server: bool


func start_gen() -> void:
	server = true
	world_seed = randi()
	world_size = int(G.gui.main_menu.world_size.text)
	
	_init_noise()
	_generate_world()


@rpc("call_local")
func join_world(sseed: int, wworld_size: int) -> void:
	server = false
	world_seed = sseed
	world_size = wworld_size
	
	_init_noise()
	_generate_world()


func _init_noise() -> void:
	# Шум для деталей объектов
	noise = FastNoiseLite.new()
	noise.seed = world_seed
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05
	
	# Шум для определения биомов
	biome_noise = FastNoiseLite.new()
	biome_noise.seed = world_seed + 1
	biome_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	biome_noise.frequency = 0.02

func _generate_terrain() -> void:
	# Генерируем меш террейна разбитый на чанки
	var offset := (world_size - 1) * spacing / 2.0
	# Вычисляем количество чанков
	var chunks_count = ceili(float(world_size) / float(CHUNK_SIZE))
	
	# Создаем чанки
	for chunk_z in range(chunks_count):
		for chunk_x in range(chunks_count):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			
			var start_x = chunk_x * CHUNK_SIZE
			var start_z = chunk_z * CHUNK_SIZE
			var end_x = mini(start_x + CHUNK_SIZE, world_size - 1)
			var end_z = mini(start_z + CHUNK_SIZE, world_size - 1)
			
			# Создаем вершины для этого чанка
			var vertex_map = {}
			var vertex_index = 0
			
			for z in range(start_z, end_z + 1):
				for x in range(start_x, end_x + 1):
					var pos_x = x * spacing - offset
					var pos_z = z * spacing - offset
					
					var height_y = noise.get_noise_2d(pos_x / noise_scale, pos_z / noise_scale) * height_max
					
					st.set_uv(Vector2(float(x) / float(world_size - 1), float(z) / float(world_size - 1)))
					st.add_vertex(Vector3(pos_x, height_y, pos_z))
					
					vertex_map[Vector2i(x, z)] = vertex_index
					vertex_index += 1
			
			# Индексы для треугольников в этом чанке
			for z in range(start_z, end_z):
				for x in range(start_x, end_x):
					var i0 = vertex_map.get(Vector2i(x, z), -1)
					var i1 = vertex_map.get(Vector2i(x + 1, z), -1)
					var i2 = vertex_map.get(Vector2i(x, z + 1), -1)
					var i3 = vertex_map.get(Vector2i(x + 1, z + 1), -1)
					
					if i0 >= 0 and i1 >= 0 and i2 >= 0 and i3 >= 0:
						st.add_index(i0)
						st.add_index(i1)
						st.add_index(i2)
						
						st.add_index(i2)
						st.add_index(i1)
						st.add_index(i3)
			
			st.generate_normals()
			var mesh = st.commit()
			
			# Создаем геометрия для визуализации чанка
			var mesh_instance = MeshInstance3D.new()
			var collider = CollisionShape3D.new()
			mesh_instance.mesh = mesh
			collider.shape = mesh_instance.mesh.create_trimesh_shape()
			mesh_instance.visibility_range_end = visible_mesh_range
			mesh_instance.material_overlay = ground_material
			terrain.call_deferred("add_child", mesh_instance)
			terrain.call_deferred("add_child", collider)

func _generate_world() -> void:
	
	_generate_terrain()
	
	if !server: return
	
	# Генерируем все объекты одновременно
	var offset2 := (world_size - 1) * spacing / 2.0
	var rng = RandomNumberGenerator.new()
	rng.seed = int(world_seed)
	
	var gx = 0
	var gz = 0
	while gx < world_size:
		gz = 0
		while gz < world_size:
			var world_x = gx * spacing - offset2
			var world_z = gz * spacing - offset2
			
			# Определяем биом в этой позиции
			var biom_value = biome_noise.get_noise_2d(world_x / 20.0, world_z / 20.0)
			var biome = _get_biome_from_value(biom_value)
			var biome_config = BIOME_CONFIG[biome]
			
			# Шум для принятия решения о спавне и для выбора варианта
			var noise_value = noise.get_noise_2d(world_x / noise_scale, world_z / noise_scale)
			
			var object_name = _select_object_for_biome(biome_config, noise_value, rng)
			if object_name != "":
				var obj_scene = R.objects.get(object_name)["scene"]
				if obj_scene:
					var instance = obj_scene.instantiate()
					# Высота спавна — берем с того же шума, чтобы объект стоял на поверхности
					var spawn_y = noise.get_noise_2d(world_x / noise_scale, world_z / noise_scale) * height_max
					instance.position = Vector3(world_x, spawn_y, world_z)
					instance.set_meta("object_name", object_name)
					G.world.call_deferred("add_child", instance, true)
		
			gz += OBJ_SPAWN_STEP
		gx += OBJ_SPAWN_STEP
	
	# Раскидываем предметы по карте
	gx = 0
	while gx < world_size:
		gz = 0
		while gz < world_size:
			var world_x = gx * spacing - offset2
			var world_z = gz * spacing - offset2
			
			
			var instance: RigidBody3D = R.item.instantiate() 
			# Высота спавна — берем с того же шума, чтобы объект стоял на поверхности
			var spawn_y = noise.get_noise_2d(world_x / noise_scale, world_z / noise_scale) * height_max
			instance.position = Vector3(world_x, spawn_y, world_z)
			instance.nname = "stone"
			G.world.call_deferred("add_child", instance, true)
		
			gz += DROP_SPAWN_STEP
		gx += DROP_SPAWN_STEP


func _get_biome_from_value(value: float) -> int:
	if value < -0.15:
		return Biome.MOUNTAINS
	elif value < 0.05:
		return Biome.PLAINS
	else:
		return Biome.FOREST

func _select_object_for_biome(biome_config: Dictionary, _noise_value: float, rng: RandomNumberGenerator) -> String:
	# 1. Сначала считаем общий вес
	var total_weight = 0.0
	for obj_name in biome_config["objects"]:
		total_weight += biome_config["objects"][obj_name]["weight"]

	# 2. ВЫБИРАЕМ ТИП ОБЪЕКТА ЧЕРЕЗ РАНДОМ (а не через шум)
	var selection = rng.randf() * total_weight
	var current_weight = 0.0

	for obj_name in biome_config["objects"]:
		var obj_config = biome_config["objects"][obj_name]
		current_weight += obj_config["weight"]

		if selection <= current_weight:
			# 3. Проверяем плотность (тоже через рандом)
			if rng.randf() < obj_config["density"]:
				return obj_name
			return ""

	return ""



func save_world(path: String = "user://world.save") -> void:
	var save_data := {
		"seed": world_seed,
		"world_size": world_size,
		"sun_rotation": time_controller.rotation_degrees.x,
		"objects": [],
		"player": {},
	}

	# Перебираем все объекты, которые мы заспавнили
	var entry := {}
	for child in G.world.get_children():
		if child.is_in_group("objects"):
			entry = {
				"name": child.nname,
				"pos": [child.position.x, child.position.y, child.position.z],
				"hp": child.health.current_health,
			}
			save_data["objects"].append(entry)
		
		elif child.is_in_group("items"):
			entry = {
				"name": child.nname,
				"pos": [child.position.x, child.position.y, child.position.z],
				"is_drop": true,
			}
			save_data["objects"].append(entry)
	
	# Сохранение игрока
	var player: CharacterBody3D = G.world.get_node(str(multiplayer.get_unique_id()))
	entry = {
		"name": player.nname,
		"pos": [player.position.x, player.position.y, player.position.z],
		"rot": [player.rotation.y, player.head.rotation.x],
		"health": player.health.current_health,
		"hunger": player.hunger.current_hunger,
		"inventory": player.inventory.inventory,
	}
	save_data["player"] = entry
	
	# Запись файла
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("World saved to: ", path)


func load_world(path: String = "user://world.save") -> void:
	if not FileAccess.file_exists(path):
		print("Save file not found!")
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var json_str = file.get_as_text()
	file.close()

	var data = JSON.parse_string(json_str)
	if data == null: return

	# Восстанавливаем параметры мира
	world_seed = data["seed"]
	world_size = data["world_size"]
	time_controller.rotation_degrees.x = data["sun_rotation"]
	server = true # Обычно загрузку делает только сервер
	
	# Пересоздаем террейн
	_init_noise()
	_generate_terrain()

	# Спавним сохраненные объекты
	for obj_data in data["objects"]:
		var pos = Vector3(obj_data["pos"][0], obj_data["pos"][1], obj_data["pos"][2])
		var obj_name = obj_data["name"]
		
		if obj_data.has("is_drop"):
			# Загрузка предметов (дропа)
			var item_instance = R.item.instantiate()
			item_instance.position = pos
			item_instance.nname = obj_name
			G.world.add_child(item_instance, true)
		else:
			# Загрузка статичных объектов (деревья, руда)
			var obj_scene = R.objects.get(obj_name)["scene"]
			if obj_scene:
				var instance = obj_scene.instantiate()
				instance.position = pos
				instance.nname = obj_name
				instance.get_node("HealthComponent").current_health = obj_data["hp"]
				G.world.add_child(instance, true)
	
	# Загружаем данные игрока
	var player: CharacterBody3D = G.world.get_node(str(multiplayer.get_unique_id()))
	var player_data: Dictionary = data["player"]
	
	player.nname = player_data["name"]
	
	player.position = Vector3(player_data["pos"][0], player_data["pos"][1], player_data["pos"][2])
	player.rotation.y = player_data["rot"][0]
	player.head.rotation.x = player_data["rot"][1]
	
	player.health.current_health = player_data["health"]
	player.hunger.current_hunger = player_data["hunger"]
	
	for item in player_data["inventory"].values():
		if item:
			player.inventory.add_item(item["name"], item["amount"])
