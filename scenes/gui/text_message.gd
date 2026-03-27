extends RichTextLabel

@onready var anim_player := $AnimationPlayer

var queue := []

func _ready() -> void:
	G.text_message = self

func add(txt: String) -> void:
	queue.append(txt)
	
	if !anim_player.is_playing():
		play()

func play() -> void:
	self.text = queue[0]
	anim_player.play("show")

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue.pop_front()
	
	if !queue.is_empty():
		play()
