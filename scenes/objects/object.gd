extends Node3D

@onready var collider := $CollisionShape3D
@onready var sprite := $Sprite3D
@onready var take_damage_audio := $TakeDamageAudio
@onready var health := $HealthComponent
@onready var damage_frame_timer := $Timers/DamageFrameRemove
@onready var shadow := $Shadow

@export var nname: String
@export var drop_items := {}
@export var despawn_particles_size := 1.0
@export var despawn_sound_name: String
@export var exp_drop: float = 0.0

var visual_sprites := []


func _ready() -> void:
	# Ищем все спрайты рекурсивно во всех дочерних узлах
	var sprites = find_children("*", "Sprite3D", true, false)
	var animated_sprites = find_children("*", "AnimatedSprite3D", true, false)
	
	visual_sprites.append_array(sprites)
	visual_sprites.append_array(animated_sprites)
	
	if not is_multiplayer_authority(): return
	
	health.died.connect(despawn)
	health.on_damage.connect(on_damage.rpc)


func drop(item_name: String) -> void:
	var drop_item: RigidBody3D = R.item.instantiate()
	drop_item.nname = item_name
	drop_item.position = self.position + Vector3(randi_range(-1,1), 2, randi_range(-1,1))
	G.environment.add_child(drop_item, true)


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
	G.environment.add_child(exp_sphere, true)


@rpc("authority", "call_local")
func on_damage() -> void:
	take_damage_audio.play_sound()
	
	for spr in visual_sprites:
		spr.modulate = Color(1, 0 ,0)
	
	damage_frame_timer.start()


func despawn() -> void:
	drop_loot()
	
	var died_particles := R.particles["explose"].instantiate()
	
	if despawn_sound_name:
		var sound_data = R.sounds["destroy"][despawn_sound_name]
		if sound_data is Array:
			died_particles.audio = sound_data.pick_random().resource_path
		else:
			died_particles.audio = sound_data.resource_path
	
	died_particles.position = self.position
	died_particles.size = despawn_particles_size
	G.environment.add_child(died_particles, true)
	
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
	for spr in visual_sprites:
		spr.modulate = Color(1, 1 ,1)
