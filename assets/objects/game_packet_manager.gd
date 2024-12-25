extends Node
class_name GamePacketManager

@export var scene: GameScene

var last_chunk_index: Vector2i

func create_block_chunk(packet: GamePacket) -> void:
	var blocks := scene.world.blocks
	var chunk_index: Vector2i = packet.data[0]
	
	# Skip if chunk exists
	if blocks.get_chunk(chunk_index) != null:
		return
	
	var chunk := blocks.create_chunk(chunk_index)
	
	scene.world.blocks.serializer.load_chunk(chunk, packet.data)
	blocks.update_chunk(chunk)
	
	scene.blocks_renderer.start_chunk(chunk)

func create_block_heightmap(packet: GamePacket) -> void:
	var chunk_x: int = packet.data[0]
	var heightmap: PackedInt32Array = packet.data[1]
	
	scene.world.blocks.load_heightmap(heightmap, chunk_x)

func load_player_chunk_index(packet: GamePacket) -> void:
	var player_chunk_index: Vector2i = packet.data
	var load_zone := GameServer.get_chunk_load_zone(player_chunk_index)
	
	var blocks := scene.world.blocks
	 
	# Unload out of range chunks
	for chunk_index in blocks.chunk_map.keys():
		if not load_zone.has_point(chunk_index):
			blocks.destroy_chunk(chunk_index)
	
	for chunk_x in blocks.heightmap_map.keys():
		if chunk_x < load_zone.position.x or chunk_x >= load_zone.end.x:
			blocks.destroy_heightmap(chunk_x)
	
	last_chunk_index = player_chunk_index
	
	scene.lighting_display.chunk_index = player_chunk_index
	scene.lighting_display.show_lightmap()

func update_block(packet: GamePacket) -> void:
	var blocks := scene.world.blocks
	var block_specifier := BlockSpecifier.from_data(packet.data[0], blocks)
	var show_effects: bool = packet.data[1]
	
	var address := blocks.get_block_address(block_specifier.block_position)
	
	if address == null:
		return
	
	scene.update_block(block_specifier, address, show_effects)

func send_check_player_position() -> void:
	var packet := GamePacket.create_packet(
		Packets.ClientPacket.CHECK_PLAYER_POSITION,
		scene.player.global_position)
	
	scene.server.send_packet(packet)

func send_check_block_update(block_specifier: BlockSpecifier) -> void:
	var packet := GamePacket.create_packet(
		Packets.ClientPacket.CHECK_BLOCK_UPDATE,
		block_specifier.to_data(scene.world.blocks))
	
	scene.server.send_packet(packet)

func create_entity(packet: GamePacket) -> void:
	scene.world.entities.serializer.create_entity(packet.data)

func destroy_entity(packet: GamePacket) -> void:
	var entity := scene.world.entities.get_entity(packet.data)
	
	if entity == null:
		return
	
	scene.world.entities.remove_entity(entity)
 
func load_entity_data(packet: GamePacket) -> void:
	var entities := scene.world.entities
	
	var entity_id: int = packet.data[EntitySerializer.DataType.ID]
	var entity := entities.get_entity(entity_id)
	
	if entity == null:
		return
	
	entities.serializer.load_entity_data(entity, packet.data)

func assign_player(packet: GamePacket) -> void:
	var entity := scene.world.entities.get_entity(packet.data)
	scene.player = entity.entity_node
	 
	scene.player_camera.reset_camera()

func create_inventory(packet: GamePacket) -> void:
	var inventory := ItemInventory.new()
	scene.player.inventory = inventory
	
	scene.world.items.serializer.load_inventory(packet.data, inventory)
	scene.hud.item_bar.show_inventory(inventory)

func change_player_skin(packet: GamePacket) -> void:
	var entity_id: int = packet.data[0]
	var skin_bytes: PackedByteArray = packet.data[1]
	
	var player: Player = scene.world.entities.get_entity(entity_id).entity_node
	PlayerSkinManager.load_skin(player, skin_bytes)

func recieve_packet(packet: GamePacket) -> void:
	print(Packets.ServerPacket.find_key(packet.type), ": ", packet.data)
	
	match packet.type:
		Packets.ServerPacket.CREATE_BLOCK_CHUNK:
			create_block_chunk(packet)
		
		Packets.ServerPacket.CREATE_BLOCK_HEIGHTMAP:
			create_block_heightmap(packet)
		
		Packets.ServerPacket.PLAYER_CHUNK_INDEX:
			load_player_chunk_index(packet)
		
		Packets.ServerPacket.UPDATE_BLOCK:
			update_block(packet)
		
		Packets.ServerPacket.CREATE_ENTITY:
			create_entity(packet)
		
		Packets.ServerPacket.DESTROY_ENTITY:
			destroy_entity(packet)
		
		Packets.ServerPacket.ENTITY_DATA:
			load_entity_data(packet)
		
		Packets.ServerPacket.ASSIGN_PLAYER:
			assign_player(packet)
		
		Packets.ServerPacket.CREATE_INVENTORY:
			create_inventory(packet)
		
		Packets.ServerPacket.CHANGE_PLAYER_SKIN:
			change_player_skin(packet)
