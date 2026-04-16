extends RigidBody3D

@onready var sprite := $Sprite3D
@onready var light := $Light

@export var nname: String


func _ready() -> void:
	sprite.texture = R.items[self.nname]["texture"]
	sprite.visibility_range_end = G.world.items_visible_range
	
	if R.items[nname].has("light"):
		light.color = R.items[nname]["light"]["color"]
		light.energy = R.items[nname]["light"]["energy"]
	else:
		light.queue_free()


func get_save_data() -> Dictionary:
	return {"nname": nname}


func get_speed() -> float:
	return abs(linear_velocity.x) + abs(linear_velocity.y) + abs(linear_velocity.z)


func load_save_data(data: Dictionary) -> void:
	if data.has("nname"):
		nname = String(data["nname"])
		if sprite:
			sprite.texture = R.items[self.nname]["texture"]
