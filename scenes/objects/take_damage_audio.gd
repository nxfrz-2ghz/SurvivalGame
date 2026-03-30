extends AudioStreamPlayer3D

func play_sound() -> void:
	stream = R.sounds["hit"]["objects"].pick_random()
	play()
