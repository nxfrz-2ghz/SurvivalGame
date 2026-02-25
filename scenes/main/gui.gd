extends CanvasLayer

@onready var main_menu = $MainMenu
@onready var game_menu := $GameMenu
@onready var hud = $HUD


func _ready() -> void:
	G.gui = self
