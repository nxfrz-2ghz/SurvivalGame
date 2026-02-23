extends Node

signal hunger_damage(dmg: float)
signal changed(current_hunger: float)

const HUNGER_DAMAGE := 0.1
const HUNGER_SPEED := 2
const MAX_HUNGER := 1000
var current_hunger := MAX_HUNGER

func eat(hng: int) -> void:
	if current_hunger < MAX_HUNGER:
		current_hunger += hng
	else:
		hunger_damage.emit(-(current_hunger + hng - MAX_HUNGER)/10) # eal if over eating
		current_hunger = MAX_HUNGER
	changed.emit(current_hunger, MAX_HUNGER)

func take_hunger(hng: int) -> void:
	if current_hunger > 0:
		current_hunger -= hng
		changed.emit(current_hunger, MAX_HUNGER)
	else:
		hunger_damage.emit(HUNGER_DAMAGE)

func _on_timer_timeout() -> void:
	take_hunger(HUNGER_SPEED)

func on_attack() -> void:
	take_hunger(HUNGER_SPEED * 5)

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("space"):
		take_hunger(HUNGER_SPEED * 3)
