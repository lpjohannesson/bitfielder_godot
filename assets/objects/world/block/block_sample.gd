class_name BlockSample

var chunks: Array[BlockChunk]
var sample_start: Vector2i
var sample_chunk_width: int

static func sample_chunks(
		chunk_start: Vector2i,
		chunk_end: Vector2i,
		blocks: BlockWorld) -> BlockSample:
	
	var block_sample := BlockSample.new()
	
	block_sample.sample_start = chunk_start
	block_sample.sample_chunk_width = chunk_end.x - chunk_start.x + 1
	
	for y in range(chunk_start.y, chunk_end.y + 1):
		for x in range(chunk_start.x, chunk_end.x + 1):
			var chunk_index := Vector2i(x, y)
			block_sample.chunks.push_back(blocks.get_chunk(chunk_index))
	
	return block_sample

func get_block_address(block_position: Vector2i) -> BlockAddress:
	var chunk_index := BlockWorld.get_chunk_index(block_position)
	var sample_chunk_index := chunk_index - sample_start
	
	var chunk_list_index := sample_chunk_index.y * sample_chunk_width + sample_chunk_index.x
	var chunk := chunks[chunk_list_index]
	
	if chunk == null:
		return null
	
	var address := BlockAddress.new()
	address.chunk = chunk
	
	var chunk_position := BlockWorld.get_chunk_position(block_position, chunk_index)
	address.block_index = BlockChunk.get_block_index(chunk_position)
	
	return address
