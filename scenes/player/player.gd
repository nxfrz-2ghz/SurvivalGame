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
@onready var actions_audio_player := $Audio/ActionsAudioPlayer3D
@onready var damage_audio_player := $Audio/TakeDamageAudio
@onready var walk_audio_player := $Audio/WalkAudioPlayer3D
@onready var walk_sound_timer := $Timers/WalkSoundPlay
@onready var rain := $RainParticles3D

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
		rain.queue_free()
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
		health.on_damage.connect(damage_audio_player.play_sound)
		health.changed.connect(spawn_damage_perticle)
		
		self.nname = G.gui.main_menu.player_name.text
		$Label3D.text = self.nname


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if Input.is_action_just_pressed("esc") and G.state_machine == "book":
		book.close_book.emit()
	
	if G.state_machine != "game": return
	
	if event.is_action_pressed("lmb"): # или любая кнопка действия
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
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
			weapon.use_item_durability()
			
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
			weapon.actions.attack(weapon.damage + get_float_velocity()/10, weapon.damage_types, weapon.push_velocity)
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
			
			# Достать готовые прдеметы
			elif collider.nname in R.exchangeable_items.keys():
				if collider.has_node("CookComponent"):
					for i in collider.cook.complete:
						inv.add_item(i)
					collider.cook.pick.rpc_id(1)
				elif collider.has_node("CraftComponent"):
					for i in collider.craft.complete:
						inv.add_item(i)
					collider.craft.pick.rpc_id(1)
				return
			
			elif collider.nname == "berry_bush":
				if collider.full:
					for i in range(3):
						if randf() > 0.3:
							inv.add_item("raw_berry")
				collider.pick.rpc_id(1)
				return
		
		# Еда
		if current_slot_data != null:
			var item_name = current_slot_data["name"]
			if R.items[item_name].get("nutrition"):
				hunger.eat(R.items[item_name]["nutrition"])
				inv.drop_item(current_slot_idx, 1)
				actions_audio_player.audio_play(R.sounds["actions"]["eating"].resource_path)
	
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
	book.set_page("MAIN")


func _on_close_book() -> void:
	G.state_machine = "game"
	weapon.weapon_anim.play("book_close_page")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_health_component_died() -> void:
	
	var died_particles := R.particles["explose"].instantiate()
	died_particles.position = self.position
	G.environment.add_child(died_particles, true)
	
	var rigid_cam := RIGID_CAM.instantiate()
	G.environment.add_child(rigid_cam)
	rigid_cam.global_position = self.global_position
	rigid_cam.apply_central_impulse(velocity)
	
	for i in range(inv.MAX_SLOTS):
		var current_slot_idx: int = i + 1
		while inv.inventory[current_slot_idx] != null:
			weapon.actions.drop(current_slot_idx)
	
	self.position = Vector3(0, 100, 0)
	health.heal(99999999.9)
	hunger.eat(99999999)


@rpc("any_peer", "call_local")
func apply_push(direction_vector: Vector3, velocity_power: float) -> void:
	velocity += direction_vector * velocity_power


func spawn_damage_perticle(cur: float, _maxx: float, last: float) -> void:
	var change_hp := cur - last
	change_hp = snapped(change_hp, 3.4)
	if change_hp == 0.0: return
	
	var particle := R.particles["damage_counter"].instantiate()
	particle.text = str(change_hp)
	if change_hp > 0:
		particle.modulate = Color.GREEN
	else:
		particle.modulate = Color.RED
	particle.position = global_position + Vector3.UP
	G.environment.add_child(particle, true)


func get_float_velocity() -> float:
	return abs(velocity.x) + abs(velocity.y) + abs(velocity.z)


func is_underwater() -> bool:
	return position.y < G.world.WATER_LEVEL


func moving(delta: float) -> void:
	
	var gravity := get_gravity()
	
	# Add the gravity.
	if not is_on_floor():
		
		if is_underwater():
			gravity /= 3
		
		velocity += gravity * delta
	
	if Input.is_action_pressed("space") and (is_on_floor() or is_underwater()):
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
		walk_sound_timer.wait_time = 0.3
		if camera.fov < 120.0:
			camera.fov += 1.0
	else:
		walk_sound_timer.wait_time = 0.4
		if camera.fov > 90.0:
			camera.fov -= 0.5
	if is_underwater():
		speed *= 0.5
	
	# Moving
	if is_on_floor():
		if direction:
			velocity.x += direction.x * speed
			velocity.z += direction.z * speed
			arm_anim.play("walk")
			
			if walk_sound_timer.is_stopped():
				walk_audio_player.audio_play.rpc(R.sounds["walk"]["grass"].pick_random().resource_path)
				walk_sound_timer.start()
		
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
	
	# First Note
	await get_tree().create_timer(15.0).timeout
	if !progress_controller.unlocked_notes.has(progress_controller.notes["stone"]):
		progress_controller.add_note("stone")


func save_character() -> void:
	
	var path: String = "user://worlds/" + G.world.world_name + "/" + nname + ".chr"
	if not DirAccess.make_dir_recursive_absolute("user://worlds/" + G.world.world_name):
		DirAccess.make_dir_absolute("user://worlds/" + G.world.world_name)
	
	# Сохранение игрока
	var data := {
		"pos": [position.x, position.y, position.z],
		"rot": [rotation.y, head.rotation.x],
		"health": health.current_health,
		"hunger": hunger.current_hunger,
		"inventory": inv.inventory,
		"unlocked_notes": progress_controller.unlocked_notes,
		"current exp": progress_controller.cur_exp,
		"current lvl":  progress_controller.lvl,
	}
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		print("Character saved to: ", path)


func load_character() -> void:
	var path: String = "user://worlds/" + G.world.world_name + "/" + nname + ".chr"
	
	if not FileAccess.file_exists(path):
		print("Character save file not found:", path)
		return
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var data = JSON.parse_string(json_string)
		
		var pos = data.get("pos", [0, 0, 0])
		position = Vector3(pos[0], pos[1], pos[2])
		
		var rot = data.get("rot", [0, 0])
		rotation.y = rot[0]
		head.rotation.x = rot[1]
		
		health.current_health = data.get("health", health.current_health)
		hunger.current_hunger = data.get("hunger", hunger.current_hunger)
		progress_controller.unlocked_notes = data.get("unlocked_notes", [])
		progress_controller.cur_exp = data.get("current exp", 0)
		progress_controller.lvl = data.get("current lvl", 0)
		
		for item in data["inventory"].values():
			if item:
				inv.add_item(item["name"], item["amount"])
		
		print("Character loaded from:", path)
