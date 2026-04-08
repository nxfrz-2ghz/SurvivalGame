extends Node

const MAX_MOBS := 25
const MAX_SPAWN_RADIUS := 80.0
const MIN_SPAWN_RADIUS := 50.0

@onready var parent := get_parent()

func _ready() -> void:
	G.mob_spawner = self


func spawn_mob(mob_scene: PackedScene, position: Vector3) -> void:
	if !parent.server: return
	var mob_instance := mob_scene.instantiate()
	mob_instance.position = position
	G.environment.add_child(mob_instance, true)
	
	# Scale mob stats with player progress
	var mob_health: Node = mob_instance.get_node_or_null("HealthComponent")
	if mob_health:
		if G.player.progress_controller.unlocked_notes.has("NTV_7"):
			mob_health.max_health *= 1.2
			mob_health.current_health *= 1.2
		if G.player.progress_controller.unlocked_notes.has("NTV_10"):
			mob_health.max_health *= 1.35
			mob_health.current_health *= 1.35
		if G.player.progress_controller.unlocked_notes.has("NTV_12"):
			mob_health.max_health *= 1.5
			mob_health.current_health *= 1.5


func _on_directional_light_3d_night_come() -> void:
	if !parent.server: return
	# Выбор случайного игрока
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty(): return
	var target_player: CharacterBody3D = players.pick_random()
	# Вычисляем случайную точку в кольце вокруг игрока
	var spawn_pos := get_random_spawn_position(target_player.global_position)
	spawn_pos.y = 20
	# Создание экземпляра
	spawn_mob(R.objects["heart"]["scene"], spawn_pos)


func _on_spawn_timer_timeout() -> void:
	if G.state_machine != "game": return
	if !parent.server: return
	
	# Проверка лимита мобов
	var current_mobs_count := get_tree().get_nodes_in_group("mobs").size()
	if current_mobs_count >= MAX_MOBS: return
	
	# Выбор моба по весам
	var selected_mob_scene: PackedScene = null
	var total_spawn_weight := 0
	
	for mob_id in R.mobs:
		total_spawn_weight += R.mobs[mob_id].get("spawn_weight", 0)
	
	if total_spawn_weight <= 0:
		return
	
	
	var rand_spawn_value := randi_range(1, total_spawn_weight)
	var current_spawn_weight := 0
	
	for mob_id in R.mobs:
		# Игнорируем мобов без веса
		var weight = R.mobs[mob_id].get("spawn_weight", 0)
		if weight <= 0:
			continue
		
		current_spawn_weight += weight
		if rand_spawn_value <= current_spawn_weight:
			
			# Проверка моба и требования как спавну
			if R.mobs[mob_id].has("requirements"):
				# Если требование моба не выполнимо, останавливаем
				if R.mobs[mob_id]["requirements"].has("night"):
					if not G.time_controller.night:
						return
			
			# Спавн моба и остановка цикла поиска
			selected_mob_scene = R.mobs[mob_id]["scene"]
			break
	
	# Логика появления рядом с игроком
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty(): return
	for target_player in players:
		
		# Вычисляем случайную точку в кольце вокруг игрока
		var spawn_pos := get_random_spawn_position(target_player.global_position)
		spawn_pos.y = 50
		
		# Создание экземпляра
		spawn_mob(selected_mob_scene, spawn_pos)


func get_random_spawn_position(center: Vector3, min_spawn_radius := MIN_SPAWN_RADIUS, max_spawn_radius := MAX_SPAWN_RADIUS) -> Vector3:
	var angle := randf() * TAU # Случайный угол в радианах
	var distance := randf_range(min_spawn_radius, max_spawn_radius)
	
	var offset := Vector3(cos(angle) * distance, 0, sin(angle) * distance)
	return center + offset
