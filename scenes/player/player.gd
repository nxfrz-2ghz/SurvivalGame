extends CharacterBody3D

@onready var head := $Head
@onready var sprite := $Sprite3D
@onready var label3d := $Label3D
@onready var interact_ray := %InteractRay
@onready var ground_ray := $Head/GroundRay
@onready var weapon := %Weapon
@onready var arm_anim := %ArmAnim
@onready var health := %HealthComponent
@onready var hunger := $HungerController
@onready var fear := $FearController
@onready var stamina := $StaminaController
@onready var camera := $Head/Camera/Camera3D
@onready var arms := $Head/Weapon/Arms
@onready var book := %Book
@onready var inv := %InventoryController
@onready var progress_controller := $ProgressController
@onready var light_controller := $LightController
@onready var actions_audio_player := $Audio/ActionsAudioPlayer3D
@onready var damage_audio_player := $Audio/TakeDamageAudio
@onready var walk_audio_player := $Audio/WalkAudioPlayer3D
@onready var walk_sound_timer := $Timers/WalkSoundPlay
@onready var rain := $RainParticles3D

const SPEED = 3.0
const JUMP_VELOCITY = 4.0

const RIGID_CAM := preload("res://scenes/player/rigid_cam/rigid_cam.tscn")

@export var nname := "Player"

enum STATE { IDLE, RUN, AIM, SLEEP }
var state := STATE.IDLE


func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	if not is_multiplayer_authority():
		# Переключаем игрока на слой, который видит камера
		sprite.set_layer_mask_value(1, true)
		sprite.set_layer_mask_value(6, false)
		label3d.set_layer_mask_value(1, true)
		label3d.set_layer_mask_value(6, false)
		
		interact_ray.queue_free()
		arms.queue_free()
		rain.queue_free()
		fear.queue_free()
		light_controller.queue_free()
	else:
		# Переключаем себя на слой, который не видит камера
		sprite.set_layer_mask_value(1, false)
		sprite.set_layer_mask_value(6, true)
		label3d.set_layer_mask_value(1, false)
		label3d.set_layer_mask_value(6, true)
		
		weapon.attack.connect(interact_ray.update)
		weapon.attack.connect(hunger.on_attack)
		
		hunger.take_damage.connect(health.take_damage)
		hunger.heal.connect(health.heal)
		
		inv.set_item_in_arm.connect(weapon.set_item_in_arm)
		inv.updatev.connect(weapon.update_player_stats)
		inv.update.emit(inv.inventory)
		
		book.open_book.connect(_on_open_book)
		book.close_book.connect(_on_close_book)
		
		health.on_damage.connect($Head/Camera/AnimationPlayer.play_on_damage)
		health.on_damage.connect(damage_audio_player.play_sound)
		health.changed.connect(spawn_damage_perticle)
		
		self.nname = G.gui.main_menu.player_name.text
		label3d.text = self.nname
		
		if DiskControl.take("super_visibility"):
			camera.far *= 5


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if Input.is_action_just_pressed("esc") and S.state_machine == "book":
		book.close_book.emit()
	
	if S.state_machine != "game": return
	if !camera.current: return
	
	if Input.is_action_just_pressed("f1"):
		arms.visible = !arms.visible
	
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
			
			var atk_spd: float = weapon.attack_speed + float(weapon.speed_rings)/5
			var vel: float = get_float_velocity()/10
			var cur_dmg: float = weapon.damage + weapon.damage * vel
			
			if is_underwater():
				atk_spd *= 0.5
				cur_dmg *= 0.5
			
			if health.current_health < health.max_health / 4:
				cur_dmg *= 0.8
			
			if hunger.current_hunger < hunger.MAX_HUNGER / 8:
				atk_spd *= 0.8
			
			weapon.weapon_anim.speed_scale = atk_spd
			weapon.weapon_anim.play("attack")
			weapon.actions.attack(weapon.is_splash, cur_dmg, weapon.damage_types, weapon.push_velocity + weapon.push_velocity * vel)
			weapon.attack.emit()
		interact_ray.update()
	
	if Input.is_action_just_pressed("rmb"):
		if interact_ray.is_colliding():
			var collider: Node = interact_ray.get_collider()
			
			if collider.nname == "berry_bush":
				if collider.full:
					for i in range(3):
						if randf() > 0.3:
							inv.add_item("raw_berry")
				collider.pick.rpc_id(1)
				return
			
			if collider.nname == "loot_chest":
				if collider.lvl_cost <= progress_controller.lvl:
					progress_controller.spend_exp_by_lvl(collider.lvl_cost)
					collider.open.rpc_id(1)
				else:
					G.text_message.add(tr("RPL_LVL_NOT_ENOUGH"))
				return
			
			if collider.nname in R.exchangeable_items.keys():
				var ex_items = R.exchangeable_items[collider.nname]
				
				if current_slot_data != null:
					var item_in_arm = current_slot_data["name"]
					var amount = current_slot_data["amount"]
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
				
				# Достать готовые предметы
				if collider.has_node("CookComponent"):
					for i in collider.cook.complete:
						inv.add_item(i)
					collider.cook.pick.rpc_id(1)
				elif collider.has_node("CraftComponent"):
					for i in collider.craft.complete:
						inv.add_item(i)
					collider.craft.pick.rpc_id(1)
				return
			
			if current_slot_data != null:
				var item_in_arm = current_slot_data["name"]
				var amount = current_slot_data["amount"]
				
				# Использование предмета по коллайдеру на пкм
				if !weapon.weapon_anim.is_playing():
					# Смена состояния постройки
					if R.items[item_in_arm].has("change_buildings"):
						if R.items[item_in_arm]["change_buildings"] == "state":
							# Простая смена состояния
							if collider.is_in_group("buildings"):
								collider.change_state.rpc_id(1)
							elif collider.is_in_group("sub_blocks"):
								collider.get_parent().reset_to_default.rpc()
							
							weapon.use_item_durability()
							weapon.weapon_anim.speed_scale = weapon.attack_speed + float(weapon.speed_rings)/5
							weapon.weapon_anim.play("use")
					
						# Режим chiseling
						elif R.items[item_in_arm]["change_buildings"] == "chisel":
							# Вырезаем
							if collider.is_in_group("sub_blocks"):
								collider.get_parent().chisel_at(collider)
								# Последующая обработка в block
							# Или если это еще обычный блок, делаем его резным
							elif collider is ChiseledBlock:
								collider.make_chiseled.rpc()
							
							weapon.use_item_durability()
							weapon.weapon_anim.speed_scale = weapon.attack_speed + float(weapon.speed_rings)/5
							weapon.weapon_anim.play("use")
		
		# Использование предметов (items)
		if current_slot_data != null:
			var item_name = current_slot_data["name"]
			
			# Еда
			if R.items[item_name].get("nutrition") and !weapon.weapon_anim.is_playing():
				weapon.weapon_anim.speed_scale = weapon.attack_speed + float(weapon.speed_rings)/5
				weapon.weapon_anim.play("use")
				hunger.eat(R.items[item_name]["nutrition"])
				fear.apply_eat(item_name)
				inv.drop_item(current_slot_idx, 1)
				actions_audio_player.audio_play(R.sounds["actions"]["eating"].resource_path)
			
			# Лечение
			if R.items[item_name].get("heal") and !weapon.weapon_anim.is_playing():
				weapon.weapon_anim.speed_scale = weapon.attack_speed + float(weapon.speed_rings)/5
				weapon.weapon_anim.play("use")
				health.heal(R.items[item_name]["heal"])
				inv.drop_item(current_slot_idx, 1)
				actions_audio_player.audio_play(R.sounds["actions"]["eating"].resource_path)
			
			# Строительство
			elif R.items[item_name].get("is_building"):
				weapon.actions.build(item_name, weapon.build.area.global_position, weapon.build.area.global_rotation)
				inv.drop_item(current_slot_idx, 1)
			
			# Стрельба
			elif R.items[item_name].get("throw_power") and !weapon.weapon_anim.is_playing():
				weapon.weapon_anim.speed_scale = weapon.attack_speed + float(weapon.speed_rings)/5
				weapon.weapon_anim.play("aim")
			
			# Получение предмета при использовании
			if R.items[item_name].has("on_use_drop"):
				for drop in R.items[item_name]["on_use_drop"]:
					inv.add_item(drop, R.items[item_name]["on_use_drop"][drop])
				weapon.use_item_durability()
				weapon.weapon_anim.speed_scale = weapon.attack_speed + float(weapon.speed_rings)/5
				weapon.weapon_anim.play("use")
			
			# Нанесение урона при использовании
			if R.items[item_name].has("on_use_damage"):
				health.take_damage(R.items[item_name]["on_use_damage"], true)
				weapon.use_item_durability()
				weapon.weapon_anim.speed_scale = weapon.attack_speed + float(weapon.speed_rings)/5
				weapon.weapon_anim.play("use")
	
	if Input.is_action_just_released("rmb") and weapon.weapon_anim.is_playing() and current_slot_data != null and R.items[current_slot_data["name"]].get("throw_power"):
		# Если прицеливания еще не закончилась то отмена
		if weapon.weapon_anim.current_animation == "aim":
			weapon.weapon_anim.speed_scale = -1.5
		# Если же анимация готовности к выстрелу то выстрел
		else:
			var current_name: String = current_slot_data["name"]
			if R.items[current_name].get("texture") != null:
				weapon.actions.shoot(weapon.damage, weapon.damage_types, weapon.push_velocity, current_name)
				inv.drop_item(inv.current_item, 1)
			weapon.weapon_anim.play("throw")
	
	if Input.is_action_pressed("shift"): return
	
	if Input.is_action_just_pressed("pickup") and !weapon.weapon_anim.is_playing():
		weapon.weapon_anim.play("pickup")
	
	if Input.is_action_just_pressed("drop"):
		if current_slot_data != null: weapon.actions.drop(current_slot_idx)
	
	if Input.is_action_just_pressed("craft"):
		weapon.actions.crafting_mode = !weapon.actions.crafting_mode
	
	if Input.is_action_just_pressed("open_book") and !weapon.weapon_anim.is_playing():
		book.open_book.emit()


func _on_open_book() -> void:
	S.state_machine = "book"
	weapon.weapon_anim.play("book_open_page")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	book.set_page("BK_MAIN")


func _on_close_book() -> void:
	S.state_machine = "game"
	weapon.weapon_anim.play("book_close_page")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_health_component_died() -> void:
	if not is_multiplayer_authority(): return
	
	var died_particles := R.particles["explose"].instantiate()
	died_particles.position = self.position
	G.environment.add_child(died_particles, true)
	
	var rigid_cam := RIGID_CAM.instantiate()
	G.environment.add_child(rigid_cam)
	rigid_cam.global_position = self.global_position
	rigid_cam.apply_central_impulse(velocity)
	
	# Перебираем все существующие ключи в инвентаре
	for slot_idx in inv.inventory.keys():
		var item = inv.inventory[slot_idx]
		
		# Проверяем, что в слоте что-то есть
		if item != null and item.has("amount"):
			# Выбрасываем предмет столько раз, сколько указано в amount
			for k in range(item["amount"]):
					weapon.actions.drop(slot_idx)
	
	progress_controller.spend_exp_by_lvl(progress_controller.lvl/1.6)
	
	self.position = Vector3(0, 300, 0)


func respawn() -> void:
	self.position = Vector3(0, 100, 0)
	health.heal(99999999.9)
	hunger.eat(99999999)
	fear.current_fear = 0
	camera.current = true
	camera.fov = 120.0


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
	#return G.world._get_height(position.x, position.z) < position.y and position.y < G.world.WATER_LEVEL
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
	if Input.is_action_pressed("shift") and stamina.energy > 0 and state != STATE.AIM:
		speed *= 1.5
		walk_sound_timer.wait_time = 0.3
		state = STATE.RUN
	else:
		walk_sound_timer.wait_time = 0.4
		state = STATE.IDLE
	if is_underwater():
		speed *= 0.5
	if weapon.weapon_anim.is_playing() and weapon.weapon_anim.current_animation == "waiting_throw":
		speed *= 0.5
	if health.current_health < health.max_health / 2:
		speed *= 0.8
	if health.current_health < health.max_health / 4:
		speed *= 0.8
	if hunger.current_hunger < hunger.MAX_HUNGER / 8:
		speed *= 0.6
	if Input.is_action_pressed("alt"):
		speed *= 0.5
	
	speed += weapon.speed_rings
	
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


func camera_control() -> void:
	var needed_fov: float
	
	if state == STATE.AIM:
		needed_fov = 70.0
	elif state == STATE.IDLE:
		needed_fov = 90.0
	elif state == STATE.RUN:
		needed_fov = 110.0
	elif state == STATE.SLEEP:
		needed_fov = 140.0
	
	if camera.fov < needed_fov:
		camera.fov += 1.0
	elif camera.fov > needed_fov:
		camera.fov -= 1.0


func scale_y_control() -> void:
	if Input.is_action_pressed("alt"):
		if self.scale.y > 0.5:
			scale.y -= 0.02
	else:
		if self.scale.y < 1.0:
			scale.y += 0.02


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	if S.state_machine != "game": return
	
	moving(delta)
	if Input.is_action_pressed("rmb") and R.items[weapon.current_name].get("throw_power"): state = STATE.AIM
	if Input.is_action_pressed("X") and interact_ray.is_colliding() and R.objects.has(interact_ray.current_target.nname) and R.objects[interact_ray.current_target.nname].get("can_sleep"):
		state = STATE.SLEEP
		G.time_controller.sleep.rpc_id(1, delta)
	if Input.is_action_pressed("shift"):
		if Input.is_action_pressed("drop"):
			if inv.inventory[inv.current_item] != null: weapon.actions.drop(inv.current_item)
		if Input.is_action_pressed("pickup"):
			weapon.actions.pickup()
		
	camera_control()
	scale_y_control()
	
	move_and_slide()


func _on_start_emit_timer_timeout() -> void:
	G.screen_text.text("")
	health.heal(0)
	hunger.eat(0)
	progress_controller.add_exp(0)
	
	if S.state_machine == "game":
		inv.update_signals()
	
	# First Note
	await get_tree().create_timer(15.0).timeout
	if !progress_controller.unlocked_notes.has(progress_controller.notes["NTK_1"]):
		progress_controller.add_note("NTK_1")


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
		"fear": fear.current_fear,
		"inventory": inv.inventory,
		"unlocked_notes": progress_controller.unlocked_notes,
		"unlocked_achievements": progress_controller.unlocked_achievements,
		"completed_achievements": progress_controller.completed_achievements,
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
		print("Character save file not found: ", path)
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
		fear.current_fear = data.get("fear", fear.current_fear)
		progress_controller.unlocked_notes = data.get("unlocked_notes", [])
		progress_controller.cur_exp = data.get("current exp", 0)
		progress_controller.lvl = data.get("current lvl", 0)
		progress_controller.unlocked_achievements = data.get("unlocked_achievements", [])
		progress_controller.completed_achievements = data.get("completed_achievements", [])
		
		for item in data["inventory"].values():
			if item:
				inv.add_item(item["name"], item["amount"])
		
		if randf() < 0.05:
			G.player.progress_controller.add_achievement("ACH_9")
		
		print("Character loaded from: ", path)
