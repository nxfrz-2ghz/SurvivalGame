extends Node

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const PORT: int = 9999

@onready var address_label := $GUI/MainMenu/MarginContainer/VBoxContainer/AddresLabel

var enet_peer := ENetMultiplayerPeer.new()


func prepare_for_a_game(type: String) -> void:
	if type == "server":
		var error = enet_peer.create_server(PORT)
		if error != OK: return
		
		multiplayer.multiplayer_peer = enet_peer
		
		# Подключаем спавн только на сервере
		multiplayer.peer_connected.connect(add_player)
		multiplayer.peer_disconnected.connect(remove_player)
		
		# Добавляем серверного игрока
		add_player(multiplayer.get_unique_id())
		start_game()
	
	elif type == "client":
		var address = "localhost" # Или возьмите из UI: menu.adress_entry.text
		if address_label.text: address = address_label.text
		var error = enet_peer.create_client(address, PORT)
		if error != OK: return
		multiplayer.multiplayer_peer = enet_peer
		start_game()


func add_player(peer_id: int) -> void:
	var player = PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	# Используем call_deferred для безопасности физики
	G.world.add_child.call_deferred(player, true)
	
	# Если игрок это мы, то подключаем сигналы
	if peer_id == multiplayer.get_unique_id():
		player.get_node("%InteractRay").target_found.connect(G.gui.hud.target_label.update)
		player.get_node("%InventoryController").update.connect(G.gui.hud.inventory.update)
		player.get_node("%InventoryController").set_hotbar_slot.connect(G.gui.hud.inventory.set_hotbar_slot)
	
	else:
		var world_node = G.world.get_node("World")
		world_node.rpc_id(peer_id, "join_world", world_node.world_seed)


func remove_player(peer_id: int) -> void:
	var player = G.world.get_node_or_null(str(peer_id))
	player.queue_free()


func start_game() -> void:
	G.gui.main_menu.hide()
	if multiplayer.get_unique_id() == 1:
		G.world.get_node("World").start_gen()


func _on_host_button_pressed() -> void:
	prepare_for_a_game("server")

func _on_join_button_pressed():
	prepare_for_a_game("client")


# Clients
func _on_player_spawner_spawned(node: Node) -> void:
	node.get_node("%InteractRay").target_found.connect(G.gui.hud.target_label.update)
	node.get_node("%InventoryController").update.connect(G.gui.hud.inventory.update)
	node.get_node("%InventoryController").set_hotbar_slot.connect(G.gui.hud.inventory.set_hotbar_slot)
