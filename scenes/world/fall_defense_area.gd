extends Area3D


func set_size(size: float) -> void:
	$CollisionShape3D.shape.size.x = size + 50
	$CollisionShape3D.shape.size.z = size + 50

func _on_body_entered(body: Node3D) -> void:
	# 1. Логика для локального игрока
	# Проверяем, что вошедший — это Плеер И мы имеем над ним власть (локальный клиент)
	if body.is_in_group("players") and body.is_multiplayer_authority():
		G.player.progress_controller.add_achievement("ACH_1")
		_teleport_object(body)
		return # Выходим, чтобы не срабатывала серверная логика ниже

	# 2. Логика для всех остальных (мобы, предметы и т.д.)
	# Эту часть выполняет только СЕРВЕР (авторитет зоны)
	if not is_multiplayer_authority(): 
		return

	# Телепортируем моба или чужого игрока
	_teleport_object(body)

	# Логика удаления быстрых предметов (только на сервере)
	if body.is_in_group("items") and body.has_method("get_speed"):
		if body.get_speed() > 50.0:
			body.queue_free()

# Вынес в отдельную функцию для чистоты
func _teleport_object(obj: Node3D) -> void:
	obj.position.y = -obj.position.y
