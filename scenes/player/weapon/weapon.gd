extends Node3D

signal attack

@onready var inventory := %InventoryController
@onready var weapon_anim := %WeaponAnim
@onready var actions := $Actions
@onready var stats := $Stats

@onready var arms_sprite := $Arms/SwayContainer/Sprites/Arms
@onready var item_sprite := $Arms/SwayContainer/Sprites/Item


func set_item_in_arm(item: String):
	stats.choose_item(item)
	update()


func update() -> void:
	if stats.current_name == "":
		arms_sprite.show()
		item_sprite.hide()
	else:
		arms_sprite.hide()
		item_sprite.show()
		item_sprite.texture = R.items[stats.current_name]["texture"]
