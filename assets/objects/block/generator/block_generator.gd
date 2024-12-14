extends Node
class_name BlockGenerator

@export var block_world: BlockWorld
@export var biome: Biome

func generate_area(chunk_start_x: int, chunk_end_x: int) -> void:
	# Create chunks
	var chunks: Array[BlockChunk] = []
	
	for y in range(BlockWorld.WORLD_CHUNK_HEIGHT):
		for x in range(chunk_start_x, chunk_end_x):
			var chunk_index := Vector2i(x, y)
			var chunk := block_world.create_chunk(chunk_index)
			
			chunks.push_back(chunk)
	
	# Fill layers
	var properties := BlockGeneratorProperties.new()
	
	properties.block_world = block_world
	properties.block_start_x = chunk_start_x * BlockChunk.CHUNK_SIZE.x
	properties.block_end_x = chunk_end_x * BlockChunk.CHUNK_SIZE.x
	
	biome.generate_biome(properties)
	
	for chunk in chunks:
		block_world.update_chunk(chunk)

func start_generator() -> void:
	biome.start_biome(block_world)
