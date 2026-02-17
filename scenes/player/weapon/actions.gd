extends Area3D

signal add_item(nname: String)
signal drop_item(nname: String)

const item := preload("res://scenes/items/item.tscn")

@onready var craft_zone_label := $CraftZone/Label3D

var crafting_mode := false:
	set(value):
		crafting_mode = value
		$CraftZone.visible = value


func attack(dmg: float, damage_types: Dictionary) -> void:
	server_attack.rpc(dmg, damage_types, multiplayer.get_unique_id())


func pickup() -> void:
	server_pickup.rpc(multiplayer.get_unique_id())


func drop(item_name: String) -> void:
	server_drop.rpc(item_name, multiplayer.get_unique_id())


func craft() -> void:
	crafting_mode = false
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
	if not multiplayer.is_server(): return
	
	var player = G.world.get_node_or_null(str(peer_id))
	if not player: return
	
	var actions_node = player.weapon.actions
	var available_nodes = _get_available_nodes(actions_node)
	
	# Ищем первый подходящий рецепт
	var craft_data = get_available_recipe(available_nodes)
	
	if craft_data:
		var result_id = craft_data["id"]
		var recipe = craft_data["recipe"]
		
		if craft_data["type"] == "object":
			actions_node.execute_craft_object(peer_id, result_id, recipe, available_nodes)
		else:
			actions_node.execute_craft(peer_id, result_id, recipe, available_nodes)

# Возвращает словарь с данными рецепта или null
func get_available_recipe(available_nodes: Dictionary) -> Variant:
	# Сначала проверяем объекты, потом предметы
	for collection in [{"data": R.objects, "type": "object"}, {"data": R.items, "type": "item"}]:
		for id in collection.data:
			var item_data = collection.data[id]
			if item_data.has("recipe") and can_craft(item_data["recipe"], available_nodes):
				return {"id": id, "recipe": item_data["recipe"], "type": collection.type}
	return null

func can_craft(recipe: Dictionary, available_nodes: Dictionary) -> bool:
	if recipe.get("craft-station") != "arm": return false
	for ingredient in recipe:
		if ingredient == "craft-station": continue
		var required = recipe[ingredient]
		if available_nodes.get(ingredient, []).size() < required:
			return false
	return true

# Вспомогательная функция для сбора предметов в зоне
func _get_available_nodes(actions_node) -> Dictionary:
	var nodes = {}
	for body in actions_node.get_overlapping_bodies():
		if "nname" in body:
			if not nodes.has(body.nname): nodes[body.nname] = []
			nodes[body.nname].append(body)
	return nodes

# Общий метод удаления ресурсов
func _consume_ingredients(recipe: Dictionary, available_nodes: Dictionary):
	for ingredient in recipe:
		if ingredient == "craft-station": continue
		for i in range(recipe[ingredient]):
			var node = available_nodes[ingredient].pop_back()
			if is_instance_valid(node): node.queue_free()

func execute_craft(peer_id: int, result_name: String, recipe: Dictionary, available_nodes: Dictionary):
	_consume_ingredients(recipe, available_nodes)
	client_receive_item.rpc_id(peer_id, result_name)

func execute_craft_object(peer_id: int, result_object: String, recipe: Dictionary, available_nodes: Dictionary):
	_consume_ingredients(recipe, available_nodes)
	
	var spawned_object = R.objects[result_object]["object"].instantiate()
	G.world.add_child(spawned_object, true)
	
	var player = G.world.get_node_or_null(str(peer_id))
	spawned_object.global_position = player.weapon.actions.global_position


func _physics_process(_delta: float) -> void:
	if crafting_mode:
		# 1. Получаем ноды в зоне (через вспомогательную функцию)
		var available_nodes = _get_available_nodes(self) 
		
		# 2. Ищем рецепт
		var craft_data = get_available_recipe(available_nodes)
		
		# 3. Выводим текст: если рецепт есть — его ID, если нет — пусто
		if craft_data:
			var result_id = craft_data["id"]
			# Если в R.items/objects есть поле "name", лучше взять его, иначе берем ID
			craft_zone_label.text = "Ready to craft: " + result_id
		else:
			craft_zone_label.text = "Drop ingridients in green box"
