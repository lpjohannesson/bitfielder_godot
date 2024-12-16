extends ClientConnection
class_name LocalClientConnection

func send_packet(packet: ServerPacket) -> void:
	GameScene.scene.recieve_packet(packet)
	pass
