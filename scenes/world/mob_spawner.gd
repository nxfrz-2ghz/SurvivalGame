extends Node

const MAX_MOBS := 8
const MAX_SPAWN_RADIUS := 90.0
const MIN_SPAWN_RADIUS := 60.0

func _on_spawn_timer_timeout() -> void:
	if G.state_machine != "game": return
	if !get_parent().server: return
	
	# Проверка лимита мобов
	var current_mobs_count = get_tree().get_nodes_in_group("mobs").size()
	if current_mobs_count >= MAX_MOBS: return
	
	# Выбор моба по весам
	var selected_mob_scene: PackedScene = null
	var total_spawn_weight := 0
	
	for mob_id in R.mobs:
		total_spawn_weight += R.mobs[mob_id]["spawn_weight"]
	
	var rand_spawn_value := randi_range(0, total_spawn_weight)
	var current_spawn_weight := 0
	
	for mob_id in R.mobs:
		current_spawn_weight += R.mobs[mob_id]["spawn_weight"]
		if rand_spawn_value <= current_spawn_weight:
			
			# Проверка моба и требования как спавну
			# Если требование моба не выполнимо, останавливаем
			if R.mobs[mob_id]["requirements"].has("night"):
				if not G.time_controller.is_night():
					return
			
			# Спавн моба и остановка цикла поиска
			selected_mob_scene = R.mobs[mob_id]["scene"]
			break
	
	# Логика появления рядом с игроком
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty(): return
	for target_player in players:
		
		# Вычисляем случайную точку в кольце вокруг игрока
		var spawn_pos = _get_random_spawn_position(target_player.global_position)
		
		# Создание экземпляра
		var mob_instance = selected_mob_scene.instantiate()
		G.world.add_child(mob_instance, true)
		mob_instance.global_position = spawn_pos


func _get_random_spawn_position(center: Vector3) -> Vector3:
	var angle = randf() * TAU # Случайный угол в радианах
	var distance = randf_range(MIN_SPAWN_RADIUS, MAX_SPAWN_RADIUS)
	
	var offset = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
	return center + offset
