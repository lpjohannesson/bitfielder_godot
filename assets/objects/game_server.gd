extends Node
class_name GameServer

const CHUNK_LOAD_EXTENTS := Vector2i(4, 3)
const BLOCK_CHECK_TIMEOUT := 0.25
const CHUNK_LOAD_DISTANCE := 128.0

@export var world: GameWorld
@export var block_generator: BlockGenerator
@export var block_serializer: BlockSerializer

static var instance: GameServer

var clients: Array[ClientConnection] = []
var next_entity_id := 1

func add_entity(entity: GameEntity) -> void:
	entity.entity_id = next_entity_id
	entity.on_server = true
	
	world.entities.add_entity(entity)
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

func get_update_block_packet(
		block_specifier: BlockSpecifier,
		show_effects: bool) -> GamePacket:
	
	return GamePacket.create_packet(
		Packets.ServerPacket.UPDATE_BLOCK,
		[block_specifier.to_data(world.block_world), show_effects]
	)

func update_block(
		block_specifier: BlockSpecifier,
		address: BlockAddress,
		show_effects: bool) -> void:
	
	# Ensure entities are updated before block update
	send_entity_states()
	
	block_specifier.write_address(address)
	
	world.block_world.update_block(block_specifier.block_position)
	var packet := get_update_block_packet(block_specifier, show_effects)
	
	for client in clients:
		client.send_packet(packet)

func get_create_entity_packet(entity: GameEntity) -> GamePacket:
	return GamePacket.create_packet(
		Packets.ServerPacket.CREATE_ENTITY,
		EntityDataManager.create_entity_spawn_data(entity)
	)

func get_destroy_entity_packet(entity: GameEntity) -> GamePacket:
	return GamePacket.create_packet(
		Packets.ServerPacket.DESTROY_ENTITY,
		entity.entity_id
	)

func get_entity_data_packet(entity_data: Dictionary) -> GamePacket:
	return GamePacket.create_packet(
		Packets.ServerPacket.ENTITY_DATA,
		entity_data
	)

func get_assign_player_packet(client: ClientConnection) -> GamePacket:
	return GamePacket.create_packet(
		Packets.ServerPacket.ASSIGN_PLAYER,
		client.player.entity.entity_id
	)

func rubberband_player(client: ClientConnection):
	var entity := client.player.entity
	
	var entity_data := EntityDataManager.create_entity_data(entity)
	var request = EntityDataManager.DataRequest.create(entity, entity_data, true)
	
	EntityDataManager.save_entity_position(request)
	EntityDataManager.save_entity_velocity(request)
	
	client.send_packet(get_entity_data_packet(entity_data))

func check_player_position(packet: GamePacket, client: ClientConnection) -> void:
	var position: Vector2 = packet.data
	
	# Check if player needs to be teleported
	if client.player.global_position.distance_to(position) > 12.0:
		rubberband_player(client)

func get_failed_block_packet(
		block_specifier: BlockSpecifier,
		block_id: int) -> GamePacket:
	
	# Send update for current block
	var new_block_specifier := BlockSpecifier.new()
	
	new_block_specifier.block_position = block_specifier.block_position
	new_block_specifier.on_front_layer = block_specifier.on_front_layer
	new_block_specifier.block_id = block_id
	
	return get_update_block_packet(new_block_specifier, false)

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
	
	var action: String = packet.data
	client.player.player_input.set_action(action, input_state)

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

func get_player_chunk_index(player_position: Vector2) -> Vector2i:
	var player_block_position := \
		world.block_world.world_to_block_round(player_position)
	
	return BlockWorld.get_chunk_index(player_block_position)

static func get_chunk_load_zone(chunk_index: Vector2i) -> Rect2i:
	return Rect2i(
		chunk_index - CHUNK_LOAD_EXTENTS,
		CHUNK_LOAD_EXTENTS * 2)

func update_player_chunks(client: ClientConnection) -> void:
	var player_position := client.player.global_position
	
	# Skip if close to loaded position
	if client.chunk_load_position.distance_to(player_position) < CHUNK_LOAD_DISTANCE:
		return
	
	var old_chunk_index = get_player_chunk_index(client.chunk_load_position)
	var new_chunk_index = get_player_chunk_index(player_position)
	
	var old_load_zone = get_chunk_load_zone(old_chunk_index)
	var new_load_zone = get_chunk_load_zone(new_chunk_index)
	
	for y in range(new_load_zone.position.y, new_load_zone.end.y):
		for x in range(new_load_zone.position.x, new_load_zone.end.x):
			var chunk_index := Vector2i(x, y)
			
			# Skip already loaded chunks
			if old_load_zone.has_point(chunk_index):
				continue
			
			var chunk := world.block_world.get_chunk(chunk_index)
			
			if chunk == null:
				continue
			
			client.send_packet(get_block_chunk_packet(chunk))
	
	client.send_packet(get_player_chunk_index_packet(new_chunk_index))
	client.chunk_load_position = player_position

func send_entity_states() -> void:
	for entity in world.entities.entities:
		var entity_data := EntityDataManager.create_entity_update_data(entity, false)
		
		# Check if no data besides ID
		if entity_data.size() == 1:
			continue
		
		var packet := get_entity_data_packet(entity_data)
		
		for client in clients:
			if entity == client.player.entity:
				continue
			
			client.send_packet(packet)

func connect_client(client: ClientConnection) -> void:
	# Spawn player
	var player: Player = world.entities_data.player_scene.instantiate()
	add_entity(player.entity)
	
	client.player = player
	
	# Send initial packets
	client.chunk_load_position = player.global_position
	var player_chunk_index = get_player_chunk_index(player.global_position)
	
	var chunk_load_zone = get_chunk_load_zone(player_chunk_index)
	
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
	var create_player_packet := get_create_entity_packet(player.entity)
	
	for other_client in clients:
		other_client.send_packet(create_player_packet)
	
	clients.push_back(client)

func disconnect_client(client: ClientConnection) -> void:
	clients.erase(client)
	
	# Send removal to others
	var destroy_packet := get_destroy_entity_packet(client.player.entity)
	
	for other_client in clients:
		other_client.send_packet(destroy_packet)
	
	world.entities.remove_entity(client.player.entity)

func _init() -> void:
	instance = self

func _ready() -> void:
	block_generator.start_generator()
	block_generator.generate_area(0, 16)

func _process(_delta: float) -> void:
	for client in clients:
		update_player_chunks(client)

func _on_entity_send_timer_timeout() -> void:
	send_entity_states()
