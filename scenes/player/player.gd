extends CharacterBody3D

@onready var head := $Head
@onready var interact_ray := %InteractRay
@onready var ground_ray := $Head/GroundRay
@onready var weapon := %Weapon
@onready var arm_anim := %ArmAnim
@onready var health := %HealthComponent
@onready var hunger := $HungerController
@onready var stamina := $StaminaController
@onready var camera := $Head/Camera/Camera3D
@onready var book := %Book
@onready var inv := %InventoryController
@onready var progress_controller := $ProgressController

const SPEED = 3.0
const JUMP_VELOCITY = 4.0

const RIGID_CAM := preload("res://scenes/player/rigid_cam/rigid_cam.tscn")

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
		
		hunger.take_damage.connect(health.take_damage)
		hunger.heal.connect(health.heal)
		
		inv.set_item_in_arm.connect(weapon.set_item_in_arm)
		inv.update_signals()
		
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
	
	# Получаем данные о текущем слоте для удобства
	var current_slot_idx: int = inv.current_item
	var current_slot_data = inv.inventory[current_slot_idx]
	
	if Input.is_action_just_pressed("lmb") and !weapon.weapon_anim.is_playing():
		if weapon.actions.crafting_mode:
			weapon.actions.craft()
		else:
			weapon.use_item()
			
			# Если слот не пуст (используем данные из массива)
			if current_slot_data != null:
				var item_name = current_slot_data["name"]
				
				if R.items[item_name].get("shovel_power") and ground_ray.is_colliding():
					var shovel_power: float = R.items[item_name].get("shovel_power")
					var get_dig_drop: String = weapon.get_dig_drop(ground_ray.get_collision_point())
					
					if get_dig_drop == "clay":
						if randi_range(0, clamp(5 - shovel_power, 0, 5)) == 0:
							inv.add_item("clay")
					elif get_dig_drop == "dirt":
						if randi_range(0, int(clamp(100 - shovel_power, 0, 100))) == 0:
							inv.add_item("copper_ore")
						if randi_range(0, int(clamp(100 - shovel_power, 0, 100))) == 0:
							inv.add_item("iron_ore")
			
			weapon.weapon_anim.speed_scale = weapon.attack_speed
			weapon.weapon_anim.play("use")
			weapon.actions.attack(weapon.damage, weapon.damage_types, weapon.push_velocity)
			weapon.attack.emit()
		interact_ray.update()
	
	if Input.is_action_just_pressed("rmb"):
		if interact_ray.is_colliding():
			var collider: Node = interact_ray.get_collider()
			
			if current_slot_data != null and collider.nname in R.exchangeable_items.keys():
				var item_in_arm = current_slot_data["name"]
				var amount = current_slot_data["amount"]
				var ex_items = R.exchangeable_items[collider.nname]
				
				if ex_items.get(item_in_arm) and amount >= ex_items.get(item_in_arm)["amount"]:
					if collider.has_node("CookComponent"): collider.cook.craft.rpc_id(1, item_in_arm)
					elif collider.has_node("CraftComponent"): collider.craft.craft.rpc_id(1, item_in_arm)
					# Выбрасываем (удаляем) из текущего слота
					inv.drop_item(current_slot_idx, ex_items.get(item_in_arm)["amount"])
					return
					
				if collider.has_node("CookComponent") and item_in_arm == collider.cook.fuel_type:
					collider.cook.add_fuel.rpc_id(1)
					inv.drop_item(current_slot_idx, 1)
					return
			
			elif collider.nname == "berry_bush":
				if collider.full:
					for i in range(3): # Пример упрощения сбора ягод
						if randf() > 0.3: inv.add_item("raw_berry")
				collider.pick.rpc_id(1)
				return
		
		# Еда
		if current_slot_data != null:
			var item_name = current_slot_data["name"]
			if R.items[item_name].get("nutrition"):
				hunger.eat(R.items[item_name]["nutrition"])
				inv.drop_item(current_slot_idx, 1)
	
	if Input.is_action_just_pressed("pickup") and !weapon.weapon_anim.is_playing():
		weapon.weapon_anim.play("pickup")
	
	if Input.is_action_just_pressed("drop"):
		if current_slot_data != null: weapon.actions.drop(current_slot_idx)
	
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


func _on_health_component_died() -> void:
	
	var died_particles := R.particles["explose"].instantiate()
	died_particles.position = self.position
	G.world.add_child(died_particles, true)
	
	var rigid_cam := RIGID_CAM.instantiate()
	G.world.add_child(rigid_cam)
	rigid_cam.global_position = self.global_position
	rigid_cam.apply_central_impulse(velocity)
	
	for i in range(inv.MAX_SLOTS - 1):
		var current_slot_idx: int = i + 1
		while inv.inventory[current_slot_idx] != null:
			weapon.actions.drop(current_slot_idx)
	
	self.position = Vector3(0, 100, 0)
	health.heal(99999999.9)
	hunger.eat(99999999)


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
	
	move_and_slide()


func _on_start_emit_timer_timeout() -> void:
	health.heal(0)
	hunger.eat(0)
	inv.update_signals()
	progress_controller.add_exp(0)
