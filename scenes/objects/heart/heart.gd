extends "res://scenes/objects/object.gd"

@onready var anim_sprite := $AnimatedSprite3D
@onready var summon_timer := $Timers/SummonTimer
@onready var corruption_decal := $Corruption


func on_damage() -> void:
	take_damage_audio.play()
	anim_sprite.anim_play.rpc("on_damage")
	if randf() > 0.7: summon()


func summon() -> void:
	pass


func _on_regeneration_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	if G.state_machine != "game": return
	health.heal(health.max_health / 10)


func _on_grow_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	if G.state_machine != "game": return
	health.max_health += health.max_health / 100
	corruption_decal.size += (Vector3.ONE * 3) / (corruption_decal.size / 2)


func _on_animated_sprite_3d_animation_finished() -> void:
	if G.state_machine != "game": return
	anim_sprite.update_animation.rpc(health.current_health, health.max_health)


func _on_summon_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	if G.state_machine != "game": return
	summon_timer.wait_time = randi_range(20, 40)
	anim_sprite.anim_play.rpc("on_summon")
	summon()
	summon_timer.start()
