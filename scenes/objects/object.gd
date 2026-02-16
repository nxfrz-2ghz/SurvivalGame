extends StaticBody3D

@onready var collider := $CollisionShape3D
@onready var sprite := $Sprite3D
@onready var take_damage_audio := $TakeDamageAudio
@onready var health := $HealthComponent
@onready var item := preload("res://scenes/items/item.tscn")

@export var nname: String
@export var drop_name: String


func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	health.died.connect(despawn)
	health.changed.connect(on_damage)
	if randf() < 0.1: drop_loot()


func drop(item_name: String) -> void:
	var drop_item: RigidBody3D = item.instantiate()
	drop_item.nname = item_name
	G.world.add_child(drop_item, true)
	drop_item.position = self.position + Vector3(randi_range(-1,1), 2, randi_range(-1,1))


func drop_loot() -> void:
	if !drop_name: return
	drop(drop_name)


func on_damage(_current_health: float, _max_health: float) -> void:
	take_damage_audio.play()
	if randf() < 0.1: drop_loot()


func despawn() -> void:
	for i in range(randi_range(3,6)):
		drop_loot()	
	queue_free()


func get_save_data() -> Dictionary:
	var data := {
		"nname": nname,
		"drop_name": drop_name,
		"health": {
			"max": health.max_health,
			"current": health.current_health,
		}
	}
	return data


func load_save_data(data: Dictionary) -> void:
	if data.has("nname"):
		nname = String(data["nname"])
	if data.has("drop_name"):
		drop_name = String(data["drop_name"])
	if data.has("health"):
		var h = data["health"]
		health.max_health = float(h.get("max", health.max_health))
		health.current_health = float(h.get("current", health.current_health))
		health.changed.emit(health.current_health, health.max_health)
