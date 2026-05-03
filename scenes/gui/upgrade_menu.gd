extends Node

@onready var lvls := {
	"container": [
		$MarginContainer/VBoxContainer/HBoxContainer4,
		$MarginContainer/VBoxContainer/HBoxContainer3,
		$MarginContainer/VBoxContainer/HBoxContainer2,
		$MarginContainer/VBoxContainer/HBoxContainer,
	],
	"unlock_button": [
		$MarginContainer/VBoxContainer/HBoxContainer4/VBoxContainer/Button,
		$MarginContainer/VBoxContainer/HBoxContainer3/VBoxContainer/Button,
		$MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer/Button,
		$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Button,
	],
}

const unlock_cost := {
	"raw_berries": 10,
	"stone": 30,
	"copper_block": 8,
	"blood": 15,
}

const lvls_amount: int = 4

const upgrades := [
	{
		"UPGR_TBL-0-0": 10,
		"UPGR_TBL-0-1": 10,
		"UPGR_TBL-0-2": 1,
	},
	{
		"UPGR_TBL-1-0": 10,
		"UPGR_TBL-1-1": 10,
		"UPGR_TBL-1-2": 1,
	},
	{
		"UPGR_TBL-2-0": 10,
		"UPGR_TBL-2-1": 10,
		"UPGR_TBL-2-2": 1,
	},
	{
		"UPGR_TBL-3-0": 10,
		"UPGR_TBL-3-1": 10,
		"UPGR_TBL-3-2": 1,
	},
]

var unlocked_lvls := [
	false,
	false,
	false,
	false,
]

var unlocked_upgrades := {
	"UPGR_TBL-0-0": 0,
	"UPGR_TBL-0-1": 0,
	"UPGR_TBL-0-2": 0,
	"UPGR_TBL-1-0": 0,
	"UPGR_TBL-1-1": 0,
	"UPGR_TBL-1-2": 0,
	"UPGR_TBL-2-0": 0,
	"UPGR_TBL-2-1": 0,
	"UPGR_TBL-2-2": 0,
	"UPGR_TBL-3-0": 0,
	"UPGR_TBL-3-1": 0,
	"UPGR_TBL-3-2": 0,
}


func _ready() -> void:
	G.upgrade_manager = self
	
	# Connecting signals
	for i in range(0, lvls_amount):
		lvls["unlock_button"][i].ppressed.connect(on_id_button_pressed)
	
	# Add cost
	for i in range(0, lvls_amount):
		lvls["unlock_button"][i].text = "unlock: " + unlock_cost.keys()[i] + " " + str(unlock_cost.values()[i])


func clear() -> void:
	for container in lvls["container"]:
		for child in container.get_children():
			if child is VBoxContainer: continue
			child.queue_free()


func show_upgrades_on_lvls() -> void:
	clear()
	for lvl in range(0, lvls_amount):
		if unlocked_lvls[lvl]: # if unlocked
			for upgr in upgrades[lvl].keys():
				var btn := id_button.new()
				btn.text = tr(upgr) + " (" + str(int(unlocked_upgrades.get(upgr, 0))) + "/" + str(int(upgrades[lvl][upgr])) + ")"
				btn.id = upgr
				btn.ppressed.connect(on_id_button_pressed)
				lvls["container"][lvl].add_child(btn)
				
				if unlocked_upgrades.get(upgr, 0) >= upgrades[lvl][upgr]:
					btn.disabled = true
					btn.text = tr(upgr) + " (MAX)"



func on_id_button_pressed(id: String) -> void:
	
	# Unlock upgrade
	for upgr_lvl in upgrades:
		if id in upgr_lvl.keys():
			unlocked_upgrades[id] += 1
			show_upgrades_on_lvls()
	
	# Unlock lvl
	if "unlock_lvl" in id:
		var lvl := int(id[-1])
		var item_name: String = unlock_cost.keys()[lvl]
		var item_amount: int = unlock_cost.values()[lvl]
		var inv: Node = G.player.inv
		
		if inv.get_item_amount(item_name) >= item_amount:
			lvls["unlock_button"][lvl].text = "🔓 UNLOCKED!"
			unlocked_lvls[lvl] = true
			show_upgrades_on_lvls()
			inv.drop_item(inv.get_item_index(item_name), item_amount)
