extends GPUParticles3D

@onready var audio_player := $AudioStreamPlayer3D

@export var size := 1.0
@export var audio: String

func _ready() -> void:
	if audio:
		audio_player.stream = load(audio) # audio уже загружено в resources и лагов быть не должно
		audio_player.play()
	draw_pass_1.size = Vector2(size/2, size/2)
	emitting = true

func _on_finished() -> void:
	if not is_multiplayer_authority(): return
	queue_free()
