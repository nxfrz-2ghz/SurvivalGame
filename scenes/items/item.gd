extends RigidBody3D

@onready var sprite := $Sprite3D

@export var nname: String


func _ready() -> void:
	sprite.texture = R.items[self.nname]["texture"]


func get_save_data() -> Dictionary:
	return {"nname": nname}


func load_save_data(data: Dictionary) -> void:
	if data.has("nname"):
		nname = String(data["nname"])
		if sprite:
			sprite.texture = R.items[self.nname]["texture"]
