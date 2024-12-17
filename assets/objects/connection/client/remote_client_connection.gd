extends ClientConnection
class_name RemoteClientConnection

var peer: ENetPacketPeer

func send_packet(packet: GamePacket) -> void:
	packet.send_to(peer)
