extends Node3D

@onready var anim_player := $AnimationPlayer
@onready var weapon := get_parent()

enum ShootState { IDLE, AIMING, WAITING, THROWING, RECOVERY }
var current_state = ShootState.IDLE


func _input(event: InputEvent) -> void:
	if weapon.weapon_anim.is_playing(): return
	if weapon.current_name == "" or not R.items[weapon.current_name].get("throw_power"): return
	
	# Нажали RMB
	if event.is_action_pressed("rmb") and current_state == ShootState.IDLE:
		start_aiming()

	# Отпустили RMB
	if event.is_action_released("rmb"):
		if current_state == ShootState.AIMING:
			cancel_aiming()
		elif current_state == ShootState.WAITING:
			perform_throw()


func start_aiming():
	current_state = ShootState.AIMING
	anim_player.speed_scale = weapon.attack_speed + float(weapon.speed_rings)/5
	anim_player.play("aim")

func cancel_aiming():
	# Возвращаем состояние в IDLE, чтобы не выстрелить случайно
	current_state = ShootState.IDLE 
	anim_player.speed_scale = -1.5

func perform_throw():
	current_state = ShootState.THROWING
	
	# Непосредственно выстрел
	if R.items[weapon.current_name].get("texture") != null:
		weapon.actions.shoot(weapon.damage, weapon.damage_types, weapon.push_velocity, weapon.current_name)
		G.player.inv.drop_item(G.player.inv.current_item, 1)
	
	anim_player.play("throw")

func _on_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"aim":
			if current_state == ShootState.AIMING:
				current_state = ShootState.WAITING
				anim_player.play("waiting_throw")
			else:
				# Если мы были в IDLE (отмена), просто сбрасываем скорость
				anim_player.speed_scale = 1.0
				
		"throw":
			current_state = ShootState.RECOVERY
			anim_player.play("cd")
			
		"cd":
			current_state = ShootState.IDLE
			anim_player.speed_scale = 1.0
