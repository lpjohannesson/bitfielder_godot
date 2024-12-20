class_name BlockSpecifier

var block_position: Vector2i
var block_id: int
var on_front_layer: bool

static func from_data(data: Array, block_world: BlockWorld) -> BlockSpecifier:
	var block_specifier := BlockSpecifier.new()
	
	block_specifier.block_position = data[0]
	block_specifier.on_front_layer = data[1]
	block_specifier.block_id = data[2]
	
	return block_specifier

func to_data(block_world: BlockWorld) -> Array:
	return [block_position, on_front_layer, block_id]

func get_layer(chunk: BlockChunk) -> PackedInt32Array:
	if on_front_layer:
		return chunk.front_ids
	else:
		return chunk.back_ids
