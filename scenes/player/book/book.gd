extends Control

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


func spawn_label(text: String, page: Node) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.modulate = Color.BLACK
	page.add_child(lbl)


func clear_page(page: Node) -> void:
	if page.get_children():
		for child in page.get_children():
			child.queue_free()


func set_page(page: String) -> void:
	if page == "CONTENT":
		
		clear_page(main_page)
		
		spawn_button("CLOSE", main_page)
		spawn_label("", main_page)
		
		spawn_label("ITEMS", main_page)
		spawn_label("", main_page) # Заполнение пустотой второй колонки для удобства читателя
		for item in R.items.keys():
			
			# Ignoring items
			if item in ["empty", ""]: continue
			
			# Create button
			spawn_button(item, main_page)
		if R.items.keys().size() % 2 != 0: # Если количество плиток нечетное, то добавляем пустоту для четности (ведь рядов два)
			spawn_label("", main_page)
		
		spawn_label("OBJECTS", main_page)
		spawn_label("", main_page) # Заполнение пустотой второй колонки для удобства читателя
		for object in R.objects.keys():
			# Create button
			spawn_button(" " + object, main_page) # Отличительная особенность объектов, тк их имя может быть у item
		if R.objects.keys().size() % 2 != 0: # Если количество плиток нечетное, то добавляем пустоту для четности (ведь рядов два)
			spawn_label("", main_page)
		
		spawn_label("MOBS", main_page)
		spawn_label("", main_page) # Заполнение пустотой второй колонки для удобства читателя
		for mob in R.mobs.keys():
			# Create button
			spawn_button(mob, main_page)
		if R.mobs.keys().size() % 2 != 0: # Если количество плиток нечетное, то добавляем пустоту для четности (ведь рядов два)
			spawn_label("", main_page)
		
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
			
			spawn_label(txt + ": " + str(R.items[page][txt]), craft_page)
		
		# Add Back Button
		spawn_button("CONTENT", craft_page)
		
		main_page.hide()
		craft_page.show()
	
	elif page.erase(0) in R.objects.keys(): # Отличительная особенность объектов, тк их имя может быть у item
		page = page.erase(0)
		
		clear_page(craft_page)
		
		for txt in R.objects[page].keys(): # Сначала получаем ключ
			
			if txt == "scene":
				var img := TextureRect.new()
				var obj: StaticBody3D = R.objects[page][txt].instantiate()
				img.texture = obj.get_node("Sprite3D").texture
				craft_page.add_child(img)
				img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
				img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				img.custom_minimum_size = Vector2(50, 50)
				
				spawn_label("HP: " + str(obj.get_node("HealthComponent").max_health), craft_page)
				if obj.drop_items:
					spawn_label("Drop_items: " + str(obj.drop_items), craft_page)
				
				obj.queue_free()
				continue
			
			spawn_label(txt + ": " + str(R.objects[page][txt]), craft_page)
		
		# Add Back Button
		spawn_button("CONTENT", craft_page)
		
		main_page.hide()
		craft_page.show()
	
	elif page in R.mobs.keys():
		
		clear_page(craft_page)
		
		for txt in R.mobs[page].keys(): # Сначала получаем ключ
			
			if txt == "texture":
				var img := TextureRect.new()
				img.texture = load(R.mobs[page][txt])
				craft_page.add_child(img)
				img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
				img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				img.custom_minimum_size = Vector2(50, 50)
				continue
			
			if txt == "scene":
				var mob: CharacterBody3D = R.mobs[page][txt].instantiate()
				spawn_label("HP: " + str(mob.get_node("HealthComponent").max_health), craft_page)
				if mob.drop_items:
					spawn_label("Drop_items: " + str(mob.drop_items), craft_page)
				
				mob.queue_free()
				continue
			
			spawn_label(txt + ": " + str(R.mobs[page][txt]), craft_page)
		
		# Add Back Button
		spawn_button("CONTENT", craft_page)
		
		main_page.hide()
		craft_page.show()
