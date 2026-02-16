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
@export var world_size := 500
const SPAWN_STEP := 2  # Генерируем объекты с шагом 4 единицы (экономит спавны)
# mesh gen
const CHUNK_SIZE := 64  # Размер одного чанка в вершинах
const CHUNK_VERTEX_COUNT := CHUNK_SIZE + 1
const spacing := 1.0     # Расстояние между вершинами
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

func _generate_world() -> void:
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
	
	if !server: return
	
	# Генерируем все объекты одновременно
	var offset2 := (world_size - 1) * spacing / 2.0
	var rng = RandomNumberGenerator.new()
	rng.seed = int(world_seed)
	
	var gx = 0
	while gx < world_size:
		var gz = 0
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
				var obj_scene = objects.get(object_name)
				if obj_scene:
					var instance = obj_scene.instantiate()
					# Высота спавна — берем с того же шума, чтобы объект стоял на поверхности
					var spawn_y = noise.get_noise_2d(world_x / noise_scale, world_z / noise_scale) * height_max
					instance.position = Vector3(world_x, spawn_y, world_z)
					instance.set_meta("object_name", object_name)
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


func save_world(path: String = "user://world.save") -> bool:
	var save_data := {
		"seed": world_seed,
		"objects": []
	}

	for child in G.world.get_children():
		if child == terrain:
			continue
		if child is RigidBody3D or child is StaticBody3D:
			var obj_name = str(child.get_meta("object_name"))
			var pos: Vector3 = child.position if child.has_method("position") else Vector3.ZERO
			var entry := {"name": obj_name, "position": [pos.x, pos.y, pos.z]}
			if child.has_method("get_save_data"):
				entry["state"] = child.call("get_save_data")
			save_data["objects"].append(entry)

	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Failed to open save file: %s" % path)
		return false

	f.store_var(save_data)
	f.close()
	return true


func load_world(path: String = "user://world.save") -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Failed to open save file: %s" % path)
		return false

	var data = f.get_var()
	f.close()

	# Restore seed and noise
	world_seed = int(data.get("seed", world_seed))
	_init_noise()

	# Remove existing spawned objects (keep terrain)
	var to_remove := []
	for child in get_children():
		if child == terrain:
			continue
		to_remove.append(child)
	for c in to_remove:
		c.queue_free()

	# Instantiate saved objects
	for obj in data.get("objects", []):
		var name: String = str(obj.get("name", ""))
		var pos_val = obj.get("position", [])
		var pos: Vector3 = Vector3.ZERO
		if typeof(pos_val) == TYPE_ARRAY and pos_val.size() >= 3:
			pos = Vector3(float(pos_val[0]), float(pos_val[1]), float(pos_val[2]))
		var scene = objects.get(name, null)
		if scene:
			var instance = scene.instantiate()
			instance.position = pos
			instance.set_meta("object_name", name)
			G.world.add_child(instance)
			var state = obj.get("state", null)
			if state != null and instance.has_method("load_save_data"):
				instance.call("load_save_data", state)

	return true
