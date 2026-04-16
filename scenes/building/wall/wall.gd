extends "res://scenes/building/building.gd"

enum State { WALL, DOOR, DESCENT }

const WALL_MESHES := {
	State.WALL : preload("res://scenes/building/wall/_meshes/wall_mesh.tres"),
	State.DOOR: preload("res://scenes/building/wall/_meshes/door_mesh.tres"),
	State.DESCENT: preload("res://scenes/building/wall/_meshes/descent_mesh.tres"),
}

const WALL_SHAPES := {
	State.WALL : preload("res://scenes/building/wall/_shapes/wall_shape.tres"),
	State.DOOR: preload("res://scenes/building/wall/_shapes/door_shape.tres"),
	State.DESCENT: preload("res://scenes/building/wall/_shapes/descent_shape.tres"),
}

@export var state: State = State.WALL:
	set(value):
		state = value
		if is_node_ready(): _update_state()

func _ready() -> void:
	super()
	_update_state()

func _update_state() -> void:
	mesh.mesh = WALL_MESHES[state]
	collision.shape = WALL_SHAPES[state]

@rpc("any_peer", "call_local")
func change_state() -> void:
	if not is_multiplayer_authority(): return
	
	# Следующий state по порядку
	state = (state + 1) % State.size() as State
