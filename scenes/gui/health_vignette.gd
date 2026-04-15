extends TextureRect

func on_fear_changed(cur: float, maxx: float) -> void:
	# Рассчитываем целевое значение прозрачности
	var target_alpha : float = cur / maxx * 2
	
	# Создаем Tween для плавной анимации
	var tween = create_tween()
	
	# Анимируем свойство "modulate:a" (альфа-канал)
	# 0.3 — длительность анимации в секундах
	tween.tween_property(self, "modulate:a", target_alpha, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
