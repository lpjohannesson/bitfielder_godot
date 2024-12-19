extends Node2D
class_name RemoteGameScene

@export var pause_screen: PauseScreen
var paused := false

func pause_game() -> void:
	paused = not paused
	pause_screen.visible = paused

func disconnect_server() -> void:
	get_tree().change_scene_to_file("res://assets/scenes/menu_scene.tscn")

func _ready() -> void:
	GameScene.instance.server = RemoteServerConnection.instance

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pause_game()
	
	var server := RemoteServerConnection.instance
	
	while true:
		var peer_event: Array = server.connection.service()
		var event_type: ENetConnection.EventType = peer_event[0]
		
		match event_type:
			ENetConnection.EVENT_NONE:
				break
			
			ENetConnection.EVENT_DISCONNECT:
				disconnect_server()
			
			ENetConnection.EVENT_RECEIVE:
				var packet = GamePacket.from_bytes(server.peer.get_packet())
				GameScene.instance.packet_manager.recieve_packet(packet)

func _on_pause_screen_continue_selected() -> void:
	pause_game()

func _on_pause_screen_quit_selected() -> void:
	disconnect_server()
