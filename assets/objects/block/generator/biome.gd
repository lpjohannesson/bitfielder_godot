extends Resource
class_name Biome

@export var bottom_y: int
@export var front_layers: Array[BlockGeneratorLayer]
@export var back_layers: Array[BlockGeneratorLayer]

static func get_front_layer(chunk: BlockChunk) -> PackedInt32Array:
	return chunk.front_ids

static func get_back_layer(chunk: BlockChunk) -> PackedInt32Array:
	return chunk.back_ids

func start_biome(block_world: BlockWorld):
	for layer in front_layers + back_layers:
		layer.start_layer(block_world)

func generate_biome(properties: BlockGeneratorProperties) -> void:
	properties.block_start_y = bottom_y
	properties.layer_getter = get_front_layer
	
	for layer in front_layers:
		properties.block_start_y -= layer.height
		layer.generate_layer(properties)
	
	properties.block_start_y = bottom_y
	properties.layer_getter = get_back_layer
	
	for layer in back_layers:
		properties.block_start_y -= layer.height
		layer.generate_layer(properties)
