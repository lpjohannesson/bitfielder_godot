extends Node
class_name GameServer

const CHUNK_LOAD_EXTENTS := Vector2i(6, 5)
const BLOCK_CHECK_TIMEOUT := 0.25
const CHUNK_LOAD_DISTANCE := 256.0
const PLAYER_SPAWN_RANGE := 8

@export var world: GameWorld
@export var block_generator: BlockGenerator

static var instance: GameServer

var clients: Array[ClientConnection] = []
var next_entity_id := 1

static func get_game_version() -> String:
	return ProjectSettings.get_setting("application/config/version")

func close_server() -> void:
	for client in clients:
		client.send_packet(GamePacket.create_packet(
			Packets.ServerPacket.SERVER_CLOSED,
			null
		))

func add_entity(entity: GameEntity) -> void:
	entity.entity_id = next_entity_id
	entity.on_server = true
	
	world.entities.add_entity(entity)
	next_entity_id += 1
	
	entity.entity_data = world.entities.serializer.create_entity_spawn_data(entity)

func get_block_chunk_packet(chunk: BlockChunk) -> GamePacket:
	return GamePacket.create_packet(
		Packets.ServerPacket.CREATE_BLOCK_CHUNK,
		world.blocks.serializer.save_chunk(chunk)
	)

func get_block_heightmap_packet(heightmap: PackedInt32Array, chunk_x: int) -> GamePacket:
	return GamePacket.create_packet(
		Packets.ServerPacket.CREATE_BLOCK_HEIGHTMAP,
		[chunk_x, heightmap]
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
		[block_specifier.to_data(world.blocks), show_effects]
	)

func update_block(
		block_specifier: BlockSpecifier,
		address: BlockAddress,
		show_effects: bool) -> void:
	
	# Ensure entities are updated before block update
	send_entity_states()
	
	block_specifier.write_address(address)
	
	world.blocks.update_block(block_specifier.block_position)
	world.blocks.update_heightmap(block_specifier)
	
	var packet := get_update_block_packet(block_specifier, show_effects)
	
	for client in clients:
		client.send_packet(packet)

func get_create_entity_packet(entity: GameEntity) -> GamePacket:
	return GamePacket.create_packet(
		Packets.ServerPacket.CREATE_ENTITY,
		entity.entity_data
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

func get_create_inventory_packet(client: ClientConnection) -> GamePacket:
	return GamePacket.create_packet(
		Packets.ServerPacket.CREATE_INVENTORY,
		world.items.serializer.save_inventory(client.player.inventory)
	)

func rubberband_player(client: ClientConnection):
	var entity := client.player.entity
	var entity_serializer := world.entities.serializer
	
	var entity_data := entity_serializer.create_entity_data(entity)
	var request = EntitySerializer.DataRequest.create(entity, entity_data, true)
	
	entity_serializer.save_entity_position(request)
	entity_serializer.save_entity_velocity(request)
	
	client.send_packet(get_entity_data_packet(entity_data))

func check_player_position(packet: GamePacket, client: ClientConnection) -> void:
	if not packet.data is Vector2:
		return
	
	var sent_position: Vector2 = packet.data
	
	# Check if player needs to be teleported
	if client.player.global_position.distance_to(sent_position) > 12.0:
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
	if not BlockSpecifier.is_data_valid(packet.data):
		return
	
	# Delay block check to wait for server-side changes
	await get_tree().create_timer(BLOCK_CHECK_TIMEOUT).timeout
	
	var block_specifier := BlockSpecifier.from_data(packet.data, world.blocks)
	var address := world.blocks.get_block_address(block_specifier.block_position)
	
	if address == null:
		return
	
	# Re-update block on client if not matching
	var block_id := block_specifier.read_address(address)
	
	if block_id != block_specifier.block_id:
		client.send_packet(get_failed_block_packet(block_specifier, block_id))

func update_player_input(
		packet: GamePacket,
		client: ClientConnection,
		input_state: bool) -> void:
	
	if not packet.data is String:
		return
	
	var action: String = packet.data
	client.player.player_input.set_action(action, input_state)

func reset_player_inputs(client: ClientConnection) -> void:
	client.player.player_input.reset_inputs()

func select_player_item(packet: GamePacket, client: ClientConnection) -> void:
	if not packet.data is int:
		return
	
	var selected_index: int = packet.data
	
	if selected_index < 0 or selected_index > ItemInventory.ITEM_COUNT:
		return
	
	client.player.inventory.selected_index = selected_index

func get_change_player_skin_packet(client: ClientConnection) -> GamePacket:
	return GamePacket.create_packet(
		Packets.ServerPacket.CHANGE_PLAYER_SKIN,
		[client.player.entity.entity_id, client.skin_bytes]
	)

func change_player_skin(packet: GamePacket, client: ClientConnection) -> void:
	if not packet.data is PackedByteArray:
		return
	
	var skin_bytes: PackedByteArray = packet.data
	
	# Check skin is valid
	var skin_image := PlayerSkinManager.load_skin_image(skin_bytes)
	
	if skin_image == null:
		return
	
	client.skin_bytes = skin_bytes
	
	# Send skin to others
	var others_packet := get_change_player_skin_packet(client)
	
	for other_client in clients:
		if other_client == client:
			continue
		
		other_client.send_packet(others_packet)

func get_player_chunk_index(player_position: Vector2) -> Vector2i:
	var player_block_position := \
		world.blocks.world_to_block_round(player_position)
	
	return BlockWorld.get_chunk_index(player_block_position)

static func get_chunk_load_zone(chunk_index: Vector2i) -> Rect2i:
	return Rect2i(
		chunk_index - CHUNK_LOAD_EXTENTS,
		CHUNK_LOAD_EXTENTS * 2)

func update_player_chunk(client: ClientConnection, chunk_index: Vector2i) -> void:
	var chunk := world.blocks.get_chunk(chunk_index)
	
	if chunk == null:
		return
	
	client.send_packet(get_block_chunk_packet(chunk))

func update_player_heightmap(client: ClientConnection, chunk_x: int) -> void:
	var heightmap = world.blocks.get_heightmap(chunk_x)
	
	if heightmap == null:
		return
	
	var heightmap_packet := get_block_heightmap_packet(heightmap, chunk_x)
	client.send_packet(heightmap_packet)

func create_player_chunks(client: ClientConnection) -> void:
	var player := client.player
	
	client.chunk_load_position = player.global_position
	var player_chunk_index = get_player_chunk_index(player.global_position)
	
	var load_zone = get_chunk_load_zone(player_chunk_index)
	
	for chunk_x in range(load_zone.position.x, load_zone.end.x):
		update_player_heightmap(client, chunk_x)
		
		for chunk_y in range(load_zone.position.y, load_zone.end.y):
			var chunk_index := Vector2i(chunk_x, chunk_y)
			update_player_chunk(client, chunk_index)
	
	client.send_packet(get_player_chunk_index_packet(player_chunk_index))

func update_player_chunks(client: ClientConnection) -> void:
	var player_position := client.player.global_position
	
	# Skip if close to loaded position
	if client.chunk_load_position.distance_to(player_position) < CHUNK_LOAD_DISTANCE:
		return
	
	var old_chunk_index = get_player_chunk_index(client.chunk_load_position)
	var new_chunk_index = get_player_chunk_index(player_position)
	
	var old_load_zone = get_chunk_load_zone(old_chunk_index)
	var new_load_zone = get_chunk_load_zone(new_chunk_index)
	
	for chunk_x in range(new_load_zone.position.x, new_load_zone.end.x):
		if chunk_x < old_load_zone.position.x or chunk_x >= old_load_zone.end.x:
			update_player_heightmap(client, chunk_x)
		
		for chunk_y in range(new_load_zone.position.y, new_load_zone.end.y):
			var chunk_index := Vector2i(chunk_x, chunk_y)
			
			# Skip already loaded chunks
			if old_load_zone.has_point(chunk_index):
				continue
			
			update_player_chunk(client, chunk_index)
	
	client.send_packet(get_player_chunk_index_packet(new_chunk_index))
	client.chunk_load_position = player_position

func send_entity_states() -> void:
	for entity in world.entities.entities:
		var entity_data := \
			world.entities.serializer.create_entity_update_data(entity, false)
		
		# Check if no data besides ID
		if entity_data.size() == 1:
			continue
		
		var packet := get_entity_data_packet(entity_data)
		
		for client in clients:
			if entity == client.player.entity:
				continue
			
			client.send_packet(packet)

func recieve_packet(packet: GamePacket, client: ClientConnection) -> void:
	match packet.type:
		Packets.ClientPacket.QUIT_SERVER:
			disconnect_client(client)
		
		Packets.ClientPacket.CHECK_PLAYER_POSITION:
			check_player_position(packet, client)
		
		Packets.ClientPacket.CHECK_BLOCK_UPDATE:
			check_block_update(packet, client)
		
		Packets.ClientPacket.ACTION_PRESSED:
			update_player_input(packet, client, true)
		
		Packets.ClientPacket.ACTION_RELEASED:
			update_player_input(packet, client, false)
		
		Packets.ClientPacket.RESET_INPUTS:
			reset_player_inputs(client)
		
		Packets.ClientPacket.SELECT_ITEM:
			select_player_item(packet, client)
		
		Packets.ClientPacket.CHANGE_SKIN:
			change_player_skin(packet, client)

func connect_client(client: ClientConnection, login_info: ClientLoginInfo) -> void:
	# Spawn player
	var player: Player = world.entities.serializer.player_scene.instantiate()
	client.player = player
	
	player.username = login_info.username
	
	# Set player position
	var player_ground_x := randi_range(-PLAYER_SPAWN_RANGE, PLAYER_SPAWN_RANGE)
	var player_ground_y := world.blocks.get_block_height(player_ground_x) - 1
	var player_ground_position := Vector2i(player_ground_x, player_ground_y)
	
	player.global_position = \
		world.blocks.block_to_world(player_ground_position, true)
	
	add_entity(player.entity)
	
	# Send chunks
	create_player_chunks(client)
	
	# Send entities
	for entity in world.entities.entities:
		client.send_packet(get_create_entity_packet(entity))
	
	# Assign player entity
	client.send_packet(get_assign_player_packet(client))
	
	# Create and send inventory
	var inventory := ItemInventory.new()
	client.player.inventory = inventory
	
	for i in range(world.items.item_types.size() - 1):
		inventory.items[i].item_id = i + 1
	
	client.send_packet(get_create_inventory_packet(client))
	
	# Send player to others
	var create_packet := get_create_entity_packet(player.entity)
	
	for other_client in clients:
		other_client.send_packet(create_packet)
		
		# Send skins to new client
		if other_client.skin_bytes.size() > 0:
			var skin_packet := get_change_player_skin_packet(other_client)
			client.send_packet(skin_packet)
	
	# Add client
	clients.push_back(client)

func disconnect_client(client: ClientConnection) -> void:
	if not clients.has(client):
		return
	
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
	block_generator.generate_area(-8, 8)

func _process(_delta: float) -> void:
	for client in clients:
		update_player_chunks(client)

func _on_entity_send_timer_timeout() -> void:
	send_entity_states()
