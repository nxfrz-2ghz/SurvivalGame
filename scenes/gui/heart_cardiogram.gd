extends Control

@onready var label := $Label

@export var max_hp: float = 100.0
@export var current_hp: float = 100.0
@export var glow_passes: int = 4
@export var glow_radius: float = 8.0
@export var glow_alpha: float = 0.08

# --- Страх ---
enum FearState { NONE, SCARE, SUSPENSE, PANIC, SHOCK }
var fear_state: FearState = FearState.NONE

var _fear_bpm_add: float = 0.0       # добавка к BPM от страха
var _fear_noise: float = 0.0         # амплитуда дрожания линии
var _fear_arrhythmia: float = 0.0    # сдвиг периода (аритмия)
var _shock_blank: float = 0.0        # 0..1, насколько линия "гасится"
var _scare_peak: float = 0.0         # дополнительный одиночный пик
var _fear_amplitude: float = 1.0   # множитель высоты волны

var points: Array[float] = []
var scroll_offset: float = 0.0
var line_width := 145

var _tween: Tween
var _fear_tween: Tween
var _glow_intensity_mul: float = 1.0

func _ready() -> void:
	points.resize(line_width)
	points.fill(0.0)

func _physics_process(delta: float) -> void:
	points.resize(line_width)
	var bpm := _get_bpm()
	var speed := bpm / 60.0 * 150.0
	scroll_offset += speed * delta

	var period := 60.0 / bpm * 150.0

	# Аритмия — искажаем период синусоидой
	var distorted_x := scroll_offset
	if _fear_arrhythmia > 0.0:
		distorted_x += sin(scroll_offset * 0.07) * _fear_arrhythmia * 18.0

	var new_y := _ecg_shape(distorted_x, period) * _fear_amplitude

	# Шок — гасим сигнал
	new_y *= (1.0 - _shock_blank)

	# Шум от страха
	if _fear_noise > 0.0:
		new_y += randf_range(-_fear_noise, _fear_noise)

	# Одиночный пик испуга
	if _scare_peak > 0.01:
		new_y += _scare_peak
		_scare_peak = move_toward(_scare_peak, 0.0, delta * 4.0)

	points.push_back(new_y)
	if points.size() > line_width:
		points.pop_front()

	queue_redraw()

func _draw() -> void:
	var h := size.y
	var color := _get_color()

	if current_hp <= 0:
		_draw_glow_line(Vector2(0, h / 2), Vector2(size.x, h / 2), Color.RED, 2.0)
		return

	for i in range(1, points.size()):
		var p1 := Vector2(i - 1, h / 2 - points[i - 1] * h * 0.4)
		var p2 := Vector2(i,     h / 2 - points[i]     * h * 0.4)
		var alpha := float(i) / points.size()
		_draw_glow_segment(p1, p2, Color(color.r, color.g, color.b, alpha * alpha))

# --- Публичные методы страха ---

# Вызвать при внезапном испуге (монстр выпрыгнул, взрыв рядом)
func trigger_scare(intensity: float = 1.0) -> void:
	fear_state = FearState.SCARE
	_scare_peak = clamp(intensity, 0.2, 1.5)

	if _fear_tween:
		_fear_tween.kill()
	_fear_tween = create_tween().set_parallel(true)
	_fear_tween.tween_property(self, "_fear_bpm_add",   80.0 * intensity, 0.05)
	_fear_tween.tween_property(self, "_fear_amplitude", 1.0, 0.1)  # сбрасываем амплитуду к норме
	_fear_tween.chain()
	_fear_tween.tween_property(self, "_fear_bpm_add", 0.0, 4.0)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_fear_tween.tween_callback(func(): fear_state = FearState.NONE)


func set_panic(active: bool) -> void:
	if _fear_tween:
		_fear_tween.kill()
	_fear_tween = create_tween().set_parallel(true)  # параллельный — все свойства одновременно

	if active:
		fear_state = FearState.PANIC
		_fear_tween.tween_property(self, "_fear_bpm_add",    60.0, 0.5)
		_fear_tween.tween_property(self, "_fear_noise",      0.2,  0.5)
		_fear_tween.tween_property(self, "_fear_arrhythmia", 1.0,  0.5)
		_fear_tween.tween_property(self, "_fear_amplitude",  1.4,  0.5)  # во время паники волны выше
	else:
		_fear_tween.tween_property(self, "_fear_bpm_add",    0.0, 2.0)
		_fear_tween.tween_property(self, "_fear_noise",      0.0, 2.0)
		_fear_tween.tween_property(self, "_fear_arrhythmia", 0.0, 2.0)
		_fear_tween.tween_property(self, "_fear_amplitude",  1.0, 3.0)  # плавный возврат
		# fear_state сбрасываем только после восстановления
		_fear_tween.chain().tween_callback(func(): fear_state = FearState.NONE)

func set_suspense(active: bool, intensity: float = 1.0) -> void:
	if _fear_tween:
		_fear_tween.kill()
	_fear_tween = create_tween().set_parallel(true)

	if active:
		fear_state = FearState.SUSPENSE
		_fear_tween.tween_property(self, "_fear_bpm_add",   35.0 * intensity, 2.0)
		_fear_tween.tween_property(self, "_fear_noise",     0.12 * intensity, 2.0)
		_fear_tween.tween_property(self, "_fear_amplitude", 1.1,  2.0)
	else:
		_fear_tween.tween_property(self, "_fear_bpm_add",   0.0, 3.0)
		_fear_tween.tween_property(self, "_fear_noise",     0.0, 3.0)
		_fear_tween.tween_property(self, "_fear_amplitude", 1.0, 3.0)
		_fear_tween.chain().tween_callback(func(): fear_state = FearState.NONE)

func trigger_shock(duration: float = 0.8) -> void:
	fear_state = FearState.SHOCK
	if _fear_tween:
		_fear_tween.kill()
	_fear_tween = create_tween()
	_fear_tween.tween_property(self, "_shock_blank",    0.9, 0.1)
	_fear_tween.tween_property(self, "_fear_amplitude", 0.1, 0.1)  # волны почти исчезают
	_fear_tween.tween_interval(duration)
	_fear_tween.tween_callback(func(): _scare_peak = 1.4)
	_fear_tween.tween_property(self, "_shock_blank",    0.0, 0.3)
	_fear_tween.tween_property(self, "_fear_amplitude", 1.0, 1.5)  # восстановление
	_fear_tween.tween_property(self, "_fear_bpm_add",  50.0, 0.1)
	_fear_tween.tween_property(self, "_fear_bpm_add",   0.0, 5.0)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_fear_tween.tween_callback(func(): fear_state = FearState.NONE)

# --- Внутренние методы (без изменений) ---

func on_health_changed(cur_hp: float, maxx_hp: float, _last_hp: float) -> void:
	max_hp = maxx_hp
	current_hp = clamp(cur_hp, 0.0, max_hp)
	_update_glow_pulse()
	label.text = "health: " + str(cur_hp/maxx_hp*100.0) + "%"
	label.modulate = _get_color()
	label.modulate.a = 0.5

func _get_bpm() -> float:
	if current_hp <= 0:
		return 60.0
	var pct := current_hp / max_hp
	var base: float
	if pct > 0.6:
		base = lerp(72.0, 80.0, 1.0 - pct)
	elif pct > 0.3:
		base = lerp(90.0, 110.0, 1.0 - pct)
	else:
		base = lerp(130.0, 160.0, 1.0 - pct)
	
	return base + _fear_bpm_add

func _get_color() -> Color:
	# При шоке — цвет белеет
	if fear_state == FearState.SHOCK:
		return Color(1.0, 1.0, 1.0)
	# При панике — краснее обычного
	if fear_state == FearState.PANIC:
		return Color(1.0, 0.1, 0.1)
	var pct := current_hp / max_hp
	if pct > 0.6: return Color.GREEN
	elif pct > 0.3: return Color.YELLOW
	return Color.RED

func _ecg_shape(x: float, period: float) -> float:
	var t := fmod(x, period) / period
	if t < 0.05: return 0.0
	if t < 0.08: return 0.15
	if t < 0.10: return -0.10
	if t < 0.14: return -0.05
	if t < 0.18: return 1.0
	if t < 0.22: return -0.30
	if t < 0.26: return 0.05
	if t < 0.34: return 0.25 * sin((t - 0.26) / 0.08 * PI)
	return 0.0

func _draw_glow_segment(p1: Vector2, p2: Vector2, base_color: Color) -> void:
	var intensity := glow_alpha * _glow_intensity_mul
	for pass_i in range(glow_passes, 0, -1):
		var width := glow_radius * (float(pass_i) / glow_passes)
		var a     := intensity * (1.0 - float(pass_i) / (glow_passes + 1))
		draw_line(p1, p2, Color(base_color.r, base_color.g, base_color.b, a), width * 2.0, true)
	draw_line(p1, p2, base_color, 2.0, true)
	draw_line(p1, p2, Color(1.0, 1.0, 1.0, base_color.a * 0.25), 0.8, true)

func _draw_glow_line(p1: Vector2, p2: Vector2, color: Color, width: float) -> void:
	for pass_i in range(glow_passes, 0, -1):
		var r := glow_radius * (float(pass_i) / glow_passes)
		var a := glow_alpha * _glow_intensity_mul * (1.0 - float(pass_i) / (glow_passes + 1))
		draw_line(p1, p2, Color(color.r, color.g, color.b, a), r * 2.0, true)
	draw_line(p1, p2, color, width, true)
	draw_line(p1, p2, Color(1, 1, 1, 0.25), 0.8, true)

func _update_glow_pulse() -> void:
	if _tween: _tween.kill()
	var pct := current_hp / max_hp
	if pct <= 0.0:
		_tween = create_tween().set_loops()
		_tween.tween_property(self, "_glow_intensity_mul", 3.0, 0.5)
		_tween.tween_property(self, "_glow_intensity_mul", 0.5, 0.5)
	elif pct <= 0.3:
		_tween = create_tween().set_loops()
		_tween.tween_property(self, "_glow_intensity_mul", 2.5, 0.2)
		_tween.tween_property(self, "_glow_intensity_mul", 0.8, 0.2)
	elif pct <= 0.6:
		_tween = create_tween().set_loops()
		_tween.tween_property(self, "_glow_intensity_mul", 1.8, 0.4)
		_tween.tween_property(self, "_glow_intensity_mul", 0.9, 0.4)
	else:
		_glow_intensity_mul = 1.0
