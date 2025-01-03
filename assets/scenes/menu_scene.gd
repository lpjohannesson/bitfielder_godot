extends Control
class_name MenuScene

enum ConnectionState {
	STOPPED,
	CONNECTING,
	LOGGING_IN
}

@export var main_menu: MainMenu
@export var remote_play_menu: RemotePlayMenu
@export var connection_menu: ConnectionMenu
@export var connection_timer: Timer
@export var copyright_label: Label

@export var copyright_text: String

var connection_state := ConnectionState.STOPPED

func get_server() -> RemoteServerConnection:
	return RemoteServerConnection.instance

func stop_server_connection() -> void:
	var server := get_server()
	
	if server == null:
		return
	
	server.connection.destroy()
	RemoteServerConnection.instance = null
	
	connection_state = ConnectionState.STOPPED
	connection_timer.stop()

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

func get_server_packet(server: RemoteServerConnection) -> GamePacket:
	while true:
		var peer_event: Array = server.connection.service()
		var event_type: ENetConnection.EventType = peer_event[0]
		
		match event_type:
			ENetConnection.EVENT_NONE:
				break
			
			ENetConnection.EVENT_RECEIVE:
				return GamePacket.from_bytes(server.peer.get_packet())
	
	return null

func try_connect_server() -> void:
	var server := get_server()
	
	if not poll_server(server):
		return
	
	# Start login
	var login_info := remote_play_menu.get_login_info()
	
	server.send_packet(GamePacket.create_packet(
		Packets.ClientPacket.LOGIN_INFO,
		login_info.to_data()))
	
	connection_state = ConnectionState.LOGGING_IN
	connection_timer.start()
	
	connection_menu.show_status(connection_menu.logging_in_text)
	
	try_login_server()

func show_server_rejection(packet: GamePacket) -> void:
	stop_server_connection()
	
	match packet.type:
		Packets.ServerPacket.REJECT_CONNECTION:
			connection_menu.show_status(connection_menu.connection_rejected_text)
		
		Packets.ServerPacket.USERNAME_IN_USE:
			connection_menu.show_status(connection_menu.username_in_use_text)
		
		Packets.ServerPacket.WRONG_GAME_VERSION:
			connection_menu.show_status(
				connection_menu.wrong_game_version_text % packet.data)

func try_login_server() -> void:
	var server := get_server()
	var packet := get_server_packet(server)
	
	if packet == null:
		return
	
	if packet.type == Packets.ServerPacket.ACCEPT_CONNECTION:
		login_server()
	else:
		show_server_rejection(packet)

func login_server() -> void:
	get_tree().change_scene_to_file(
		"res://assets/scenes/remote_game_scene.tscn")

func _ready() -> void:
	copyright_label.text = copyright_text % GameServer.get_game_version()
	
	# Check if disconnected from server
	if get_server() == null:
		main_menu.select_menu_page()
	else:
		main_menu.hide()
		connection_menu.select_menu_page()
		connection_menu.show_status(connection_menu.disconnected_text)
		
		stop_server_connection()

func _process(_delta: float) -> void:
	match connection_state:
		ConnectionState.CONNECTING:
			try_connect_server()
		
		ConnectionState.LOGGING_IN:
			try_login_server()

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
	
	connection_menu.show_status(connection_menu.connecting_text)
	connection_timer.start()
	
	connection_state = ConnectionState.CONNECTING

func _on_remote_play_menu_cancel_selected() -> void:
	remote_play_menu.hide()
	main_menu.select_menu_page()

func _on_connection_menu_back_selected() -> void:
	stop_server_connection()
	
	connection_menu.hide()
	remote_play_menu.select_menu_page()

func _on_connection_timer_timeout() -> void:
	stop_server_connection()
	
	connection_menu.show_status(connection_menu.connection_timed_out_text)
