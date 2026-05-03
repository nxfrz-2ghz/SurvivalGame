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


@rpc("any_peer", "call_local")
func vampirism(total_health: float) -> void:
	heal(total_health/30 * G.upgrade_manager.unlocked_upgrades["UPGR_TBL-2-0"])


func heal(health: float) -> void:
	last_health = current_health
	
	current_health += health
	if current_health > max_health:
		current_health = max_health
	changed.emit(current_health, max_health, last_health)


@rpc("any_peer", "call_local")
func take_damage(base_damage: float, ignore_armor := false, remote_peer := 0, incoming_types: Dictionary = {"melee": 1.0}) -> void:
	last_health = current_health
	
	var total_damage = 0.0
	for type in incoming_types:
		var multiplier = incoming_types[type]
		# Берем сопротивление моба к этому типу (по умолчанию 1.0, если не указано)
		var resistance: float = resists.get(type, 1.0) 
		total_damage += base_damage * multiplier * resistance
	
	total_damage -= armor
	
	if ignore_armor:
		total_damage = base_damage
	
	if total_damage > 0.0:
		current_health -= total_damage
		if current_health < 0:
			current_health = 0
		changed.emit(current_health, max_health, last_health)
		on_damage.emit()
	
	# Если это игрок а не моб
	if remote_peer != 0:
		
		# Ачивка ваншота, если хп >= 10
		if last_health == max_health and last_health >= S.dmg_to_get_ach_ultrakill and current_health <= 0.0:
			G.player.progress_controller.add_achievement.rpc_id(remote_peer, "ACH_7")
		
		# Возвращение оповещения о нанесении урона
		if total_damage > 0.0:
			G.player.health.vampirism.rpc_id(remote_peer, total_damage)
	
	if current_health <= 0:
		died.emit()


func alive() -> bool:
	return current_health > 0
