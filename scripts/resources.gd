extends Node

const item := preload("res://scenes/items/item.tscn")
const throwable_item := preload("res://scenes/items/throwable_item.tscn")

const OXIDING_SPEED := 50
const dmg_to_get_ach_ultrakill := 10.0


const sounds := {
	"walk": {
		"grass": [
			preload("res://res/sounds/walk/Grass_hit1.mp3"),
			preload("res://res/sounds/walk/Grass_hit2.mp3"),
			preload("res://res/sounds/walk/Grass_hit3.mp3"),
			preload("res://res/sounds/walk/Grass_hit4.mp3"),
			preload("res://res/sounds/walk/Grass_hit5.mp3"),
			preload("res://res/sounds/walk/Grass_hit6.mp3"),
		],
	},
	"hit": {
		"player": [
			preload("res://res/sounds/hit/hit1.mp3"),
			preload("res://res/sounds/hit/hit2.mp3"),
			preload("res://res/sounds/hit/hit3.mp3"),
		],
		"objects": [
			preload("res://res/sounds/crack/1.mp3"),
			preload("res://res/sounds/crack/2.mp3"),
			preload("res://res/sounds/crack/3.mp3"),
			preload("res://res/sounds/crack/4.mp3"),
			preload("res://res/sounds/crack/5.mp3"),
			preload("res://res/sounds/crack/6.mp3"),
			preload("res://res/sounds/crack/7.mp3"),
			preload("res://res/sounds/crack/8.mp3"),
		],
		"pig": [
			preload("res://res/sounds/idle/pig/1.mp3"),
			preload("res://res/sounds/idle/pig/2.mp3"),
			preload("res://res/sounds/idle/pig/3.mp3"),
			preload("res://res/sounds/destroy/pig_destroy_1.mp3"),
			preload("res://res/sounds/destroy/pig_destroy_2.mp3"),
		],
		"voron": [
			preload("res://res/sounds/idle/voron/damage_1.mp3"),
			preload("res://res/sounds/idle/voron/damage_2.mp3"),
			preload("res://res/sounds/idle/voron/damage_3.mp3"),
		],
		"evil_tree": [
			preload("res://res/sounds/crack/2.mp3"),
			preload("res://res/sounds/crack/3.mp3"),
			preload("res://res/sounds/crack/4.mp3"),
			preload("res://res/sounds/crack/5.mp3"),
			preload("res://res/sounds/crack/6.mp3"),
			preload("res://res/sounds/crack/7.mp3"),
			preload("res://res/sounds/crack/8.mp3"),
		]
	},
	"destroy": {
		"tree": preload("res://res/sounds/destroy/tree_destroy.mp3"),
		"stone": preload("res://res/sounds/destroy/stone_destroy.mp3"),
		"meat": preload("res://res/sounds/destroy/meat_destroy.mp3"),
		"pig": [
			preload("res://res/sounds/destroy/pig_destroy_1.mp3"),
			preload("res://res/sounds/destroy/pig_destroy_2.mp3"),
		],
		"wood": [
			preload("res://res/sounds/crack/1.mp3"),
			preload("res://res/sounds/crack/2.mp3"),
			preload("res://res/sounds/crack/3.mp3"),
			preload("res://res/sounds/crack/4.mp3"),
			preload("res://res/sounds/crack/5.mp3"),
			preload("res://res/sounds/crack/6.mp3"),
			preload("res://res/sounds/crack/7.mp3"),
			preload("res://res/sounds/crack/8.mp3"),
		],
		"meteor": preload("res://res/sounds/destroy/meteorite_despawn.mp3"),
		"instrument": preload("res://res/sounds/destroy/instrument_destroy.mp3"),
	},
	"idle": {
		"pig": [
			preload("res://res/sounds/idle/pig/1.mp3"),
			preload("res://res/sounds/idle/pig/2.mp3"),
			preload("res://res/sounds/idle/pig/3.mp3"),
		],
		"voron": [
			preload("res://res/sounds/idle/voron/idle.mp3"),
			preload("res://res/sounds/idle/voron/damage_2.mp3"),
		],
		"meteor": [
			preload("res://res/sounds/idle/meteor/idle_meteor_1.mp3"),
			preload("res://res/sounds/idle/meteor/idle_meteor_2.mp3"),
		],
	},
	"actions": {
		"eating": preload("res://res/sounds/actions/eating.mp3"),
		"pickup": preload("res://res/sounds/actions/pickup.mp3"),
	},
	"ambient": {
		"rain": preload("res://res/sounds/ambient/rain.mp3"),
	}
}

const music := [
	preload("res://res/music/wtf2.mp3"),
]

const exchangeable_items := {
	"campfire": {
		"raw_berry": {"amount": 1, "output": "cooked_berry", "speed": 3},
		"raw_meat":  {"amount": 1, "output": "cooked_meet", "speed": 5},
	},
	"furnace": {
		"copper_ore": {"amount": 1, "output": "copper_ingot", "speed": 8},
		"clay":       {"amount": 1, "output": "brick", "speed": 6},
	},
	"furnace_t2": {
		"iron_ore": {"amount": 1, "output": "iron_ingot", "speed": 8},
		"iron_ingot": {"amount": 5, "output": "steel_ingot", "speed": 15},
		
		# Uncrafting Trash
		"stone_axe": {"amount": 1, "output": "stone", "speed": 10},
		"stone_pickaxe": {"amount": 1, "output": "stone", "speed": 10},
		"copper_knife": {"amount": 1, "output": "", "speed": 1},
		"copper_shovel": {"amount": 1, "output": "copper_ingot", "speed": 2},
		"copper_axe": {"amount": 1, "output": "copper_ingot", "speed": 3},
		"copper_pickaxe": {"amount": 1, "output": "copper_ingot", "speed": 3},
		"copper_axe_ox1": {"amount": 1, "output": "copper_ingot", "speed": 4},
		"copper_pickaxe_ox1": {"amount": 1, "output": "copper_ingot", "speed": 4},
		"copper_axe_ox2": {"amount": 1, "output": "copper_ingot", "speed": 5},
		"copper_pickaxe_ox2": {"amount": 1, "output": "copper_ingot", "speed": 5},
		"wooden_hammer": {"amount": 1, "output": "", "speed": 1},
		"iron_axe": {"amount": 1, "output": "iron_ingot", "speed": 5},
		"iron_pickaxe": {"amount": 1, "output": "iron_ingot", "speed": 5},
		"steel_axe": {"amount": 1, "output": "steel_ingot", "speed": 25},
		"steel_pickaxe": {"amount": 1, "output": "steel_ingot", "speed": 25},
	},
	"alchemy_station": {
		"log": {"amount": 3, "output": "coal", "speed": 5},
	},
}

const prefabs := {
	"meteor": preload("res://scenes/prefabs/meteorite/meteorite_rigid.tscn"),
	"explosion": preload("res://scenes/prefabs/explosion/explosion_3d.tscn"),
	"exp_sphere": preload("res://scenes/prefabs/exp_sphere/exp_sphere.tscn"),
}

const mobs := {
	"darkness_eye": {
		"texture": "res://res/sprites/mobs/darkness_eye/eye0.png",
		"scene": preload("res://scenes/mobs/darkness_eye/darkness_eye.tscn"),
		"requirements": ["night", ],
		"spawn_weight": 5,
	},
	"pig": {
		"texture": "res://res/sprites/mobs/pig/front/front0.png",
		"scene": preload("res://scenes/mobs/pig/pig.tscn"),
		"spawn_weight": 3,
	},
	"krab": {
		"texture": "res://res/sprites/mobs/krab/front/idle.png",
		"scene": preload("res://scenes/mobs/krab/krab.tscn"),
	},
	"long": {
		"texture": "res://res/sprites/mobs/pegur/front.png",
		"scene": preload("res://scenes/mobs/long/long.tscn"),
		"requirements": ["night", ],
		"spawn_weight": 1,
	},
	"voron": {
		"texture": "res://res/sprites/mobs/voron/1.png",
		"scene": preload("res://scenes/mobs/voron/voron.tscn"),
		"spawn_weight": 2,
	},
	"evil_tree": {
		"texture": "res://res/sprites/mobs/evil_tree/evil_tree.png",
		"scene": preload("res://scenes/mobs/evil_tree/evil_tree.tscn"),
	},
}

const buildings := {
	# Стены Walls
	"wood_wall": {
		"scene": preload("res://scenes/building/wall/wood/wood_wall.tscn"),
	},
	"stone_wall": {
		"scene": preload("res://scenes/building/wall/stone/stone_wall.tscn"),
	},
	"brick_wall": {
		"scene": preload("res://scenes/building/wall/brick/brick_wall.tscn"),
	},
	# Блоки Blocks
	"wood_block": {
		"scene": preload("res://scenes/building/block/wood/wood_block.tscn"),
	},
	"stone_block": {
		"scene": preload("res://scenes/building/block/stone/stone_block.tscn"),
	},
	"brick_block": {
		"scene": preload("res://scenes/building/block/brick/brick_block.tscn"),
	},
}

const objects := {
	"grass": {
		"scene": preload("res://scenes/objects/grass/grass.tscn"),
		#"recipe": {},
	},
	"berry_bush": {
		"scene": preload("res://scenes/objects/berry_bush/berry_bush.tscn"),
		"recipe": {"log": 2, "raw_berry": 5},
	},
	"tree": {
		"scene": preload("res://scenes/objects/tree/tree.tscn"),
		#"recipe": {},
	},
	"stone": {
		"scene": preload("res://scenes/objects/stone/stone.tscn"),
		#"recipe": {},
	},
	"rock": {
		"scene": preload("res://scenes/objects/rock/rock.tscn"),
		#"recipe": {},
	},
	"copper_ore": {
		"scene": preload("res://scenes/objects/copper_ore/copper_ore.tscn"),
		#"recipe": {},
	},
	"iron_ore": {
		"scene": preload("res://scenes/objects/iron_ore/iron_ore.tscn"),
		#"recipe": {},
	},
	"meteorite": {
		"scene": preload("res://scenes/objects/meteorite/meteorite.tscn"),
	},
	"campfire": {
		"scene": preload("res://scenes/objects/campfire/campfire.tscn"),
		"recipe": {"log": 3},
	},
	"furnace": {
		"scene": preload("res://scenes/objects/furnace/furnace.tscn"),
		"recipe": {"stone": 5},
	},
	"furnace_t2": {
		"scene": preload("res://scenes/objects/furnace_t2/furnace_t_2.tscn"),
		"recipe": {"brick": 5},
	},
	"alchemy_station": {
		"scene": preload("res://scenes/objects/alchemy_station/alchemy_station.tscn"),
		"recipe": {"copper_ingot": 5},
	},
	"heart": {
		"scene": preload("res://scenes/objects/heart/heart.tscn"),
	},
}

const items := {
	# BUILDING ITEMS
	"wood_wall": {
		"texture": preload("res://res/sprites/items/building/wall.png"),
		"recipe": {
			"log":4,
		},
		"amount_craft": 2,
		"stack_size": 10,
		"is_building": true,
		"build_type": "wall",
	},
	"stone_wall": {
		"texture": preload("res://res/sprites/items/building/wall.png"),
		"recipe": {
			"stone":4,
		},
		"amount_craft": 2,
		"stack_size": 10,
		"is_building": true,
		"build_type": "wall",
	},
	"brick_wall": {
		"texture": preload("res://res/sprites/items/building/wall.png"),
		"recipe": {
			"brick":4,
		},
		"amount_craft": 2,
		"stack_size": 10,
		"is_building": true,
		"build_type": "wall",
	},
	"wood_block": {
		"texture": preload("res://res/sprites/items/building/block.png"),
		"recipe": {
			"log":2,
		},
		"amount_craft": 2,
		"stack_size": 30,
		"is_building": true,
		"build_type": "block",
	},
	"stone_block": {
		"texture": preload("res://res/sprites/items/building/block.png"),
		"recipe": {
			"stone":2,
		},
		"amount_craft": 2,
		"stack_size": 30,
		"is_building": true,
		"build_type": "block",
	},
	"brick_block": {
		"texture": preload("res://res/sprites/items/building/block.png"),
		"recipe": {
			"brick":2,
		},
		"amount_craft": 2,
		"stack_size": 30,
		"is_building": true,
		"build_type": "block",
	},
	
	# ITEMS
	"": {
		"attack_speed": 1.2,
		"damage_types":
			{
				"melee": 1.0,
				"axe": 0.2,
				"pickaxe": 0.1,
			},
	},
	"health_ring": {
		"texture": preload("res://res/sprites/items/rings/health_ring.png"),
		"stack_size": 3,
	},
	"armor_ring": {
		"texture": preload("res://res/sprites/items/rings/armor_ring.png"),
		"stack_size": 3,
	},
	"speed_ring": {
		"texture": preload("res://res/sprites/items/rings/speed_ring.png"),
		"stack_size": 3,
	},
	"stone_axe": {
		"texture": preload("res://res/sprites/items/weapons/stone_axe.png"),
		"recipe": {
			"log":3,
			"stone":2,
		},
		"durability": 50,
		"on_crack_drop_items": {"stone":2,},
		"attack_speed": 1.0,
		"damage": 2.0,
		"damage_types": {
			"melee": 0.5,
			"axe": 0.8,
			"pickaxe": 0.0,
		},
	},
	"stone_pickaxe": {
		"texture": preload("res://res/sprites/items/weapons/stone_pickaxe.png"),
		"recipe": {
			"log":2,
			"stone":3,
		},
		"durability": 30,
		"on_crack_drop_items": {"stone":2,},
		"attack_speed": 1.0,
		"damage": 2.0,
		"damage_types": {
			"melee": 0.2,
			"axe": 0.0,
			"pickaxe": 0.8,
		},
	},
	"copper_knife": {
		"texture": preload("res://res/sprites/items/weapons/copper/copper_knife.png"),
		"recipe": {
			"copper_ingot":1,
		},
		"stack_size": 15,
		"amount_craft": 5, # Сразу 5 крафтится
		"durability": 10,
		"attack_speed": 2.0,
		"damage": 1.8,
		"damage_types": {
			"melee": 0.9,
			"axe": 0.2,
			"pickaxe": 0.1,
		},
		"throw_power": 15.0,
		"throw_drop_chance": 0.5,
		"billboard": false,
		"explose": false,
	},
	"copper_shovel": {
		"texture": preload("res://res/sprites/items/weapons/copper/copper_shovel.png"),
		"recipe": {
			"log":2,
			"copper_ingot":2,
		},
		"durability": 80,
		"attack_speed": 0.7,
		"damage": 2.0,
		"damage_types": {
			"melee": 0.5,
			"axe": 0.0,
			"pickaxe": 0.1,
		},
		"shovel_power": 2,
	},
	"copper_axe": {
		"texture": preload("res://res/sprites/items/weapons/copper/copper_axe.png"),
		"recipe": {
			"log":3,
			"copper_ingot":2,
		},
		"can_oxiding": "copper_axe_ox1",
		"durability": 60,
		"attack_speed": 1.1,
		"damage": 2.5,
		"damage_types": {
			"melee": 0.8,
			"axe": 1.0,
			"pickaxe": 0.0,
		},
	},
	"copper_pickaxe": {
		"texture": preload("res://res/sprites/items/weapons/copper/copper_pickaxe.png"),
		"recipe": {
			"log":2,
			"copper_ingot":3,
		},
		"can_oxiding": "copper_pickaxe_ox1",
		"durability": 60,
		"attack_speed": 1.1,
		"damage": 2.5,
		"damage_types": {
			"melee": 0.5,
			"axe": 0.0,
			"pickaxe": 1.0,
		},
	},
	"copper_axe_ox1": {
		"texture": preload("res://res/sprites/items/weapons/copper/copper_axe.png"),
		"can_oxiding": "copper_axe_ox2",
		"durability": 80,
		"attack_speed": 0.9,
		"damage": 2.7,
		"damage_types": {
			"melee": 0.8,
			"axe": 1.1,
			"pickaxe": 0.0,
		},
	},
	"copper_pickaxe_ox1": {
		"texture": preload("res://res/sprites/items/weapons/copper/copper_pickaxe.png"),
		"can_oxiding": "copper_pickaxe_ox2",
		"durability": 80,
		"attack_speed": 0.9,
		"damage": 2.7,
		"damage_types": {
			"melee": 0.5,
			"axe": 0.0,
			"pickaxe": 1.1,
		},
	},
	"copper_axe_ox2": {
		"texture": preload("res://res/sprites/items/weapons/copper/copper_axe.png"),
		"durability": 100,
		"attack_speed": 0.7,
		"damage": 2.9,
		"damage_types": {
			"melee": 0.8,
			"axe": 1.1,
			"pickaxe": 0.0,
		},
	},
	"copper_pickaxe_ox2": {
		"texture": preload("res://res/sprites/items/weapons/copper/copper_pickaxe.png"),
		"durability": 100,
		"attack_speed": 0.7,
		"damage": 2.9,
		"damage_types": {
			"melee": 0.5,
			"axe": 0.0,
			"pickaxe": 1.1,
		},
	},
	"iron_axe": {
		"texture": preload("res://res/sprites/items/weapons/iron_axe.png"),
		"recipe": {
			"log":3,
			"iron_ingot":2,
		},
		"durability": 250,
		"attack_speed": 1.1,
		"damage": 3.5,
		"damage_types": {
			"melee": 0.8,
			"axe": 1.1,
			"pickaxe": 0.0,
		},
	},
	"iron_pickaxe": {
		"texture": preload("res://res/sprites/items/weapons/iron_pickaxe.png"),
		"recipe": {
			"log":2,
			"iron_ingot":3,
		},
		"durability": 250,
		"attack_speed": 1.1,
		"damage": 3.5,
		"damage_types": {
			"melee": 0.5,
			"axe": 0.0,
			"pickaxe": 1.1,
			"pickaxe_lvl2": 0.8,
		},
	},
	"steel_axe": {
		"texture": preload("res://res/sprites/items/weapons/steel_axe.png"),
		"recipe": {
			"log":3,
			"steel_ingot":2,
		},
		"durability": 650,
		"attack_speed": 1.2,
		"damage": 4.0,
		"damage_types": {
			"melee": 0.9,
			"axe": 1.2,
			"pickaxe": 0.0,
		},
	},
	"steel_pickaxe": {
		"texture": preload("res://res/sprites/items/weapons/steel_pickaxe.png"),
		"recipe": {
			"log":2,
			"steel_ingot":3,
		},
		"durability": 650,
		"attack_speed": 1.2,
		"damage": 4.0,
		"damage_types": {
			"melee": 0.6,
			"axe": 0.0,
			"pickaxe": 1.2,
			"pickaxe_lvl2": 1.2,
		},
	},
	"bomb": {
		"texture": preload("res://res/sprites/items/weapons/bomb.png"),
		"recipe": {
			"iron_ingot":1,
			"coal": 1,
		},
		"stack_size": 10,
		"amount_craft": 2,
		"durability": 1,
		"attack_speed": 1.0,
		"damage": 25.0,
		"damage_types": {
			"melee": 0.0,
			"axe": 0.0,
			"pickaxe": 0.0,
			"explose": 1.0,
		},
		"throw_power": 15.0,
		"throw_drop_chance": 1.0,
		"billboard": true,
		"explose": true,
	},
	"wooden_hammer": {
		"texture": preload("res://res/sprites/items/weapons/wooden_hammer.png"),
		"recipe": {
			"log":2,
		},
		"durability": 30,
		"attack_speed":  0.5,
		"damage": 2.0,
		"damage_types": {
			"melee": 0.5,
			"heavy": 1.0,
			"axe": 0.1,
			"pickaxe": 0.0,
		},
		"can_change_state_buildings": true,
	},
	"raw_berry": {
		"texture": preload("res://res/sprites/items/berry/raw_berry.png"),
		"stack_size": 20,
		"nutrition": 40,
	},
	"cooked_berry": {
		"texture": preload("res://res/sprites/items/berry/cooked_berry.png"),
		"stack_size": 20,
		"nutrition": 80,
	},
	"raw_meat": {
		"texture": preload("res://res/sprites/items/meat/raw_meat.png"),
		"stack_size": 8,
		"nutrition": 50,
	},
	"cooked_meet": {
		"texture": preload("res://res/sprites/items/meat/cooked_meat.png"),
		"stack_size": 8,
		"nutrition": 200,
	},
	"log": {
		"texture": preload("res://res/sprites/items/log.png"),
		"stack_size": 20,
		"attack_speed": 0.7,
		"damage": 1.5,
		"damage_types": {
			"melee": 0.8,
			"axe": 0.3,
			"pickaxe": 0.1,
		},
	},
	"stone": {
		"texture": preload("res://res/sprites/items/stone.png"),
		"stack_size": 50,
		"attack_speed": 0.5,
		"damage": 2.0,
		"damage_types": {
			"melee": 0.8,
			"axe": 0.5,
			"pickaxe": 0.3,
		},
		"throw_power": 7.0,
		"throw_drop_chance": 1.0,
		"billboard": true,
		"explose": false,
	},
	"copper_ore": {
		"texture": preload("res://res/sprites/items/copper_ore.png"),
		"stack_size": 30,
	},
	"iron_ore": {
		"texture": preload("res://res/sprites/items/iron_ore.png"),
		"stack_size": 30,
	},
	"copper_ingot": {
		"texture": preload("res://res/sprites/items/copper_ingot.png"),
		"stack_size": 30,
	},
	"iron_ingot": {
		"texture": preload("res://res/sprites/items/iron_ingot.png"),
		"stack_size": 30,
	},
	"steel_ingot": {
		"texture": preload("res://res/sprites/items/steel_ingot.png"),
		"stack_size": 20,
	},
	"clay": {
		"texture": preload("res://res/sprites/items/clay.png"),
		"stack_size": 100,
	},
	"brick": {
		"texture": preload("res://res/sprites/items/brick.png"),
		"stack_size": 50,
		"damage": 3.0,
		"attack_speed": 0.6,
		"damage_types": {
			"melee": 0.8,
			"axe": 0.5,
			"pickaxe": 0.3,
		},
		"durability": 10,
		"throw_power": 15.0,
		"throw_drop_chance": 0.1,
		"billboard": true,
		"explose": false,
	},
	"coal": {
		"texture": preload("res://res/sprites/items/coal.png"),
		"stack_size": 50,
	},
	"empty": {
		"texture": preload("res://res/sprites/items/empty.png"),
	},
}

const particles := {
	"smoke": preload("res://scenes/particles/smoke_particle/smoke_particle.tscn"),
	"explose": preload("res://scenes/particles/explose_particle/explose_particle.tscn"),
	"damage_counter": preload("res://scenes/particles/damage_counter/damage_counter.tscn"),
}
