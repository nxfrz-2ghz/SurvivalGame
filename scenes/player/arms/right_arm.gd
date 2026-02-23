extends Node3D


func change_item(item: int):
	if not is_multiplayer_authority(): return
	
	$Models/Placeholder.hide()
	$Models/Grass.hide()
	$Models/Dirt.hide()
	$Models/CobbleStone.hide()
	$Models/Metal.hide()
	
	match item:
		1:
			$Models/Placeholder.show()
		2:
			$Models/Grass.show()
		3:
			$Models/Dirt.show()
		4:
			$Models/CobbleStone.show()
		5:
			$Models/Metal.show()
			
