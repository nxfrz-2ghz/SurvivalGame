extends Node

func _ready() -> void:
	Console.add_command("spawn", spawn, ["entity_name", "amount", "position", "delay"], 1)
	Console.console_opened.connect(_on_console_opened)
	Console.console_closed.connect(_on_console_closed)

var last_state: String
func _on_console_opened() -> void:
	last_state = G.state_machine
	G.state_machine = "console"
func _on_console_closed() -> void:
	G.state_machine = last_state

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
