extends Node

@export var craft_category: String

@onready var parent := get_parent()
@onready var toogle_on := $"../ToggleOn"
@onready var craft_timer := $"../Timers/CraftTimer"

var queue: Array = []

func _ready() -> void:
	craft_timer.timeout.connect(_on_craft_timer_timeout)

func drop_queue() -> void:
	while !queue.is_empty():
		parent.drop(queue.pop_front())

func toggle() -> void:
	toogle_on.visible = !toogle_on.visible
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
	if craft_timer.is_stopped(): start_craft()

func _on_craft_timer_timeout() -> void:
	toggle()
	parent.drop(R.exchangeable_items[craft_category].get(queue.pop_front())["output"])
	
	# Продолжение плавки
	if !queue.is_empty(): start_craft()
