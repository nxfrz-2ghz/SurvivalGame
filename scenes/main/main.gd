extends Node

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const PORT: int = 9999

var enet_peer := ENetMultiplayerPeer.new()

func _ready() -> void:
	if OS.get_name() == "Web":
		G.text_message.add("HINT: web version cant support volumetic fog and multiplayer, for better expirience recommended play full downlowdable version")


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("f1"):
		G.gui.hud.debug.visible = !G.gui.hud.debug.visible


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
	
	elif type == "client":
		var address = "localhost" # Или возьмите из UI: menu.adress_entry.text
		if G.gui.main_menu.address_label.text: address = G.gui.main_menu.address_label.text
		var error = enet_peer.create_client(address, PORT)
		if error != OK: return
		multiplayer.multiplayer_peer = enet_peer


func connect_signals_to_player(player: CharacterBody3D) -> void:
	player.get_node("%InteractRay").target_found.connect(G.gui.hud.target_label.update)
	player.get_node("%InventoryController").update.connect(G.gui.hud.inventory.update)
	player.get_node("%InventoryController").set_hotbar_slot.connect(G.gui.hud.inventory.set_hotbar_slot)
	player.get_node("%Book").open_book.connect(G.gui.hud.inventory.hide)
	player.get_node("%Book").close_book.connect(G.gui.hud.inventory.show)
	player.get_node("%HealthComponent").changed.connect(G.gui.hud.health_vignette.on_health_changed)
	player.get_node("%HealthComponent").on_damage.connect(G.gui.hud.damage_vignette.on_damage)
	player.get_node("StaminaController").changed.connect(G.gui.hud.stamina_bar.on_stamina_changed)
	player.get_node("%HealthComponent").changed.connect(G.gui.hud.debug.on_health_changed)
	player.get_node("HungerController").changed.connect(G.gui.hud.debug.on_hunger_changed)


func add_player(peer_id: int) -> void:
	var player = PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	player.position.y = 50
	# Используем call_deferred для безопасности физики
	G.world.add_child(player, true)
	
	# Если игрок это мы, отложенно подключаем сигналы
	if peer_id == multiplayer.get_unique_id():
		connect_signals_to_player(player)
		G.player = player
	else:
		var world_node = G.world.get_node("World")
		world_node.rpc_id(peer_id, "join_world", world_node.world_seed, int(G.gui.main_menu.world_size.text))


func remove_player(peer_id: int) -> void:
	var player = G.world.get_node_or_null(str(peer_id))
	player.queue_free()


func start_game(is_load: bool = false) -> void:
	G.gui.main_menu.hide()
	G.gui.background.queue_free()
	if multiplayer.get_unique_id() == 1:
		if is_load:
			G.world.get_node("World").load_world()
		else:
			G.world.get_node("World").start_gen()
	G.state_machine = "game"
	G.gui.game_menu.game = true


func _on_create_button_pressed() -> void:
	if G.gui.main_menu.host_button.button_pressed:
		prepare_for_a_game("server")
		start_game()
	else:
		add_player(1)
		start_game()

func _on_load_button_pressed() -> void:
	if G.gui.main_menu.host_button.button_pressed:
		prepare_for_a_game("server")
		start_game(true)
	else:
		add_player(1)
		start_game(true)


func _on_join_button_pressed():
	prepare_for_a_game("client")
	start_game()


# Clients
func _on_player_spawner_spawned(node: Node) -> void:
	node.position.y = 50
	if str(multiplayer.get_unique_id()) == node.name:
		connect_signals_to_player(node)
		G.player = node
