extends Node
class_name GamePacketManager

@export var scene: GameScene

func load_block_chunk(packet: GamePacket) -> void:
	var block_world := scene.world.block_world
	var chunk := block_world.create_chunk(packet.data["index"])
	
	scene.block_serializer.load_chunk(chunk, packet.data)
	block_world.update_chunk(chunk)
	
	scene.block_world_renderer.start_chunk(chunk)

func recieve_packet(packet: GamePacket) -> void:
	match packet.type:
		Packets.ServerPacket.BLOCK_CHUNK:
			load_block_chunk(packet)
