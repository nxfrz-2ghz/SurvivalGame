extends "res://scenes/objects/object.gd"

@onready var full_sprite := $FullSprite3D
@onready var grow_timer := $Timers/GrowUp
@export var full: bool = true

func _ready() -> void:
	toggle(full)
	if not is_multiplayer_authority(): return
	super()
	grow_timer.start()

@rpc("authority", "call_local")
func toggle(on: bool) -> void:
	full = on
	sprite.visible = !on
	full_sprite.visible = on

@rpc("any_peer", "call_local")
func pick() -> void:
	take_damage_audio.play()
	if full:
		toggle.rpc(false)
		grow_timer.wait_time = randi_range(30, 150)
		grow_timer.start()

func _on_grow_up_timeout() -> void:
	toggle.rpc(true)
