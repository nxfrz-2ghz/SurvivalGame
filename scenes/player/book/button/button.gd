extends Button

signal set_page(page_name: String)

func _on_pressed() -> void:
	set_page.emit(text)
