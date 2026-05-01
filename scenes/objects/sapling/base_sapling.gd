extends "res://scenes/objects/object.gd"

const dry_bush := preload("res://scenes/objects/bush/dry_bush/dry_bush.tscn")

@export var tree: PackedScene
@export var grow_state: int = 0
@export var max_grow_state: int = 10


func _ready() -> void:
	super()
	if not is_multiplayer_authority(): return
	if G.world._get_temp(position.x, position.z) <= 0.3:
		var node := dry_bush.instantiate()
		node.position = self.global_position
		G.environment.add_child(node, true)
		entity.despawn()


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
