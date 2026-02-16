extends TextureProgressBar

func update(current_value: float, max_vvalue: float) -> void:
	show()
	self.value = current_value
	self.max_value = max_vvalue
