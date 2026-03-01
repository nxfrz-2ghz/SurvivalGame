extends CharacterBody3D

@onready var collider := $CollisionShape3D
@onready var sprite := $AnimatedSprite3D
@onready var take_damage_audio := $TakeDamageAudio
@onready var health := $HealthComponent
@onready var damage_frame_timer := $Timers/DamageFrameRemove
@onready var shadow := $Shadow

const item := preload("res://scenes/items/item.tscn")

@export var nname: String
@export var drop_items := {}


func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	health.died.connect(despawn)
	health.on_damage.connect(on_damage)
	
	G.time_controller.night_come.connect(shadow.hide)
	G.time_controller.day_come.connect(shadow.show)


func drop(item_name: String) -> void:
	var drop_item: RigidBody3D = item.instantiate()
	drop_item.nname = item_name
	G.world.add_child(drop_item, true)
	drop_item.position = self.position + Vector3(randi_range(-1,1), 2, randi_range(-1,1))


func drop_loot() -> void:
	if drop_items.is_empty(): return
	for item_name in drop_items:
		for i in range(drop_items[item_name] + randi_range(0, 1)):
			drop(item_name)


func on_damage() -> void:
	take_damage_audio.play()
	sprite.modulate = Color(1, 0 ,0)
	damage_frame_timer.start()


func despawn() -> void:
	drop_loot()
	
	var died_particles := R.particles["explose"].instantiate()
	G.world.add_child(died_particles, true)
	died_particles.position = self.position
	
	queue_free()


func _on_damage_frame_remove_timeout() -> void:
	sprite.modulate = Color(1, 1 ,1)


func get_target_player() -> CharacterBody3D:
	var players = get_tree().get_nodes_in_group("players")
	var closest_dist = INF
	var closest_player: Node3D = null
	
	for player in players:
		if not is_instance_valid(player):
			continue
		var dist = global_position.distance_to(player.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_player = player

	return closest_player


func loop(_delta: float) -> void:
	return


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	if G.state_machine != "game": return
	
	loop(delta)
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()


@rpc("any_peer", "call_local")
func apply_push(direction_vector: Vector3, velocity_power: float) -> void:
	velocity += direction_vector * velocity_power


func _on_update_timer_timeout() -> void:
	if position.distance_to(get_target_player().position) > 100.0:
		despawn()
	if position.y < -100:
		despawn()
