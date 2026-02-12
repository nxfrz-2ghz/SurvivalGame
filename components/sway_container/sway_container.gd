extends Node2D

@export var smoothing := 10.0
@export var intensity := 5.0

var target_pos := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		target_pos = -event.relative * intensity

func _process(delta: float) -> void:
	position = position.lerp(target_pos, smoothing * delta)
	target_pos = target_pos.lerp(Vector2.ZERO, smoothing * delta)
