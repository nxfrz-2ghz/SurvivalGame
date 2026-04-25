extends Node

func _ready() -> void:
	Console.add_command("spawn", spawn, ["entity_name", "amount", "position", "delay"], 1)
	Console.add_command("tick", tick, ["rate"])
	Console.add_command("tp", tp, ["x","y","z", "node_name"], 3)
	Console.add_command("give", give, ["item_name", "amount"], 1)
	Console.add_command("attack", attack, ["dmg","damage_types","node_name"], 1)
	
	Console.console_opened.connect(_on_console_opened)
	Console.console_closed.connect(_on_console_closed)

var last_state: String
func _on_console_opened() -> void:
	last_state = S.state_machine
	S.state_machine = "console"
func _on_console_closed() -> void:
	S.state_machine = last_state

func spawn(entity_name: String, amount, position, delay) -> void:
	if last_state != "game": return
	var type: String
	var scene: PackedScene
	
	if amount:
		amount = int(amount)
	else:
		amount = 1
	
	if delay:
		delay = float(delay)
	else:
		delay = 0.0
	
	if position:
		position = Vector3(position)
	else:
		position = G.player.global_position
	 
	
	# Loading
	if R.objects.has(entity_name):
		scene = R.objects[entity_name]["scene"]
		type = "object"
	elif R.buildings.has(entity_name):
		scene = R.buildings[entity_name]["scene"]
		type = "building"
	elif R.mobs.has(entity_name):
		scene = R.mobs[entity_name]["scene"]
		type = "mob"
	elif R.items.has(entity_name):
		scene = R.item
		type = "item"
	elif R.prefabs.has(entity_name):
		scene = R.prefabs[entity_name]
		type = "prefab"
	
	if !scene: return
	
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	
	# Spawning
	for i in range(amount):
		var node := scene.instantiate()
		if type == "item":
			node.nname = entity_name
		elif type in ["object", "building"]:
			node.add_child(R.prefabs["fall_ray"].instantiate(), true)
		
		node.position = position
		G.environment.add_child(node, true)

# Измените объявления функций на такие:

func tick(rate) -> void:
	if !rate: rate = 60
	Engine.physics_ticks_per_second = int(rate)

func tp(x, y, z, node_name = "") -> void:
	# Если node_name не передан, берем игрока
	var target_name = node_name if node_name != "" else G.player.name
	var node: Node3D = G.environment.get_node_or_null(NodePath(target_name))
	if !node: return
	node.position = Vector3(float(x), float(y), float(z))

func give(item_name: String, amount = "1") -> void:
	G.player.inv.add_item(item_name, int(amount))

func attack(dmg, damage_types = null, node_name = "") -> void:
	var target_name = node_name if node_name != "" else G.player.name
	var node: Node3D = G.environment.get_node_or_null(NodePath(target_name))
	if !node: return
	var health: Node = node.get_node_or_null("HealthComponent")
	
	# Сложные типы (как damage_types словарь) часто нельзя передать строкой через консоль
	var d_types = damage_types if damage_types else {"melee": 1}
	if health: health.take_damage(float(dmg), false, d_types)
