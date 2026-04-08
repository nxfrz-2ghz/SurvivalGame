extends Node3D

@onready var entity := $EntityComponent
@onready var collision := $CollisionShape3D
@onready var take_damage_audio := $TakeDamageAudio
@onready var health := $HealthComponent
@onready var mesh := $MeshInstance3D

@export var nname: String

func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	health.died.connect(entity.despawn)
	health.on_damage.connect(on_damage.rpc)
	health.changed.connect(entity.spawn_damage_perticle)

@rpc("authority", "call_local")
func on_damage() -> void:
	take_damage_audio.play_sound()
