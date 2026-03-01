extends Node

const item := preload("res://scenes/items/item.tscn")

const exchangeable_items := {
	"campfire": {
		"raw_berry": {
			"amount": 1,
			"output": "cooked_berry",
		},
		"raw_meet": {
			"amount": 1,
			"output": "cooked_meet",
		},
	},
	"furnace": {
		"copper_ore": {
			"amount": 2,
			"output": "copper_bar",
		},
		"iron_ore": {
			"amount": 2,
			"output": "iron_bar",
		},
	},
}

const mobs := {
	"darkness_eye": {
		"texture": "res://res/sprites/mobs/darkness_eye/eye0.png",
		"scene": preload("res://scenes/mobs/darkness_eye/darkness_eye.tscn"),
		"requirements": ["night", ],
		"spawn_weight": 1,
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
	"heart": {
		"scene": preload("res://scenes/objects/heart/heart.tscn"),
	}
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
	"stone_axe": {
		"texture": preload("res://res/sprites/items/stone_axe.png"),
		"recipe": {
			"log":3,
			"stone":2,
		},
		"attack_speed": 1.0,
		"damage": 2.0,
		"damage_types":
			{
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
		"attack_speed": 1.0,
		"damage": 2.0,
		"damage_types":
			{
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
		"attack_speed": 1.1,
		"damage": 3.5,
		"damage_types":
			{
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
		"attack_speed": 1.1,
		"damage": 3.5,
		"damage_types":
			{
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
	"raw_meet": {
		"texture": preload("res://res/sprites/items/meat/raw_meet.png"),
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
		"damage_types":
			{
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
		"damage_types":
			{
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
	"empty": {
		"texture": preload("res://res/sprites/items/empty.png"),
	},
}

const particles := {
	"smoke": preload("res://scenes/particles/smoke_particle/smoke_particle.tscn"),
	"explose": preload("res://scenes/particles/explose_particle/explose_particle.tscn"),
}
