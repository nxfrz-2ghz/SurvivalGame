extends "res://scenes/building/building.gd"
class_name ChiseledBlock

enum State { FULL }

const BLOCK_MESHES := {
	State.FULL: preload("res://scenes/building/block/_meshes/full_box.tres"),
}
const BLOCK_SHAPES := {
	State.FULL: preload("res://scenes/building/block/_shapes/full_box.tres"),
}

@export var state: State = State.FULL:
	set(value):
		state = value
		if is_node_ready():
			_update_state()

@export var grid_size: int = 8
@export var block_size: float = 1.0

const SUB_BLOCK := preload("res://scenes/building/block/_sub_block/sub_block.tscn")

# Список удалённых позиций (Vector3i)
var sub_blocks: Dictionary = {}
@export var removed_subs: Array[Vector3i] = []
# Словарь для быстрого доступа: { Vector3i: StaticBody3D }
@export var is_chiseled: bool = false

func _ready() -> void:
	super()
	if is_chiseled:
		_restore_chiseled_state()
	else:
		_update_state()

func _update_state() -> void:
	mesh.mesh = BLOCK_MESHES[state]
	collision.shape = BLOCK_SHAPES[state]
	mesh.visible = true
	collision.disabled = false

@rpc("any_peer", "call_local")
func change_state() -> void:
	if not is_multiplayer_authority(): return
	
	# Следующий state по порядку
	state = (state + 1) % State.size() as State
	

## 🛠 Логика Chisel (Долото)

@rpc("any_peer", "call_local")
func make_chiseled() -> void:
	if is_chiseled:
		return
		
	is_chiseled = true
	mesh.visible = false
	collision.disabled = true
	entity.spawn_died_particle()
	_spawn_sub_blocks()

func _spawn_sub_blocks() -> void:
	var step := block_size / grid_size
	var offset := (block_size / 2.0) - (step / 2.0)
	
	for x in grid_size:
		for y in grid_size:
			for z in grid_size:
				var grid_pos := Vector3i(x, y, z)
				if grid_pos in removed_subs:
					continue
				_create_sub_block(grid_pos, step, offset)

func _create_sub_block(grid_pos: Vector3i, step: float, offset: float) -> void:
	var sub := SUB_BLOCK.instantiate()
	
	sub.nname = self.nname
	sub.size = Vector3.ONE * step
	
	# Позиционирование
	sub.position = Vector3(
		grid_pos.x * step - offset,
		grid_pos.y * step - offset,
		grid_pos.z * step - offset
	)
	
	add_child(sub)
	sub_blocks[grid_pos] = sub
	sub.mesh.material_override = mesh.get_active_material(0)

## 🔨 Взаимодействие

# Вызывается игроком локально
func chisel_at(sub_node: StaticBody3D) -> void:
	# Находим координаты нажатого суб-блока
	for pos in sub_blocks:
		if sub_blocks[pos] == sub_node:
			chisel_at_rpc.rpc(pos)
			break

@rpc("any_peer", "call_local")
func chisel_at_rpc(grid_pos: Vector3i) -> void:
	if not sub_blocks.has(grid_pos):
		return
		
	var sub = sub_blocks[grid_pos]
	removed_subs.append(grid_pos)
	sub_blocks.erase(grid_pos)
	sub.queue_free()
	
	# Если удалили всё — удаляем весь блок
	if sub_blocks.is_empty():
		queue_free()

@rpc("any_peer", "call_local")
func reset_to_default() -> void:
	for sub in sub_blocks.values():
		sub.queue_free()
		
	sub_blocks.clear()
	removed_subs.clear()
	is_chiseled = false
	_update_state()

func _restore_chiseled_state() -> void:
	mesh.visible = false
	collision.disabled = true
	_spawn_sub_blocks()
