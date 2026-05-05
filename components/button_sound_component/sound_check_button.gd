extends CheckButton
class_name SoundCheckButton

func _ready() -> void:
	mouse_entered.connect(ButtonSound.play_hover)
	pressed.connect(ButtonSound.play_click)
