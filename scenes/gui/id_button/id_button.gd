extends Button
class_name id_button

signal ppressed(page_name: String)

@export var id: String

func _on_pressed() -> void:
	ppressed.emit(id)
