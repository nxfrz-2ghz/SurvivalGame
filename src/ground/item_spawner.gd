extends Node2D

const ITEM := preload("res://src/entity/item/item.tscn")
const CAGE := preload("res://src/entity/item/cage/cage.tscn")

const items := {
	"consumables": {
		"meat": {
			"texture": preload("res://res/sprites/items/meat/meat.png"),
		},
		"coin": {
			"frames": preload("res://res/sprites/items/coin/frames.tres"),
			"light_color": Color.BISQUE,
			"light_energy": 1.0,
		},
	},
	"acessories": {
		"extra_jump": {
			"texture": preload("res://res/sprites/items/acessories/double jump.png")
		},
		"weapon_levelup": {
			"texture": preload("res://res/sprites/items/acessories/weapon levelup.png"),
		},
		"health_potion": {
			"texture": preload("res://res/sprites/items/acessories/health potion.png")
		},
		"vampirism": {
			"texture": preload("res://res/sprites/items/acessories/vampirism.png")
		},
	},
	"weapons": {
		"pistol": {
			"texture": preload("res://res/sprites/guns/3Pistol03.png"),
		},
		"shotgun": {
			"texture": preload("res://res/sprites/guns/2Shotgun02.png"),
		},
		"P90": {
			"texture": preload("res://res/sprites/guns/5AssaultRifle05.png"),
		},
		"M4": {
			"texture": preload("res://res/sprites/guns/7Assoultrifle07.png"),
		},
		"rocket_launcher": {
			"texture": preload("res://res/sprites/guns/4Explosive04.png"),
		},
		"sniper_rifle": {
			"texture": preload("res://res/sprites/guns/4SniperRifle04.png"),
		},
		"toxic_gun": {
			"texture": preload("res://res/sprites/guns/Toxic Gun.png"),
		},
		"fire_torch": {
			"frames": preload("res://res/sprites/guns/torch/fire_torch_frames.tres"),
		},
		"base_sword": {
			"texture": preload("res://res/sprites/guns/base_sword.png"),
		},
	},
}

var i: int = 0


func spawn(world_seed: int, pos_x: int, location: int, distance: int) -> void:
	var item: PhysicsBody2D = ITEM.instantiate()
	var rng := RandomNumberGenerator.new()
	rng.seed = location + distance + world_seed + i
	i += 1
	
	self.position.x = pos_x - 10 - rng.randf_range(0, float(pos_x)/4)
	self.position.y = -10
	
	var current_item: String
	var current_type: String
	
	if rng.randi_range(0, 18) == 0:
		current_type = "weapons"
		var weapons = items["weapons"].keys()
		current_item = weapons[randi() % weapons.size()]
	elif rng.randi_range(0, 20) == 0:
		current_type = "acessories"
		var weapons = items["acessories"].keys()
		current_item = weapons[randi() % weapons.size()]
	else:
		current_type = "consumables"
		if rng.randi_range(0, 10) == 0:
			current_item = "meat"
		else:
			current_item = "coin"
	
	item.item = current_item
	item.lvl = location + int(randi_range(0, 10) == 10)
	
	var item_data = items[current_type][current_item]
	
	if item_data.get("texture"):
		item.texture = item_data["texture"]
	if item_data.get("frames"):
		item.frames = item_data["frames"]
	if item_data.get("light_color"):
		item.light_color = item_data["light_color"]
	if item_data.get("light_energy"):
		item.light_energy = item_data["light_energy"]
	
	add_child(item)
	item.top_level = true
	item.position = self.global_position
	
	if current_type == "weapons" and rng.randi_range(0,1) == 0:
		item.add_child(CAGE.instantiate())
	if current_type == "acessories" and rng.randi_range(0,2) == 0:
		item.add_child(CAGE.instantiate())
