extends Node3D

@onready var terrain := $Terrain
@onready var weather := $WeatherController
@onready var fall_defense_area := $FallDefenseArea

# Биомы и их параметры
enum Biome { FOREST, ORE_PLATEAU, MOUNTAINS, PLAINS, UNDERWATER }

const BIOME_CONFIG = {
	Biome.FOREST: {
		"name": "Forest",
		"height_multiplier": 2.0,
		"noise_threshold": 0.4,
		"objects": {
			"grass": {"weight": 25, "density": 0.01},
			"tree": {"weight": 55, "density": 0.04},
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
			"rock": {"weight": 45, "density": 0.01},
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
			"grass": {"weight": 92, "density": 0.005},
			"stone": {"weight": 3, "density": 0.01},
			"tree": {"weight": 2, "density": 0.01},
			"berry_bush" : {"weight": 2, "density": 0.04},
		}
	},
	Biome.UNDERWATER: {
		"name": "Underwater",
		"noise_threshold": 0.0,
		"objects": {}
	},
}

const BIOME_TEMP_SWAP := {
	"sand": {
		"tree": "",
		"grass": "",
		"berry_bush": "",
	},
	"snow": {
		"tree": "",
		"grass": "",
		"berry_bush": "",
	},
}

const BIOME_BLEND := 0.03
const BIOME_BORDER_PLATEU := -0.3  # плато / лес
const BIOME_BORDER_FOREST   := -0.1   # лес / равнина
const BIOME_BORDER_PLAINS   := 0.1   # равнина / горы

const TEMP_BORDER_SAND := 0.2
const TEMP_BORDER_GROUND := 0.8
const TEMP_BORDER_SNOW := 1.0

var world_name: String
var world_seed: int
var noise: FastNoiseLite
var biome_noise: FastNoiseLite
var temp_noise: FastNoiseLite

@export var world_size := 500
@export var height_max := 10.0
@export var terrain_visible_range := 100.0
@export var grass_visible_range := 90.0
@export var objects_visible_range := 100.0
@export var buildings_visible_range := 100.0
@export var items_visible_range := 100.0
@export var mobs_visible_range := 100.0

const WATER_LEVEL := -5.5
const CLAY_LEVEL := -7.5

const spacing := 1.0     # Расстояние между вершинами
# object gen
const OBJ_SPAWN_STEP := 1.5  # Генерируем объекты с шагом (экономит спавны)
const LOOT_SPAWN_STEP := 50.0
# drop gen
const DROP_SPAWN_STEP := 25.0  # Генерируем предметы с шагом (экономит спавны)
# mesh gen
const CHUNK_SIZE := 64  # Размер одного чанка в вершинах
const CHUNK_VERTEX_COUNT := CHUNK_SIZE + 1
const noise_scale := 5.0

const ground_material := preload("res://scenes/world/materials/ground_material.tres")
const water_material := preload("res://scenes/world/materials/water_material.tres")


# Grass
const GRASS_DENSITY := 0.5      # вероятность травы на точку
const GRASS_SPAWN_STEP := 0.5
const GRASS_SCALE := Vector3(0.5, 0.5, 0.5)
const grass_mesh := preload("res://res/models/grass/grass.res")

const VARS_WHITELIST := [
	"full", # berry_bush
	"corruption_size", # heart
	"state", # walls
	# for craft and cook components
	"queue",
	"complete",
	"fuel",
	# ========
	"lvl_cost", # loot_chest
	# for saving chiseled blocks
	"is_chiseled",
	"removed_subs",
	# ========
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
func join_world(nname: String, sseed: int, wworld_size: int) -> void:
	server = false
	world_name = nname
	world_seed = sseed
	world_size = wworld_size
	
	_init_noise()
	_generate_world()
	G.player.load_character()
	weather.update.rpc_id(1)


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
	
	# Шум для определения температуры
	temp_noise = FastNoiseLite.new()
	temp_noise.seed = world_seed + 2
	temp_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	temp_noise.frequency = 0.002
	
	fall_defense_area.set_size(world_size)
	weather.env.setup()
	#NodeOptimizer.start()


func _generate_terrain() -> void:
	var offset := (world_size - 1) * spacing / 2.0
	var chunks_count := ceili(float(world_size) / float(CHUNK_SIZE))
	
	for chunk_z in range(chunks_count):
		for chunk_x in range(chunks_count):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			
			var start_x := chunk_x * CHUNK_SIZE
			var start_z := chunk_z * CHUNK_SIZE
			var end_x := mini(start_x + CHUNK_SIZE, world_size - 1)
			var end_z := mini(start_z + CHUNK_SIZE, world_size - 1)
			
			var vertex_map := {}
			var vertex_index := 0
			
			for z in range(start_z, end_z + 1):
				for x in range(start_x, end_x + 1):
					var pos_x := x * spacing - offset
					var pos_z := z * spacing - offset
					var height_y := _get_height(pos_x, pos_z)
					
					# Крутизна — сравниваем высоту с соседними точками
					var h_right := _get_height(pos_x + spacing, pos_z)
					var h_down  := _get_height(pos_x, pos_z + spacing)
					var slope: float= max(abs(height_y - h_right), abs(height_y - h_down))
					var steepness := clampf(slope / 2.0, 0.0, 1.0)  # 0=плоско, 1=скала
					
					# Температура из шума
					var temp := _get_temp(pos_x, pos_z)
					
					# Подводная глина
					var clay := 1.0 if height_y < CLAY_LEVEL else 0.0
					
					st.set_color(Color(steepness, temp, clay, 0.0))
					st.set_uv(Vector2(float(x) / float(world_size - 1), float(z) / float(world_size - 1)))
					st.add_vertex(Vector3(pos_x, height_y, pos_z))
					
					vertex_map[Vector2i(x, z)] = vertex_index
					vertex_index += 1
			
			# Индексы для треугольников в этом чанке
			for z in range(start_z, end_z):
				for x in range(start_x, end_x):
					var i0: int = vertex_map.get(Vector2i(x, z), -1)
					var i1: int = vertex_map.get(Vector2i(x + 1, z), -1)
					var i2: int = vertex_map.get(Vector2i(x, z + 1), -1)
					var i3: int = vertex_map.get(Vector2i(x + 1, z + 1), -1)
					
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
			var mesh_instance := MeshInstance3D.new()
			var collision := CollisionShape3D.new()
			mesh_instance.mesh = mesh
			collision.shape = mesh_instance.mesh.create_trimesh_shape()
			mesh_instance.visibility_range_end = terrain_visible_range
			mesh_instance.material_overlay = ground_material
			mesh_instance.material_overlay.set_shader_parameter("hot_threshold", 1.0 - TEMP_BORDER_SAND)
			mesh_instance.material_overlay.set_shader_parameter("cold_threshold", 1.0 - TEMP_BORDER_GROUND)
			mesh_instance.set_layer_mask_value(2, true) # Enable shadow decal support
			mesh_instance.set_layer_mask_value(3, true) # Enable corruption decal support
			collision.add_to_group("optimized_sync")
			terrain.call_deferred("add_child", mesh_instance)
			terrain.call_deferred("add_child", collision)

func _generate_grass() -> void:
	G.screen_text.text("Generating Grass...")
	await get_tree().process_frame
	
	var offset := (world_size - 1) * spacing / 2.0
	var chunks_count := ceili(float(world_size) / float(CHUNK_SIZE))
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed + 999  # отдельный seed чтобы не мешать объектам
	
	for chunk_z in range(chunks_count):
		for chunk_x in range(chunks_count):
			var start_x := chunk_x * CHUNK_SIZE
			var start_z := chunk_z * CHUNK_SIZE
			var end_x := mini(start_x + CHUNK_SIZE, world_size - 1)
			var end_z := mini(start_z + CHUNK_SIZE, world_size - 1)
			
			# Собираем позиции травы в этом чанке
			var transforms: Array[Transform3D] = []
			
			var gx := float(start_x)
			while gx < end_x:
				gx += GRASS_SPAWN_STEP
				var gz := float(start_z)
				while gz < end_z:
					gz += GRASS_SPAWN_STEP
					var world_x := gx * spacing - offset
					var world_z := gz * spacing - offset
					
					# Проверка высоты
					var spawn_y := _get_height(world_x, world_z)
					if spawn_y <= WATER_LEVEL: continue
					
					# Проверяем биом — трава только в лесу и равнине
					var biome_val := biome_noise.get_noise_2d(world_x / 20.0, world_z / 20.0)
					var biome := _get_biome(biome_val, world_x, world_z)
					if biome not in [Biome.FOREST, Biome.PLAINS]: continue
					
					# Проверка температуры
					var temp := _get_temp(world_x, world_z)
					if temp < TEMP_BORDER_SAND or temp > TEMP_BORDER_GROUND: continue
					
					# Уменьшаем колво травы
					if rng.randf() > GRASS_DENSITY: continue
					
					# Случайный поворот и небольшой разброс позиции
					var offset_x := rng.randf_range(-0.5, 0.5)
					var offset_z := rng.randf_range(-0.5, 0.5)
					var rot_y := rng.randf() * TAU
					
					var t := Transform3D()
					t = t.rotated(Vector3.UP, rot_y)
					t = t.scaled(GRASS_SCALE)
					t.origin = Vector3(world_x + offset_x, spawn_y, world_z + offset_z)
					transforms.append(t)
			
			if transforms.is_empty():
				continue
			
			# Создаём MultiMeshInstance3D для этого чанка
			var mmi := MultiMeshInstance3D.new()
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = grass_mesh
			mm.instance_count = transforms.size()
			
			for i in transforms.size():
				mm.set_instance_transform(i, transforms[i])
			
			mmi.multimesh = mm
			mmi.visibility_range_end = grass_visible_range
			mmi.set_layer_mask_value(2, true) # Enable shadow decal support
			mmi.set_layer_mask_value(3, true) # Enable corruption decal support
			terrain.call_deferred("add_child", mmi)

func _generate_water() -> void:
	var offset := (world_size - 1) * spacing / 2.0
	var chunks_count := ceili(float(world_size) / float(CHUNK_SIZE))
	
	for chunk_z in range(chunks_count):
		for chunk_x in range(chunks_count):
			var has_water := false
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			
			var start_x := chunk_x * CHUNK_SIZE
			var start_z := chunk_z * CHUNK_SIZE
			var end_x := mini(start_x + CHUNK_SIZE, world_size - 1)
			var end_z := mini(start_z + CHUNK_SIZE, world_size - 1)
			
			var vertex_map := {}
			var vertex_index := 0
			
			for z in range(start_z, end_z + 1):
				for x in range(start_x, end_x + 1):
					var pos_x := x * spacing - offset
					var pos_z := z * spacing - offset
					var terrain_h := _get_height(pos_x, pos_z)
					
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
						var px: float = check.x * spacing - offset
						var pz: float = check.y * spacing - offset
						var h := _get_height(px, pz)
						if h < WATER_LEVEL:
							any_underwater = true
							break
					
					if not any_underwater:
						continue
					
					var i0: int = vertex_map[Vector2i(x, z)]
					var i1: int = vertex_map[Vector2i(x + 1, z)]
					var i2: int = vertex_map[Vector2i(x, z + 1)]
					var i3: int = vertex_map[Vector2i(x + 1, z + 1)]
					
					st.add_index(i0); st.add_index(i1); st.add_index(i2)
					st.add_index(i2); st.add_index(i1); st.add_index(i3)
			
			st.generate_normals()
			var mesh_instance := MeshInstance3D.new()
			mesh_instance.mesh = st.commit()
			mesh_instance.material_override = water_material
			mesh_instance.visibility_range_end = terrain_visible_range
			terrain.call_deferred("add_child", mesh_instance)


func _generate_objects() -> void:
	G.screen_text.text("Spawning objects...")
	await get_tree().process_frame
	
	var offset := (world_size - 1) * spacing / 2.0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(world_seed)
	
	var gx := 0.0
	var gz := 0.0
	while gx < world_size:
		gz = 0
		while gz < world_size:
			var world_x := gx * spacing - offset
			var world_z := gz * spacing - offset
			
			# Определяем биом в этой позиции
			var biom_value := biome_noise.get_noise_2d(world_x / 20.0, world_z / 20.0)
			var biome := _get_biome(biom_value, world_x, world_z)
			var biome_config: Dictionary = BIOME_CONFIG[biome]
			
			# Шум для принятия решения о спавне и для выбора варианта
			var noise_value := _get_height(world_x, world_z)
			
			var object_name: String = _select_object(biome_config, noise_value, rng, world_x, world_z)
			if object_name != "":
				var obj_scene: PackedScene = R.objects.get(object_name)["scene"]
				if obj_scene:
					var instance := obj_scene.instantiate()
					# Высота спавна — берем с того же шума, чтобы объект стоял на поверхности
					var spawn_y := _get_height(world_x, world_z)
					instance.position = Vector3(world_x, spawn_y, world_z)
					G.environment.call_deferred("add_child", instance, true)
			
			gz += OBJ_SPAWN_STEP
		gx += OBJ_SPAWN_STEP

func _generate_loot_chests() -> void:
	G.screen_text.text("Spawning loot...")
	await get_tree().process_frame
	
	var offset := (world_size - 1) * spacing / 2.0
	var rng = RandomNumberGenerator.new()
	rng.seed = int(world_seed)
	
	var gx := 0.0
	var gz := 0.0
	while gx < world_size:
		gz = 0
		while gz < world_size:
			var world_x := gx * spacing - offset
			var world_z := gz * spacing - offset
			var obj_scene: PackedScene = R.objects.get("loot_chest")["scene"]
			if obj_scene:
				var instance := obj_scene.instantiate()
				var spawn_y := _get_height(world_x, world_z)
				instance.position = Vector3(world_x, spawn_y, world_z)
				instance.lvl_cost = randi_range(2, 8)
				G.environment.call_deferred("add_child", instance, true)
			
			gz += LOOT_SPAWN_STEP
		gx += LOOT_SPAWN_STEP

func _generate_items() -> void:
	G.screen_text.text("Spawning items...")
	await get_tree().process_frame
	
	var offset := (world_size - 1) * spacing / 2.0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(world_seed)
	
	# Раскидываем предметы по миру
	var gx := 0.0
	var gz := 0.0
	while gx < world_size:
		gz = 0
		while gz < world_size:
			var world_x := gx * spacing - offset
			var world_z := gz * spacing - offset
			
			var spawn_y := +_get_height(world_x, world_z)
			
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
	
	if server:
		weather.toggle_fog.rpc(false)
		weather.toggle_rain.rpc(false)
		weather.toggle_meteor_rain.rpc(false)
	
	if G.gui.main_menu.debug.terrain_gen.button_pressed:
		G.screen_text.text("Generating Terrain...")
		await get_tree().process_frame
		_generate_terrain()
	
	if G.gui.main_menu.debug.grass_gen.button_pressed:
		G.screen_text.text("Generating Grass...")
		await get_tree().process_frame
		_generate_grass()
	
	if G.gui.main_menu.debug.water_gen.button_pressed:
		G.screen_text.text("Generating Water...")
		await get_tree().process_frame
		_generate_water()
	
	G.screen_text.text("")
	if !server: return
	
	if G.gui.main_menu.debug.objects_gen.button_pressed:
		_generate_objects()
	
	if G.gui.main_menu.debug.loot_chests_gen.button_pressed:
		_generate_loot_chests()
	
	if G.gui.main_menu.debug.items_gen.button_pressed:
		_generate_items()


func _get_height(world_x: float, world_z: float) -> float:
	var biome_value := biome_noise.get_noise_2d(world_x / 20.0, world_z / 20.0)
	var multiplier := _get_blended_height_multiplier(biome_value)
	return noise.get_noise_2d(world_x / noise_scale, world_z / noise_scale) * height_max * multiplier


func _get_temp(world_x: float, world_z: float) -> float:
	var raw_noise_temp := temp_noise.get_noise_2d(world_x, world_z)
	# Переводим из -1..1 в 0..1
	var normalized := (raw_noise_temp + 1.0) / 2.0
	# Растягиваем 0.4-0.6 в 0.0-1.0
	return clamp(inverse_lerp(0.4, 0.6, normalized), 0.0, 1.0)


func _get_biome(value: float, world_x: float = 0.0, world_z: float = 0.0) -> int:
	# Сначала проверяем высоту — если под водой, это водный биом
	var height := _get_height(world_x, world_z)
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
	var m_ore      := BIOME_CONFIG[Biome.ORE_PLATEAU]["height_multiplier"]
	var m_forest   := BIOME_CONFIG[Biome.FOREST]["height_multiplier"]
	var m_plains   := BIOME_CONFIG[Biome.PLAINS]["height_multiplier"]
	var m_mountain := BIOME_CONFIG[Biome.MOUNTAINS]["height_multiplier"]

	if biome_value < BIOME_BORDER_PLATEU - BIOME_BLEND:
		return m_ore
	elif biome_value < BIOME_BORDER_PLATEU + BIOME_BLEND:
		var t := inverse_lerp(BIOME_BORDER_PLATEU - BIOME_BLEND, BIOME_BORDER_PLATEU + BIOME_BLEND, biome_value)
		return lerp(m_ore, m_forest, t)
	elif biome_value < BIOME_BORDER_FOREST - BIOME_BLEND:
		return m_forest
	elif biome_value < BIOME_BORDER_FOREST + BIOME_BLEND:
		var t := inverse_lerp(BIOME_BORDER_FOREST - BIOME_BLEND, BIOME_BORDER_FOREST + BIOME_BLEND, biome_value)
		return lerp(m_forest, m_plains, t)
	elif biome_value < BIOME_BORDER_PLAINS - BIOME_BLEND:
		return m_plains
	elif biome_value < BIOME_BORDER_PLAINS + BIOME_BLEND:
		var t := inverse_lerp(BIOME_BORDER_PLAINS - BIOME_BLEND, BIOME_BORDER_PLAINS + BIOME_BLEND, biome_value)
		return lerp(m_plains, m_mountain, t)
	else:
		return m_mountain

func _select_object(biome_config: Dictionary, _noise_value: float, rng: RandomNumberGenerator, pos_x: float, pos_z: float) -> String:
	# 1. Сначала считаем общий вес
	var total_weight := 0.0
	for obj_name in biome_config["objects"]:
		total_weight += biome_config["objects"][obj_name]["weight"]

	# 2. ВЫБИРАЕМ ТИП ОБЪЕКТА ЧЕРЕЗ РАНДОМ (а не через шум)
	var selection := rng.randf() * total_weight
	var current_weight := 0.0

	for obj_name in biome_config["objects"]:
		var obj_config: Dictionary = biome_config["objects"][obj_name]
		current_weight += obj_config["weight"]

		if selection <= current_weight:
			# 3. Проверяем плотность (тоже через рандом)
			if rng.randf() < obj_config["density"]:
				# 4. Проверяем температуру
				var temp := _get_temp(pos_x, pos_z)
				
				# Если не обычный биом, то ищем замену в биомных вариантах объектов
				if temp < TEMP_BORDER_SAND:
					if BIOME_TEMP_SWAP["sand"].get(obj_name):
						obj_name = BIOME_TEMP_SWAP["sand"][obj_name]
				elif temp > TEMP_BORDER_SNOW:
					if BIOME_TEMP_SWAP["snow"].get(obj_name):
						obj_name = BIOME_TEMP_SWAP["snow"][obj_name]
				
				return obj_name
			return ""

	return ""


func save_world() -> void:
	if !server: return
	
	var path: String = "user://worlds/" + world_name + "/world.wld"
	if not DirAccess.dir_exists_absolute("user://worlds/" + world_name):
		DirAccess.make_dir_recursive_absolute("user://worlds/" + world_name)
	
	var save_data := {
		"seed": world_seed,
		"world_size": world_size,
		"sun_rotation": G.time_controller.rotation_degrees.x,
		"day_counter": G.time_controller.day_counter,
		"weather": {
			"fog": weather.fog,
			"rain": weather.rain,
			"meteor_rain": weather.meteor_rain,
		},
		"objects": [],
		"buildings": [],
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
				"component_vars": {},
			}
			for var_name in VARS_WHITELIST:
				if var_name in child:
					# Если у объекта есть такая 
					var val = child.get(var_name)
					# Если это вектор (или любой другой сложный тип), упаковываем его в спец-строку
					entry["vars"][var_name] = var_to_str(val) 
					
				var cook_component := child.get_node_or_null("CookComponent")
				if cook_component and var_name in cook_component:
					var val = cook_component.get(var_name)
					entry["component_vars"][var_name] = var_to_str(val) 
				var craft_component := child.get_node_or_null("CraftComponent")
				if craft_component and var_name in craft_component:
					var val = craft_component.get(var_name)
					entry["component_vars"][var_name] = var_to_str(val) 
			
			save_data["objects"].append(entry)
		
		if child.is_in_group("buildings"):
			entry = {
				"name": child.nname,
				"pos": [child.position.x, child.position.y, child.position.z],
				"rot": [child.rotation.x, child.rotation.y, child.rotation.z],
				"hp": child.health.current_health,
				"vars": {},
			}
			for var_name in VARS_WHITELIST:
				if var_name in child:
					# Если у объекта есть такая 
					var val = child.get(var_name)
					# Если это вектор (или любой другой сложный тип), упаковываем его в спец-строку
					entry["vars"][var_name] = var_to_str(val) 
			save_data["buildings"].append(entry)
		
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
	
	# Запись файла
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("World saved to: ", path)


func load_world() -> void:
	
	var path: String = "user://worlds/" + world_name + "/world.wld"
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
	G.time_controller.day_counter = data.get("day_counter", 1)
	
	if data.get("weather"):
		weather.toggle_fog.rpc(data["weather"]["fog"])
		weather.toggle_rain.rpc(data["weather"]["rain"])
		weather.toggle_meteor_rain.rpc(data["weather"]["meteor_rain"])
	
	server = true # Обычно загрузку делает только сервер
	
	# Пересоздаем террейн
	_init_noise()
	
	if G.gui.main_menu.debug.terrain_gen.button_pressed:
		G.screen_text.text("Generating Terrain...")
		await get_tree().process_frame
		_generate_terrain()
	if G.gui.main_menu.debug.grass_gen.button_pressed:
		G.screen_text.text("Generating Grass...")
		await get_tree().process_frame
		_generate_grass()
	if G.gui.main_menu.debug.water_gen.button_pressed:
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
			if !G.gui.main_menu.debug.items_gen.button_pressed: return
			# Загрузка предметов (дропа)
			var item_instance = R.item.instantiate()
			item_instance.position = pos
			item_instance.nname = obj_name
			G.environment.add_child(item_instance, true)
		else:
			if !G.gui.main_menu.debug.objects_gen.button_pressed: return
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
				if obj_data.has("component_vars"):
					for var_name in obj_data["component_vars"]:
						var raw_value = obj_data["component_vars"][var_name]
						var final_value = raw_value
						if typeof(raw_value) == TYPE_STRING:
							final_value = str_to_var(raw_value)
						var craft_component: Node = instance.get_node_or_null("CraftComponent")
						if craft_component: craft_component.set(var_name, final_value)
						var cook_component: Node = instance.get_node_or_null("CookComponent")
						if cook_component: cook_component.set(var_name, final_value)
				G.environment.add_child(instance, true)
				instance.get_node("HealthComponent").current_health = obj_data["hp"]
	
	for obj_data in data["buildings"]:
		var pos := Vector3(obj_data["pos"][0], obj_data["pos"][1], obj_data["pos"][2])
		var rot := Vector3(obj_data["rot"][0], obj_data["rot"][1], obj_data["rot"][2])
		var obj_name = obj_data["name"]
		
		var obj_scene = R.buildings.get(obj_name)["scene"]
		if obj_scene:
			var instance = obj_scene.instantiate()
			instance.position = pos
			instance.rotation = rot
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

	if G.gui.main_menu.debug.mobs_spawn.button_pressed:
		# Спавним мобов
		for mob_data in data["mobs"]:
			var pos = Vector3(mob_data["pos"][0], mob_data["pos"][1], mob_data["pos"][2])
			var mob_scene = R.mobs.get(mob_data["name"])["scene"]
			if mob_scene:
				var instance = mob_scene.instantiate()
				instance.position = pos
				G.environment.add_child(instance, true)
				instance.get_node("HealthComponent").current_health = mob_data["hp"]
	
	G.screen_text.text("")
	print("World loaded from: ", path)


func _on_autosave_timer_timeout() -> void:
	if !world_name: return
	if !G.gui.main_menu.autosave.button_pressed: return
	save_world()
	G.player.save_character()
