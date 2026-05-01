extends MarginContainer

@onready var choose_slot := $PanelContainer/MarginContainer/Node2D
@onready var slot := [
	$PanelContainer/MarginContainer/HBoxContainer/Slot1,
	$PanelContainer/MarginContainer/HBoxContainer/Slot2,
	$PanelContainer/MarginContainer/HBoxContainer/Slot3,
	$PanelContainer/MarginContainer/HBoxContainer/Slot4,
	$PanelContainer/MarginContainer/HBoxContainer/Slot5,
	$PanelContainer/MarginContainer/HBoxContainer/Slot6,
	$PanelContainer/MarginContainer/HBoxContainer/Slot7,
	$PanelContainer/MarginContainer/HBoxContainer/Slot8,
	$PanelContainer/MarginContainer/HBoxContainer/Slot9,
	$PanelContainer/MarginContainer/HBoxContainer/Slot10,
	$PanelContainer/MarginContainer/HBoxContainer/Slot11,
	$PanelContainer/MarginContainer/HBoxContainer/Slot12,
]
@onready var left_slot := $PanelContainer/MarginContainer/HBoxContainer/LeftSlot


func set_hotbar_slot(pos: int) -> void:
	choose_slot.global_position = slot[pos].global_position

func set_left_arm_slot(item: Dictionary) -> void:
	var label = left_slot.get_node("Label")
	if item == {}:
		left_slot.texture = R.items["empty"]["texture"]
		label.text = ""
		label.hide()
	else:
		left_slot.texture = R.items[item["name"]]["texture"]
		label.text = str(item["amount"]) if item["amount"] > 1 else ""
		label.show()


func update(inventory: Dictionary) -> void:
	show()
	for i in range(12):
		var item_data = inventory.get(i) # Получаем данные слота (может быть null)
		var current_slot = slot[i]
		var label = current_slot.get_node("Label")

		if item_data != null:
			# Если в слоте есть предмет
			current_slot.texture = R.items[item_data["name"]]["texture"]
			label.text = str(item_data["amount"]) if item_data["amount"] > 1 else ""
			label.show()
		else:
			# Если слот пустой — очищаем визуализацию
			current_slot.texture = R.items["empty"]["texture"]
			label.text = ""
			label.hide()
