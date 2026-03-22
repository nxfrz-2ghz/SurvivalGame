extends CharacterBody3D

@onready var collider := $CollisionShape3D
@onready var sprite := $AnimatedSprite3D
@onready var take_damage_audio := $TakeDamageAudio
@onready var health := $HealthComponent
@onready var damage_frame_timer := $Timers/DamageFrameRemove
@onready var shadow := $Shadow

@export var nname: String
@export var speed := 0.0
@export var drop_items := {}
@export var despawn_particles_size := 1.0
@export var exp_drop: float = 0.0


func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	health.died.connect(despawn)
	health.on_damage.connect(on_damage.rpc)
	
	G.time_controller.night_come.connect(shadow.hide)
	G.time_controller.day_come.connect(shadow.show)


func drop(item_name: String) -> void:
	var drop_item: RigidBody3D = R.item.instantiate()
	drop_item.nname = item_name
	drop_item.position = self.position + Vector3(randi_range(-1,1), 2, randi_range(-1,1))
	G.world.add_child(drop_item, true)


func drop_loot() -> void:
	if drop_items.is_empty(): return
	for item_name in drop_items:
		for i in range(drop_items[item_name] + randi_range(0, 1)):
			drop(item_name)


func drop_exp_sphere(value: float) -> void:
	var exp_sphere: RigidBody3D = R.exp_sphere.instantiate()
	exp_sphere.value = value
	var random_offset = Vector3(
		randf_range(-0.5, 0.5),
		randf_range(0.5, 1.5), # Подбрасываем немного вверх
		randf_range(-0.5, 0.5)
	)
	exp_sphere.position = self.position + random_offset
	G.world.add_child(exp_sphere, true)


@rpc("authority", "call_local")
func on_damage() -> void:
	take_damage_audio.play()
	sprite.modulate = Color(1, 0 ,0)
	damage_frame_timer.start()


func despawn() -> void:
	drop_loot()
	
	var died_particles := R.particles["explose"].instantiate()
	died_particles.position = self.position
	died_particles.size = despawn_particles_size
	G.world.add_child(died_particles, true)
	
	if exp_drop > 0:
		var count: int
		
		# Логика распределения:
		if exp_drop <= 5:
			# Если опыта мало, каждая единица — это сфера (минимум 1 опыт в сфере)
			count = int(max(1, exp_drop))
		else:
			# Если опыта > 5, ограничиваем быстрый рост сфер
			# Например: 5 сфер + по одной за каждые 10 единиц сверх лимита
			count = 5 + int((exp_drop - 5) / 10)
			# Ограничим разумным пределом, чтобы не спавнить сотни объектов
			count = clamp(count, 5, 20) 
		
		var value_per_sphere = exp_drop / count
		
		for i in range(count):
			drop_exp_sphere(value_per_sphere)
	
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


func walk(direction: Vector3, spd: float) -> void:
	if !is_on_floor(): spd /= 50.0
	velocity.x += direction.x * spd
	velocity.z += direction.z * spd


func braking() -> void:
	if velocity:
		if is_on_floor():
			velocity.x /= 1.5
			velocity.z /= 1.5
		else:
			velocity.x /= 1.01
			velocity.z /= 1.01
		
		if abs(velocity.x) < 0.01:
			velocity.x = 0
		if abs(velocity.z) < 0.01:
			velocity.z = 0


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
	if position.distance_to(get_target_player().position) > 120.0:
		queue_free()
