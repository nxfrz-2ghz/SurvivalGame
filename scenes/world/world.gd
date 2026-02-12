extends Node3D

@onready var terrain := $Terrain

const objects := {
	"grass": preload("res://scenes/objects/grass/grass.tscn"),
	"tree": preload("res://scenes/objects/tree/tree.tscn"),
	"stone": preload("res://scenes/objects/stone/stone.tscn"),
	"rock": preload("res://scenes/objects/rock/rock.tscn"),
	"copper_ore": preload("res://scenes/objects/copper_ore/copper_ore.tscn"),
	"iron_ore": preload("res://scenes/objects/iron_ore/iron_ore.tscn"),
}

# Биомы и их параметры
enum Biome { FOREST, MOUNTAINS, PLAINS }

const BIOME_CONFIG = {
	Biome.FOREST: {
		"name": "Forest",
		"noise_threshold": 0.4,
		"objects": {
			"grass": {"weight": 40, "density": 0.08},
			"tree": {"weight": 45, "density": 0.05},
			"stone": {"weight": 15, "density": 0.02},
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
			"grass": {"weight": 60, "density": 0.06},
			"stone": {"weight": 25, "density": 0.02},
			"tree": {"weight": 15, "density": 0.02},
		}
	},
}

var world_seed: int
var noise: FastNoiseLite
var biome_noise: FastNoiseLite

# object gen
const WORLD_SIZE = 500
const CHUNK_SIZE = 10
const SPAWN_RADIUS = 300
const SPAWN_STEP = 2  # Генерируем объекты с шагом 4 единицы (экономит спавны)
# mesh gen
const spacing := 1.0     # Расстояние между вершинами
const noise_scale := 5.0
const height_max := 10.0

var server: bool

func start_gen() -> void:
	server = true
	world_seed = randi()
	
	_init_noise()
	_generate_world()


@rpc("call_local")
func join_world(seed: int) -> void:
	server = false
	world_seed = seed
	
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

func _generate_world() -> void:
	WorkerThreadPool.add_task(Callable(self, "_generate_around_position").bind(Vector3.ZERO))

func _generate_around_position(center_pos: Vector3) -> void:
	var grid_x_min = int(center_pos.x - SPAWN_RADIUS) / CHUNK_SIZE
	var grid_x_max = int(center_pos.x + SPAWN_RADIUS) / CHUNK_SIZE
	var grid_z_min = int(center_pos.z - SPAWN_RADIUS) / CHUNK_SIZE
	var grid_z_max = int(center_pos.z + SPAWN_RADIUS) / CHUNK_SIZE
	
	for chunk_x in range(grid_x_min, grid_x_max + 1):
		for chunk_z in range(grid_z_min, grid_z_max + 1):
			_generate_chunk(chunk_x, chunk_z)

func _generate_chunk(chunk_x: int, chunk_z: int) -> void:
	# Генерируем/устанавливаем меш террейна один раз (избегаем пересоздания для каждого чанка)
	if not terrain.mesh_instance.mesh:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var offset := (WORLD_SIZE - 1) * spacing / 2.0

		# Создаем вершины террейна
		for z in range(WORLD_SIZE):
			for x in range(WORLD_SIZE):
				var pos_x = x * spacing - offset
				var pos_z = z * spacing - offset
				
				var height_y = noise.get_noise_2d(pos_x / noise_scale, pos_z / noise_scale) * height_max
				
				st.set_uv(Vector2(float(x) / float(WORLD_SIZE - 1), float(z) / float(WORLD_SIZE - 1)))
				st.add_vertex(Vector3(pos_x, height_y, pos_z))

		# Индексы для треугольников
		for z in range(WORLD_SIZE - 1):
			for x in range(WORLD_SIZE - 1):
				var i0 = z * WORLD_SIZE + x
				var i1 = z * WORLD_SIZE + x + 1
				var i2 = (z + 1) * WORLD_SIZE + x
				var i3 = (z + 1) * WORLD_SIZE + x + 1

				st.add_index(i0)
				st.add_index(i1)
				st.add_index(i2)

				st.add_index(i2)
				st.add_index(i1)
				st.add_index(i3)

		st.generate_normals()
		var mesh = st.commit()
		terrain.call_deferred("set_mesh", mesh)

	# Спавн объектов — используем координаты в мировом пространстве и детерминированный RNG
	var start_x = chunk_x * CHUNK_SIZE
	var start_z = chunk_z * CHUNK_SIZE
	var offset2 := (WORLD_SIZE - 1) * spacing / 2.0

	# Определяем биом для этого чанка
	var biom_value = biome_noise.get_noise_2d(chunk_x * 2.0, chunk_z * 2.0)
	var biome = _get_biome_from_value(biom_value)
	var biome_config = BIOME_CONFIG[biome]

	var rng = RandomNumberGenerator.new()
	rng.seed = int(world_seed) + chunk_x * 1007 + chunk_z * 1009

	var gx = start_x
	while gx < start_x + CHUNK_SIZE:
		var gz = start_z
		while gz < start_z + CHUNK_SIZE:
			var world_x = gx * spacing - offset2
			var world_z = gz * spacing - offset2

			# Шум для принятия решения о спавне и для выбора варианта
			var noise_value = noise.get_noise_2d(world_x / noise_scale, world_z / noise_scale)

			var object_name = _select_object_for_biome(biome_config, noise_value, rng)
			if object_name != "":
				var obj_scene = objects.get(object_name)
				if obj_scene:
					var instance = obj_scene.instantiate()
					# Высота спавна — берем с того же шума, чтобы объект стоял на поверхности
					var spawn_y = noise.get_noise_2d(world_x / noise_scale, world_z / noise_scale) * height_max
					instance.position = Vector3(world_x, spawn_y, world_z)
					G.world.call_deferred("add_child", instance, true)

			gz += SPAWN_STEP
		gx += SPAWN_STEP

func _get_biome_from_value(value: float) -> int:
	if value < -0.25:
		return Biome.MOUNTAINS
	elif value < 0.1:
		return Biome.PLAINS
	else:
		return Biome.FOREST

func _select_object_for_biome(biome_config: Dictionary, noise_value: float, rng = null) -> String:
	# Нормализуем шум к 0..1
	var normalized_noise = (noise_value + 1.0) / 2.0

	# Выбираем объект по весам с учетом плотности
	var total_weight = 0.0
	for obj_name in biome_config["objects"]:
		total_weight += biome_config["objects"][obj_name]["weight"]

	var selection = normalized_noise * total_weight
	var current_weight = 0.0

	for obj_name in biome_config["objects"]:
		var obj_config = biome_config["objects"][obj_name]
		current_weight += obj_config["weight"]

		if selection <= current_weight:
			# Используем переданный RNG для детерминированности, иначе fallback на randf()
			var roll = (rng.randf() if rng != null else randf())
			if roll < obj_config["density"]:
				return obj_name
			else:
				return ""

	return ""
