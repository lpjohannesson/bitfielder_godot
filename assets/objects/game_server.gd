extends Node
class_name GameServer

@export var world: GameWorld
@export var block_generator: BlockGenerator
@export var block_serializer: BlockSerializer
@export var player_scene: PackedScene

static var instance: GameServer

func rubberband_player(client: ClientConnection):
	var packet := GamePacket.create_packet(
		Packets.ServerPacket.TELEPORT_PLAYER,
		{
			"position": client.player.global_position,
			"velocity": client.player.velocity
		}
	)
	
	client.send_packet(packet)

func update_player_position(packet: GamePacket, client: ClientConnection):
	var position: Vector2 = packet.data["position"]
	
	# Check if player needs to be teleported
	if client.player.global_position.distance_to(position) > 8.0:
		rubberband_player(client)

func update_player_input(
		packet: GamePacket,
		client: ClientConnection,
		input_state: bool):
	
	var action: String = packet.data["action"]
	client.player.player_input.input_map[action] = input_state

func recieve_packet(packet: GamePacket, client: ClientConnection):
	match packet.type:
		Packets.ClientPacket.PLAYER_POSITION:
			update_player_position(packet, client)
		
		Packets.ClientPacket.ACTION_PRESSED:
			update_player_input(packet, client, true)
		
		Packets.ClientPacket.ACTION_RELEASED:
			update_player_input(packet, client, false)

func connect_client(client: ClientConnection) -> void:
	# Spawn player
	var player: Player = player_scene.instantiate()
	add_child(player)
	
	client.player = player
	player.entity.on_server = true
	
	for chunk in world.block_world.chunk_map.values():
		var packet := GamePacket.create_packet(
			Packets.ServerPacket.BLOCK_CHUNK,
			block_serializer.save_chunk(chunk)
		)
		
		client.send_packet(packet)

func _init() -> void:
	instance = self

func _ready() -> void:
	block_generator.start_generator()
	block_generator.generate_area(0, 16)
