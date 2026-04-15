extends RigidBody3D

const max_distance := 30.0
@onready var sprite := $Sprite3D
@export var value := 1.0
@export var attraction_force := 40.0 # Сила притяжения
@export var max_speed := 15.0
var target_player: CharacterBody3D

func get_target_player() -> void:
	if not is_multiplayer_authority(): return
	
	var players = get_tree().get_nodes_in_group("players")
	var closest_dist = INF
	var closest_player: Node3D = null
	
	for player in players:
		if not is_instance_valid(player):
			continue
		var dist = global_position.distance_to(player.global_position)
		if dist < closest_dist and dist <= max_distance:
			closest_dist = dist
			closest_player = player
	
	target_player = closest_player


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	if target_player:
		
		var hue = wrapf(Time.get_ticks_msec() / 1000.0 * 1, 0, 1)
		sprite.modulate = Color.from_hsv(hue, 0.8, 1.0)
		
		var direction = (target_player.global_position - global_position).normalized()
		
		# Прикладываем силу в сторону игрока
		apply_central_force(direction * attraction_force)
		
		# Ограничиваем максимальную скорость, чтобы сфера не летала как пуля
		if linear_velocity.length() > max_speed:
			linear_velocity = linear_velocity.normalized() * max_speed


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority(): return
	
	if body.is_in_group("players"):
		body.progress_controller.add_exp(value)
		queue_free()
