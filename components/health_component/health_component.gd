extends Node

signal changed(current: float, max: float, last: float)
signal on_damage
signal died

@export var resists := {
	"melee": 1.0
}

@export var max_health: float = 1.0:
	set(value):
		max_health = round(value * 100) / 100.0
@export var current_health: float:
	set(value):
		current_health = round(value * 100) / 100.0
@export var armor: float

var last_health: float


func _ready() -> void:
	current_health = max_health


func heal(health: float) -> void:
	last_health = current_health
	
	current_health += health
	if current_health > max_health:
		current_health = max_health
	changed.emit(current_health, max_health, last_health)


@rpc("any_peer", "call_local")
func take_damage(base_damage: float, incoming_types: Dictionary = {"melee": 1.0}) -> void:
	last_health = current_health
	
	var total_damage = 0.0
	for type in incoming_types:
		var multiplier = incoming_types[type]
		# Берем сопротивление моба к этому типу (по умолчанию 1.0, если не указано)
		var resistance: float = resists.get(type, 1.0) 
		total_damage += base_damage * multiplier * resistance
	
	total_damage -= armor
	
	if total_damage > 0.0:
		current_health -= total_damage
		if current_health < 0:
			current_health = 0
		changed.emit(current_health, max_health, last_health)
		on_damage.emit()
	
	# Ачивка ваншота, если хп >= 10
	if last_health == max_health and last_health >= R.dmg_to_get_ach_ultrakill and current_health <= 0.0:
		G.player.progress_controller.add_achievement("ACH_7")
	
	if current_health <= 0:
		died.emit()


func alive() -> bool:
	return current_health > 0
