extends "res://scenes/gui/settings_buttons/base_button.gd"

func _ready() -> void:
	toggled.connect(_on_toggled)
	if DiskControl.has(key):
		var val = DiskControl.take(key)
		button_pressed = val
		_on_toggled(val)
	else:
		# Если язык не настраивался и он не английский, сохраняем настройку и меняем положение кнопки
		if tr("TGL_LANG_SWITCH") != "[ENG]/ru":
			_on_toggled(true)
			toggle_mode = true

func apply(_toggled_on: bool) -> void:
	if _toggled_on: TranslationServer.set_locale("ru")
	else: TranslationServer.set_locale("en")
