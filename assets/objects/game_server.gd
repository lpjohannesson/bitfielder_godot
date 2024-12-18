extends Node
class_name GameServer

const CHUNK_LOAD_EXTENTS := Vector2i(3, 2)
const BLOCK_CHECK_TIMEOUT := 0.25

@export var world: GameWorld
@export var block_generator: BlockGenerator
@export var block_serializer: BlockSerializer

static var instance: GameServer

var clients: Array[ClientConnection] = []
var next_entity_id := 1

func add_entity(entity: GameEntity, entity_node: Node) -> void:
	world.entities.add_entity(entity, next_entity_id, entity_node, true)
	next_entity_id += 1

func get_block_chunk_packet(chunk: BlockChunk) -> GamePacket:
	return GamePacket.create_packet(
		Packets.ServerPacket.CREATE_BLOCK_CHUNK,
		block_serializer.save_chunk(chunk)
	)

func get_player_chunk_index_packet(chunk_index: Vector2i) -> GamePacket:
	return GamePacket.create_packet(
		Packets.ServerPacket.PLAYER_CHUNK_INDEX,
		chunk_index
	)

func get_update_block_packet(block_specifier: BlockSpecifier) -> GamePacket:
	return GamePacket.create_packet(
		Packets.ServerPacket.UPDATE_BLOCK,
		block_specifier.to_data(world.block_world)
	)

func update_block(block_specifier: BlockSpecifier) -> void:
	world.block_world.update_block(block_specifier.block_position)
	var packet := get_update_block_packet(block_specifier)
	
	for client in clients:
		client.send_packet(packet)

func get_create_entity_packet(entity: GameEntity) -> GamePacket:
	return GamePacket.create_packet(
		Packets.ServerPacket.CREATE_ENTITY,
		{
			"id": entity.entity_id,
			"type": entity.entity_type
		}
	)

func get_entity_position_packet(entity: GameEntity) -> GamePacket:
	return GamePacket.create_packet(
		Packets.ServerPacket.ENTITY_POSITION,
		{ "id": entity.entity_id, "value": entity.body.position }
	)

func get_entity_velocity_packet(entity: GameEntity) -> GamePacket:
	return GamePacket.create_packet(
		Packets.ServerPacket.ENTITY_VELOCITY,
		{ "id": entity.entity_id, "value": entity.body.velocity }
	)

func get_assign_player_packet(client: ClientConnection) -> GamePacket:
	return GamePacket.create_packet(
		Packets.ServerPacket.ASSIGN_PLAYER,
		client.player.entity.entity_id
	)

func rubberband_player(client: ClientConnection):
	var entity := client.player.entity
	
	client.send_packet(get_entity_position_packet(entity))
	client.send_packet(get_entity_velocity_packet(entity))

func check_player_position(packet: GamePacket, client: ClientConnection) -> void:
	var position: Vector2 = packet.data["position"]
	
	# Check if player needs to be teleported
	if client.player.global_position.distance_to(position) > 8.0:
		rubberband_player(client)

func get_failed_block_packet(
		block_specifier: BlockSpecifier,
		block_id: int) -> GamePacket:
	
	# Send update for current block
	var new_block_specifier := BlockSpecifier.new()
	
	new_block_specifier.block_position = block_specifier.block_position
	new_block_specifier.on_front_layer = block_specifier.on_front_layer
	new_block_specifier.block_id = block_id
	
	return get_update_block_packet(new_block_specifier)

func check_block_update(packet: GamePacket, client: ClientConnection) -> void:
	# Delay block check to wait for server-side changes
	await get_tree().create_timer(BLOCK_CHECK_TIMEOUT).timeout
	
	var block_specifier := BlockSpecifier.from_data(packet.data, world.block_world)
	var address := world.block_world.get_block_address(block_specifier.block_position)
	
	if address == null:
		return
	
	# Re-update block on client if not matching
	var block_ids := block_specifier.get_layer(address.chunk)
	var block_id := block_ids[address.block_index]
	
	if block_id != block_specifier.block_id:
		client.send_packet(get_failed_block_packet(block_specifier, block_id))

func update_player_input(
		packet: GamePacket,
		client: ClientConnection,
		input_state: bool) -> void:
	
	var action: String = packet.data["action"]
	client.player.player_input.input_map[action] = input_state

func recieve_packet(packet: GamePacket, client: ClientConnection) -> void:
	match packet.type:
		Packets.ClientPacket.CHECK_PLAYER_POSITION:
			check_player_position(packet, client)
		
		Packets.ClientPacket.CHECK_BLOCK_UPDATE:
			check_block_update(packet, client)
		
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
	client.chunk_index = get_player_chunk_index(client)
	var chunk_load_zone = get_chunk_load_zone(client.chunk_index)
	
	for y in range(chunk_load_zone.position.y, chunk_load_zone.end.y):
		for x in range(chunk_load_zone.position.x, chunk_load_zone.end.x):
			var chunk_index := Vector2i(x, y)
			var chunk := world.block_world.get_chunk(chunk_index)
			
			if chunk == null:
				continue
			
			client.send_packet(get_block_chunk_packet(chunk))
	
	for entity in world.entities.entities:
		client.send_packet(get_create_entity_packet(entity))
	
	client.send_packet(get_assign_player_packet(client))
	
	# Add client and send to others
	var entity_packet := get_create_entity_packet(player.entity)
	
	for other_client in clients:
		other_client.send_packet(entity_packet)
	
	clients.push_back(client)

func get_player_chunk_index(client: ClientConnection) -> Vector2i:
	var player_block_position := \
		world.block_world.world_to_block_round(client.player.global_position)
	
	return BlockWorld.get_chunk_index(player_block_position)

static func get_chunk_load_zone(chunk_index: Vector2i) -> Rect2i:
	return Rect2i(
		chunk_index - CHUNK_LOAD_EXTENTS,
		CHUNK_LOAD_EXTENTS * 2)

func update_player_chunks(client: ClientConnection) -> void:
	var chunk_index = get_player_chunk_index(client)
	
	# Skip if still on same chunk
	if chunk_index == client.chunk_index:
		return
	
	var old_load_zone = get_chunk_load_zone(client.chunk_index)
	var new_load_zone = get_chunk_load_zone(chunk_index)
	
	for y in range(new_load_zone.position.y, new_load_zone.end.y):
		for x in range(new_load_zone.position.x, new_load_zone.end.x):
			var new_chunk_index := Vector2i(x, y)
			
			# Skip already loaded chunks
			if old_load_zone.has_point(new_chunk_index):
				continue
			
			var chunk := world.block_world.get_chunk(new_chunk_index)
			
			if chunk == null:
				continue
			
			client.send_packet(get_block_chunk_packet(chunk))
	
	client.chunk_index = chunk_index
	client.send_packet(get_player_chunk_index_packet(chunk_index))

func _init() -> void:
	instance = self

func _ready() -> void:
	block_generator.start_generator()
	block_generator.generate_area(0, 16)

func _process(_delta: float) -> void:
	for client in clients:
		update_player_chunks(client)
	
	for entity in world.entities.entities:
		if entity.body != null:
			var position_packet := get_entity_position_packet(entity)
			var velocity_packet = get_entity_velocity_packet(entity)
			
			for client in clients:
				if entity == client.player.entity:
					continue
				
				client.send_packet(position_packet)
				client.send_packet(velocity_packet)
