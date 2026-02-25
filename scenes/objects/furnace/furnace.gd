extends "res://scenes/objects/object.gd"

@onready var toogle_on := $ToggleOn
@onready var craft_timer := $Timers/CraftTimer

var queue: Array = []


func _ready() -> void:
	super()
	health.died.connect(drop_queue)


func drop_queue() -> void:
	while !queue.is_empty():
		drop(queue.pop_front())


func toggle() -> void:
	toogle_on.visible = !toogle_on.visible
	sprite.visible = !sprite.visible
	$Shadow.visible = !$Shadow.visible
	$SmokeParticle.emitting = !$SmokeParticle.emitting


@rpc("any_peer", "call_local")
func craft(input: String):
	queue.append(input)
	if craft_timer.is_stopped():
		craft_timer.start()
		toggle()


func _on_craft_timer_timeout() -> void:
	toggle()
	drop(R.furnace_items.get(queue.pop_front())["output"])
	
	# Продолжение плавки
	if !queue.is_empty():
		craft_timer.start()
		toggle()
