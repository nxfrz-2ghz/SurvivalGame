extends TextureRect

func on_health_changed(cur: float, maxx: float, _last: float) -> void:
	self.modulate.a = (1.0 - cur/maxx) * 2
