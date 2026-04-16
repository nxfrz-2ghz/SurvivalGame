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
	
	mesh.visibility_range_end = G.world.buildings_visible_range


func _on_damage_scale_anim() -> void:
	# Scale animation
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE*0.85, 0.05)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3.ONE, 0.25)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_IN)

@rpc("authority", "call_local")
func on_damage() -> void:
	take_damage_audio.play_sound()
	_on_damage_scale_anim()
