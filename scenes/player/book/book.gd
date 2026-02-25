extends MarginContainer

signal close_book

@onready var main_page := $MainPage
@onready var craft_page := $CraftPage

const button := preload("res://scenes/player/book/button/button.tscn")


func _ready() -> void:
	set_page("CONTENT")


func spawn_button(text: String, page: Node) -> void:
	var btn := button.instantiate()
	btn.text = text
	page.add_child(btn)
	btn.set_page.connect(set_page)


func clear_page(page: Node) -> void:
	if page.get_children():
		for child in page.get_children():
			child.queue_free()


func set_page(page: String) -> void:
	if page == "CONTENT":
		
		clear_page(main_page)
		
		for item in R.items.keys():
			
			# Ignoring items
			if item in ["empty", ""]: continue
			
			# Create button
			spawn_button(item, main_page)
		
		spawn_button("CLOSE", main_page)
		
		main_page.show()
		craft_page.hide()
	
	elif page == "CLOSE":
		close_book.emit()
	
	# Названием страницы может быть item и тогда выведется вся инфа про него
	elif page in R.items.keys():
		
		clear_page(craft_page)
		
		for txt in R.items[page].keys(): # Сначала получаем ключ
			
			if txt == "texture":
				var img := TextureRect.new()
				img.texture = R.items[page][txt]
				craft_page.add_child(img)
				img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
				img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				img.custom_minimum_size = Vector2(50, 50)
				continue
			
			if txt == "damage_types":
				continue
			
			var lbl := Label.new()
			lbl.text = txt + ": " + str(R.items[page][txt]) # Потом добавляем к ключу значение
			lbl.modulate = Color.BLACK
			craft_page.add_child(lbl)
		
		# Add Back Button
		spawn_button("CONTENT", craft_page)
		
		main_page.hide()
		craft_page.show()
