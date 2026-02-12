extends Node

signal changed()
signal died

@export var resists := {}

@export var max_health: float = 1.0
@export var current_health: float


func _ready() -> void:
	current_health = max_health


func take_damage(base_damage: float, incoming_types: Dictionary):
	var total_damage = 0.0
	for type in incoming_types:
		var multiplier = incoming_types[type]
		# Берем сопротивление моба к этому типу (по умолчанию 1.0, если не указано)
		var resistance: float = resists.get(type, 1.0) 
		total_damage += base_damage * multiplier * resistance
	
	if total_damage > 0.0:
		current_health -= total_damage
		changed.emit()
	
	if current_health <= 0:
		died.emit()


func alive() -> bool:
	return current_health > 0
