extends Node

signal changed(cur_exp: float, max_exp: float, cur_lvl: int)

@onready var audio_player := $AudioStreamPlayer

const new_note := preload("res://res/sounds/actions/new_note.mp3")
const new_achievement := preload("res://res/sounds/actions/new_achievement.mp3")

# NOTES
const notes := {
	"NTK_1": "NTV_1",
	"NTK_2": "NTV_2",
	"NTK_3": "NTV_3",
	"NTK_4": "NTV_4",
	"NTK_5": "NTV_5",
	"NTK_6": "NTV_6",
	"NTK_7": "NTV_7",
	"NTK_8": "NTV_8",
	"NTK_9": "NTV_9",
	"NTK_10": "NTV_10",
	"NTK_11": "NTV_11",
	"NTK_12": "NTV_12",
	"NTK_13": "NTV_13",
	"NTK_14": "NTV_14",
}

var unlocked_notes := []

func add_note(note_name: String) -> void:
	unlocked_notes.append(notes[note_name])
	G.text_message.add(tr("RPL_NEW_NOTE"))
	audio_player.stream = new_note
	audio_player.play()

func _ready() -> void:
	G.time_controller.day_come.connect(_on_day_come)
	G.time_controller.night_come.connect(_on_night_come)

func _on_day_come() -> void:
	if !unlocked_notes.has(notes["NTK_4"]):
		add_note("NTK_4")
func _on_night_come() -> void:
	if !unlocked_notes.has(notes["NTK_3"]):
		add_note("NTK_3")

# ACHIEVEMENTS
const achievements := [
	"ACH_1",
	"ACH_2",
	"ACH_3",
	"ACH_4",
	"ACH_5",
	"ACH_6",
	"ACH_7",
	"ACH_8",
	"ACH_9",
]

const show_achievement_cost := 1

var unlocked_achievements := []
var completed_achievements := []

func show_achievement(ach_name: String) -> bool:
	if spend_exp_by_lvl(show_achievement_cost + unlocked_achievements.size()):
		unlocked_achievements.append(ach_name)
		return true
	else:
		return false

@rpc("any_peer", "call_local")
func add_achievement(ach_name: String) -> void:
	if completed_achievements.has(ach_name): return
	unlocked_achievements.append(ach_name)
	completed_achievements.append(ach_name)
	G.text_message.add(tr("RPL_NEW_ACHIEVEMENT"))
	audio_player.stream = new_achievement
	audio_player.play()


# EXPERIENCE
const lvlup_cost := 6.0
var lvl: int = 0
var cur_exp: float = 0.0

func add_exp(added_exp: float) -> void:
	cur_exp += added_exp
	
	if cur_exp > get_lvlup_cost():
		cur_exp -= get_lvlup_cost()
		lvl += 1
		G.text_message.add(tr("RPL_NEW_LVL"))
	
	changed.emit(cur_exp, get_lvlup_cost(), lvl)

func spend_exp_by_lvl(levels_to_spend: int) -> bool:
	if lvl >= levels_to_spend:
		# Вычитаем уровни
		lvl -= levels_to_spend
		
		# Конвертируем избытки опыта в уровни
		if cur_exp > get_lvlup_cost():
			cur_exp -= get_lvlup_cost()
			lvl += 1
		
		changed.emit(cur_exp, get_lvlup_cost(), lvl)
		
		return true # Успешно потрачено
	
	return false # Недостаточно ресурсов

func get_lvlup_cost() -> float:
	return lvlup_cost + (lvlup_cost * lvl / 2.0)
