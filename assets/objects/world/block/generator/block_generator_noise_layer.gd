extends BlockGeneratorLayer
class_name BlockGeneratorNoiseLayer

@export var top_block_name: String
@export var bottom_block_name: String
@export var noise: Noise

var top_id: int
var bottom_id: int

func start_layer(block_world: BlockWorld) -> void:
	noise.seed = randi()
	
	top_id = block_world.get_block_id(top_block_name)
	bottom_id = block_world.get_block_id(bottom_block_name)

func generate_layer(properties: BlockGeneratorProperties) -> void:
	var block_end_y = properties.block_start_y + height
	
	for x in range(properties.block_start_x, properties.block_end_x):
		var ground_level := get_ground_level(properties, noise, x)
		
		for y in range(properties.block_start_y, block_end_y):
			var block_position := Vector2i(x, y)
			var address := properties.block_world.get_block_address(
				block_position)
			
			var layer: PackedInt32Array = \
				properties.layer_getter.call(address.chunk)
			
			var block_id = top_id if y < ground_level else bottom_id
			layer[address.block_index] = block_id
