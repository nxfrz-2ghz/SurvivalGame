extends AudioStreamPlayer3D

@rpc("any_peer", "call_local")
func audio_play(audio_path: String) -> void:
	# Загружаем ресурс из пути на каждой стороне
	var audio_resource = load(audio_path)
	if audio_resource is AudioStream:
		stream = audio_resource
		play()
