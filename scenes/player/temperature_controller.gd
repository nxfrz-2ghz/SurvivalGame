extends Node

signal changed(temp: float, max_temp: float)

const max_temp := 200.0
var temp: float = 0.0

func _ready() -> void:
	G.timer_1sec.timeout.connect(_on_timer_timeout)

func bad() -> bool:
	if temp > max_temp:
		return true
	if temp < -max_temp:
		return true
	return false

func apply_eat(eat_name: String) -> void:
	if R.items[eat_name].has("temp_affect"):
		temp += R.items[eat_name]["temp_affect"]
		changed.emit(temp, max_temp)

func _on_timer_timeout() -> void:
	if S.state_machine != "game": return
	
	# Регулировка организмом
	if temp > max_temp / 10:
		temp -= 1.5
	elif temp < max_temp / 10:
		temp += 1
	if G.player.state == G.player.STATE.RUN:
		temp += 2
	if G.player.state == G.player.STATE.SLEEP:
		temp -= 5
	
	# Влияние времени суток
	if G.time_controller.night != G.time_controller.n.FALSE:
		temp -= (1.0 - G.time_controller.min_night_energy[G.time_controller.night]) * 3
	
	# Влияние освещения
	temp += G.player.light_controller.color.r
	
	# Влияние температурного биома
	temp -= G.world.temp_noise.get_noise_2d(G.player.position.x, G.player.position.z) * 10
	if G.player.is_underwater():
		temp -= G.world.temp_noise.get_noise_2d(G.player.position.x, G.player.position.z) * 25
	
	# Влияние погоды
	if G.player.rain.emitting:
		temp -= 1.0
	
	temp = clampf(temp, -max_temp*1.1, max_temp*1.1)
	changed.emit(temp, max_temp)
	
	if bad(): G.player.health.take_damage(0.5, false)
