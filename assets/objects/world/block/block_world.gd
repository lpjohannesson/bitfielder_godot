extends Node2D
class_name BlockWorld

const BLOCKS_FOLDER = "res://assets/resources/blocks"

const WORLD_CHUNK_HEIGHT = 16

@export var chunk_scene: PackedScene

@export var chunks: Node2D
@export var serializer: BlockSerializer
@export var heightmaps: HeightmapManager

var block_types: Array[BlockType]
var block_type_map := {}

var chunk_map := {}

static func get_chunk_index(block_position: Vector2i) -> Vector2i:
	return floor(Vector2(block_position) / Vector2(BlockChunk.CHUNK_SIZE))

static func get_chunk_position(
	block_position: Vector2i,
	chunk_index: Vector2i) -> Vector2i:
	
	return block_position - chunk_index * BlockChunk.CHUNK_SIZE

static func get_block_position(
	chunk_position: Vector2i,
	chunk_index: Vector2i) -> Vector2i:
	
	return chunk_position + chunk_index * BlockChunk.CHUNK_SIZE

func world_to_block(world_position: Vector2) -> Vector2i:
	return floor(world_position / scale)

func world_to_block_round(world_position: Vector2) -> Vector2i:
	return round(world_position / scale)

func block_to_world(block_position: Vector2i, centered: bool) -> Vector2:
	var world_position := Vector2(block_position) * scale
	
	if centered:
		return world_position + scale * 0.5
	else:
		return world_position

func get_chunk(chunk_index: Vector2i) -> BlockChunk:
	if not chunk_map.has(chunk_index):
		return null
	
	return chunk_map[chunk_index]

func get_block_address(block_position: Vector2i) -> BlockAddress:
	# Find chunk by index
	var chunk_index := get_chunk_index(block_position)
	var chunk := get_chunk(chunk_index)
	
	if chunk == null:
		return null
	
	# Create address
	var address = BlockAddress.new()
	address.chunk = chunk
	
	# Get block position relative to chunk
	var chunk_position = get_chunk_position(block_position, chunk_index)
	
	address.block_index = \
		BlockChunk.get_block_index(chunk_position)
	
	return address

func create_colliders(chunk: BlockChunk) -> void:
	for collider in chunk.colliders.get_children():
		collider.free()
	
	for y in range(BlockChunk.CHUNK_SIZE.y):
		for x in range(BlockChunk.CHUNK_SIZE.x):
			var chunk_position := Vector2i(x, y)
			var block_index := BlockChunk.get_block_index(chunk_position)
			var block_id := chunk.front_ids[block_index]
			var block := block_types[block_id]
			
			if not block.is_solid:
				continue
			
			var collider := BlockCollider.new()
			
			collider.block_position = \
				get_block_position(chunk_position, chunk.chunk_index)
			
			chunk.colliders.add_child(collider)
			
			collider.position = Vector2(chunk_position) + Vector2.ONE * 0.5
			
			if block.collider == null:
				collider.shape = RectangleShape2D.new()
				collider.shape.size = Vector2.ONE
			else:
				collider.shape = block.collider
			
			collider.one_way_collision = block.is_one_way

func create_chunk(chunk_index: Vector2i) -> BlockChunk:
	var chunk: BlockChunk = chunk_scene.instantiate()
	
	chunk.chunk_index = chunk_index
	chunk.position = chunk_index * BlockChunk.CHUNK_SIZE
	chunks.add_child(chunk)
	
	chunk_map[chunk_index] = chunk
	
	return chunk

func destroy_chunk(chunk_index: Vector2i) -> void:
	var chunk := get_chunk(chunk_index)
	
	if chunk == null:
		return
	
	# Wait for chunk to finish drawing
	if chunk.redrawing_chunk:
		await chunk.chunk_done_drawing
	
	chunk_map.erase(chunk_index)
	chunk.queue_free()

func update_chunk(chunk: BlockChunk) -> void:
	create_colliders(chunk)

func get_neighboring_chunks(block_position: Vector2i) -> Array[BlockChunk]:
	var block_chunks: Array[BlockChunk] = []
	
	# Find chunks including neighbours
	var chunk_start := get_chunk_index(block_position - Vector2i.ONE)
	var chunk_end := get_chunk_index(block_position + Vector2i.ONE)
	var chunk_count := Vector2i.ONE + (chunk_end - chunk_start)
	
	for y in range(chunk_count.y):
		for x in range(chunk_count.x):
			var chunk_index = chunk_start + Vector2i(x, y)
			var chunk := get_chunk(chunk_index)
			
			if chunk == null:
				continue
			
			block_chunks.push_back(chunk)
	
	return block_chunks

func update_block(block_position: Vector2i) -> void:
	var chunk_index := get_chunk_index(block_position)
	var chunk := get_chunk(chunk_index)
	
	update_chunk(chunk)

func get_block_id(block_name: String) -> int:
	if not block_type_map.has(block_name):
		return 0
	
	return block_type_map[block_name]

func set_block_name(block: BlockType, block_name: String) -> void:
	block.block_name = block_name

func _ready() -> void:
	GameResourceLoader.load_resources(
		BLOCKS_FOLDER,
		block_types,
		block_type_map,
		set_block_name)
