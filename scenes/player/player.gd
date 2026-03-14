extends CharacterBody3D

@onready var head := $Head
@onready var interact_ray := %InteractRay
@onready var inventory := %InventoryController
@onready var weapon := %Weapon
@onready var arm_anim := %ArmAnim
@onready var health := %HealthComponent
@onready var hunger := $HungerController
@onready var stamina := $StaminaController
@onready var camera := $Head/Camera/Camera3D
@onready var book := %Book

const SPEED = 3.0
const JUMP_VELOCITY = 4.0

@export var nname := "Player"


func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	if not is_multiplayer_authority():
		interact_ray.queue_free()
		$Head/Weapon/Arms.queue_free()
	else:
		weapon.attack.connect(interact_ray.update)
		weapon.attack.connect(hunger.on_attack)
		
		weapon.actions.add_item.connect(inventory.add_item)
		weapon.actions.drop_item.connect(inventory.drop_item)
		
		hunger.take_damage.connect(health.take_damage)
		hunger.heal.connect(health.heal)
		
		inventory.set_item_in_arm.connect(weapon.set_item_in_arm)
		inventory.update_signals()
		
		book.open_book.connect(_on_open_book)
		book.close_book.connect(_on_close_book)
		
		health.on_damage.connect($Head/Camera/AnimationPlayer.play_on_damage)


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	if G.state_machine != "game": return
	
	if event is InputEventMouseMotion:
		
		rotation.y += (-event.relative.x * 0.005)
		head.rotation.x += (-event.relative.y * 0.005)
		
		head._apply_camera_limits()
	
	if Input.is_action_just_pressed("lmb") and !weapon.weapon_anim.is_playing():
		if weapon.actions.crafting_mode:
			weapon.actions.craft()
		else:
			
			if inventory.inventory[inventory.current_item] != null:
				var item_name: String = inventory.inventory[inventory.current_item]["name"]
				if R.items[item_name].has("durability"):
					if randi_range(0, R.items[item_name]["durability"]) == 0:
						inventory.drop_item(item_name)
			
			weapon.weapon_anim.speed_scale = weapon.attack_speed
			weapon.weapon_anim.play("use")
			weapon.actions.attack(weapon.damage, weapon.damage_types, weapon.push_velocity)
			weapon.attack.emit()
		interact_ray.update()
	
	if Input.is_action_just_pressed("rmb"):
		
		if interact_ray.is_colliding():
			var collider: Node = interact_ray.get_collider()
			
			# Если коллайдер перерабатывает предметы и слот в инвентаре не пустой
			if collider.nname in R.exchangeable_items.keys() and inventory.inventory[inventory.current_item]:
				var item_in_arm: String = inventory.inventory[inventory.current_item]["name"]
				var amount: int = inventory.inventory[inventory.current_item]["amount"]
				# Если предмет есть в словаре крафтов печи и его количество достаточно
				var ex_items: Dictionary = R.exchangeable_items[collider.nname]
				if ex_items.get(item_in_arm) and amount >= ex_items.get(item_in_arm)["amount"]:
					collider.cook.craft.rpc_id(1, item_in_arm)
					inventory.drop_item(item_in_arm, ex_items.get(item_in_arm)["amount"])
					return
				# Если предмет это подходящее топливо и его достаточно
				if item_in_arm == collider.cook.fuel_type and amount > 0:
					collider.cook.add_fuel.rpc_id(1)
					inventory.drop_item(item_in_arm, 1)
					return
			
			elif collider.nname == "berry_bush":
				if collider.full:
					inventory.add_item("raw_berry")
					if randf() > 0:
						inventory.add_item("raw_berry")
						if randf() > 0:
							inventory.add_item("raw_berry")
				collider.pick.rpc_id(1)
				return
		
		if inventory.inventory[inventory.current_item]:
			var item_name: String = inventory.inventory[inventory.current_item]["name"]
			if R.items[item_name].get("nutrition"):
				inventory.drop_item(item_name)
				hunger.eat(R.items[item_name]["nutrition"])
	
	if Input.is_action_just_pressed("pickup") and !weapon.weapon_anim.is_playing():
		weapon.weapon_anim.play("pickup")
		interact_ray.update()
	
	if Input.is_action_just_pressed("drop"):
		if weapon.current_name == "": return
		weapon.actions.drop(weapon.current_name)
	
	if Input.is_action_just_pressed("craft"):
		weapon.actions.crafting_mode = !weapon.actions.crafting_mode
	
	if Input.is_action_just_pressed("open_book") and !weapon.weapon_anim.is_playing():
		book.open_book.emit()


func _on_open_book() -> void:
	G.state_machine = "book"
	weapon.weapon_anim.play("book_open_page")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_close_book() -> void:
	G.state_machine = "game"
	weapon.weapon_anim.play("book_close_page")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


@rpc("any_peer", "call_local")
func apply_push(direction_vector: Vector3, velocity_power: float) -> void:
	velocity += direction_vector * velocity_power


func moving(delta: float) -> void:
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_pressed("space") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Arm animation
	if input_dir and is_on_floor():
		arm_anim.play("walk", 0.2)
	else:
		arm_anim.play("idle", 0.2)
	
	var speed: float = SPEED
	if Input.is_action_pressed("shift") and stamina.energy > 0:
		speed *= 1.5
		if camera.fov < 120.0:
			camera.fov += 1.0
	else:
		if camera.fov > 90.0:
			camera.fov -= 0.5
	
	# Moving
	if is_on_floor():
		if direction:
			velocity.x += direction.x * speed
			velocity.z += direction.z * speed
			arm_anim.play("walk")
		
		if velocity:
			velocity.x /= 1.5
			velocity.z /= 1.5
	
	else:
		arm_anim.play("idle")
		if direction:
			velocity.x += direction.x * speed / 50
			velocity.z += direction.z * speed / 50
		
		if velocity:
			velocity.x /= 1.01
			velocity.z /= 1.01
	
	if abs(velocity.x) < 0.01:
		velocity.x = 0
	if abs(velocity.z) < 0.01:
		velocity.z = 0


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	if G.state_machine != "game": return
	
	moving(delta)
	
	if position.y < -50:
		position.y = 50
	
	move_and_slide()
