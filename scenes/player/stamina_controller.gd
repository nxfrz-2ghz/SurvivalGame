extends Node

signal changed(current: float, maximum: float)

var MAX_ENERGY: int = 1000
var energy := MAX_ENERGY

func is_moving() -> bool:
	if Input.is_action_pressed("up") or\
	Input.is_action_pressed("down") or\
	Input.is_action_pressed("left") or\
	Input.is_action_pressed("right"):
		return true
	else:
		return false

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	if S.state_machine != "game": return
	
	if Input.is_action_pressed("shift") and is_moving():
		energy -= 5
	else:
		if is_moving():
			energy += 1
		else:
			energy += 3
	
	if energy < 0:
		energy = 0
	if energy > MAX_ENERGY:
		energy = MAX_ENERGY
	else:
		changed.emit(energy, MAX_ENERGY)
