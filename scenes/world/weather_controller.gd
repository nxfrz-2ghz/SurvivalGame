extends Node

@onready var env := $"../WorldEnvironment"
@onready var audio_player := $AudioStreamPlayer3D
@onready var meteor_timer := $MeteorTimer

var fog: bool
var rain: bool
var meteor_rain: bool

var fog_tween: Tween
var rain_tween: Tween
var meteor_rain_tween: Tween

@rpc("authority", "call_local")
func toggle_fog(is_active: bool) -> void:
	fog = is_active
	# Если старая анимация еще идет, прерываем её
	if fog_tween: fog_tween.kill()
	fog_tween = create_tween()
	
	# Выбираем целевую плотность (например, 0.04 для тумана и 0.0 для чистого неба)
	var target_density := 0.04 if is_active else 0.0
	
	# Плавно меняем плотность за 5.0 секунд
	fog_tween.tween_property(env.environment, "volumetric_fog_density", target_density, 5.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

@rpc("authority", "call_local")
func toggle_rain(is_active: bool) -> void:
	rain = is_active
	if rain_tween: rain_tween.kill()
	rain_tween = create_tween()
	
	if is_active:
		# Если звук не играет, включаем его на минимальной громкости
		if not audio_player.playing:
			audio_player.stream = R.sounds["ambient"]["rain"]
			audio_player.volume_db = -40 # Начинаем с тишины
			audio_player.play()
		
		# Плавно повышаем до 0 (или вашей рабочей громкости)
		rain_tween.tween_property(audio_player, "volume_db", 0.0, 3.0)
		G.player.rain.emitting = true
	else:
		# Плавно глушим до -40 и выключаем
		rain_tween.tween_property(audio_player, "volume_db", -40.0, 3.0)
		rain_tween.tween_callback(audio_player.stop)
		if G.player: G.player.rain.emitting = false

@rpc("authority", "call_local")
func toggle_meteor_rain(is_active: bool) -> void:
	meteor_rain = is_active
	if meteor_rain_tween: meteor_rain_tween.kill()
	meteor_rain_tween = create_tween()
	
	var target_fog_color := Color.from_rgba8(145,54,13) if is_active else Color.from_rgba8(132,141,155)
	
	# Плавно меняем цвет за 2.0 секунды
	meteor_rain_tween.tween_property(env.environment, "fog_light_color", target_fog_color, 2.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	if is_active: _on_meteor_timer_timeout()

func _on_meteor_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	if G.state_machine != "game": return
	if env.environment != env.envs["default"]: return
	
	var spawn_pos: Vector3 = G.mob_spawner.get_random_spawn_position(G.player.position, 0.0, 10.0)
	spawn_pos.y += 50.0
	G.mob_spawner.spawn_mob(R.prefabs["meteor"], spawn_pos)
	
	if meteor_rain:
		meteor_timer.wait_time = randf_range(0.5, 1.5)
		meteor_timer.start()

func _on_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	if G.state_machine != "game": return
	if env.environment != env.envs["default"]: return
	
	toggle_fog.rpc(false)
	toggle_rain.rpc(false)
	toggle_meteor_rain.rpc(false)
	
	if randf() < 0.1:
		toggle_fog.rpc(true)
	if randf() < 0.15:
		toggle_rain.rpc(true)
	if randf() < 0.01:
		toggle_meteor_rain.rpc(true)


@rpc("any_peer", "call_local")
func update() -> void:
	if not is_multiplayer_authority(): return
	toggle_fog.rpc(fog)
	toggle_rain.rpc(rain)
	toggle_meteor_rain.rpc(meteor_rain)
