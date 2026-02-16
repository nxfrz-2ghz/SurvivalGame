extends RayCast3D
class_name InteractRay # Позволяет добавлять этот узел через поиск

# Сигнал, на который будет подписываться HUD или другой интерфейс
signal target_found(node_name: String)

var current_target: Node = null
var last_target: Node = null


func update() -> void:
	last_target = current_target
	# Если нашли объект — шлем имя, если нет — пустую строку
	var target_name = ""
	if current_target:
		target_name = current_target.nname 
		if current_target.is_in_group("objects") or current_target.is_in_group("players"):
			target_name += "\n" + str(current_target.health.current_health) + "/" + str(current_target.health.max_health)
		if current_target.is_in_group("items"):
			target_name += "\nPRESS [F] TO PICKUP"
	target_found.emit(target_name)


func _physics_process(_delta) -> void:
	current_target = get_collider() if is_colliding() else null
	if current_target != last_target:
		update()
