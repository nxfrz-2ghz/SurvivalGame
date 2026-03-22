extends Node3D

signal attack

@onready var weapon_anim := %WeaponAnim
@onready var actions := $Actions

@onready var arms_sprite := $Arms/ShakingContainer/SwayContainer/Sprites/Arms
@onready var item_sprite := $Arms/ShakingContainer/SwayContainer/Sprites/Item


var current_name: String
var damage: float
var attack_speed: float
var damage_types: Dictionary
var push_velocity: float


func get_dig_drop(hit_position: Vector3) -> String:
	var world_gen = G.world.get_node("World")  # или как у тебя называется
	if hit_position.y < world_gen.WATER_LEVEL:
		return "clay"
	return "dirt"


func use_item() -> void:
	if current_name != null and R.items[current_name].has("durability"):
		if randi_range(0, R.items[current_name]["durability"]) == 0:
			actions.inv.drop_item(actions.inv.current_item)


func choose_item(item: String = "") -> void:
	current_name = item
	damage = R.items[item].get("damage", 1.0)
	attack_speed = R.items[item].get("attack_speed", 1.0)
	damage_types = R.items[item].get("damage_types", {"melee": 1.0})
	push_velocity = R.items[item].get("push_velocity", 1.0) * 10


func set_item_in_arm(item: String):
	choose_item(item)
	update()


func update() -> void:
	if current_name == "":
		arms_sprite.show()
		item_sprite.hide()
	else:
		arms_sprite.hide()
		item_sprite.show()
		item_sprite.texture = R.items[current_name]["texture"]
