extends Node

@onready var player_name := $PlayerContainer/MarginContainer/VBoxContainer/PlayerLineEdit
@onready var address_label := $VBoxContainer/PanelContainer3/MarginContainer/VBoxContainer/AddresLabel
@onready var host_button := $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/VBoxContainer/HostButton
@onready var world_name := $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/WorldName
@onready var world_size := $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/WorldSize
@onready var world_seed := $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/WorldSeed
@onready var world_chooser := $VBoxContainer/PanelContainer2/MarginContainer/VBoxContainer/HBoxContainer/WorldChooser
