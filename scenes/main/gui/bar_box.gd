extends VBoxContainer

@onready var exp_bar := $ExpBar
@onready var lvl_label := $ExpBar/RichTextLabel

func exp_changed(cur: float, max_exp: float, lvl: int) -> void:
	exp_bar.value = cur / max_exp
	lvl_label.text = "[fade] Lvl: " + str(lvl) 

@onready var hunger_bar := $HungerBar

func hunger_changed(cur: float) -> void:
	hunger_bar.value = cur
