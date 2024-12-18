extends Node
class_name GameServer

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
	for chunk in world.block_world.chunk_map.values():
		client.send_packet(get_block_chunk_packet(chunk))
	
	for entity in world.entities.entities:
		client.send_packet(get_create_entity_packet(entity))
	
	client.send_packet(get_assign_player_packet(client))
	
	# Add client and send to others
	var entity_packet := get_create_entity_packet(player.entity)
	
	for other_client in clients:
		other_client.send_packet(entity_packet)
	
	clients.push_back(client)

func _init() -> void:
	instance = self

func _ready() -> void:
	block_generator.start_generator()
	block_generator.generate_area(0, 16)

func _process(_delta: float) -> void:
	for entity in world.entities.entities:
		if entity.body != null:
			var position_packet := get_entity_position_packet(entity)
			var velocity_packet = get_entity_velocity_packet(entity)
			
			for client in clients:
				if entity == client.player.entity:
					continue
				
				client.send_packet(position_packet)
				client.send_packet(velocity_packet)
