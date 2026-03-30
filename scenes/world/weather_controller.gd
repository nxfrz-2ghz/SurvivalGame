extends Node

@onready var env := $"../WorldEnvironment"
@onready var audio_player := $AudioStreamPlayer3D

var fog_tween: Tween
var rain_tween: Tween

@rpc("authority", "call_local")
func toggle_fog(is_active: bool) -> void:
	# Если старая анимация еще идет, прерываем её
	if fog_tween:
		fog_tween.kill()
	
	fog_tween = create_tween()
	
	# Выбираем целевую плотность (например, 0.04 для тумана и 0.0 для чистого неба)
	var target_density = 0.04 if is_active else 0.0
	
	# Плавно меняем плотность за 5.0 секунд
	fog_tween.tween_property(env.environment, "volumetric_fog_density", target_density, 5.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

@rpc("authority", "call_local")
func toggle_rain(is_active: bool) -> void:
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
		G.player.rain.emitting = false

func _on_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	if G.state_machine != "game": return
	
	toggle_fog.rpc(false)
	toggle_rain.rpc(false)
	
	if randf() < 0.1:
		toggle_fog.rpc(true)
	elif randf() < 0.1:
		toggle_rain.rpc(true)
