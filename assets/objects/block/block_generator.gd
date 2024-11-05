extends Node
class_name BlockGenerator

@export var block_world: BlockWorld
@export var noise: Noise

func generate_area(chunk_start: int, chunk_end: int) -> void:
	# Create chunks
	var chunks: Array[BlockChunk] = []
	
	for y in range(BlockWorld.WORLD_CHUNK_HEIGHT):
		for x in range(chunk_end - chunk_start):
			var chunk_index := Vector2i(chunk_start + x, y)
			var chunk := block_world.create_chunk(chunk_index)
			
			chunks.push_back(chunk)
	
	# Get block types
	var dirt_id := block_world.get_block_id("dirt")
	var stone_id := block_world.get_block_id("stone")
	
	# Generate world
	for chunk in chunks:
		for y in range(BlockChunk.CHUNK_SIZE.y):
			for x in range(BlockChunk.CHUNK_SIZE.x):
				var chunk_position := Vector2i(x, y)
				var block_index := BlockChunk.get_block_index(chunk_position)
				var block_position := BlockWorld.get_block_position(chunk_position, chunk.chunk_index)
				
				var noise_sample := noise.get_noise_2d(block_position.x, block_position.y)
				
				var back_id: int
				
				if block_position.y >= 32:
					back_id = stone_id
				else:
					back_id = 0
				
				if noise_sample > 0.1:
					chunk.back_ids[block_index] = dirt_id
				else:
					chunk.back_ids[block_index] = back_id
				
				if noise_sample > 0.2:
					chunk.front_ids[block_index] = dirt_id
				else:
					chunk.front_ids[block_index] = back_id
	
	for chunk in chunks:
		block_world.update_chunk(chunk)
