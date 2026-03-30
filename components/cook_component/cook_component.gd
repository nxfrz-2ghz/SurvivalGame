extends Node

@export var cook_category: String

@onready var parent := get_parent()
@onready var toogle_on := $"../ToggleOn"
@onready var craft_timer := $"../Timers/CraftTimer"
@onready var fuel_timer := $"../Timers/FuelTimer"
@onready var label := $"../Label3D"

@export var fuel_type := "log"

# Синхронизируется на всякий случай, щас пока надо, чтобы у клиента была возможность забирать правильный complete
@export var fuel := 0
@export var queue: Array = []
@export var complete: Array = []

func _ready() -> void:
	craft_timer.timeout.connect(_on_craft_timer_timeout)
	fuel_timer.timeout.connect(_on_fuel_timer_timeout)

func drop_queue() -> void:
	for item in queue: parent.entity.drop(item)
	for item in complete: parent.entity.drop(item)
	for i in range(fuel): parent.entity.drop(fuel_type)
	queue.clear()
	complete.clear()
	fuel = 0
	update_label.rpc(queue, complete, fuel)

func toggle() -> void:
	toogle_on.visible = !toogle_on.visible
	parent.sprite.visible = !parent.sprite.visible
	parent.shadow.visible = !parent.shadow.visible
	$"../SmokeParticle".emitting = !$"../SmokeParticle".emitting

func start_cook() -> void:
	if queue.is_empty(): return
	# Берем первый элемент очереди для получения времени
	var item_name = queue[0]
	craft_timer.wait_time = R.exchangeable_items[cook_category][item_name]["speed"]
	craft_timer.start()

@rpc("any_peer", "call_local")
func craft(input: String):
	queue.append(input)
	update_label.rpc(queue, complete, fuel)
	if fuel and craft_timer.is_stopped(): start_cook()

@rpc("any_peer", "call_local")
func add_fuel() -> void:
	if fuel == 0:
		toggle()
	fuel += 1
	update_label.rpc(queue, complete, fuel)
	fuel_timer.start()
	
	# Продолжение плавки
	if !queue.is_empty(): start_cook()

@rpc("any_peer", "call_local")
func pick() -> void:
	complete = []
	update_label.rpc(queue, complete, fuel)

@rpc("authority", "call_local")
func update_label(_queue: Array, _complete: Array, _fuel: int) -> void:
	var q_text := ""
	var c_text := ""
	
	var q_list := {}
	var c_list := {}
	
	for i in _queue: q_list[i] = q_list.get(i, 0) + 1
	for i in _complete: c_list[i] = c_list.get(i, 0) + 1
	
	for i in q_list.keys():
		q_text += "\n" + i + ((": x" + str(q_list[i])) if q_list[i] > 1 else "")
	
	for i in c_list.keys():
		c_text += "\n" + i + ((": x" + str(c_list[i])) if c_list[i] > 1 else "")
	
	label.text = "Fuel: %d\nQueue: %s\nComplete: %s" % [_fuel, q_text, c_text]

func _on_craft_timer_timeout() -> void:
	complete.append(R.exchangeable_items[parent.nname].get(queue.pop_front())["output"])
	update_label.rpc(queue, complete, fuel)
	
	# Продолжение плавки
	if !queue.is_empty(): start_cook()

func _on_fuel_timer_timeout() -> void:
	fuel -= 1
	update_label.rpc(queue, complete, fuel)
	if fuel > 0:
		fuel_timer.start()
	else:
		toggle()
		craft_timer.stop()
