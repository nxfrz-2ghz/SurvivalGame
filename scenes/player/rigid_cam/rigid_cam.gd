extends RigidBody3D

@onready var label := $ColorRect/RichTextLabel

const splashes := [
	"YOU ARE DED",
	"досадно...",
	"skill issue",
	"ПОТРАЧЕНО",
]

const can_respawn_splashes := [
	"Не теряй решимость",
	"Выйграет тот, кто останется стоять последним,\n не сдавайся!",
	"У тебя все получится, вставай"
]

func _ready() -> void:
	if randf() <= float(G.upgrade_manager.unlocked_upgrades["UPGR_TBL-3-0"])/10:
		label.text = can_respawn_splashes.pick_random()
		label.text += "\nSPAM [X] to try respawn, " + G.player.nname + "!"
	else:
		label.text = splashes.pick_random()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("X"):
		if randf() <= float(G.upgrade_manager.unlocked_upgrades["UPGR_TBL-3-0"])/200:
			var spawn_pos := self.global_position + Vector3.UP
			G.player.respawn(false, spawn_pos)
			free()

func despawn() -> void:
	G.player.respawn()
	queue_free()

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	despawn()
