extends StaticBody3D

@onready var collider := $CollisionShape3D
@onready var sprite := $Sprite3D
@onready var take_damage_audio := $TakeDamageAudio
@onready var health := $HealthComponent
@onready var item := preload("res://scenes/items/item.tscn")

@export var nname: String
@export var drop_name: String


func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	health.died.connect(despawn)
	health.changed.connect(on_damage)
	if randf() < 0.1: drop_loot()


func drop_loot() -> void:
	if !drop_name: return
	var drop: RigidBody3D = item.instantiate()
	drop.nname = self.drop_name
	G.world.add_child(drop, true)
	drop.position = self.position + Vector3(randi_range(-1,1), 2, randi_range(-1,1))


func on_damage() -> void:
	take_damage_audio.play()
	if randf() < 0.1: drop_loot()


func despawn() -> void:
	for i in range(randi_range(3,6)):
		drop_loot()	
	queue_free()
