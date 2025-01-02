extends ClientConnection
class_name RemoteClientConnection

var peer: ENetPacketPeer
var client_accepted := false

func send_packet(packet: GamePacket) -> void:
	packet.send_to(peer)
