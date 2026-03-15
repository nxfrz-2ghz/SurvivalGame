extends Node

@export var cook_category: String

@onready var parent := get_parent()
@onready var toogle_on := $"../ToggleOn"
@onready var craft_timer := $"../Timers/CraftTimer"
@onready var fuel_timer := $"../Timers/FuelTimer"

@export var fuel_type := "log"

var fuel := 0
var queue: Array = []

func _ready() -> void:
	craft_timer.timeout.connect(_on_craft_timer_timeout)

func drop_queue() -> void:
	while !queue.is_empty():
		parent.drop(queue.pop_front())
	while fuel > 0:
		parent.drop(fuel_type)
		fuel -= 1

func toggle() -> void:
	toogle_on.visible = !toogle_on.visible
	parent.sprite.visible = !parent.sprite.visible
	parent.shadow.visible = !parent.shadow.visible
	$"../SmokeParticle".emitting = !$"../SmokeParticle".emitting

@rpc("any_peer", "call_local")
func craft(input: String):
	queue.append(input)
	if fuel and craft_timer.is_stopped(): start_cook()

@rpc("any_peer", "call_local")
func add_fuel() -> void:
	if fuel == 0:
		toggle()
	fuel += 1
	if !queue.is_empty() and craft_timer.is_stopped():
		fuel_timer.start()

func start_cook() -> void:
	craft_timer.wait_time = R.exchangeable_items[cook_category][queue.max()]["speed"]
	craft_timer.start()

func _on_craft_timer_timeout() -> void:
	parent.drop(R.exchangeable_items[parent.nname].get(queue.pop_front())["output"])
	
	# Продолжение плавки
	if !queue.is_empty(): start_cook()

func _on_fuel_timer_timeout() -> void:
	fuel -= 1
	if fuel == 0:
		toggle()
		craft_timer.stop()
