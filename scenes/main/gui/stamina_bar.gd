extends Control

@onready var pbar1 := $ProgressBar
@onready var pbar2 := $ProgressBar2

func on_stamina_changed(cur: float, maxx: float) -> void:
	var value := cur / maxx
	pbar1.value = value
	pbar2.value = value
	self.modulate.a = 1


func _physics_process(_delta: float) -> void:
	if self.modulate.a > 0:
		self.modulate.a -= 0.01
