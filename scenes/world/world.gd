extends Node3D

@onready var terrain := $Terrain
@onready var fall_defense_area := $FallDefenseArea

# Биомы и их параметры
enum Biome { FOREST, ORE_PLATEAU, MOUNTAINS, PLAINS, UNDERWATER }

const BIOME_CONFIG = {
	Biome.FOREST: {
		"name": "Forest",
		"height_multiplier": 2.0,
		"noise_threshold": 0.4,
		"objects": {
			"grass": {"weight": 25, "density": 0.07},
			"tree": {"weight": 60, "density": 0.04},
			"stone": {"weight": 5, "density": 0.02},
			"berry_bush" : {"weight": 10, "density": 0.05},
		}
	},
	Biome.ORE_PLATEAU: {
		"name": "Ore_plateu",
		"height_multiplier": 1.0,
		"noise_threshold": 0.7,
		"objects": {
			"rock": {"weight": 50, "density": 0.05},
			"copper_ore": {"weight": 30, "density": 0.03},
			"iron_ore": {"weight": 20, "density": 0.03},
		}
	},
	Biome.MOUNTAINS: {
		"name": "Mountains",
		"height_multiplier": 5.0,
		"noise_threshold": 0.7,
		"objects": {
			"rock": {"weight": 50, "density": 0.01},
			"copper_ore": {"weight": 20, "density": 0.005},
			"iron_ore": {"weight": 20, "density": 0.005},
			"tree": {"weight": 10, "density": 0.01},
		}
	},
	Biome.PLAINS: {
		"name": "Plains",
		"height_multiplier": 1.0,
		"noise_threshold": 0.0,
		"objects": {
			"grass": {"weight": 93, "density": 0.06},
			"stone": {"weight": 3, "density": 0.01},
			"tree": {"weight": 2, "density": 0.01},
			"berry_bush" : {"weight": 2, "density": 0.05},
		}
	},
	Biome.UNDERWATER: {
		"name": "Underwater",
		"noise_threshold": 0.0,
		"objects": {}
	},
}

const BIOME_BLEND := 0.03
const BIOME_BORDER_PLATEU := -0.3  # плато / лес
const BIOME_BORDER_FOREST   := -0.1   # лес / равнина
const BIOME_BORDER_PLAINS   := 0.1   # равнина / горы

var world_seed: int
var noise: FastNoiseLite
var biome_noise: FastNoiseLite

@export var world_size := 500
@export var height_max := 10.0
@export var visible_mesh_range := 120.0
const WATER_LEVEL := -5.5
const spacing := 1.0     # Расстояние между вершинами
# object gen
const OBJ_SPAWN_STEP := 1.5  # Генерируем объекты с шагом (экономит спавны)
# drop gen
const DROP_SPAWN_STEP := 25.0  # Генерируем предметы с шагом (экономит спавны)
# mesh gen
const CHUNK_SIZE := 64  # Размер одного чанка в вершинах
const CHUNK_VERTEX_COUNT := CHUNK_SIZE + 1
const noise_scale := 5.0

const ground_material := preload("res://scenes/world/world_material.tres")
const water_material := preload("res://scenes/world/water_material.tres")

const VARS_WHITELIST := [
	"full", # berry_bush
	"corruption_size", # heart
]

var server: bool


func _ready() -> void:
	G.world = self


func start_gen() -> void:
	server = true
	if G.gui.main_menu.world_seed.text:
		world_seed = int(G.gui.main_menu.world_seed.text)
	else:
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
	biome_noise.frequency = 0.05

func _generate_terrain() -> void:
	# Генерируем меш террейна разбитый на чанки
	var offset := (world_size - 1) * spacing / 2.0
	# Вычисляем количество чанков
	var chunks_count = ceili(float(world_size) / float(CHUNK_SIZE))
	var last_status_gen: int
	
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
					
					var height_y = _get_height(pos_x, pos_z)
					
					if height_y < WATER_LEVEL:
						st.set_color(Color(0.6, 0.4, 0.2))  # коричневый — глина
					else:
						st.set_color(Color.WHITE)
					
					
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
			mesh_instance.set_layer_mask_value(2, true) # Enable shadow decal support
			mesh_instance.set_layer_mask_value(3, true) # Enable corruption decal support
			terrain.call_deferred("add_child", mesh_instance)
			terrain.call_deferred("add_child", collider)

func _generate_water() -> void:
	var offset := (world_size - 1) * spacing / 2.0
	var chunks_count = ceili(float(world_size) / float(CHUNK_SIZE))
	
	for chunk_z in range(chunks_count):
		for chunk_x in range(chunks_count):
			var has_water := false
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			
			var start_x = chunk_x * CHUNK_SIZE
			var start_z = chunk_z * CHUNK_SIZE
			var end_x = mini(start_x + CHUNK_SIZE, world_size - 1)
			var end_z = mini(start_z + CHUNK_SIZE, world_size - 1)
			
			var vertex_map := {}
			var vertex_index := 0
			
			for z in range(start_z, end_z + 1):
				for x in range(start_x, end_x + 1):
					var pos_x = x * spacing - offset
					var pos_z = z * spacing - offset
					var terrain_h = _get_height(pos_x, pos_z)
					
					# Вершину воды добавляем только там где terrain ниже уровня воды
					if terrain_h < WATER_LEVEL:
						has_water = true
					
					st.set_uv(Vector2(float(x) / float(world_size - 1), float(z) / float(world_size - 1)))
					st.add_vertex(Vector3(pos_x, WATER_LEVEL, pos_z))
					vertex_map[Vector2i(x, z)] = vertex_index
					vertex_index += 1
			
			if not has_water:
				continue  # пропускаем чанки без воды
			
			for z in range(start_z, end_z):
				for x in range(start_x, end_x):
					# Проверяем что хотя бы одна вершина квада — над водой
					var any_underwater := false
					for check in [Vector2i(x,z), Vector2i(x+1,z), Vector2i(x,z+1), Vector2i(x+1,z+1)]:
						var px = check.x * spacing - offset
						var pz = check.y * spacing - offset
						var h = _get_height(px, pz)
						if h < WATER_LEVEL:
							any_underwater = true
							break
					
					if not any_underwater:
						continue
					
					var i0 = vertex_map[Vector2i(x, z)]
					var i1 = vertex_map[Vector2i(x + 1, z)]
					var i2 = vertex_map[Vector2i(x, z + 1)]
					var i3 = vertex_map[Vector2i(x + 1, z + 1)]
					
					st.add_index(i0); st.add_index(i1); st.add_index(i2)
					st.add_index(i2); st.add_index(i1); st.add_index(i3)
			
			st.generate_normals()
			var mesh_instance := MeshInstance3D.new()
			mesh_instance.mesh = st.commit()
			mesh_instance.material_override = water_material
			mesh_instance.visibility_range_end = visible_mesh_range
			terrain.call_deferred("add_child", mesh_instance)


func _generate_objects() -> void:
	G.screen_text.text("Spawning objects...")
	await get_tree().process_frame
	
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
			var biome = _get_biome(biom_value, world_x, world_z)
			var biome_config = BIOME_CONFIG[biome]
			
			# Шум для принятия решения о спавне и для выбора варианта
			var noise_value = _get_height(world_x, world_z)
			
			var object_name = _select_object_for_biome(biome_config, noise_value, rng)
			if object_name != "":
				var obj_scene = R.objects.get(object_name)["scene"]
				if obj_scene:
					var instance = obj_scene.instantiate()
					# Высота спавна — берем с того же шума, чтобы объект стоял на поверхности
					var spawn_y = _get_height(world_x, world_z)
					instance.position = Vector3(world_x, spawn_y, world_z)
					G.environment.call_deferred("add_child", instance, true)
			
			gz += OBJ_SPAWN_STEP
		gx += OBJ_SPAWN_STEP
	
	G.screen_text.text("Spawning items...")
	await get_tree().process_frame
	
	# Раскидываем предметы по миру
	gx = 0
	while gx < world_size:
		gz = 0
		while gz < world_size:
			var world_x = gx * spacing - offset2
			var world_z = gz * spacing - offset2
			
			var spawn_y = +_get_raw_noise_height(world_x, world_z)
			
			# Не спавним предметы под водой
			if spawn_y >= WATER_LEVEL:
				var instance: RigidBody3D = R.item.instantiate()
				instance.position = Vector3(world_x, spawn_y, world_z)
				instance.nname = "stone"
				G.environment.call_deferred("add_child", instance, true)
			
			gz += DROP_SPAWN_STEP
		gx += DROP_SPAWN_STEP
	
	G.screen_text.text("")


func _generate_world() -> void:
	
	G.screen_text.text("Generating Terrain...")
	await get_tree().process_frame
	fall_defense_area.set_size(world_size)
	_generate_terrain()
	
	G.screen_text.text("Generating Water...")
	await get_tree().process_frame
	_generate_water()
	
	G.screen_text.text("")
	if !server: return
	_generate_objects()


func _get_height(world_x: float, world_z: float) -> float:
	var biome_value = biome_noise.get_noise_2d(world_x / 20.0, world_z / 20.0)
	var multiplier = _get_blended_height_multiplier(biome_value)
	return noise.get_noise_2d(world_x / noise_scale, world_z / noise_scale) * height_max * multiplier


func _get_raw_noise_height(world_x: float, world_z: float) -> float:
	return noise.get_noise_2d(world_x / noise_scale, world_z / noise_scale)


func _get_biome(value: float, world_x: float = 0.0, world_z: float = 0.0) -> int:
	# Сначала проверяем высоту — если под водой, это водный биом
	var height = _get_height(world_x, world_z)
	if height < WATER_LEVEL:
		return Biome.UNDERWATER
	
	if value < BIOME_BORDER_PLATEU:
		return Biome.ORE_PLATEAU
	elif value < BIOME_BORDER_FOREST:
		return Biome.FOREST
	elif value < BIOME_BORDER_PLAINS:
		return Biome.PLAINS
	else:
		return Biome.MOUNTAINS


func _get_blended_height_multiplier(biome_value: float) -> float:
	var m_ore      = BIOME_CONFIG[Biome.ORE_PLATEAU]["height_multiplier"]
	var m_forest   = BIOME_CONFIG[Biome.FOREST]["height_multiplier"]
	var m_plains   = BIOME_CONFIG[Biome.PLAINS]["height_multiplier"]
	var m_mountain = BIOME_CONFIG[Biome.MOUNTAINS]["height_multiplier"]

	if biome_value < BIOME_BORDER_PLATEU - BIOME_BLEND:
		return m_ore
	elif biome_value < BIOME_BORDER_PLATEU + BIOME_BLEND:
		var t = inverse_lerp(BIOME_BORDER_PLATEU - BIOME_BLEND, BIOME_BORDER_PLATEU + BIOME_BLEND, biome_value)
		return lerp(m_ore, m_forest, t)
	elif biome_value < BIOME_BORDER_FOREST - BIOME_BLEND:
		return m_forest
	elif biome_value < BIOME_BORDER_FOREST + BIOME_BLEND:
		var t = inverse_lerp(BIOME_BORDER_FOREST - BIOME_BLEND, BIOME_BORDER_FOREST + BIOME_BLEND, biome_value)
		return lerp(m_forest, m_plains, t)
	elif biome_value < BIOME_BORDER_PLAINS - BIOME_BLEND:
		return m_plains
	elif biome_value < BIOME_BORDER_PLAINS + BIOME_BLEND:
		var t = inverse_lerp(BIOME_BORDER_PLAINS - BIOME_BLEND, BIOME_BORDER_PLAINS + BIOME_BLEND, biome_value)
		return lerp(m_plains, m_mountain, t)
	else:
		return m_mountain

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
		"sun_rotation": G.time_controller.rotation_degrees.x,
		"objects": [],
		"mobs": [],
		"player": {},
	}

	# Перебираем все объекты, которые мы заспавнили
	var entry := {}
	for child in G.environment.get_children():
		if child.is_in_group("objects"):
			entry = {
				"name": child.nname,
				"pos": [child.position.x, child.position.y, child.position.z],
				"hp": child.health.current_health,
				"vars": {},
			}
			for var_name in VARS_WHITELIST:
				if var_name in child:
					# Если у объекта есть такая 
					var val = child.get(var_name)
					# Если это вектор (или любой другой сложный тип), упаковываем его в спец-строку
					entry["vars"][var_name] = var_to_str(val) 
			save_data["objects"].append(entry)
		
		elif child.is_in_group("items"):
			entry = {
				"name": child.nname,
				"pos": [child.position.x, child.position.y, child.position.z],
				"is_drop": true,
			}
			save_data["objects"].append(entry)
		
		elif child.is_in_group("mobs"):
			entry = {
				"name": child.nname,
				"pos": [child.position.x, child.position.y, child.position.z],
				"hp": child.health.current_health,
			}
			save_data["mobs"].append(entry)
	
	# Сохранение игрока
	var player: CharacterBody3D = G.environment.get_node(str(multiplayer.get_unique_id()))
	entry = {
		"name": player.nname,
		"pos": [player.position.x, player.position.y, player.position.z],
		"rot": [player.rotation.y, player.head.rotation.x],
		"health": player.health.current_health,
		"hunger": player.hunger.current_hunger,
		"inventory": player.inv.inventory,
		"unlocked_notes": player.progress_controller.unlocked_notes,
		"current exp": player.progress_controller.cur_exp,
		"current lvl":  player.progress_controller.lvl,
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
	G.time_controller.rotation_degrees.x = data["sun_rotation"]
	server = true # Обычно загрузку делает только сервер
	
	# Пересоздаем террейн
	G.screen_text.text("Generating Terrain...")
	await get_tree().process_frame
	_init_noise()
	_generate_terrain()
	G.screen_text.text("Generating Water...")
	await get_tree().process_frame
	_generate_water()
	
	G.screen_text.text("Loading Data...")
	await get_tree().process_frame
	# Спавним сохраненные объекты
	for obj_data in data["objects"]:
		var pos = Vector3(obj_data["pos"][0], obj_data["pos"][1], obj_data["pos"][2])
		var obj_name = obj_data["name"]
		
		if obj_data.has("is_drop"):
			# Загрузка предметов (дропа)
			var item_instance = R.item.instantiate()
			item_instance.position = pos
			item_instance.nname = obj_name
			G.environment.add_child(item_instance, true)
		else:
			# Загрузка статичных объектов (деревья, руда)
			var obj_scene = R.objects.get(obj_name)["scene"]
			if obj_scene:
				var instance = obj_scene.instantiate()
				instance.position = pos
				instance.nname = obj_name
				if obj_data.has("vars"):
					for var_name in obj_data["vars"]:
						var raw_value = obj_data["vars"][var_name]
						var final_value = raw_value
						if typeof(raw_value) == TYPE_STRING:
							final_value = str_to_var(raw_value)
						instance.set(var_name, final_value)
				G.environment.add_child(instance, true)
				instance.get_node("HealthComponent").current_health = obj_data["hp"]
	
	# Спавним мобов
	for mob_data in data["mobs"]:
		var pos = Vector3(mob_data["pos"][0], mob_data["pos"][1], mob_data["pos"][2])
		var mob_scene = R.mobs.get(mob_data["name"])["scene"]
		if mob_scene:
			var instance = mob_scene.instantiate()
			instance.position = pos
			G.environment.add_child(instance, true)
			instance.get_node("HealthComponent").current_health = mob_data["hp"]
	
	# Загружаем данные игрока
	var player: CharacterBody3D = G.environment.get_node(str(multiplayer.get_unique_id()))
	var player_data: Dictionary = data["player"]
	
	player.nname = player_data["name"]
	
	player.position = Vector3(player_data["pos"][0], player_data["pos"][1], player_data["pos"][2])
	player.rotation.y = player_data["rot"][0]
	player.head.rotation.x = player_data["rot"][1]
	
	player.health.current_health = player_data["health"]
	player.hunger.current_hunger = player_data["hunger"]
	
	for item in player_data["inventory"].values():
		if item:
			player.inv.add_item(item["name"], item["amount"])
	
	player.progress_controller.unlocked_notes = player_data["unlocked_notes"]
	player.progress_controller.cur_exp = player_data["current exp"]
	player.progress_controller.lvl = player_data["current lvl"]
	
	G.screen_text.text("")
