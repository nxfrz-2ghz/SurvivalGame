extends Decal

func hide_rpc() -> void:
	hr.rpc()

func show_rpc() -> void:
	sr.rpc()

@rpc("authority", "call_local")
func hr() -> void:
	hide()

@rpc("authority", "call_local")
func sr() -> void:
	show()
