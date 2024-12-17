extends ServerConnection
class_name RemoteServerConnection

var connection := ENetConnection.new()
var peer: ENetPacketPeer

static var instance: RemoteServerConnection

func send_packet(packet: GamePacket) -> void:
	packet.send_to(peer)
