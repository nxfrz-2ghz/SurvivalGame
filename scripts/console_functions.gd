extends Node

func _ready() -> void:
	Console.add_command("spawn", request_spawn, ["entity_name", "amount", "position", "delay"], 1, "Spawn entity")
	Console.add_command("tick", tick, ["rate"], 0, "Change game physics tickrate")
	Console.add_command("tp", tp, ["x","y","z", "node_name"], 0, "Teleport entity to xyz")
	Console.add_command("give", give, ["item_name", "amount"], 1, "Add Item to Inventory")
	Console.add_command("attack", attack, ["dmg","node_name"], 1, "Take Damage to Entity")
	Console.add_command("weather", weather, ["variant"], 0, "Set or Reser Current Weather")
	Console.add_command("seed", print_seed, [], 0, "Get World Seed")
	Console.add_command("name", get_collider_name, [], 0, "Print True Collider Name")
	
	Console.console_opened.connect(_on_console_opened)
	Console.console_closed.connect(_on_console_closed)

var last_state: String
func _on_console_opened() -> void:
	last_state = S.state_machine
	S.state_machine = "console"
func _on_console_closed() -> void:
	S.state_machine = last_state

func request_spawn(entity_name: String, amount, position, delay) -> void:
	spawn.rpc_id(1, entity_name, amount, position, delay)
@rpc("any_peer", "call_local")
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

func tick(rate) -> void:
	if !rate: rate = 60
	Engine.physics_ticks_per_second = int(rate)

func tp(x=0, y=0, z=0, node_name = "") -> void:
	# Если node_name не передан, берем игрока
	var target_name = node_name if node_name != "" else G.player.name
	var node: Node3D = G.environment.get_node_or_null(NodePath(target_name))
	if !node: return
	node.position = Vector3(float(x), float(y), float(z))

func give(item_name: String, amount) -> void:
	if !amount: amount = "1"
	G.player.inv.add_item(item_name, int(amount))

func attack(dmg, node_name = "") -> void:
	var target_name = node_name if node_name != "" else G.player.name
	var node: Node3D = G.environment.get_node_or_null(NodePath(target_name))
	if !node: return
	var health: Node = node.get_node_or_null("HealthComponent")
	if health: health.take_damage(float(dmg), true)

func weather(variant = "") -> void:
	if variant == "":
		G.world.weather.toggle_fog.rpc(false)
		G.world.weather.toggle_rain.rpc(false)
		G.world.weather.toggle_meteor_rain.rpc(false)
	if variant == "fog":
		G.world.weather.toggle_fog.rpc(true)
	if variant == "rain":
		G.world.weather.toggle_rain.rpc(true)
	if variant == "meteor_rain":
		G.world.weather.toggle_meteor_rain.rpc(true)

func print_seed() -> void:
	Console.print_line(G.world.world_seed)

func get_collider_name() -> void:
	if G.player.interact_ray.is_colliding():
		Console.print_line(G.player.interact_ray.get_collider().name)
	else:
		Console.print_error("No Collider!")
