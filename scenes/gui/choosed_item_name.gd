extends Label


func on_choosed(item_name: String) -> void:
	if item_name == "": return
	self.text = "[" + item_name + "]"
	self.modulate.a = 1


func _physics_process(_delta: float) -> void:
	if self.modulate.a > 0:
		self.modulate.a -= 0.01
