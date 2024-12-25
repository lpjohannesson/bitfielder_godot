extends Node
class_name BlockGenerator

@export var world: GameWorld
@export var biome: Biome

func generate_area(chunk_start_x: int, chunk_end_x: int) -> void:
	var blocks: BlockWorld = world.blocks
	
	# Create chunks
	var chunks: Array[BlockChunk] = []
	
	var chunk_columns := []
	
	for chunk_x in range(chunk_start_x, chunk_end_x):
		var chunk_column: Array[BlockChunk] = []
		chunk_column.resize(BlockWorld.WORLD_CHUNK_HEIGHT)
		
		for chunk_y in range(BlockWorld.WORLD_CHUNK_HEIGHT):
			var chunk_index := Vector2i(chunk_x, chunk_y)
			var chunk := blocks.create_chunk(chunk_index)
			
			chunks.push_back(chunk)
			chunk_column[chunk_y] = chunk
		
		chunk_columns.push_back(chunk_column)
	
	# Fill layers
	var properties := BlockGeneratorProperties.new()
	
	properties.blocks = blocks
	properties.start_x = chunk_start_x * BlockChunk.CHUNK_SIZE.x
	properties.end_x = chunk_end_x * BlockChunk.CHUNK_SIZE.x
	
	biome.generate_biome(properties)
	
	# Create heightmap
	for i in range(chunk_columns.size()):
		var chunk_column: Array[BlockChunk] = chunk_columns[i]
		var chunk_x = chunk_start_x + i
		
		blocks.create_heightmap(chunk_column, chunk_x)
	
	# Update chunks
	for chunk in chunks:
		blocks.update_chunk(chunk)

func start_generator() -> void:
	biome.start_biome(world.blocks)
