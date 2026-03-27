extends CheckButton

@export var key: String

func _ready() -> void:
	toggled.connect(_on_toggled)
	if DiskControl.has(key):
		var val = DiskControl.take(key)
		button_pressed = val
		_on_toggled(val)


func _on_toggled(toggled_on: bool) -> void:
	apply(toggled_on)
	
	if DiskControl.has(key):
		if DiskControl.take(key) != toggled_on:
			DiskControl.save(key, toggled_on)


func apply(_toggled_on: bool) -> void: pass
