extends ClientConnection
class_name LocalClientConnection

func send_packet(packet: GamePacket) -> void:
	GameScene.instance.packet_manager.recieve_packet(packet)
