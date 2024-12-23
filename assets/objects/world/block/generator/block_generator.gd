extends Node
class_name BlockGenerator

@export var world: GameWorld
@export var biome: Biome

func generate_area(chunk_start_x: int, chunk_end_x: int) -> void:
	var blocks: BlockWorld = world.blocks
	
	# Create chunks
	var chunks: Array[BlockChunk] = []
	
	for y in range(BlockWorld.WORLD_CHUNK_HEIGHT):
		for x in range(chunk_start_x, chunk_end_x):
			var chunk_index := Vector2i(x, y)
			var chunk := blocks.create_chunk(chunk_index)
			
			chunks.push_back(chunk)
	
	# Fill layers
	var properties := BlockGeneratorProperties.new()
	
	properties.blocks = blocks
	properties.start_x = chunk_start_x * BlockChunk.CHUNK_SIZE.x
	properties.end_x = chunk_end_x * BlockChunk.CHUNK_SIZE.x
	
	biome.generate_biome(properties)
	
	for chunk in chunks:
		blocks.update_chunk(chunk)

func start_generator() -> void:
	biome.start_biome(world.blocks)
