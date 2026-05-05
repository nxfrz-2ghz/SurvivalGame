extends Node

const sounds := {
	"HoverPlayer": preload("hover.mp3"),
	"ClickPlayer": preload("click.mp3"),
}

var hover_player: AudioStreamPlayer
var click_player: AudioStreamPlayer

func _ready():
	# Инициализируем плееры и сохраняем ссылки на них
	hover_player = create_player("HoverPlayer")
	click_player = create_player("ClickPlayer")

func create_player(player_name: String) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.name = player_name
	player.bus = "Sounds" 
	player.stream = sounds[player_name]
	add_child(player)
	return player 

func play_hover():
	hover_player.play()

func play_click():
	click_player.play()
