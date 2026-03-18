extends Node

# NOTES
const notes := {
	
}

var unlocked_notes := []

# EXPERIENCE
const lvlup_cost := 10.0
var lvl: int = 0
var cur_exp: float = 0.0

func add_exp(added_exp: float) -> void:
	cur_exp += added_exp
	
	var cur_lvlup_cost: float = lvlup_cost + lvlup_cost * lvl/2
	if cur_exp > cur_lvlup_cost:
		cur_exp -= cur_lvlup_cost
		lvl += 1
		G.text_message.add("NEW LEVEL REACHED!")
