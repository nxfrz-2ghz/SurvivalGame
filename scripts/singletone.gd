extends Node

const OXIDING_SPEED := 200
const dmg_to_get_ach_ultrakill := 10.0

var state_machine := "main_menu"

func attack(body: Node3D, rot_node: Node3D, dmg: float, ignore_armor: bool, push_velocity := 1.0, damage_types := {"melee":1.0}) -> void:
	# Урон по игрокам
	if body.is_in_group("players"):
		body.health.take_damage.rpc_id(int(body.name), dmg, ignore_armor, damage_types)
		body.apply_push.rpc_id(int(body.name), -rot_node.global_transform.basis.z.normalized() + Vector3.UP/2, push_velocity)
	
	# Урон по объектам
	if body.is_in_group("objects") or body.is_in_group("buildings"):
		body.health.take_damage.rpc_id(1, dmg, ignore_armor, damage_types)
	
	if body.is_in_group("sub_blocks"):
		body.get_parent().health.take_damage.rpc_id(1, dmg, ignore_armor, damage_types)
		# Останавливаем выполнение, тк в зоне коллизии куча микро блоков и каждый нанесет урон
		return
	
	# Урон по мобам
	if body.is_in_group("mobs"):
		body.health.take_damage.rpc_id(1, dmg, ignore_armor, damage_types)
		body.apply_push(-rot_node.global_transform.basis.z.normalized() + Vector3.UP/2, push_velocity)
