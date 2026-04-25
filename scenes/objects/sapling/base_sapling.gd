extends "res://scenes/objects/object.gd"

@export var tree: PackedScene
@export var grow_state: int = 0
@export var max_grow_state: int = 10


func _on_grow_timer_timeout() -> void:
	if S.state_machine != "game": return
	if not is_multiplayer_authority(): return
	grow_state += 1
	if grow_state >= max_grow_state:
		if tree:
			var node := tree.instantiate()
			node.position = self.global_position
			G.environment.add_child(node, true)
		entity.despawn()
