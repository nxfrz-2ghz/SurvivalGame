extends Node

signal take_damage(dmg: float)
signal heal(health: float)
signal changed(current_hunger: float)

const HUNGER_DAMAGE := 0.08
const HUNGER_SPEED := 2
const MAX_HUNGER := 1000
var current_hunger := MAX_HUNGER

func eat(hng: int) -> void:
	if current_hunger < MAX_HUNGER:
		current_hunger += hng
	else:
		heal.emit(float(hng)/50) # heal if overeating
	current_hunger = clamp(current_hunger, 0, MAX_HUNGER)
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
			G.text_message.add("I'm very hungry")
	
	else:
		take_damage.emit(HUNGER_DAMAGE)

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
	
	# Heal
	@warning_ignore("integer_division")
	if G.player and current_hunger >= MAX_HUNGER/10*8 and G.player.health.current_health < G.player.health.max_health:
		heal.emit(G.player.health.max_health/100)
		take_hunger(HUNGER_SPEED * 3)

func on_attack() -> void:
	take_hunger(HUNGER_SPEED * 5)
