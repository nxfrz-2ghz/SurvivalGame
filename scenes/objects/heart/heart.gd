extends "res://scenes/objects/object.gd"

@onready var anim_sprite := $AnimatedSprite3D
@onready var summon_timer := $Timers/SummonTimer
@onready var corruption_decal := $Corruption

const spawn_mob := R.mobs["krab"]["scene"]

@rpc("authority", "call_local")
func on_damage() -> void:
	take_damage_audio.play()
	anim_sprite.anim_play.rpc("on_damage")
	if randf() > 0.9: summon(spawn_mob)


func summon(scene: PackedScene) -> void:
	anim_sprite.anim_play.rpc("on_summon")
	var node := scene.instantiate()
	var corrupted_territory_size := 0.0
	node.position = G.mob_spawner.get_random_spawn_position(self.position, corrupted_territory_size/3, corrupted_territory_size)
	node.position.y = 50
	G.world.call_deferred("add_child", node, true)


func _on_regeneration_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	if G.state_machine != "game": return
	health.heal(health.max_health / 10)


func _on_grow_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	if G.state_machine != "game": return
	if health.max_health < 40.0:
		health.max_health += health.max_health / 100
		corruption_decal.size += (Vector3.ONE * 3) / (corruption_decal.size / 2)
	else:
		if randf() > 0.1:
			summon(R.objects["heart"]["scene"])


func _on_animated_sprite_3d_animation_finished() -> void:
	if G.state_machine != "game": return
	anim_sprite.update_animation.rpc(health.current_health, health.max_health)


func _on_summon_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	if G.state_machine != "game": return
	summon_timer.wait_time = randi_range(40, 60) - corruption_decal.size.x
	anim_sprite.anim_play.rpc("on_summon")
	summon(spawn_mob)
	summon_timer.start()
