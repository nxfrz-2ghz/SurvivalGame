extends Node

signal take_damage(dmg: float)
signal heal(health: float)
signal changed(current_hunger: float)

const HUNGER_DAMAGE := 0.1
const HUNGER_SPEED := 1
const MAX_HUNGER := 1000
var current_hunger := MAX_HUNGER

func eat(hng: int) -> void:
	if current_hunger < MAX_HUNGER:
		current_hunger += hng
	else:
		heal.emit(float(hng)/50) # heal if overeating
		current_hunger = MAX_HUNGER
	changed.emit(current_hunger)
	
func take_hunger(hng: int) -> void:
	if current_hunger > 0:
		current_hunger -= hng
		changed.emit(current_hunger)
		
		@warning_ignore("integer_division")
		if current_hunger == MAX_HUNGER/2:
			G.text_message.add("I'm a little hungy")
		@warning_ignore("integer_division")
		if current_hunger == MAX_HUNGER/4:
			G.text_message.add("I'm very hungy")
		
	else:
		take_damage.emit(HUNGER_DAMAGE)
		G.text_message.add("I'm dying of hunger")

func _on_timer_timeout() -> void:
	if G.state_machine != "game": return
	take_hunger(HUNGER_SPEED)
	
	if Input.is_action_pressed("space"):
		take_hunger(HUNGER_SPEED)
	if Input.is_action_pressed("shift"):
		take_hunger(HUNGER_SPEED)
	if Input.is_action_pressed("up"):
		take_hunger(HUNGER_SPEED)
	if Input.is_action_pressed("down"):
		take_hunger(HUNGER_SPEED)
	if Input.is_action_pressed("left"):
		take_hunger(HUNGER_SPEED)
	if Input.is_action_pressed("right"):
		take_hunger(HUNGER_SPEED)

func on_attack() -> void:
	take_hunger(HUNGER_SPEED * 5)
