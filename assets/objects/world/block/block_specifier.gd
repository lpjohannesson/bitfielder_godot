class_name BlockSpecifier

var block_position: Vector2i
var block_id: int
var on_front_layer: bool

static func is_data_valid(data: Variant) -> bool:
	if not data is Array:
		return false
	
	if data.size() != 3:
		return false
	
	if not data[0] is Vector2i:
		return false
	
	if not data[1] is int:
		return false
	
	if not data[2] is bool:
		return false
	
	return true

static func from_data(data: Array, blocks: BlockWorld) -> BlockSpecifier:
	var block_specifier := BlockSpecifier.new()
	
	block_specifier.block_position = data[0]
	block_specifier.on_front_layer = data[1]
	block_specifier.block_id = blocks.get_block_id(data[2])
	
	return block_specifier

func to_data(blocks: BlockWorld) -> Array:
	var block_name := blocks.block_types[block_id].block_name
	
	return [block_position, on_front_layer, block_name]

func get_layer(chunk: BlockChunk) -> PackedInt32Array:
	return chunk.get_layer(on_front_layer)

func read_address(address: BlockAddress) -> int:
	return get_layer(address.chunk)[address.block_index]

func write_address(address: BlockAddress) -> void:
	get_layer(address.chunk)[address.block_index] = block_id
