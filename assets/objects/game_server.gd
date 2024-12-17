extends Node
class_name GameServer

@export var world: GameWorld
@export var block_generator: BlockGenerator
@export var block_serializer: BlockSerializer

static var instance: GameServer

func recieve_packet(packet: GamePacket, client: ClientConnection):
	match packet.type:
		Packets.ClientPacket.PLAYER_POSITION:
			print(packet.data)

func connect_client(client: ClientConnection) -> void:
	for chunk in world.block_world.chunk_map.values():
		var packet := GamePacket.new()
		
		packet.type = Packets.ServerPacket.BLOCK_CHUNK
		packet.data = block_serializer.save_chunk(chunk)
		
		client.send_packet(packet)

func _init() -> void:
	instance = self

func _ready() -> void:
	block_generator.start_generator()
	block_generator.generate_area(0, 16)
