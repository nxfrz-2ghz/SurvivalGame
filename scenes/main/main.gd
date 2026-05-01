extends Node

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const PORT: int = 9999

var enet_peer := ENetMultiplayerPeer.new()

func _ready() -> void:
	if OS.get_name() == "Web":
		G.text_message.add("HINT: web version cant support volumetic fog and multiplayer, for better expirience recommended play full downlowdable version")
	
	G.gui.game_menu.reload.connect(_on_reload)


func _on_reload() -> void:
	# 1. Останавливаем сетевое взаимодействие
	multiplayer.multiplayer_peer = null
	enet_peer.close()
	
	# 2. Обнуляем ссылки в глобальных синглтонах, чтобы не было "previously freed"
	G.player = null
	
	# 3. Перезагружаем сцену
	get_tree().reload_current_scene()


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("f1") and S.state_machine == "game":
		G.gui.hud.inventory.visible = !G.gui.hud.inventory.visible
		G.gui.hud.aim.visible = !G.gui.hud.aim.visible
		G.gui.hud.bar_box.visible = !G.gui.hud.bar_box.visible
		G.gui.hud.stamina_bar.visible = !G.gui.hud.stamina_bar.visible
		G.gui.hud.fear_vignette.visible = !G.gui.hud.fear_vignette.visible
		G.gui.hud.damage_vignette.visible = !G.gui.hud.damage_vignette.visible
		G.gui.hud.target_label.get_node("PanelContainer").visible = !G.gui.hud.target_label.get_node("PanelContainer").visible
	if Input.is_action_just_pressed("f3"):
		match S.state_machine:
			"game":
				G.gui.hud.debug.visible = !G.gui.hud.debug.visible
			"main_menu":
				G.gui.main_menu.debug.visible = !G.gui.main_menu.debug.visible


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


func set_up_player(player: CharacterBody3D) -> void:
	player.get_node("%InteractRay").target_found.connect(G.gui.hud.target_label.update)
	player.get_node("%InventoryController").update.connect(G.gui.hud.inventory.update)
	player.get_node("%InventoryController").set_hotbar_slot.connect(G.gui.hud.inventory.set_hotbar_slot)
	player.get_node("%InventoryController").set_item_in_arm.connect(G.gui.hud.choosed_item_display.on_choosed)
	player.get_node("%InventoryController").set_item_in_left_arm.connect(G.gui.hud.inventory.set_left_arm_slot)
	player.get_node("%Book").open_book.connect(G.gui.hud.inventory.hide)
	player.get_node("%Book").close_book.connect(G.gui.hud.inventory.show)
	player.get_node("%Book").open_book.connect(G.gui.hud.aim.hide)
	player.get_node("%Book").close_book.connect(G.gui.hud.aim.show)
	player.get_node("FearController").changed.connect(G.gui.hud.fear_vignette.on_fear_changed)
	player.get_node("%HealthComponent").on_damage.connect(G.gui.hud.damage_vignette.on_damage)
	player.get_node("%HealthComponent").changed.connect(G.gui.hud.heart_cradiogram.on_health_changed)
	player.get_node("FearController").suspense.connect(G.gui.hud.heart_cradiogram.set_suspense)
	player.get_node("FearController").panic.connect(G.gui.hud.heart_cradiogram.set_panic)
	player.get_node("FearController").scare.connect(G.gui.hud.heart_cradiogram.trigger_scare)
	player.get_node("FearController").shock.connect(G.gui.hud.heart_cradiogram.trigger_shock)
	player.get_node("HungerController").changed.connect(G.gui.hud.bar_box.hunger_changed)
	player.get_node("TemperatureController").changed.connect(G.gui.hud.bar_box.temp_changed)
	player.get_node("ProgressController").changed.connect(G.gui.hud.bar_box.exp_changed)
	player.get_node("StaminaController").changed.connect(G.gui.hud.stamina_bar.on_stamina_changed)
	G.player = player


func add_player(peer_id: int) -> void:
	var player = PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	player.position.y = 50
	# Используем call_deferred для безопасности физики
	G.environment.add_child(player, true)
	
	# Если игрок это мы, отложенно подключаем сигналы
	if peer_id == multiplayer.get_unique_id():
		set_up_player(player)
		player.position.x = randf_range(-10.0, 10.0)
		player.position.z = randf_range(-10.0, 10.0)
	else:
		G.world.rpc_id(peer_id, "join_world", G.world.world_name, G.world.world_seed, G.world.world_size)


func remove_player(peer_id: int) -> void:
	var player = G.environment.get_node_or_null(str(peer_id))
	player.queue_free()


func start_game(is_load: bool = false) -> void:
	G.gui.main_menu.hide()
	G.gui.background.queue_free()
	if multiplayer.get_unique_id() == 1:
		if is_load:
			G.world.world_name = G.gui.main_menu.world_chooser.text
			G.world.load_world()
			G.player.load_character() # Клиент же при входе грузится в world
		else:
			G.world.world_name = G.gui.main_menu.world_name.text
			G.world.start_gen()
	S.state_machine = "game"
	G.gui.game_menu.game = true


func _on_create_button_pressed() -> void:
	if G.gui.main_menu.world_name.text == "": return
	if G.gui.main_menu.host_button.button_pressed:
		prepare_for_a_game("server")
		start_game()
	else:
		add_player(1)
		start_game()

func _on_load_button_pressed() -> void:
	if G.gui.main_menu.world_chooser.text == "": return
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
		set_up_player(node)
