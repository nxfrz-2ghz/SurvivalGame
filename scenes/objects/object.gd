extends StaticBody3D

@onready var collider := $CollisionShape3D
@onready var sprite := $Sprite3D
@onready var take_damage_audio := $TakeDamageAudio
@onready var health := $HealthComponent
@onready var damage_frame_timer := $Timers/DamageFrameRemove
@onready var shadow := $Shadow

const item := preload("res://scenes/items/item.tscn")

@export var nname: String
@export var drop_items := {}
@export var despawn_particles_size := 1.0

var visual_sprites := []


func _ready() -> void:
	# Получение всех спрайтов для эффектов при уроне
	var nodes = get_children()
	for child in nodes:
		if child is Sprite3D or child is AnimatedSprite3D:
			visual_sprites.append(child)
	
	if not is_multiplayer_authority(): return
	
	health.died.connect(despawn)
	health.on_damage.connect(on_damage.rpc)


func drop(item_name: String) -> void:
	var drop_item: RigidBody3D = item.instantiate()
	drop_item.nname = item_name
	drop_item.position = self.position + Vector3(randi_range(-1,1), 2, randi_range(-1,1))
	G.world.add_child(drop_item, true)


func drop_loot() -> void:
	if drop_items.is_empty(): return
	for item_name in drop_items:
		for i in range(drop_items[item_name] + randi_range(0, 1)):
			drop(item_name)


@rpc("authority", "call_local")
func on_damage() -> void:
	take_damage_audio.play()
	
	for spr in visual_sprites:
		spr.modulate = Color(1, 0 ,0)
	
	damage_frame_timer.start()


func despawn() -> void:
	drop_loot()
	
	var died_particles := R.particles["explose"].instantiate()
	died_particles.position = self.position
	died_particles.size = despawn_particles_size
	G.world.add_child(died_particles, true)
	
	queue_free()


func _on_damage_frame_remove_timeout() -> void:
	for spr in visual_sprites:
		spr.modulate = Color(1, 1 ,1)
