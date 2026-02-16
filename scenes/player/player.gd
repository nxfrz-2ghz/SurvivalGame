extends CharacterBody3D

@onready var head := $Head
@onready var interact_ray := %InteractRay
@onready var inventory := %InventoryController
@onready var weapon := %Weapon
@onready var arm_anim := %ArmAnim
@onready var health := %HealthComponent

const SPEED = 3.0
const JUMP_VELOCITY = 4.0

@export var nname := "Player"


func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	if not is_multiplayer_authority():
		interact_ray.queue_free()
	else:
		weapon.attack.connect(interact_ray.update)
		
		weapon.actions.add_item.connect(inventory.add_item)
		weapon.actions.drop_item.connect(inventory.drop_item)
		
		inventory.set_item_in_arm.connect(weapon.set_item_in_arm)
		
		inventory.update_signals()


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		
		rotation.y += (-event.relative.x * 0.005)
		head.rotation.x += (-event.relative.y * 0.005)
		
		head._apply_camera_limits()
	
	if Input.is_action_just_pressed("lmb") and !weapon.weapon_anim.is_playing():
		weapon.weapon_anim.speed_scale = weapon.stats.attack_speed
		weapon.weapon_anim.play("use")
		weapon.actions.attack(weapon.stats.damage, weapon.stats.damage_types)
		weapon.attack.emit()
		interact_ray.update()
	
	if Input.is_action_just_pressed("rmb"):
		if interact_ray.is_colliding():
			var collider: Node = interact_ray.get_collider()
			if collider.nname == "furnace":
				var item_in_arm: String = inventory.inventory[inventory.current_item-1]
				collider.craft.rpc_id(1, item_in_arm)
	
	if Input.is_action_just_pressed("pickup") and !weapon.weapon_anim.is_playing():
		weapon.weapon_anim.speed_scale = 1
		weapon.weapon_anim.play("pickup")
		interact_ray.update()
	
	if Input.is_action_just_pressed("drop"):
		if weapon.stats.current_name == "": return
		weapon.actions.drop(weapon.stats.current_name)
	
	if Input.is_action_just_pressed("craft"):
		weapon.actions.craft()


func moving(delta: float) -> void:
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_pressed("space") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Arm animation
	if input_dir and is_on_floor(): arm_anim.play("walk")
	else: arm_anim.play("idle")
	
	# Moving
	if is_on_floor():
		if direction:
			velocity.x += direction.x * SPEED
			velocity.z += direction.z * SPEED
			arm_anim.play("walk")
		
		if velocity:
			velocity.x /= 1.5
			velocity.z /= 1.5
	
	else:
		arm_anim.play("idle")
		if direction:
			velocity.x += direction.x * SPEED / 50
			velocity.z += direction.z * SPEED / 50
		
		if velocity:
			velocity.x /= 1.01
			velocity.z /= 1.01
	
	if abs(velocity.x) < 0.01:
		velocity.x = 0
	if abs(velocity.z) < 0.01:
		velocity.z = 0


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	moving(delta)
	
	if position.y < -50:
		position.y = 50
	
	move_and_slide()
