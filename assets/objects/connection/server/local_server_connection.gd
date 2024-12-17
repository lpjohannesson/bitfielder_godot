extends ServerConnection
class_name LocalServerConnection

var client: LocalClientConnection

func send_packet(packet: GamePacket) -> void:
	GameServer.instance.recieve_packet(packet, client)
