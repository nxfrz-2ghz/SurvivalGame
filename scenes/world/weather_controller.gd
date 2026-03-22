extends Node

@onready var env := $"../WorldEnvironment"

var fog := false
var fog_tween: Tween

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

func _on_timer_timeout() -> void:
	if not is_multiplayer_authority(): return
	
	if randf() < 0.1:
		fog = !fog
		toggle_fog.rpc(fog)
