extends Node3D

@onready var entity := $EntityComponent
@onready var collision := $CollisionShape3D
@onready var sprite := $Sprite3D
@onready var take_damage_audio := $TakeDamageAudio
@onready var damage_particle := $DamageParticle
@onready var health := $HealthComponent
@onready var damage_frame_timer := $Timers/DamageFrameRemove
@onready var shadow := $Shadow

@export var nname: String

var visual_sprites := []

func _ready() -> void:
	# Ищем все спрайты рекурсивно во всех дочерних узлах
	var sprites = find_children("*", "Sprite3D", true, false)
	var animated_sprites = find_children("*", "AnimatedSprite3D", true, false)
	
	visual_sprites.append_array(sprites)
	visual_sprites.append_array(animated_sprites)
	
	if not is_multiplayer_authority(): return
	
	health.died.connect(entity.despawn)
	health.on_damage.connect(on_damage.rpc)
	health.changed.connect(entity.spawn_damage_perticle)
	
	G.time_controller.night_come.connect(shadow.hide)
	G.time_controller.day_come.connect(shadow.show)

@rpc("authority", "call_local")
func on_damage() -> void:
	take_damage_audio.play_sound()
	damage_particle.emitting = true
	
	for spr in visual_sprites:
		spr.modulate = Color(1, 0 ,0)
	
	damage_frame_timer.start()

func _on_damage_frame_remove_timeout() -> void:
	for spr in visual_sprites:
		spr.modulate = Color(1, 1 ,1)
