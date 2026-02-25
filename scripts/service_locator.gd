extends Node

var gui: CanvasLayer
var world: Node3D
var time_controller: DirectionalLight3D

var state_machine := "main_menu"
var player: CharacterBody3D
