extends Node

signal update(items: Dictionary)
signal set_hotbar_slot(pos: int)
signal set_item_in_arm(item: String)

const MAX_SLOTS = 10

# Структура предмета в слоте: {"name": String, "type": String, "amount": int}
var inventory: Dictionary = {}
var current_item := 1


func _ready():
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
	
	
	if Input.is_action_pressed("up_mouse_wheel"):
		current_item -= 1
		if current_item < 1:
			current_item += 10
		update_signals()
	
	if Input.is_action_pressed("down_mouse_wheel"):
		current_item += 1
		if current_item > 10:
			current_item -= 10
		update_signals()

### --- ОСНОВНЫЕ ФУНКЦИИ ---

func add_item(item_name: String, amount: int = 1):
	var remaining_amount = amount
	var max_s = R.items[item_name].get("stack_size", 1) # По умолчанию стак 1

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

func drop_item(slot_index: int, amount: int = 1):
	if slot_index < 0 or slot_index >= MAX_SLOTS: return
	
	var slot = inventory[slot_index]
	if slot:
		if slot["amount"] > amount:
			slot["amount"] -= amount
		else:
			inventory[slot_index] = null # Удаляем предмет полностью
		
		update_signals()
