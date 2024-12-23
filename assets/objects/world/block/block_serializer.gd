extends Node
class_name BlockSerializer

@export var blocks: BlockWorld

func create_palette(
		palette: PackedStringArray,
		palette_map: Dictionary,
		block_ids: PackedInt32Array) -> void:
	
	for block_id in block_ids:
		if palette_map.has(block_id):
			continue
		
		var block := blocks.block_types[block_id]
		
		palette_map[block_id] = palette.size()
		palette.push_back(block.block_name)

func save_paletted_blocks(
		palette_map: Dictionary,
		block_ids: PackedInt32Array) -> PackedInt32Array:
	
	var saved_block_ids: PackedInt32Array = []
	saved_block_ids.resize(BlockChunk.BLOCK_COUNT)
	
	for i in range(BlockChunk.BLOCK_COUNT):
		var block_id := block_ids[i]
		saved_block_ids[i] = palette_map[block_id]
	
	return saved_block_ids

func save_chunk(chunk: BlockChunk) -> Array:
	# Create palette
	var palette: PackedStringArray = []
	var palette_map := {}
	
	create_palette(palette, palette_map, chunk.front_ids)
	create_palette(palette, palette_map, chunk.back_ids)
	
	var chunk_data := [chunk.chunk_index, palette]
	
	# Save space if all one block
	if palette_map.size() == 1:
		return chunk_data
	
	# Load block data
	chunk_data.push_back(save_paletted_blocks(
		palette_map, chunk.front_ids))
	
	chunk_data.push_back(save_paletted_blocks(
		palette_map, chunk.back_ids))
	
	return chunk_data

func load_chunk(chunk: BlockChunk, chunk_data: Array) -> void:
	# Load palette blocks
	var palette: PackedStringArray = chunk_data[1]
	
	# Check for all one block
	if palette.size() == 1:
		var block_id := blocks.get_block_id(palette[0])
		
		for i in range(BlockChunk.BLOCK_COUNT):
			chunk.front_ids[i] = block_id
			chunk.back_ids[i] = block_id
		
		return
	
	# Load blocks from palette
	var palette_ids: PackedInt32Array = []
	
	for block_name in palette:
		var block_id := blocks.get_block_id(block_name)
		palette_ids.push_back(block_id)
	
	# Load block data
	var front_ids: PackedInt32Array = chunk_data[2]
	var back_ids: PackedInt32Array = chunk_data[3]
	
	for i in range(BlockChunk.BLOCK_COUNT):
		chunk.front_ids[i] = palette_ids[front_ids[i]]
		chunk.back_ids[i] = palette_ids[back_ids[i]]
