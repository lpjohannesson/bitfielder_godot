extends BlockGeneratorLayer
class_name BlockGeneratorGroundLayer

@export var top_block_name: String
@export var bottom_block_name: String
@export var noise: Noise

var top_id: int
var bottom_id: int

func start_layer(blocks: BlockWorld) -> void:
	noise.seed = randi()
	
	top_id = blocks.get_block_id(top_block_name)
	bottom_id = blocks.get_block_id(bottom_block_name)

func generate_layer(properties: BlockGeneratorProperties) -> void:
	var block_end_y = properties.start_y + height
	
	for x in range(properties.start_x, properties.end_x):
		var ground_level := get_ground_level(properties, noise, x)
		
		var ground_position := Vector2i(x, ground_level)
		var ground_address := properties.blocks.get_block_address(
			ground_position)
		
		var ground_layer: PackedInt32Array = \
			properties.layer_getter.call(ground_address.chunk)
		
		ground_layer[ground_address.block_index] = top_id
		
		for y in range(ground_level + 1, block_end_y):
			var block_position := Vector2i(x, y)
			var address := properties.blocks.get_block_address(block_position)
			
			var layer: PackedInt32Array = \
				properties.layer_getter.call(address.chunk)
			
			layer[address.block_index] = bottom_id
