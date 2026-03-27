extends "res://scripts/base_audio_player_rpc.gd"

func play_sound() -> void:
	audio_play.rpc(R.sounds["hit"]["player"].pick_random().resource_path)
