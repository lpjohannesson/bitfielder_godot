extends Node2D
class_name RemoteGameScene

var peer := ENetMultiplayerPeer.new()

func _ready() -> void:
	peer.create_client("localhost", ServerHost.PORT)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(func(_id: int) -> void:
		print("connected")
	)
	
	multiplayer.peer_packet.connect(func(
			id: int, packet: PackedByteArray) -> void:
		
		var packet_data: Dictionary = bytes_to_var(packet)
		
		var server_packet := ServerPacket.new()
		server_packet.type = packet_data["type"]
		server_packet.data = packet_data["data"]
		
		GameScene.scene.recieve_packet(server_packet)
	)
