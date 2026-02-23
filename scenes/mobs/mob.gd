extends CharacterBody3D

@onready var collider := $CollisionShape3D
@onready var sprite := $AnimatedSprite3D
@onready var take_damage_audio := $TakeDamageAudio
@onready var health := $HealthComponent
@onready var damage_frame_timer := $Timers/DamageFrameRemove

const item := preload("res://scenes/items/item.tscn")

@export var nname: String
@export var drop_items := {}


func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	health.died.connect(despawn)
	health.changed.connect(on_damage)


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


func on_damage(_current_health: float, _max_health: float) -> void:
	take_damage_audio.play()
	sprite.modulate = Color(1, 0 ,0)
	damage_frame_timer.start()


func despawn() -> void:
	drop_loot()
	queue_free()


func _on_damage_frame_remove_timeout() -> void:
	sprite.modulate = Color(1, 1 ,1)
