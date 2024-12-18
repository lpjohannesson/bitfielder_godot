extends Node
class_name GamePacketManager

@export var scene: GameScene

func create_block_chunk(packet: GamePacket) -> void:
	var chunk_index: Vector2i = packet.data["index"]
	
	var block_world := scene.world.block_world
	var chunk := block_world.create_chunk(chunk_index)
	
	scene.block_serializer.load_chunk(chunk, packet.data)
	block_world.update_chunk(chunk)
	
	scene.block_world_renderer.start_chunk(chunk)

func update_block(packet: GamePacket) -> void:
	var block_world := scene.world.block_world
	var block_specifier := BlockSpecifier.from_data(packet.data, block_world)
	
	var address := block_world.get_block_address(block_specifier.block_position)
	
	if address == null:
		return
	
	var block_ids := block_specifier.get_layer(address.chunk)
	block_ids[address.block_index] = block_specifier.block_id
	
	scene.update_block(block_specifier.block_position)

func send_check_player_position() -> void:
	var packet := GamePacket.create_packet(
		Packets.ClientPacket.CHECK_PLAYER_POSITION,
		{ "position": scene.player.global_position })
	
	scene.server.send_packet(packet)

func send_check_block_update(block_specifier: BlockSpecifier) -> void:
	var packet := GamePacket.create_packet(
		Packets.ClientPacket.CHECK_BLOCK_UPDATE,
		block_specifier.to_data(scene.world.block_world)
	)
	
	scene.server.send_packet(packet)

func get_packet_entity(packet: GamePacket) -> GameEntity:
	var entity_id: int = packet.data["id"]
	return scene.world.entities.get_entity(entity_id)

func create_entity(packet: GamePacket) -> void:
	var entity_id: int = packet.data["id"]
	var entity_type: String = packet.data["type"]
	
	scene.world.entities.create_entity_by_type(entity_id, entity_type, false)
 
func load_entity_position(packet: GamePacket) -> void:
	var entity := get_packet_entity(packet)
	
	if entity == null:
		return
	
	entity.body.global_position = packet.data["value"]

func load_entity_velocity(packet: GamePacket) -> void:
	var entity := get_packet_entity(packet)
	
	if entity == null:
		return
	
	entity.body.velocity = packet.data["value"]

func assign_player(packet: GamePacket) -> void:
	var entity := scene.world.entities.get_entity(packet.data)
	scene.player = entity.body

func recieve_packet(packet: GamePacket) -> void:
	match packet.type:
		Packets.ServerPacket.CREATE_BLOCK_CHUNK:
			create_block_chunk(packet)
		
		Packets.ServerPacket.UPDATE_BLOCK:
			update_block(packet)
			print("update")
		
		Packets.ServerPacket.CREATE_ENTITY:
			create_entity(packet)
		
		Packets.ServerPacket.ENTITY_POSITION:
			load_entity_position(packet)
		
		Packets.ServerPacket.ENTITY_VELOCITY:
			load_entity_velocity(packet)
		
		Packets.ServerPacket.ASSIGN_PLAYER:
			assign_player(packet)
