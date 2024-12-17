extends Node2D
class_name RemoteGameScene

func _ready() -> void:
	GameScene.instance.server = RemoteServerConnection.instance

func _process(_delta: float) -> void:
	var server := RemoteServerConnection.instance
	
	while true:
		var peer_event: Array = server.connection.service()
		var event_type: ENetConnection.EventType = peer_event[0]
		
		match event_type:
			ENetConnection.EVENT_NONE:
				break
			
			ENetConnection.EVENT_RECEIVE:
				var packet = GamePacket.from_bytes(server.peer.get_packet())
				GameScene.instance.packet_manager.recieve_packet(packet)
