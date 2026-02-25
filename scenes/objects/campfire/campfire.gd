extends "res://scenes/objects/object.gd"

@rpc("any_peer", "call_local")
func toggle() -> void:
	sprite.visible = !sprite.visible
	$Shadow.visible = !$Shadow.visible
	$Toogle.visible = !$Toogle.visible
	$SmokeParticle.emitting = !$SmokeParticle.emitting
