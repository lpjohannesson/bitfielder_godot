extends BlockGeneratorLayer
class_name BlockGeneratorFillLayer

@export var block_name: String

var block_id: int

func start_layer(blocks: BlockWorld) -> void:
	block_id = blocks.get_block_id(block_name)

func generate_layer(properties: BlockGeneratorProperties) -> void:
	for y in range(properties.start_y, properties.start_y + height):
		for x in range(properties.start_x, properties.end_x):
			var block_position := Vector2i(x, y)
			var address := properties.blocks.get_block_address(block_position)
			
			var layer: PackedInt32Array = \
				properties.layer_getter.call(address.chunk)
			
			layer[address.block_index] = block_id
