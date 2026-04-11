extends TextureRect

func _ready() -> void:
	self.texture = load("res://res/sprites/gui/backgorunds/" + str(randi_range(1,6)) + ".png")
