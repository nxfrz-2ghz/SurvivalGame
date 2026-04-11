extends Node3D

signal effect_changed(stage: int)

const distance := 50.0

const nodes_affect := {
	"campfire": 2,
	"heart": -1,
}

var max_fear: int = 1000
var current_fear: int = 0
var current_stage: int


func apply_change(node: Node) -> void:
	var node_name: String = node.nname
	
	# Список игнорирования с условиями
	if node_name == "campfire" and !node.cook.toggle_on.visible: return
	
	# Применение эффекта
	if node_name in nodes_affect:
		current_fear -= nodes_affect[node_name]


func _on_timer_one_second_timeout() -> void:
	if G.state_machine != "game": return
	var last_fear := current_fear
	var nodes := get_tree().get_nodes_in_group("can_affect_fear")
	
	for node in nodes:
		# Отбрасываем дальние узлы
		var dist: float = self.global_position.distance_to(node.global_position)
		
		# Исключаем дальние узлы
		if dist > distance:
			continue
		# Применяем дальние узлы
		elif dist > distance / 2:
			apply_change(node)
		# Применяем ближние узлы в 2 раза сильнее
		else:
			apply_change(node)
			apply_change(node)
	
	current_fear = clampi(current_fear, 0, max_fear)
	
	# Всего 5 стадий
	current_stage = int(float(current_fear)/200)
	var last_stage: int = int(float(last_fear)/200)
	
	if current_stage != last_stage:
		effect_changed.emit(current_stage)
