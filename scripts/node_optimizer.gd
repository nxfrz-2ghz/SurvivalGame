extends Node

@export var visibility_range: float = 50.0
@export var update_interval: float = 1.0

func start() -> void:
	if is_multiplayer_authority():
		G.timer_1sec.timeout.connect(_optimize_world)

func _optimize_world() -> void:
	var players = get_tree().get_nodes_in_group("players")
	# Группируем все объекты, которые нужно оптимизировать (мобы, предметы и т.д.)
	var targets = get_tree().get_nodes_in_group("optimized_sync")
	
	for target in targets:
		var is_near_any_player = false
		
		# Проверяем, есть ли хоть один игрок рядом с объектом
		for player in players:
			if target.global_position.distance_to(player.global_position) < visibility_range:
				is_near_any_player = true
				break
		
		# Управляем состоянием объекта
		_set_target_active(target, is_near_any_player)

func _set_target_active(target: Node3D, active: bool) -> void:
	# 1. Отключаем/включаем синхронизатор (чтобы не жрать сеть)
	var sync := target.get_node_or_null("MultiplayerSynchronizer")
	if sync:
		# Если false, сервер перестает слать обновления об этом объекте
		sync.public_visibility = active 
	var sync2 := target.get_node_or_null("MultiplayerSynchronizer2")
	if sync2:
		sync2.public_visibility = active 
	
	# 2. Отключаем/включаем логику (Process и Физику)
	if active:
		target.process_mode = PROCESS_MODE_INHERIT
	else:
		target.process_mode = PROCESS_MODE_DISABLED
