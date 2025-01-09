extends Node
class_name HeightmapManager

const HEIGHTMAP_BOTTOM = BlockWorld.WORLD_CHUNK_HEIGHT * BlockChunk.CHUNK_SIZE.y

@export var blocks: BlockWorld

var heightmap_map := {}

static func get_chunk_x(block_x: int) -> int:
	return floor(float(block_x) / float(BlockChunk.CHUNK_SIZE.x))

static func is_block_opaque(block: BlockType) -> bool:
	return not block.is_partial and not block.is_transparent

static func is_block_solid(block: BlockType) -> bool:
	return block.is_solid

func generate_height(
		x: int,
		chunk_column: Array[BlockChunk],
		block_checker: Callable) -> int:
	
	for chunk_y in range(BlockWorld.WORLD_CHUNK_HEIGHT):
		var chunk := chunk_column[chunk_y]
		
		for y in range(BlockChunk.CHUNK_SIZE.y):
			var chunk_position := Vector2i(x, y)
			var block_index := BlockChunk.get_block_index(chunk_position)
			var block_id := chunk.front_ids[block_index]
			var block := blocks.block_types[block_id]
			
			if not block_checker.call(block):
				continue
			
			return chunk_y * BlockChunk.CHUNK_SIZE.y + y
	
	return HEIGHTMAP_BOTTOM

func generate_heightmap(chunk_column: Array[BlockChunk], chunk_x: int) -> void:
	var heightmap := create_heightmap(chunk_x)
	
	heightmap.light_data.resize(BlockChunk.CHUNK_SIZE.x)
	heightmap.collision_data.resize(BlockChunk.CHUNK_SIZE.x)
	
	for x in range(BlockChunk.CHUNK_SIZE.x):
		heightmap.light_data[x] = generate_height(
			x, chunk_column, is_block_opaque)
		
		heightmap.collision_data[x] = generate_height(
			x, chunk_column, is_block_solid)

func get_heightmap(chunk_x: int) -> BlockHeightmap:
	if not heightmap_map.has(chunk_x):
		return null
	
	return heightmap_map[chunk_x]

func create_heightmap(chunk_x: int) -> BlockHeightmap:
	var heightmap := BlockHeightmap.new()
	heightmap_map[chunk_x] = heightmap
	
	return heightmap

func destroy_heightmap(chunk_x: int) -> void:
	if get_heightmap(chunk_x) == null:
		return
	
	heightmap_map.erase(chunk_x)

func get_height_address(block_x: int) -> HeightAddress:
	var chunk_x: int = get_chunk_x(block_x)
	var heightmap := get_heightmap(chunk_x)
	
	if heightmap == null:
		return null
	
	var address := HeightAddress.new()
	
	address.heightmap = heightmap
	address.height_index = block_x - chunk_x * BlockChunk.CHUNK_SIZE.x
	
	return address

func update_height_data(
		height_data: PackedInt32Array,
		height_address: HeightAddress,
		block_specifier: BlockSpecifier,
		block_checker: Callable) -> void:
	
	var height: int = height_data[height_address.height_index]
	
	if height == block_specifier.block_position.y:
		# Move height down
		while true:
			var below_block_position := \
				Vector2(block_specifier.block_position.x, height)
			
			var below_block_address := blocks.get_block_address(below_block_position)
			
			if below_block_address == null:
				break
			
			var below_block_id := \
				below_block_address.chunk.front_ids[below_block_address.block_index]
			
			var below_block = blocks.block_types[below_block_id]
			
			if block_checker.call(below_block):
				break
			
			height += 1
	
	elif height > block_specifier.block_position.y:
		# Move height up
		var placed_block := blocks.block_types[block_specifier.block_id]
		
		if not block_checker.call(placed_block):
			return
		
		height = block_specifier.block_position.y
	else:
		return
	
	height_data[height_address.height_index] = height

func update_height(block_specifier: BlockSpecifier, on_server: bool) -> void:
	if not block_specifier.on_front_layer:
		return
	
	var height_address := \
		get_height_address(block_specifier.block_position.x)
	
	if height_address == null:
		return
	
	update_height_data(
		height_address.heightmap.light_data,
		height_address,
		block_specifier,
		is_block_opaque)
	
	if on_server:
		update_height_data(
			height_address.heightmap.collision_data,
			height_address,
			block_specifier,
			is_block_solid)
