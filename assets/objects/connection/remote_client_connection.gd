extends ClientConnection
class_name RemoteClientConnection

var peer_id: int

func send_packet(packet: ServerPacket) -> void:
	ServerHost.scene.multiplayer.send_bytes(
		var_to_bytes({ "type": packet.type, "data": packet.data }), peer_id)
