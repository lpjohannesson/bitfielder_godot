extends Node2D
class_name MenuScene

@export var main_menu: MainMenu
@export var remote_play_menu: RemotePlayMenu
@export var connection_menu: ConnectionMenu
@export var connection_timer: Timer

func get_server() -> RemoteServerConnection:
	return RemoteServerConnection.instance

func stop_server_connection() -> void:
	var server := get_server()
	
	if server == null:
		return
	
	# Send final packets
	if server.peer != null and server.peer.is_active():
		server.connection.service()
	
	server.connection.destroy()
	RemoteServerConnection.instance = null

func poll_server(server: RemoteServerConnection) -> bool:
	while true:
		var peer_event: Array = server.connection.service()
		var event_type: ENetConnection.EventType = peer_event[0]
		
		match event_type:
			ENetConnection.EVENT_NONE:
				break
			
			ENetConnection.EVENT_CONNECT:
				return true
	
	return false

func _ready() -> void:
	# Check if disconnected from server
	if get_server() == null:
		main_menu.select_menu_page()
	else:
		main_menu.hide()
		connection_menu.select_menu_page()
		connection_menu.show_disconnected()
		
		stop_server_connection()

func _process(_delta: float) -> void:
	var server := get_server()
	
	if server != null:
		if poll_server(server):
			get_tree().change_scene_to_file(
				"res://assets/scenes/remote_game_scene.tscn")

func _on_main_menu_local_play_selected() -> void:
	get_tree().change_scene_to_file(
		"res://assets/scenes/local_game_scene.tscn")

func _on_main_menu_remote_play_selected() -> void:
	main_menu.hide()
	remote_play_menu.select_menu_page()

func _on_remote_play_menu_connect_selected(address: String, port: int) -> void:
	remote_play_menu.hide()
	connection_menu.select_menu_page()
	
	# Connect to server
	var server := RemoteServerConnection.new()
	RemoteServerConnection.instance = server
	
	server.connection.create_host(1)
	server.peer = server.connection.connect_to_host(address, port)
	
	connection_menu.show_connecting()
	connection_timer.start()

func _on_remote_play_menu_cancel_selected() -> void:
	remote_play_menu.hide()
	main_menu.select_menu_page()

func _on_connection_menu_back_selected() -> void:
	stop_server_connection()
	
	connection_menu.hide()
	remote_play_menu.select_menu_page()

func _on_connection_timer_timeout() -> void:
	stop_server_connection()
	
	connection_menu.show_connection_timed_out()
