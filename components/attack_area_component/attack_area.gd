extends Area3D

@export var damage := 1.0
@export var damage_types := {"melee":1.0}
@export var push_velocity := 0.0

func attack() -> void:
	var bodies := get_overlapping_bodies()
	
	for body in bodies:
		S.attack(body, self, damage, false, 0, push_velocity, damage_types)
