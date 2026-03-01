extends Node

@export var cook_category: String

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


@rpc("any_peer", "call_local")
func craft(input: String):
	queue.append(input)
	if craft_timer.is_stopped():
		craft_timer.start()
		toggle()


func _on_craft_timer_timeout() -> void:
	toggle()
	parent.drop(R.exchangeable_items["campfire"].get(queue.pop_front())["output"])
	
	# Продолжение плавки
	if !queue.is_empty():
		craft_timer.start()
		toggle()
