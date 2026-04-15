extends Node

signal update(items: Dictionary)
signal updatev
signal set_hotbar_slot(pos: int)
signal set_item_in_arm(item: String)

const MAX_SLOTS = 12

# Структура предмета в слоте: {"name": String, "type": String, "amount": int}
var inventory: Dictionary = {}
var current_item := 1


func _ready() -> void:
	# Инициализируем пустые слоты
	for i in range(1, MAX_SLOTS + 1):
		inventory[i] = null

func update_signals() -> void:
	set_hotbar_slot.emit(current_item)
	update.emit(inventory)
	var item_data = inventory[current_item]
	set_item_in_arm.emit(item_data["name"] if item_data != null else "")


func _input(_event: InputEvent) -> void:
	if G.state_machine != "game": return
	if is_multiplayer_authority() and %WeaponAnim.is_playing(): return
	
	if Input.is_action_just_pressed("1"):
		current_item = 1
		update_signals()
	if Input.is_action_just_pressed("2"):
		current_item = 2
		update_signals()
	if Input.is_action_just_pressed("3"):
		current_item = 3
		update_signals()
	if Input.is_action_just_pressed("4"):
		current_item = 4
		update_signals()
	if Input.is_action_just_pressed("5"):
		current_item = 5
		update_signals()
	if Input.is_action_just_pressed("6"):
		current_item = 6
		update_signals()
	if Input.is_action_just_pressed("7"):
		current_item = 7
		update_signals()
	if Input.is_action_just_pressed("8"):
		current_item = 8
		update_signals()
	if Input.is_action_just_pressed("9"):
		current_item = 9
		update_signals()
	if Input.is_action_just_pressed("0"):
		current_item = 10
		update_signals()
	if Input.is_action_just_pressed("11"):
		current_item = 11
		update_signals()
	if Input.is_action_just_pressed("12"):
		current_item = 12
		update_signals()
	
	
	if Input.is_action_pressed("up_mouse_wheel"):
		current_item -= 1
		if current_item < 1:
			current_item += MAX_SLOTS
		update_signals()
	
	if Input.is_action_pressed("down_mouse_wheel"):
		current_item += 1
		if current_item > MAX_SLOTS:
			current_item -= MAX_SLOTS
		update_signals()


func check_progress(item_name) -> void:
	if !G.player: return
	var prg: Node = G.player.progress_controller
	
	if item_name == "iron_axe": G.player.progress_controller.add_achievement("ACH_6")
	
	var note_will_add: int
	
	if item_name == "stone": note_will_add = 1
	elif item_name == "log": note_will_add = 2
	elif item_name == "copper_ore": note_will_add = 5
	elif item_name == "iron_ore": note_will_add = 6
	elif item_name == "copper_ingot": note_will_add = 7
	elif item_name == "copper_shovel": note_will_add = 8
	elif item_name == "clay": note_will_add = 9
	elif item_name == "iron_ingot": note_will_add = 10
	elif item_name == "wall_wood": note_will_add = 11
	elif item_name == "steel_ingot": note_will_add = 12
	elif item_name == "copper_piclaxe": note_will_add = 13
	elif "ring" in item_name: note_will_add = 14
	
	if note_will_add and !prg.unlocked_notes.has("NTV_"+str(note_will_add)): prg.add_note("NTK_"+str(note_will_add))

### --- ОСНОВНЫЕ ФУНКЦИИ ---

func get_item(item_name: String) -> int:
	for slot_idx in inventory:
		if inventory[slot_idx] != null:
			if inventory[slot_idx]["name"] == item_name:
				return inventory[slot_idx]["amount"]
	return 0

func add_item(item_name: String, amount: int = 1) -> void:
	$"../Audio/ActionsAudioPlayer3D".audio_play(R.sounds["actions"]["pickup"].resource_path)
	var remaining_amount = amount
	var max_s = R.items[item_name].get("stack_size", 1) # По умолчанию стак 1
	check_progress(item_name)

	# 1. Сначала пытаемся добавить в существующие стаки того же типа
	for i in range(1, MAX_SLOTS + 1):
		var slot = inventory[i]
		if slot and slot["name"] == item_name and slot["amount"] < max_s:
			var can_add = max_s - slot["amount"]
			var added = min(can_add, remaining_amount)
			
			inventory[i]["amount"] += added
			remaining_amount -= added
			
			if remaining_amount <= 0:
				update_signals()
				updatev.emit()
				return

	# 2. Если осталось что добавлять, ищем пустые слоты
	for i in range(1, MAX_SLOTS + 1):
		if inventory[i] == null:
			var added = min(max_s, remaining_amount)
			inventory[i] = {
				"name": item_name,
				"amount": added
			}
			remaining_amount -= added
			
			if remaining_amount <= 0:
				break
	
	update_signals()
	updatev.emit()

func drop_item(slot_index: int, amount: int = 1) -> void:
	$"../Audio/ActionsAudioPlayer3D".audio_play(R.sounds["actions"]["pickup"].resource_path)
	if slot_index < 0 or slot_index >= MAX_SLOTS+1: return
	
	var slot = inventory[slot_index]
	if slot:
		if slot["amount"] > amount:
			slot["amount"] -= amount
		else:
			inventory[slot_index] = null # Удаляем предмет полностью
		
		update_signals()
		updatev.emit()
