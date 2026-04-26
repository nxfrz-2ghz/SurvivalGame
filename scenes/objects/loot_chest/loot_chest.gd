extends "res://scenes/objects/object.gd"

const explosion := preload("res://scenes/prefabs/explosion/explosion_3d.tscn")
const chest_mimic_chance_percent := 10.0

@export var lvl_cost: int
@onready var label := $Label3D

func _ready() -> void:
	super()
	label.text = "lvl: " + str(lvl_cost)

@rpc("any_peer", "call_local")
func open() -> void:
	if not is_multiplayer_authority(): return
	if randf() < chest_mimic_chance_percent / 100:
		G.mob_spawner.spawn_mob(R.mobs["chest_mimic"]["scene"], self.position)
		queue_free()
	entity.despawn()

@rpc("authority", "call_local")
func on_damage() -> void:
	super()
	if not is_multiplayer_authority(): return
	
	if randf() < chest_mimic_chance_percent / 100:
		G.mob_spawner.spawn_mob(R.mobs["chest_mimic"]["scene"], self.position)
		queue_free()
	
	if health.current_health <= 0:
		G.mob_spawner.spawn_mob(explosion, self.position)
		
		for i in entity.drop_items.keys():
			if randf() < 0.6:
				entity.drop_items[i] = 0
