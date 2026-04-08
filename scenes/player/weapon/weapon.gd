extends Node3D

signal attack

@onready var weapon_anim := %WeaponAnim
@onready var actions := $Actions
@onready var throw_sprite := $ThrowSprite

@onready var arms_sprite := $Arms/ShakingContainer/SwayContainer/Sprites/Arms
@onready var item_sprite := $Arms/ShakingContainer/SwayContainer/Sprites/Item


var current_name: String
var damage: float
var attack_speed: float
var damage_types: Dictionary
var push_velocity: float


func get_dig_drop(hit_position: Vector3) -> String:
	if hit_position.y < G.world.WATER_LEVEL:
		return "clay"
	return "dirt"


func check_corrosion_item() -> void:
	# Оксисление
	if R.items[current_name].has("can_oxiding"):
		if randi_range(0, R.OXIDING_SPEED) == 0:
			var oxided_item: String = R.items[current_name]["can_oxiding"]
			actions.inv.drop_item(actions.inv.current_item)
			actions.inv.add_item(oxided_item)


func use_item_durability() -> void:
	check_corrosion_item()
	if current_name != null and R.items[current_name].has("durability"):
		if randi_range(0, R.items[current_name]["durability"]) == 0:
			var item_name := current_name # Сохранеяем имя предмета, чтобы после удаления сигналы не обновили его на ""
			actions.inv.drop_item(actions.inv.current_item)
			
			# Выпадение специальных предметов при поломке если таковы имеются
			if R.items[item_name].has("on_crack_drop_items"):
				for dropped_item in R.items[item_name]["on_crack_drop_items"].keys():
					actions.inv.add_item(dropped_item, R.items[item_name]["on_crack_drop_items"][dropped_item])
			
			G.player.actions_audio_player.audio_play(R.sounds["destroy"]["instrument"].resource_path)


func choose_item(item: String = "") -> void:
	current_name = item
	damage = R.items[item].get("damage", 1.0)
	attack_speed = R.items[item].get("attack_speed", 1.0)
	damage_types = R.items[item].get("damage_types", {"melee": 1.0})
	push_velocity = R.items[item].get("push_velocity", 1.0) * 10
	throw_sprite.texture =  R.items[item].get("texture", R.items["empty"]["texture"])


func set_item_in_arm(item: String):
	choose_item(item)
	update()


func _on_weapon_anim_animation_finished(anim_name: StringName) -> void:
	if anim_name == "throw": throw()

func throw() -> void:
	if Input.is_action_pressed("rmb") and R.items[current_name].get("texture") != null: # Не сработает при отмене
		actions.shoot(damage, damage_types, push_velocity, current_name, R.items[current_name]["texture"].resource_path, R.items[current_name]["throw_drop_chance"], R.items[current_name]["throw_power"], R.items[current_name]["billboard"])
		actions.inv.drop_item(actions.inv.current_item, 1)
	weapon_anim.play("cd")


func update() -> void:
	
	actions.build_zone_mesh.visible = R.items[current_name].has("is_building")
	
	if current_name == "":
		arms_sprite.show()
		item_sprite.hide()
	else:
		arms_sprite.hide()
		item_sprite.show()
		item_sprite.texture = R.items[current_name]["texture"]
