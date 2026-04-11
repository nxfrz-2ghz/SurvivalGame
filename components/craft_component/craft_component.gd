extends Node

@export var craft_category: String

@onready var parent := get_parent()
@onready var toggle_on := $"../ToggleOn"
@onready var craft_timer := $"../Timers/CraftTimer"
@onready var label := $"../Label3D"

# Синхронизируется на всякий случай, щас пока надо, чтобы у клиента была возможность забирать правильный complete
@export var queue: Array = []
@export var complete: Array = []

func _ready() -> void:
	if not is_multiplayer_authority(): return
	craft_timer.timeout.connect(_on_craft_timer_timeout)
	
	await parent.ready
	if queue: start_craft()
	update_label.rpc(queue, complete)

func drop_queue() -> void:
	for item in queue: parent.enity.drop(item)
	for item in complete: parent.entity.drop(item)
	queue.clear()
	complete.clear()
	update_label.rpc(queue, complete)

func toggle() -> void:
	toggle_on.visible = !toggle_on.visible
	parent.sprite.visible = !parent.sprite.visible
	parent.shadow.visible = !parent.shadow.visible
	$"../SmokeParticle".emitting = !$"../SmokeParticle".emitting

func start_craft() -> void:
	toggle()
	craft_timer.wait_time = R.exchangeable_items[craft_category][queue.max()]["speed"]
	craft_timer.start()

@rpc("any_peer", "call_local")
func craft(input: String):
	queue.append(input)
	update_label.rpc(queue, complete)
	if craft_timer.is_stopped(): start_craft()

@rpc("any_peer", "call_local")
func pick() -> void:
	complete = []
	update_label.rpc(queue, complete)

@rpc("authority", "call_local")
func update_label(_queue: Array, _complete: Array) -> void:
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
	
	label.text = "Queue: %s\nComplete: %s" % [q_text, c_text]

func _on_craft_timer_timeout() -> void:
	toggle()
	complete.append(R.exchangeable_items[parent.nname].get(queue.pop_front())["output"])
	update_label.rpc(queue, complete)
	
	# Продолжение плавки
	if !queue.is_empty(): start_craft()
