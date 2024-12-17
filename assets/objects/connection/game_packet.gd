class_name GamePacket

var type: int
var data: Variant

func to_bytes() -> PackedByteArray:
	return var_to_bytes({
		"type": type,
		"data": data
	})

func send_to(peer: ENetPacketPeer) -> void:
	peer.send(0, to_bytes(), ENetPacketPeer.FLAG_RELIABLE)

static func from_bytes(bytes: PackedByteArray) -> GamePacket:
	var packet_data = bytes_to_var(bytes)
	var packet := GamePacket.new()
	
	packet.type = packet_data["type"]
	packet.data = packet_data["data"]
	
	return packet
