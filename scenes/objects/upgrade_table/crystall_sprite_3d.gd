extends AnimatedSprite3D


var tween: Tween
@export var float_range = 0.2 # Насколько высоко/низко
@export var speed = 1.0
func start_floating() -> void:
	# Создаем tween, который будет жить пока существует узел
	tween = create_tween().set_loops()
	
	# Плавное движение вверх
	tween.tween_property(self, "position:y", position.y - float_range, speed)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Плавное движение вниз
	tween.tween_property(self, "position:y", position.y + float_range, speed)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
