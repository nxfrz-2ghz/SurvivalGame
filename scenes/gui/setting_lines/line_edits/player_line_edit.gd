extends "res://scenes/gui/setting_lines/key_line.gd"

func _ready() -> void:
	super()
	if text == "":
		text = "player" + str(randi_range(0, 999999))
		# Сохраняем сгенерированное имя
		_on_save()
