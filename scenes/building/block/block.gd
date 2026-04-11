extends "res://scenes/building/building.gd"

enum State { FULL }

const BLOCK_MESHES := {
	State.FULL : preload("res://scenes/building/block/_meshes/full_box.tres"),
}

const BLOCK_SHAPES := {
	State.FULL : preload("res://scenes/building/block/_shapes/full_box.tres"),
}

@export var state: State = State.FULL:
	set(value):
		state = value
		if is_node_ready(): _update_state()

func _ready() -> void:
	super()
	_update_state()

func _update_state() -> void:
	mesh.mesh = BLOCK_MESHES[state]
	collision.shape = BLOCK_SHAPES[state]

@rpc("any_peer", "call_local")
func change_state() -> void:
	if not is_multiplayer_authority(): return
	
#	if state == State.WALL:
#		state = State.DOOR
#	elif state == State.DOOR:
#		state = State.DESCENT
#	elif state == State.DESCENT:
#		state = State.WALL
