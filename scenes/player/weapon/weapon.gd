extends Node3D

signal attack

@onready var weapon_anim := %WeaponAnim
@onready var actions := $Actions
@onready var build := $BuildingController
@onready var throw_sprite := $ThrowSprite

@onready var light2d := $Arms/ShakingContainer/SwayContainer/Sprites/Item/FireParticles2D/PointLight2D
@onready var light3d := $OmniLight3D
@onready var fire_particles := $Arms/ShakingContainer/SwayContainer/Sprites/Item/FireParticles2D

@onready var arms_sprite := $Arms/ShakingContainer/SwayContainer/Sprites/Arms
@onready var item_sprite := $Arms/ShakingContainer/SwayContainer/Sprites/Item

var current_name: String
var damage: float
var attack_speed: float
var damage_types: Dictionary
var push_velocity: float

func _ready() -> void:
	G.timer_1sec.timeout.connect(check_corrosion_item)
	G.timer_1sec.timeout.connect(regen)

var health_rings: int
var speed_rings: int
var armor_rings: int:
	set(value):
		armor_rings = value
		G.player.health.armor = float(value) / 2

func update_player_stats() -> void:
	health_rings = actions.inv.get_item("health_ring")
	armor_rings = actions.inv.get_item("armor_ring")
	speed_rings = actions.inv.get_item("speed_ring")


func get_dig_drop(hit_position: Vector3) -> String:
	if hit_position.y < G.world.WATER_LEVEL:
		return "clay"
	return "dirt"


func check_corrosion_item() -> void:
	if G.state_machine != "game": return
	
	# Оксисление
	if R.items[current_name].has("can_oxiding"):
		if randi_range(0, R.OXIDING_SPEED) == 0:
			var oxided_item: String = R.items[current_name]["can_oxiding"]
			actions.inv.drop_item(actions.inv.current_item)
			actions.inv.add_item(oxided_item)


func regen() -> void:
	if G.state_machine != "game": return
	
	if G.player:
		G.player.health.heal(float(health_rings)/20)


func use_item_durability() -> void:
	check_corrosion_item()
	if current_name != null and R.items[current_name].has("durability"):
		if randi_range(0, R.items[current_name]["durability"] + (R.items[current_name]["durability"] * armor_rings / 3)) == 0:
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
	
	if R.items[item].has("light"):
		fire_particles.emitting = true
		light3d.visible = true
		light3d.light_energy = R.items[item]["light"]["energy"]
		light3d.light_color = R.items[item]["light"]["color"]
		light2d.visible = true
		light2d.energy = R.items[item]["light"]["energy"]
		light2d.color = R.items[item]["light"]["color"]
		
	else:
		fire_particles.emitting = false
		light3d.visible = false
		light2d.visible = false


func set_item_in_arm(item: String):
	choose_item(item)
	update()


func update() -> void:
	build.set_item(current_name)
	
	if current_name == "":
		arms_sprite.show()
		item_sprite.hide()
	else:
		arms_sprite.hide()
		item_sprite.show()
		item_sprite.texture = R.items[current_name]["texture"]
