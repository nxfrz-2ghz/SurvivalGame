extends OptionButton

const WORLDS_PATH := "user://worlds/"


func _ready() -> void:
	scan_worlds()


func scan_worlds():
	self.clear()
	#self.add_item("choose save:")
	
	var dir_access = DirAccess.open(WORLDS_PATH)
	if dir_access:
		dir_access.list_dir_begin()
		var entry_name = dir_access.get_next()
		
		while entry_name != "":
			if dir_access.current_is_dir():
				self.add_item(entry_name)
			entry_name = dir_access.get_next()
		dir_access.list_dir_end()
