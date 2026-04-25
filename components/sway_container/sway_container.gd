extends Node2D

@export var smoothing := 10.0
@export var intensity := 5.0

var target_pos := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if S.state_machine != "game": return
	if event is InputEventMouseMotion:
		target_pos = -event.relative * intensity

func _physics_process(delta: float) -> void:
	if S.state_machine != "game": return
	position = position.lerp(target_pos, smoothing * delta)
	target_pos = target_pos.lerp(Vector2.ZERO, smoothing * delta)
