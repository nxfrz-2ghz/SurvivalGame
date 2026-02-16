extends Area3D

@onready var item := preload("res://scenes/items/item.tscn")

signal add_item(nname: String)
signal drop_item(nname: String)


func attack(dmg: float, damage_types: Dictionary) -> void:
	server_attack.rpc(dmg, damage_types, multiplayer.get_unique_id())


func pickup() -> void:
	server_pickup.rpc(multiplayer.get_unique_id())


func drop(item_name: String) -> void:
	server_drop.rpc(item_name, multiplayer.get_unique_id())


func craft() -> void:
	server_craft.rpc(multiplayer.get_unique_id())


@rpc("any_peer", "call_local")
func client_receive_item(item_name: String) -> void:
	emit_signal("add_item", item_name)


@rpc("any_peer", "call_local")
func client_drop_item(item_name: String) -> void:
	emit_signal("drop_item", item_name)


@rpc("authority", "call_local")
func server_attack(dmg: float, damage_types: Dictionary, peer_id: int) -> void:
	
	if not multiplayer.is_server():
		return
	
	var player = G.world.get_node(str(peer_id))
	var actions_node = player.weapon.actions
	for body in actions_node.get_overlapping_bodies():
		
		# Отключение урона по себе от самого себя
		if body.name == str(peer_id): continue
		
		# Урон по игрокам
		if body.is_in_group("players"):
			body.health.take_damage.rpc_id(int(body.name), dmg, damage_types)
		
		# Урон по объектам
		if body.is_in_group("objects"):
			body.health.take_damage(dmg, damage_types)


@rpc("authority", "call_local")
func server_pickup(peer_id: int) -> void:
	
	if not multiplayer.is_server():
		return
	
	var player = G.world.get_node_or_null(str(peer_id))
	if not player: return
	var actions_node = player.weapon.actions
	for body in actions_node.get_overlapping_bodies():
		if body.is_in_group("items"):
			client_receive_item.rpc_id(peer_id, body.nname)
			body.free()


@rpc("authority", "call_local")
func server_drop(item_name: String, peer_id: int) -> void:
	
	if not multiplayer.is_server():
		return
	
	var player = G.world.get_node_or_null(str(peer_id))
	if not player: return
	var actions_node = player.weapon.actions

	var node: RigidBody3D = item.instantiate()
	node.nname = item_name
	G.world.add_child(node, true)
	node.position = actions_node.global_position
	client_drop_item.rpc_id(peer_id, item_name)


@rpc("authority", "call_local")
func server_craft(peer_id: int) -> void:
	
	if not multiplayer.is_server():
		return
	
	var player = G.world.get_node_or_null(str(peer_id))
	if not player: return
	var actions_node = player.weapon.actions

	# 1. Получаем все тела в зоне
	var bodies = actions_node.get_overlapping_bodies()
	
	# 2. Создаем словарь: { "имя": [список_узлов] }
	# Сохраняем ссылки на сами узлы, чтобы их потом было легко удалять
	var available_nodes = {}
	for body in bodies:
		if "nname" in body:
			var item_name = body.nname
			if not available_nodes.has(item_name):
				available_nodes[item_name] = []
			available_nodes[item_name].append(body)

	# 3. Ищем подходящий рецепт в объектах
	for result_object in R.objects:
		var data = R.objects[result_object]
		if not data.has("recipe"):
			continue
		var recipe = data["recipe"]
		if can_craft(recipe, available_nodes):
			# 4. Если ресурсов хватает — крафтим объект!
			actions_node.execute_craft_object(peer_id, result_object, recipe, available_nodes)
			return # Выходим после первого успешного рецепта
	
	# 5. Ищем подходящий рецепт в предметах (если не нашли в объектах)
	for result_item in R.items:
		var data = R.items[result_item]
		if not data.has("recipe"):
			continue
			
		var recipe = data["recipe"]
		if can_craft(recipe, available_nodes):
			# 6. Если ресурсов хватает — крафтим!
			actions_node.execute_craft(peer_id,result_item, recipe, available_nodes)
			return # Выходим после первого успешного рецепта

# Проверка: хватает ли предметов для конкретного рецепта
func can_craft(recipe: Dictionary, available_nodes: Dictionary) -> bool:
	if recipe["craft-station"] != "arm": return false
	for ingredient in recipe:
		var required_count = recipe[ingredient]
		# Если такого предмета нет вообще или его меньше, чем нужно
		if not available_nodes.has(ingredient) or available_nodes[ingredient].size() < required_count:
			return false
	return true

# Удаление ресурсов и вызов сигнала
func execute_craft(peer_id: int, result_name: String, recipe: Dictionary, available_nodes: Dictionary):
	for ingredient in recipe:
		var count_to_remove = recipe[ingredient]
		for i in range(count_to_remove):
			var node_to_delete = available_nodes[ingredient].pop_back()
			node_to_delete.queue_free()
	
	client_receive_item.rpc_id(peer_id, result_name)

# Спавнирование объекта вместо добавления в инвентарь
func execute_craft_object(peer_id: int, result_object: String, recipe: Dictionary, available_nodes: Dictionary):
	# Удаляем ресурсы
	for ingredient in recipe:
		var count_to_remove = recipe[ingredient]
		for i in range(count_to_remove):
			var node_to_delete = available_nodes[ingredient].pop_back()
			node_to_delete.queue_free()
	
	# Спавним объект в мире
	var object_data = R.objects[result_object]
	var object_scene = object_data["object"]
	var spawned_object: Node3D = object_scene.instantiate()
	G.world.add_child(spawned_object, true)
	spawned_object.position = G.world.get_node_or_null(str(peer_id)).weapon.actions.global_position
