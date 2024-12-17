extends Node
class_name GameServer

@export var world: GameWorld
@export var block_generator: BlockGenerator
@export var block_serializer: BlockSerializer

static var instance: GameServer

var clients: Array[ClientConnection] = []
var next_entity_id := 1

func add_entity(entity: GameEntity, entity_node: Node) -> void:
	world.entities.add_entity(entity, next_entity_id, entity_node, true)
	next_entity_id += 1

func send_block_chunk(chunk: BlockChunk, client: ClientConnection) -> void:
	var packet := GamePacket.create_packet(
		Packets.ServerPacket.CREATE_BLOCK_CHUNK,
		block_serializer.save_chunk(chunk)
	)
	
	client.send_packet(packet)

func send_entity(entity: GameEntity, client: ClientConnection) -> void:
	var packet := GamePacket.create_packet(
		Packets.ServerPacket.CREATE_ENTITY,
		{
			"id": entity.entity_id,
			"type": entity.entity_type
		}
	)
	
	client.send_packet(packet)

func send_entity_position(entity: GameEntity, client: ClientConnection) -> void:
	var packet := GamePacket.create_packet(
		Packets.ServerPacket.ENTITY_POSITION,
		{ "id": entity.entity_id, "value": entity.body.position }
	)
	
	client.send_packet(packet)

func send_entity_velocity(entity: GameEntity, client: ClientConnection) -> void:
	var packet := GamePacket.create_packet(
		Packets.ServerPacket.ENTITY_VELOCITY,
		{ "id": entity.entity_id, "value": entity.body.velocity }
	)
	
	client.send_packet(packet)

func assign_player(client: ClientConnection):
	var packet := GamePacket.create_packet(
		Packets.ServerPacket.ASSIGN_PLAYER,
		client.player.entity.entity_id
	)
	
	client.send_packet(packet)

func rubberband_player(client: ClientConnection):
	send_entity_position(client.player.entity, client)
	send_entity_velocity(client.player.entity, client)

func check_player_position(packet: GamePacket, client: ClientConnection) -> void:
	var position: Vector2 = packet.data["position"]
	
	# Check if player needs to be teleported
	if client.player.global_position.distance_to(position) > 8.0:
		rubberband_player(client)

func update_player_input(
		packet: GamePacket,
		client: ClientConnection,
		input_state: bool) -> void:
	
	var action: String = packet.data["action"]
	client.player.player_input.input_map[action] = input_state

func recieve_packet(packet: GamePacket, client: ClientConnection) -> void:
	match packet.type:
		Packets.ClientPacket.PLAYER_POSITION:
			check_player_position(packet, client)
		
		Packets.ClientPacket.ACTION_PRESSED:
			update_player_input(packet, client, true)
		
		Packets.ClientPacket.ACTION_RELEASED:
			update_player_input(packet, client, false)

func connect_client(client: ClientConnection) -> void:
	# Spawn player
	var player: Player = world.entities.player_scene.instantiate()
	add_entity(player.entity, player)
	
	client.player = player
	
	# Send initial packets
	for chunk in world.block_world.chunk_map.values():
		send_block_chunk(chunk, client)
	
	for entity in world.entities.entities:
		send_entity(entity, client)
	
	assign_player(client)
	
	# Add client and send to others
	for other_client in clients:
		send_entity(player.entity, other_client)
	
	clients.push_back(client)

func _init() -> void:
	instance = self

func _ready() -> void:
	block_generator.start_generator()
	block_generator.generate_area(0, 16)

func _process(_delta: float) -> void:
	for client in clients:
		for entity in world.entities.entities:
			# Skip sending client's player
			if entity == client.player.entity:
				continue
			
			if entity.body != null:
				send_entity_position(entity, client)
				send_entity_velocity(entity, client)
