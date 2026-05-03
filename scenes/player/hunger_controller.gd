extends Node

signal take_damage(dmg: float, ignore_armor: bool)
signal heal(health: float)
signal changed(current_hunger: float)

const HUNGER_DAMAGE := 0.5
const HUNGER_SPEED := 1.2
const MAX_HUNGER := 800.0
var current_hunger := MAX_HUNGER

func _ready() -> void:
	G.timer_1sec.timeout.connect(_on_timer_timeout)

func eat(hng: float) -> void:
	if current_hunger < MAX_HUNGER:
		current_hunger += hng
	else:
		heal.emit(float(hng)/10) # heal if overeating
	changed.emit(current_hunger)
	
func take_hunger(hng: float) -> void:
	if current_hunger > 0:
		current_hunger -= hng
		changed.emit(current_hunger)
		
		if current_hunger == MAX_HUNGER/2:
			G.text_message.add(tr("RPL_LITTLE_HUNGER"))
		if current_hunger == MAX_HUNGER/4:
			G.text_message.add(tr("RPL_BIG_HUNGER"))
	
	else:
		take_damage.emit(HUNGER_DAMAGE, true)

func _on_timer_timeout() -> void:
	if S.state_machine != "game": return
	
	var hs := HUNGER_SPEED
	var hng_upgrs: int = G.upgrade_manager.unlocked_upgrades["UPGR_TBL-0-0"]
	if hng_upgrs > 0: hs /= hng_upgrs*1.6
	
	take_hunger(hs)
	
	if Input.is_action_pressed("space"):
		take_hunger(hs)
	if Input.is_action_pressed("shift"):
		take_hunger(hs)
	if Input.is_action_pressed("up"):
		take_hunger(hs)
	if Input.is_action_pressed("down"):
		take_hunger(hs)
	if Input.is_action_pressed("left"):
		take_hunger(hs)
	if Input.is_action_pressed("right"):
		take_hunger(hs)
	
	if G.player:
		# Heal
		@warning_ignore("integer_division")
		if G.player and current_hunger >= MAX_HUNGER/10*8 and G.player.health.current_health < G.player.health.max_health:
			heal.emit(G.player.health.max_health/100)
			take_hunger(HUNGER_SPEED * 3)
		
		if !G.player.progress_controller.unlocked_notes.has("NTV_3") and current_hunger <= MAX_HUNGER/2:
			G.player.progress_controller.add_note("NTK_3")
		
		if G.player.state == G.player.STATE.SLEEP:
			take_hunger(hs * 100)

func on_attack() -> void:
	take_hunger(HUNGER_SPEED * 5)
