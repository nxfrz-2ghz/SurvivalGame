extends CharacterBody3D

@onready var entity := $EntityComponent
@onready var collision := $CollisionShape3D
@onready var sprite := $AnimatedSprite3D
@onready var take_damage_audio := $Audio/TakeDamageAudio
@onready var damage_particle := $DamageParticle
@onready var health := $HealthComponent
@onready var damage_frame_timer := $Timers/DamageFrameRemove
@onready var shadow := $Shadow
@onready var walk_audio_player := $Audio/WalkAudioPlayer3D
@onready var walk_sound_timer := $Timers/WalkSoundPlay

@export var nname: String
@export var speed := 0.0

func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	health.died.connect(entity.despawn)
	health.on_damage.connect(on_damage.rpc)
	health.changed.connect(entity.spawn_damage_perticle)
	
	G.time_controller.night_come.connect(shadow.hide)
	G.time_controller.day_come.connect(shadow.show)

@rpc("authority", "call_local")
func on_damage() -> void:
	damage_particle.emitting = true
	if R.sounds["hit"].has(nname):
		take_damage_audio.audio_play(R.sounds["hit"][nname].pick_random().resource_path)
	sprite.modulate = Color(1, 0 ,0)
	damage_frame_timer.start()

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
	if !is_on_floor():
		spd /= 50.0
	else:
		if walk_sound_timer.is_stopped():
			walk_audio_player.audio_play.rpc(R.sounds["walk"]["grass"].pick_random().resource_path)
			walk_sound_timer.start()
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
	if G.state_machine != "game": return
	loop(delta)
	if not is_multiplayer_authority(): return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()

@rpc("any_peer", "call_local")
func apply_push(direction_vector: Vector3, velocity_power: float) -> void:
	velocity += direction_vector * velocity_power

func _on_update_timer_timeout() -> void:
	if position.distance_to(get_target_player().position) > 120.0:
		queue_free()
	if position.y < G.world.WATER_LEVEL:
		health.take_damage(1.0)
