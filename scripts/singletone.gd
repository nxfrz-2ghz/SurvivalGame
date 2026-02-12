extends Node

const items := {
	"": {
		"attack_speed": 1.2,
		"damage": 1.0,
		"damage_types":
			{
				"melee": 1.0,
				"axe": 0.1,
				"pickaxe": 0.0,
			},
	},
	"axe": {
		"texture": preload("res://res/sprites/items/axe.png"),
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
	"pickaxe": {
		"texture": preload("res://res/sprites/items/pickaxe.png"),
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
	"empty": {
		"texture": preload("res://res/sprites/items/empty.png"),
	},
}
