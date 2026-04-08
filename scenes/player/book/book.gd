extends Control

signal open_book
signal close_book

@onready var grid_page := $GridPage
@onready var box_page := $BoxPage

const button := preload("res://scenes/player/book/button/button.tscn")

var current_page: Node


func spawn_button(text: String) -> void:
	var btn := button.instantiate()
	btn.text = tr(text)
	btn.id = text
	current_page.add_child(btn)
	btn.set_page.connect(set_page)


func spawn_label(text: String) -> void:
	var lbl := Label.new()
	lbl.text = tr(text)
	lbl.modulate = Color.BLACK
	current_page.add_child(lbl)
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var min_size := 200.0
	if grid_page.visible: min_size /= 1.5
	
	if lbl.size.x > min_size:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size.x = min_size


func add_back_button() -> void:
	spawn_label("")
	spawn_label("BK_BACK")
	spawn_button("BK_BESTIARY")


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
	if page == "BK_MAIN":
		show_page(box_page)
		
		spawn_button("BK_CLOSE")
		spawn_label("")
		spawn_label("BK_NOTES")
		
		if !G.player.progress_controller.unlocked_notes.is_empty():
			var reversed_notes: Array = G.player.progress_controller.unlocked_notes.duplicate()
			reversed_notes.reverse() 
			for note in reversed_notes:
				spawn_button(G.player.progress_controller.notes.find_key(note))
		
		spawn_label("")
		spawn_label("==================")
		spawn_label("")
		spawn_button("BK_ACHIVIEMENTS")
		spawn_button("BK_BESTIARY")
		for i in range(5):
			spawn_label("")
	
	elif page in G.player.progress_controller.notes:
		show_page(box_page)
		
		spawn_label(tr(page))
		spawn_label("")
		
		spawn_label(G.player.progress_controller.notes[page])
		if page == "NTK_7":
			spawn_button(" alchemy_station")
		
		spawn_label("")
		spawn_label("BK_BACK")
		spawn_button("BK_MAIN")
		for i in range(5):
			spawn_label("")
	
	
	elif page == "BK_ACHIVIEMENTS":
		show_page(grid_page)
		
		spawn_label(tr(page))
		spawn_label("")
		spawn_label("============")
		spawn_label("============")
		
		var full_size: int = G.player.progress_controller.achievements.size()
		var unlocked: int = G.player.progress_controller.unlocked_achievements.size()
		var completed: int = 0
		var iter: int = 0
		for ach in G.player.progress_controller.achievements:
			iter += 1
			if G.player.progress_controller.unlocked_achievements.has(ach):
				spawn_label(ach)
				if G.player.progress_controller.completed_achievements.has(ach):
					completed += 1
					spawn_label("ACH_UNL")
				else:
					spawn_label("ACH_SHW")
			else:
				spawn_label("???")
				spawn_button("UNL_ACH_" + str(iter))
			
			spawn_label("============")
			spawn_label("============")
		
		spawn_label("")
		spawn_label("")
		spawn_label("COMPLETED: " + str(completed) + "/"+ str(full_size))
		if unlocked < full_size:
			spawn_label("")
			spawn_label("")
			spawn_label("")
			spawn_label("UNLK_ACH_TIP")
			spawn_label("[" + str(unlocked + G.player.progress_controller.show_achievement_cost) + " LVL]")
			spawn_label("")
			spawn_label("")
			spawn_label("")
		
		spawn_label("")
		spawn_label("BK_BACK")
		spawn_button("BK_MAIN")
		for i in range(5):
			spawn_label("")
	
	
	# Кнопка показа скрытого достижения
	elif "UNL_ACH" in page:
		G.player.progress_controller.show_achievement("ACH_" + page[-1])
		set_page("BK_ACHIVIEMENTS")
	
	elif page == "BK_BESTIARY":
		show_page(grid_page)
		
		spawn_label("BK_BACK")
		spawn_button("BK_MAIN")
		
		spawn_label("BK_ITEMS")
		spawn_label("") # Заполнение пустотой второй колонки для удобства читателя
		
		var i: int = 0
		for item in R.items.keys():
			
			# Ignoring items
			if item in ["empty", ""]: continue
			if "_ox" in item: continue
			if R.items[item].has("is_building"): continue
			
			# Create button
			spawn_button(item)
			i += 1
		if i % 2 != 0: # Если количество плиток нечетное, то добавляем пустоту для четности (ведь рядов два)
			spawn_label("")
		
		spawn_label("BK_OBJECTS")
		spawn_label("") # Заполнение пустотой второй колонки для удобства читателя
		for object in R.objects.keys():
			# Create button
			spawn_button(" " + object) # Отличительная особенность объектов, тк их имя может быть у item
		if R.objects.keys().size() % 2 != 0: # Если количество плиток нечетное, то добавляем пустоту для четности (ведь рядов два)
			spawn_label("")
		
		spawn_label("BK_BUILDINGS")
		spawn_label("") # Заполнение пустотой второй колонки для удобства читателя
		i = 0
		for building in R.buildings.keys():
			# Create button
			spawn_button(building)
			i += 1
		if i % 2 != 0: # Если количество плиток нечетное, то добавляем пустоту для четности (ведь рядов два)
			spawn_label("")
		
		spawn_label("BK_MOBS")
		spawn_label("") # Заполнение пустотой второй колонки для удобства читателя
		i = 0
		for mob in R.mobs.keys():
			# Create button
			spawn_button(mob)
			i += 1
		if i % 2 != 0: # Если количество плиток нечетное, то добавляем пустоту для четности (ведь рядов два)
			spawn_label("")
	
	# Названием страницы может быть item и тогда выведется вся инфа про него
	elif page in R.items.keys() and page not in R.buildings.keys():
		show_page(box_page)
		spawn_label(page)
		
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
		spawn_label(page)
		
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
				if obj.get_node("EntityComponent").drop_items:
					spawn_label("Drop_items: " + str(obj.get_node("EntityComponent").drop_items))
				
				obj.queue_free()
				continue
			
			spawn_label(txt + ": " + str(R.objects[page][txt]))
		
		add_back_button()
	
	elif page in R.buildings.keys() and page in R.items.keys():
		show_page(box_page)
		spawn_label(page)
		
		for txt in R.items[page].keys() + R.buildings[page].keys(): # Сначала получаем ключ
			
			if txt == "texture":
				var img := TextureRect.new()
				img.texture = R.items[page][txt]
				box_page.add_child(img)
				img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
				img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				img.custom_minimum_size = Vector2(50, 50)
				continue
			
			if txt == "scene":
				var obj: StaticBody3D = R.buildings[page][txt].instantiate()
				
				spawn_label("HP: " + str(obj.get_node("HealthComponent").max_health))
				if obj.get_node("EntityComponent").drop_items:
					spawn_label("Drop_items: " + str(obj.get_node("EntityComponent").drop_items))
				
				obj.queue_free()
				continue
			
			if txt == "damage_types":
				continue
			
			if txt == "is_building":
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
	
	elif page in R.mobs.keys():
		show_page(box_page)
		spawn_label(page)
		
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
				if mob.get_node("EntityComponent").drop_items:
					spawn_label("Drop_items: " + str(mob.get_node("EntityComponent").drop_items))
				
				mob.queue_free()
				continue
			
			spawn_label(txt + ": " + str(R.mobs[page][txt]))
		
		add_back_button()
	
	elif page == "BK_CLOSE":
		close_book.emit()
