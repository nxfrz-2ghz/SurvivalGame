extends Control

signal open_book
signal close_book

@onready var grid_page := $GridPage
@onready var box_page := $BoxPage

const button := preload("res://scenes/player/book/button/button.tscn")

var current_page: Node


func spawn_button(text: String) -> void:
	var btn := button.instantiate()
	btn.text = text
	current_page.add_child(btn)
	btn.set_page.connect(set_page)


func spawn_label(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.modulate = Color.BLACK
	current_page.add_child(lbl)
	if lbl.size.x > 200.0:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size.x = 200.0


func add_back_button() -> void:
	spawn_label("")
	spawn_label("Back to...")
	spawn_button("BESTIARY")


func clear_page(page: Node) -> void:
	if page.get_children():
		for child in page.get_children():
			child.queue_free()


func show_page(node_page: Node) -> void:
	clear_page(node_page)

	current_page = node_page

	if node_page == grid_page:
		grid_page.show()
		box_page.hide()
	else:
		grid_page.hide()
		box_page.show()


func set_page(page: String) -> void:
	if page == "MAIN":
		show_page(box_page)
		
		spawn_button("CLOSE")
		spawn_label("")
		
		if !G.player.progress_controller.unlocked_notes.is_empty():
			var reversed_notes = G.player.progress_controller.unlocked_notes.duplicate()
			reversed_notes.reverse() 
			for note in reversed_notes:
				spawn_button(G.player.progress_controller.notes.find_key(note))
		
		spawn_label("")
		spawn_button("BESTIARY")
		for i in range(5):
			spawn_label("")
	
	elif page in G.player.progress_controller.notes:
		show_page(box_page)
		
		spawn_label(page)
		spawn_label("")
		
		spawn_label(G.player.progress_controller.notes[page])
		
		spawn_label("")
		spawn_label("Back to...")
		spawn_button("MAIN")
		for i in range(5):
			spawn_label("")
	
	elif page == "BESTIARY":
		show_page(grid_page)
		
		spawn_label("To return:")
		spawn_button("MAIN")
		
		spawn_label("ITEMS")
		spawn_label("") # Заполнение пустотой второй колонки для удобства читателя
		for item in R.items.keys():
			
			# Ignoring items
			if item in ["empty", ""]: continue
			
			# Create button
			spawn_button(item)
		if R.items.keys().size() % 2 != 0: # Если количество плиток нечетное, то добавляем пустоту для четности (ведь рядов два)
			spawn_label("")
		
		spawn_label("OBJECTS")
		spawn_label("") # Заполнение пустотой второй колонки для удобства читателя
		for object in R.objects.keys():
			# Create button
			spawn_button(" " + object) # Отличительная особенность объектов, тк их имя может быть у item
		if R.objects.keys().size() % 2 != 0: # Если количество плиток нечетное, то добавляем пустоту для четности (ведь рядов два)
			spawn_label("")
		
		spawn_label("MOBS")
		spawn_label("") # Заполнение пустотой второй колонки для удобства читателя
		for mob in R.mobs.keys():
			# Create button
			spawn_button(mob)
		if R.mobs.keys().size() % 2 != 0: # Если количество плиток нечетное, то добавляем пустоту для четности (ведь рядов два)
			spawn_label("")
	
	# Названием страницы может быть item и тогда выведется вся инфа про него
	elif page in R.items.keys():
		show_page(box_page)

		for txt in R.items[page].keys(): # Сначала получаем ключ
			
			if txt == "texture":
				var img := TextureRect.new()
				img.texture = R.items[page][txt]
				box_page.add_child(img)
				img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
				img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				img.custom_minimum_size = Vector2(50, 50)
				continue
			
			if txt == "damage_types":
				continue
			
			spawn_label(txt + ": " + str(R.items[page][txt]))
		
		
		# Add exchagable recipe
		for station in R.exchangeable_items.keys():
			for ingidient in R.exchangeable_items[station].keys():
				if R.exchangeable_items[station][ingidient]["output"] == page:
					var text := "[STATION RECIPE]:\n"
					text += "> station: " + station
					text += "\n> ingridient: " + ingidient
					text += "\n> amount: " + str(R.exchangeable_items[station][ingidient]["amount"])
					spawn_label(text)
		
		add_back_button()
	
	elif page.erase(0) in R.objects.keys(): # Отличительная особенность объектов, тк их имя может быть у item
		show_page(box_page)
		
		page = page.erase(0)
		
		clear_page(box_page)
		
		for txt in R.objects[page].keys(): # Сначала получаем ключ
			
			if txt == "scene":
				var img := TextureRect.new()
				var obj: StaticBody3D = R.objects[page][txt].instantiate()
				img.texture = obj.get_node("Sprite3D").texture
				box_page.add_child(img)
				img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
				img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				img.custom_minimum_size = Vector2(50, 50)
				
				spawn_label("HP: " + str(obj.get_node("HealthComponent").max_health))
				if obj.drop_items:
					spawn_label("Drop_items: " + str(obj.drop_items))
				
				obj.queue_free()
				continue
			
			spawn_label(txt + ": " + str(R.objects[page][txt]))
		
		add_back_button()
	
	elif page in R.mobs.keys():
		show_page(box_page)
		
		clear_page(box_page)
		
		for txt in R.mobs[page].keys(): # Сначала получаем ключ
			
			if txt == "texture":
				var img := TextureRect.new()
				img.texture = load(R.mobs[page][txt])
				box_page.add_child(img)
				img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
				img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				img.custom_minimum_size = Vector2(50, 50)
				continue
			
			if txt == "scene":
				var mob: CharacterBody3D = R.mobs[page][txt].instantiate()
				spawn_label("HP: " + str(mob.get_node("HealthComponent").max_health))
				if mob.drop_items:
					spawn_label("Drop_items: " + str(mob.drop_items))
				
				mob.queue_free()
				continue
			
			spawn_label(txt + ": " + str(R.mobs[page][txt]))
		
		add_back_button()
	
	elif page == "CLOSE":
		close_book.emit()
