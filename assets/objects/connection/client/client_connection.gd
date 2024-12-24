class_name ClientConnection

var player: Player
var chunk_load_position: Vector2
var skin_bytes: PackedByteArray

func send_packet(_packet: GamePacket) -> void:
	pass
