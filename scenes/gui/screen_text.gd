extends CanvasItem

@onready var label := $ScreenTextLabel

func _ready() -> void:
	G.screen_text = self

func text(value: String) -> void:
	label.text = value
	if value == "":
		hide()
	else:
		show()
