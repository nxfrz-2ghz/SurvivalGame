extends RigidBody3D

@onready var audio_player := $AudioStreamPlayer3D

const damage_type := {"meteor":1.0}
const despawn_sound_name := "meteor"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	apply_central_impulse(Vector3(randf_range(-30.0, 30.0), -20, randf_range(-30.0, 30.0)))
	audio_player.audio_play(R.sounds["idle"]["meteor"].pick_random().resource_path)


func get_damage() -> float:
	return abs(linear_velocity.x) + abs(linear_velocity.y) + abs(linear_velocity.z)


func _on_body_entered(body: Node) -> void:
	var node_health := body.get_node_or_null("HealthComponent")
	if node_health:
		node_health.take_damage(get_damage(), damage_type)
		
	var died_particles := R.particles["explose"].instantiate()
	if despawn_sound_name:
		var sound_data = R.sounds["destroy"][despawn_sound_name]
		died_particles.audio = (
			sound_data.pick_random() if sound_data is Array else sound_data
		).resource_path
	died_particles.position = self.position
	died_particles.size = 1.5
	G.environment.add_child(died_particles, true)


func _on_sleeping_state_changed() -> void:
	var meteorite_node := R.objects["meteorite"]["scene"].instantiate()
	meteorite_node.position = self.position
	G.environment.add_child(meteorite_node, true)
	queue_free()


func _on_sleep_timer_timeout() -> void:
	if get_damage() < 1.0:
		_on_sleeping_state_changed()
