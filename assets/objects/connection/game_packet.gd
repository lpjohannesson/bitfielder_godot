class_name GamePacket

var type: int
var data: Variant

static func create_packet(init_type: int, init_data: Variant) -> GamePacket:
	var packet := GamePacket.new()
	
	packet.type = init_type
	packet.data = init_data
	
	return packet

static func from_bytes(bytes: PackedByteArray) -> GamePacket:
	var packet_data = bytes_to_var(bytes)
	
	return create_packet(packet_data["type"], packet_data["data"])

func to_bytes() -> PackedByteArray:
	return var_to_bytes({
		"type": type,
		"data": data
	})

func send_to(peer: ENetPacketPeer) -> void:
	peer.send(0, to_bytes(), ENetPacketPeer.FLAG_RELIABLE)
