extends Node

var gui: CanvasLayer
var world: Node3D
var time_controller: DirectionalLight3D
var mob_spawner: Node
var text_message: RichTextLabel
var inv: Node

var state_machine := "main_menu"
var player: CharacterBody3D
