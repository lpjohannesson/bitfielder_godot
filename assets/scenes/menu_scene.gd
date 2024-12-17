extends Node2D
class_name MenuScene

@export var main_menu: MainMenu
@export var multiplayer_menu: MultiplayerMenu
@export var connection_menu: ConnectionMenu

var server: RemoteServerConnection

func poll_server() -> bool:
	while true:
		var peer_event: Array = server.connection.service()
		var event_type: ENetConnection.EventType = peer_event[0]
		
		match event_type:
			ENetConnection.EVENT_NONE:
				break
			
			ENetConnection.EVENT_CONNECT:
				return true
	
	return false

func _process(_delta: float) -> void:
	if server != null:
		if poll_server():
			get_tree().change_scene_to_file("res://assets/scenes/remote_game_scene.tscn")

func _on_main_menu_singleplayer_selected() -> void:
	get_tree().change_scene_to_file("res://assets/scenes/local_game_scene.tscn")

func _on_main_menu_mulitplayer_selected() -> void:
	main_menu.hide()
	multiplayer_menu.show()

func _on_multiplayer_menu_connect_selected(address: String, port: int) -> void:
	multiplayer_menu.hide()
	connection_menu.show()
	
	server = RemoteServerConnection.new()
	RemoteServerConnection.instance = server
	
	server.connection.create_host(1)
	server.peer = server.connection.connect_to_host(address, port)

func _on_multiplayer_menu_cancel_selected() -> void:
	multiplayer_menu.hide()
	main_menu.show()

func _on_connection_menu_cancel_selected() -> void:
	connection_menu.hide()
	multiplayer_menu.show()
