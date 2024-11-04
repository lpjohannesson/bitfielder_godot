extends Node
class_name BlockGenerator

func generate_chunk(chunk: BlockChunk) -> void:
	for y in range(BlockChunk.CHUNK_SIZE.y):
		for x in range(BlockChunk.CHUNK_SIZE.x):
			var chunk_position := Vector2i(x, y)
			var block_index := BlockChunk.get_block_index(chunk_position)
			
			chunk.front_ids[block_index] = max(0, randi() % 9 - 2)
			chunk.back_ids[block_index] = randi() % 7
