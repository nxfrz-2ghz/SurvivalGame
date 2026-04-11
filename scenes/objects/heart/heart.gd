extends "res://scenes/objects/object.gd"

@onready var anim_sprite := $AnimatedSprite3D
@onready var summon_timer := $Timers/SummonTimer
@onready var corruption_decal := $Corruption

const spawn_mob := R.mobs["krab"]["scene"]

@export var corruption_size: Vector3 = Vector3(2.0, 2.0, 2.0):
	set(value):
		corruption_size = value
		if corruption_decal:
			corruption_decal.size = value

func _ready() -> void:
	super()
	corruption_decal.size = corruption_size


@rpc("authority", "call_local")
func on_damage() -> void:
	take_damage_audio.play()
	anim_sprite.anim_play.rpc("on_damage")
	if randf() > 0.9: summon(spawn_mob)


func summon(scene: PackedScene) -> void:
	anim_sprite.anim_play.rpc("on_summon")
	var pos: Vector3 = G.mob_spawner.get_random_spawn_position(self.position, corruption_size.x/3, corruption_size.x)
	pos.y = 30
	G.mob_spawner.spawn_mob(scene, pos)


func _on_regeneration_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	if G.state_machine != "game": return
	health.heal(health.max_health / 10)


func _on_grow_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	if G.state_machine != "game": return
	if health.max_health < 40.0:
		health.max_health += health.max_health / 10
		
		# Целевой размер расширения
		var target_size = corruption_size + (Vector3.ONE * 3) / (corruption_size / 2)
		
		# Создаем анимацию
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE) # Плавное начало и конец
		tween.set_ease(Tween.EASE_OUT)
		
		# Анимируем свойство size (или scale, в зависимости от узла)
		tween.tween_property(self, "corruption_size", target_size, 0.5) 
	else:
		if randf() > 0.1:
			summon(load(self.scene_file_path))


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
