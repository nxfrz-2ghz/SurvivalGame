extends Label

func _physics_process(_delta: float) -> void:
	if !visible: return
	if G.state_machine != "game": return
	if not G.player: return
	
	text = "FPS: " + str(Engine.get_frames_per_second())
	
	text += "\nPosition\n"
	text += "X: " + str(G.player.position.x) + "\n"
	text += "Y: " + str(G.player.position.y) + "\n"
	text += "Z: " + str(G.player.position.z) + "\n"
	text += "Rotation\n"
	text += "X: " + str(G.player.rotation.y) + "\n"
	text += "Y: " + str(G.player.head.rotation.x) + "\n"
	
	text += output


# STATS_LABEL

var health: float
var hunger: float

var output: String

func on_health_changed(cur: float, _maxx: float, _last: float) -> void:
	health = cur
	update()

func on_hunger_changed(cur: float) -> void:
	hunger = cur
	update()

func update() -> void:
	output = "\nHealth: " + str(health) + "\nHunger: " + str(hunger)
