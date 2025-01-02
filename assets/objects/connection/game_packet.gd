class_name GamePacket

var type: int
var data: Variant

static func create_packet(init_type: int, init_data: Variant) -> GamePacket:
	var packet := GamePacket.new()
	
	packet.type = init_type
	packet.data = init_data
	
	return packet

static func is_data_valid(packet_data: Variant) -> bool:
	if not packet_data is Array:
		return false
	
	if not packet_data.size() == 2:
		return false
	
	if not packet_data[0] is int:
		return false
	
	return true

static func from_bytes(bytes: PackedByteArray) -> GamePacket:
	var packet_data = bytes_to_var(bytes)
	
	if not is_data_valid(packet_data):
		return null
	
	return create_packet(packet_data[0], packet_data[1])

func to_bytes() -> PackedByteArray:
	return var_to_bytes([type, data])

func send_to(peer: ENetPacketPeer) -> void:
	peer.send(0, to_bytes(), ENetPacketPeer.FLAG_RELIABLE)
