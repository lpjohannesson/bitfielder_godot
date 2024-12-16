extends Node
class_name GameServer

@export var world: GameWorld
@export var block_generator: BlockGenerator
@export var block_serializer: BlockSerializer

func connect_client(client: ClientConnection) -> void:
	for chunk in world.block_world.chunk_map.values():
		var packet := ServerPacket.new()
		
		packet.type = ServerPacket.PacketType.BLOCK_CHUNK
		packet.data = block_serializer.save_chunk(chunk)
		
		client.send_packet(packet)

func _ready() -> void:
	block_generator.start_generator()
	block_generator.generate_area(0, 16)
