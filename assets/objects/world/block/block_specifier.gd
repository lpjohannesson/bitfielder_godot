class_name BlockSpecifier

var block_position: Vector2i
var block_id: int
var on_front_layer: bool

static func from_data(data: Dictionary, block_world: BlockWorld) -> BlockSpecifier:
	var block_specifier := BlockSpecifier.new()
	
	block_specifier.block_position = data["position"]
	block_specifier.on_front_layer = data["on_front_layer"]
	block_specifier.block_id = block_world.get_block_id(data["name"])
	
	return block_specifier

func to_data(block_world: BlockWorld) -> Dictionary:
	return {
		"position": block_position,
		"on_front_layer": on_front_layer,
		"name": block_world.block_types[block_id].block_name
	}

func get_layer(chunk: BlockChunk) -> PackedInt32Array:
	if on_front_layer:
		return chunk.front_ids
	else:
		return chunk.back_ids
