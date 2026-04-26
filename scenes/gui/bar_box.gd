extends VBoxContainer

@onready var exp_bar := $ExpBar
@onready var lvl_label := $ExpBar/RichTextLabel

func exp_changed(cur: float, max_exp: float, lvl: int) -> void:
	exp_bar.value = cur / max_exp
	lvl_label.text = "[fade] Lvl: " + str(lvl) 

@onready var hunger_bar := $HungerBar

func hunger_changed(cur: float) -> void:
	hunger_bar.value = cur

@onready var temp_bar := $TempBar
@onready var temp_texture_rect := $TempBar/TextureRect
@onready var text_label := $TempBar/RichTextLabel
const temp_texture := [
	preload("res://res/sprites/gui/temp/low_temp.png"),
	preload("res://res/sprites/gui/temp/norm_temp.png"),
	preload("res://res/sprites/gui/temp/high_temp.png"),
]

func temp_changed(cur: float, maxx: float) -> void:
	temp_bar.value = (cur + maxx)
	temp_bar.max_value = maxx * 2
	text_label.text = ""
	
	if temp_bar.value < temp_bar.max_value/4:
		temp_texture_rect.texture = temp_texture[0]
		text_label.text += "[shake rate=6 level=1]"
	elif temp_bar.value > temp_bar.max_value - temp_bar.max_value/4:
		temp_texture_rect.texture = temp_texture[2]
		text_label.text += "[wave rate=6 level=1][pulse]"
	else:
		temp_texture_rect.texture = temp_texture[1]
	
	text_label.text += str(int(cur))
