extends RigidBody3D

@onready var sprite := $Sprite3D
@onready var sprite2 := $Sprite3D2

@export var damage := 0.0
@export var damage_types := {"melee": 0.1}
@export var push_velocity := 0.0
@export var item_name: String
@export var texture_path: String
@export var despawn_chance: float
@export var throw_power: float
@export var billboard: bool

func _ready() -> void:
	if texture_path:
		if billboard:
			sprite.texture = load(texture_path)
			sprite.billboard = true
		else:
			sprite.texture = load(texture_path)
			sprite2.texture = load(texture_path)
	
	apply_central_impulse(-global_transform.basis.z.normalized() * throw_power)


func spawn_item() -> void:
	var item := R.item.instantiate()
	item.position = self.global_position
	item.position.y += 1.0
	item.nname = item_name
	G.environment.add_child(item, true)


func _on_body_entered(body: Node) -> void:
	if not is_multiplayer_authority(): return
	
	if body.has_node("HealthComponent"):
		body.health.take_damage(damage, damage_types)
		if body is CharacterBody3D:
			body.apply_push(self.global_transform.basis.z.normalized() + Vector3.UP/2, push_velocity)
		
		if item_name and randf() <= despawn_chance:
			spawn_item()
		
		if self.position.distance_to(G.player.position) > 25.0:
			G.player.progress_controller.add_achievement("ACH_4")
	else:
		if item_name:
			spawn_item()
	
	queue_free()


func _integrate_forces(_state: PhysicsDirectBodyState3D) -> void:
	if linear_velocity.length() > 0.5:
		look_at(global_transform.origin + linear_velocity, Vector3.UP)
