extends Button

func _on_pressed() -> void:
	if G.gui.main_menu.world_chooser.text != "":
		DiskControl.rm_dir("user://worlds/" + G.gui.main_menu.world_chooser.text)
		G.gui.main_menu.world_chooser.scan_worlds()
