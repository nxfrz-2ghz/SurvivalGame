extends "res://scenes/objects/object.gd"

const evil_tree_spawn_chance_percent := 1.7

@rpc("authority", "call_local")
func on_damage() -> void:
	super()
	if not is_multiplayer_authority(): return
	if randf() < evil_tree_spawn_chance_percent / 100:
		G.mob_spawner.spawn_mob(R.mobs["evil_tree"]["scene"], self.position)
		queue_free()
