extends Node
class_name BlockSerializer

@export var blocks: BlockWorld

func create_layer_palette(
		block_ids: PackedInt32Array,
		palette: PackedStringArray,
		palette_map: Dictionary) -> void:
	
	for block_id in block_ids:
		if palette_map.has(block_id):
			continue
		
		var block := blocks.block_types[block_id]
		
		palette_map[block_id] = palette.size()
		palette.push_back(block.block_name)

func create_chunk_palette(
		chunk: BlockChunk,
		palette: PackedStringArray,
		palette_map: Dictionary) -> void:
	
	create_layer_palette(chunk.front_ids, palette, palette_map)
	create_layer_palette(chunk.back_ids, palette, palette_map)

func save_paletted_layer(
		block_ids: PackedInt32Array,
		palette_map: Dictionary) -> Variant:
	
	var starting_block := block_ids[0]
	var all_one_block := true
	
	var saved_block_ids: PackedInt32Array = []
	saved_block_ids.resize(BlockChunk.BLOCK_COUNT)
	
	for i in range(BlockChunk.BLOCK_COUNT):
		var block_id := block_ids[i]
		
		if all_one_block and starting_block != block_id:
			all_one_block = false
		
		saved_block_ids[i] = palette_map[block_id]
	
	if all_one_block:
		return palette_map[starting_block]
	else:
		return saved_block_ids

func save_paletted_chunk(
		chunk: BlockChunk,
		palette_map: Dictionary) -> Array:
	
	return [
		save_paletted_layer(chunk.front_ids, palette_map),
		save_paletted_layer(chunk.back_ids, palette_map)
	]

func save_chunk(chunk: BlockChunk) -> Array:
	# Create palette
	var palette: PackedStringArray = []
	var palette_map := {}
	
	create_chunk_palette(chunk, palette, palette_map)
	
	return [chunk.chunk_index, palette, save_paletted_chunk(chunk, palette_map)]

func load_paletted_layer(
		layer_data: Variant,
		block_ids: PackedInt32Array,
		palette_ids: PackedInt32Array) -> void:
	
	if layer_data is int:
		# Load all one block
		var block_id := palette_ids[layer_data]
		
		for i in range(BlockChunk.BLOCK_COUNT):
			block_ids[i] = block_id
	else:
		for i in range(BlockChunk.BLOCK_COUNT):
			block_ids[i] = palette_ids[layer_data[i]]

func load_paletted_chunk(
		paletted_chunk: Array,
		chunk: BlockChunk,
		palette_ids: PackedInt32Array) -> void:
	
	load_paletted_layer(paletted_chunk[0], chunk.front_ids, palette_ids)
	load_paletted_layer(paletted_chunk[1], chunk.back_ids, palette_ids)
	
	blocks.update_chunk(chunk)

func get_palette_ids(palette: PackedStringArray) -> PackedInt32Array:
	var palette_ids: PackedInt32Array = []
	
	for block_name in palette:
		var block_id := blocks.get_block_id(block_name)
		palette_ids.push_back(block_id)
	  
	return palette_ids

func create_chunk_from_data(chunk_data: Array) -> BlockChunk:
	# Get parameters
	var chunk_index: Vector2i = chunk_data[0]
	var palette: PackedStringArray = chunk_data[1]
	var paletted_chunk: Array = chunk_data[2]
	
	# Create chunk
	var chunk := blocks.create_chunk(chunk_index)
	
	var palette_ids := get_palette_ids(palette)
	load_paletted_chunk(paletted_chunk, chunk, palette_ids)
	
	return chunk

func save_chunk_column(chunk_x: int) -> Dictionary:
	# Create palette
	var palette: PackedStringArray = []
	var palette_map := {}
	
	var chunks: Array[BlockChunk] = []
	
	for chunk_y in range(BlockWorld.WORLD_CHUNK_HEIGHT):
		var chunk_index := Vector2i(chunk_x, chunk_y)
		
		var chunk := blocks.get_chunk(chunk_index)
		chunks.push_back(chunk)
		
		create_chunk_palette(chunk, palette, palette_map)
	
	# Save block data
	var paletted_chunks := []
	
	for chunk in chunks:
		paletted_chunks.push_back(save_paletted_chunk(chunk, palette_map))
	
	return {
		"x": chunk_x,
		"pal": palette,
		"chunks": paletted_chunks
	}

func create_chunk_column_from_data(column_data: Dictionary) -> void:
	# Get parameters
	var chunk_x: int = column_data["x"]
	var palette: PackedStringArray = column_data["pal"]
	var paletted_chunks: Array = column_data["chunks"]
	
	# Load chunks
	var palette_ids := get_palette_ids(palette)
	var chunk_column: Array[BlockChunk] = []
	
	for chunk_y in range(BlockWorld.WORLD_CHUNK_HEIGHT):
		var chunk_index := Vector2i(chunk_x, chunk_y)
		var chunk := blocks.create_chunk(chunk_index)
		
		chunk_column.push_back(chunk)
		
		var paletted_chunk = paletted_chunks[chunk_y]
		load_paletted_chunk(paletted_chunk, chunk, palette_ids)
	
	blocks.heightmaps.generate_heightmap(chunk_column, chunk_x)

func save_chunk_column_file(chunk_x: int, chunks_path: String) -> void:
	var chunk_column_path := "%s/%s.dat" % [chunks_path, chunk_x]
	var file = FileAccess.open(chunk_column_path, FileAccess.WRITE)
	
	var bytes := var_to_bytes(save_chunk_column(chunk_x))
	file.store_buffer(bytes)

func create_chunk_column_from_file(path: String) -> BlockChunk:
	var bytes := FileAccess.get_file_as_bytes(path)
	var column_data: Dictionary = bytes_to_var(bytes)
	
	create_chunk_column_from_data(column_data)
	return
