extends MarginContainer

@onready var label := $PanelContainer/MarginContainer/Label


func update(txt: String):
	self.visible = bool(txt.length())
	label.text = txt
