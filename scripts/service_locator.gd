extends Node

var gui: CanvasLayer
var environment: Node3D
var world: Node3D
var time_controller: DirectionalLight3D
var mob_spawner: Node
var text_message: RichTextLabel
var screen_text: CanvasItem
var timer_1sec: Timer

var state_machine := "main_menu"
var player: CharacterBody3D
