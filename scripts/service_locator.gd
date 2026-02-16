extends Node

@onready var gui := $/root/Main/GUI
@onready var world := $/root/Main/Environment

var game := false
var player: CharacterBody3D
