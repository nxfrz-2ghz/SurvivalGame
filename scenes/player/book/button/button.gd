extends Button

signal set_page(page_name: String)

var id: String

func _on_pressed() -> void:
	set_page.emit(id)
