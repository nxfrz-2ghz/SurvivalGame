extends GPUParticles3D

@export var size := 1.0


func _ready() -> void:
	draw_pass_1.size = Vector2(size/2, size/2)
	emitting = true

func _on_finished() -> void:
	queue_free()
