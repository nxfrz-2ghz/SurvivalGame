extends Node3D

signal changed(fear: int, max_fear: int)
signal suspense(active: bool)
signal panic(active: bool)
signal shock()
signal scare()

const DISTANCE := 50.0
const FEAR_ARM_SHAKING := 2000.0
const STAGE_COUNT := 5

const BUTTONS_ACTIONS := [
	"up", "down", "left", "right", "space",
	"lmb", "rmb", "drop", "pickup",
	"1","2","3","4","5","6","7","8","9","10","11","12",
]

const NODES_AFFECT := {
	"campfire": 2,
	"heart": -1,
}

var max_fear: int = 500
var current_fear: int = 0
var current_stage: int = 0
var last_stage: int = 0
var pressed_action: String = ""

# Ссылка на ECG — назначь в инспекторе или через get_node
@export var ecg_indicator: NodePath
@onready var ecg: Control = get_node_or_null(ecg_indicator)

func _ready() -> void:
	G.timer_1sec.timeout.connect(_on_timer_timeout)

func apply_change(node: Node) -> void:
	var node_name: String = node.nname
	if node_name == "campfire" and not node.cook.toggle_on.visible:
		return
	if node_name in NODES_AFFECT:
		current_fear -= NODES_AFFECT[node_name]

func apply_eat(eat_name: String) -> void:
	if R.items[eat_name].has("fear_affect"):
		current_fear -= R.items[eat_name]["fear_affect"] * 10

func _on_timer_timeout() -> void:
	if G.state_machine != "game": return

	last_stage = current_stage

	# Сброс зажатой кнопки прошлого тика
	if pressed_action != "":
		Input.action_release(pressed_action)
		pressed_action = ""

	# День/ночь
	if G.time_controller.night:
		current_fear += 1
	else:
		current_fear -= 1

	# Обход узлов влияния
	var nodes := get_tree().get_nodes_in_group("can_affect_fear")
	for node in nodes:
		var dist: float = global_position.distance_to(node.global_position)
		if dist > DISTANCE:
			continue
		apply_change(node)
		# Ближняя зона — двойной эффект
		if dist <= DISTANCE / 2.0:
			apply_change(node)

	current_fear = clampi(current_fear, 0, max_fear)
	changed.emit(current_fear, max_fear)

	# Стадии 0–4: делим диапазон на STAGE_COUNT равных частей
	current_stage = mini(
		int(float(current_fear) / float(max_fear) * STAGE_COUNT),
		STAGE_COUNT - 1
	)

	_handle_stage_change()

func _handle_stage_change() -> void:
	# --- Suspense: стадия 1+ ---
	if current_stage >= 1 and last_stage < 1:
		suspense.emit(true)
		if ecg: ecg.set_suspense(true, 0.5)
	elif current_stage < 1 and last_stage >= 1:
		suspense.emit(false)
		if ecg: ecg.set_suspense(false)

	# --- Panic: стадия 3+ ---
	if current_stage >= 3 and last_stage < 3:
		panic.emit(true)
		if ecg: ecg.set_panic(true)
	elif current_stage < 3 and last_stage >= 3:
		panic.emit(false)
		if ecg: ecg.set_panic(false)

	# --- Анимация камеры на стадии 4 ---
	var anim := $"../Head/Camera/AnimationPlayer"
	if current_stage >= 4 and last_stage < 4:
		anim.play("on_deadly_fear_on")
	elif current_stage < 4 and last_stage >= 4:
		anim.play("on_deadly_fear_off")

	# --- Scare: случайный испуг на стадии 2+ ---
	if current_stage >= 2 and randf() < 0.05:
		scare.emit()
		if ecg: ecg.trigger_scare(float(current_stage) / STAGE_COUNT)

	# --- Тряска рук ---
	if current_stage >= 2 and randf() < 0.1:
		var sway := $"../Head/Weapon/Arms/ShakingContainer/SwayContainer"
		sway.target_pos = Vector2(
			randf_range(-FEAR_ARM_SHAKING, FEAR_ARM_SHAKING),
			randf_range(-FEAR_ARM_SHAKING, FEAR_ARM_SHAKING)
		)

	# --- Стадия 4: случайное нажатие кнопок ---
	if current_stage >= 4 and randf() < 0.1:
		pressed_action = BUTTONS_ACTIONS.pick_random()
		Input.action_press(pressed_action)
	
	# --- Стадия 5 (максимальная): шок и урон ---
	if current_stage == 5:
		if randf() > 0.4: 
			shock.emit()
		if randf() < 0.1:
			shock.emit()
			G.player.health.take_damage(100.0, false)
	
