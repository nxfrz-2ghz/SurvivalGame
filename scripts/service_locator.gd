extends Node

@onready var gui := $/root/Main/GUI
@onready var world := $/root/Main/Environment

var state_machine := "main_menu"
var player: CharacterBody3D
