extends Node

const item := preload("res://scenes/items/item.tscn")
const exp_sphere := preload("res://scenes/exp_sphere/exp_sphere.tscn")

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
		"instrument": preload("res://res/sounds/destroy/instrument_destroy.mp3"),
	},
	"idle": {
		"pig": [
			preload("res://res/sounds/idle/pig/1.mp3"),
			preload("res://res/sounds/idle/pig/2.mp3"),
			preload("res://res/sounds/idle/pig/3.mp3"),
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
		"copper_ore": {"amount": 2, "output": "copper_bar", "speed": 8},
		"clay":       {"amount": 1, "output": "brick", "speed": 6},
	},
	"furnace_t2": {
		"iron_ore": {"amount": 2, "output": "iron_bar", "speed": 8},
		"iron_bar": {"amount": 5, "output": "steel_bar", "speed": 15},
	},
	"alchemy_station": {
		"log": {"amount": 3, "output": "coal", "speed": 5},
	},
}

const mobs := {
	"darkness_eye": {
		"texture": "res://res/sprites/mobs/darkness_eye/eye0.png",
		"scene": preload("res://scenes/mobs/darkness_eye/darkness_eye.tscn"),
		"requirements": ["night", ],
		"spawn_weight": 1,
	},
	"pig": {
		"texture": "res://res/sprites/mobs/pig/front/front0.png",
		"scene": preload("res://scenes/mobs/pig/pig.tscn"),
		"spawn_weight": 1,
	},
	"krab": {
		"texture": "res://res/sprites/mobs/krab/front/idle.png",
		"scene": preload("res://scenes/mobs/krab/krab.tscn"),
	}
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
		"recipe": {"copper_bar": 5},
	},
	"heart": {
		"scene": preload("res://scenes/objects/heart/heart.tscn"),
	},
	"wall_wood": {
		"scene": preload("res://scenes/building/wall_wood/wall_wood.tscn"),
		"recipe": {"log": 2},
		"is_building": true,
	},
#	"wall_stone": {
#		"scene": preload("res://scenes/building/wall_stone/wall_stone.tscn"),
#		"recipe": {"stone": 4},
#		"is_building": true,
#	},
#	"door_wood": {
#		"scene": preload("res://scenes/building/door_wood/door_wood.tscn"),
#		"recipe": {"log": 3},
#		"is_building": true,
#	},
#	"chest": {
#		"scene": preload("res://scenes/building/chest/chest.tscn"),
#		"recipe": {"log": 6},
#		"is_building": true,
#	},
}

const items := {
	"": {
		"attack_speed": 1.2,
		"damage_types":
			{
				"melee": 1.0,
				"axe": 0.2,
				"pickaxe": 0.1,
			},
	},
	"copper_shovel": {
		"texture": preload("res://res/sprites/items/copper_shovel.png"),
		"recipe": {
			"log":2,
			"copper_bar":2,
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
	"stone_axe": {
		"texture": preload("res://res/sprites/items/stone_axe.png"),
		"recipe": {
			"log":3,
			"stone":2,
		},
		"durability": 50,
		"attack_speed": 1.0,
		"damage": 2.0,
		"damage_types": {
			"melee": 0.5,
			"axe": 1.0,
			"pickaxe": 0.0,
		},
	},
	"stone_pickaxe": {
		"texture": preload("res://res/sprites/items/stone_pickaxe.png"),
		"recipe": {
			"log":2,
			"stone":3,
		},
		"durability": 50,
		"attack_speed": 1.0,
		"damage": 2.0,
		"damage_types": {
			"melee": 0.2,
			"axe": 0.0,
			"pickaxe": 1.0,
		},
	},
	"iron_axe": {
		"texture": preload("res://res/sprites/items/iron_axe.png"),
		"recipe": {
			"log":3,
			"iron_bar":2,
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
		"texture": preload("res://res/sprites/items/iron_pickaxe.png"),
		"recipe": {
			"log":2,
			"iron_bar":3,
		},
		"durability": 250,
		"attack_speed": 1.1,
		"damage": 3.5,
		"damage_types": {
			"melee": 0.5,
			"axe": 0.0,
			"pickaxe": 1.1,
		},
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
	},
	"copper_ore": {
		"texture": preload("res://res/sprites/items/copper_ore.png"),
		"stack_size": 30,
	},
	"iron_ore": {
		"texture": preload("res://res/sprites/items/iron_ore.png"),
		"stack_size": 30,
	},
	"copper_bar": {
		"texture": preload("res://res/sprites/items/copper_bar.png"),
		"stack_size": 30,
	},
	"iron_bar": {
		"texture": preload("res://res/sprites/items/iron_bar.png"),
		"stack_size": 30,
	},
	"steel_bar": {
		"texture": preload("res://res/sprites/items/steel_bar.png"),
		"stack_size": 20,
	},
	"clay": {
		"texture": preload("res://res/sprites/items/clay.png"),
		"stack_size": 100,
	},
	"brick": {
		"texture": preload("res://res/sprites/items/brick.png"),
		"stack_size": 50,
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
