extends AudioStreamPlayer

@onready var timer := $Timer


func update() -> void:
	if R.music.is_empty(): return
	
	if randf() < 0.2:
		stream = R.music.pick_random()
		play()


func _on_timer_timeout() -> void:
	update()


func _on_finished() -> void:
	timer.wait_time = randi_range(40, 60)
	timer.start()
