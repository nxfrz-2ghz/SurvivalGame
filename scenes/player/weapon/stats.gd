extends Node

var current_name: String
var damage: float
var attack_speed: float
var damage_types: Dictionary


func choose_item(item: String = "") -> void:
	current_name = item
	damage = R.items[item].get("damage", 0.0)
	attack_speed = R.items[item].get("attack_speed", 1.0)
	damage_types = R.items[item].get("damage_types", {})
