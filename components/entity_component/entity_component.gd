# entity_component.gd
class_name EntityComponent
extends Node

var entity: Node3D

@export var drop_items := {}
@export var despawn_particles_size := 1.0
@export var despawn_sound_name: String
@export var exp_drop: float = 0.0

func _ready() -> void:
	entity = get_parent()

func spawn_damage_perticle(cur: float, _maxx: float, last: float) -> void:
	var change_hp := cur - last
	change_hp = snappedf(change_hp, 0.01)
	if change_hp == 0.0: return
	
	var particle := R.particles["damage_counter"].instantiate()
	particle.text = str(change_hp)
	if change_hp > 0:
		particle.modulate = Color.GREEN
	else:
		particle.modulate = Color.RED
	particle.position = entity.global_position + Vector3.UP
	G.environment.add_child(particle, true)

func drop(item_name: String) -> void:
	var drop_item: RigidBody3D = R.item.instantiate()
	drop_item.nname = item_name
	drop_item.position = entity.position + Vector3(randi_range(-1,1), 2, randi_range(-1,1))
	G.environment.add_child(drop_item, true)

func drop_loot() -> void:
	if drop_items.is_empty(): return
	for item_name in drop_items:
		for i in range(drop_items[item_name] + randi_range(0, 1)):
			drop(item_name)

func drop_exp_sphere(value: float) -> void:
	var exp_sphere: RigidBody3D = R.exp_sphere.instantiate()
	exp_sphere.value = value
	exp_sphere.position = entity.position + Vector3(
		randf_range(-0.5, 0.5),
		randf_range(0.5, 1.5),
		randf_range(-0.5, 0.5)
	)
	G.environment.add_child(exp_sphere, true)

func despawn() -> void:
	drop_loot()
	
	var died_particles := R.particles["explose"].instantiate()
	
	if despawn_sound_name:
		var sound_data = R.sounds["destroy"][despawn_sound_name]
		died_particles.audio = (
			sound_data.pick_random() if sound_data is Array else sound_data
		).resource_path
	
	died_particles.position = entity.position
	died_particles.size = despawn_particles_size
	G.environment.add_child(died_particles, true)
	
	if exp_drop > 0:
		var count: int
		if exp_drop <= 5:
			count = int(max(1, exp_drop))
		else:
			count = clamp(5 + int((exp_drop - 5) / 10), 5, 20)
		var value_per_sphere = exp_drop / count
		for i in range(count):
			drop_exp_sphere(value_per_sphere)
	
	entity.queue_free()
