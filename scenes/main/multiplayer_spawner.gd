extends MultiplayerSpawner


func _ready() -> void:
	# Автоматическое добавление всех, кого надо синхронизировать
	for obj in R.objects:
		add_spawnable_scene(R.objects[obj]["scene"].get_path())
	for building in R.buildings:
		add_spawnable_scene(R.buildings[building]["scene"].get_path())
	for mob in R.mobs:
		add_spawnable_scene(R.mobs[mob]["scene"].get_path())
	for particle in R.particles:
		add_spawnable_scene(R.particles[particle].get_path())
	for prefab in R.prefabs:
		add_spawnable_scene(R.prefabs[prefab].get_path())
