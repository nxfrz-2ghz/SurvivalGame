extends Button
class_name SoundButton

func _ready() -> void:
	mouse_entered.connect(ButtonSound.play_hover)
	pressed.connect(ButtonSound.play_click)
