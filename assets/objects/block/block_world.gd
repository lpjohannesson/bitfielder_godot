extends Node2D
class_name BlockWorld

@export var block_types: Array[BlockType]
@export var chunk_scene: PackedScene
@export var particle_scene: PackedScene

@export var chunks: Node2D
@export var particles: Node2D
@export var generator: BlockGenerator

var chunk_map := {}

static func get_chunk_index(block_position: Vector2i) -> Vector2i:
	return floor(Vector2(block_position) / Vector2(BlockChunk.CHUNK_SIZE))

static func get_chunk_position(
	block_position: Vector2i,
	chunk_index: Vector2i) -> Vector2i:
	
	return block_position - chunk_index * BlockChunk.CHUNK_SIZE

func world_to_block(world_position: Vector2) -> Vector2i:
	return floor(world_position / scale)

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
	for y in range(BlockChunk.CHUNK_SIZE.y):
		for x in range(BlockChunk.CHUNK_SIZE.x):
			var chunk_position := Vector2i(x, y)
			var block_index := BlockChunk.get_block_index(chunk_position)
			var front_id := chunk.front_ids[block_index]
			
			if front_id == 0:
				continue
			
			var collider := CollisionShape2D.new()
			chunk.colliders.add_child(collider)
			
			collider.position = Vector2(chunk_position) + Vector2.ONE * 0.5
			collider.shape = RectangleShape2D.new()
			collider.shape.size = Vector2.ONE

func draw_block(block_id: int, render_data: BlockRenderData) -> void:
	var block := block_types[block_id]
	
	if block.renderer == null:
		return
	
	block.renderer.draw_block(render_data)

func draw_chunk(block_ids: PackedInt32Array, layer: Node2D) -> void:
	var render_data := BlockRenderData.new()
	render_data.layer = layer
	
	for y in range(BlockChunk.CHUNK_SIZE.y):
		for x in range(BlockChunk.CHUNK_SIZE.x):
			render_data.chunk_position = Vector2i(x, y)
			var block_index := \
				BlockChunk.get_block_index(render_data.chunk_position)
			
			draw_block(block_ids[block_index], render_data)

func draw_chunk_front(chunk: BlockChunk) -> void:
	draw_chunk(chunk.front_ids, chunk.front_layer)

func draw_chunk_back(chunk: BlockChunk) -> void:
	draw_chunk(chunk.back_ids, chunk.back_layer)

func draw_chunk_shadow(chunk: BlockChunk) -> void:
	var render_data := BlockRenderData.new()
	render_data.layer = chunk.shadow_layer
	
	for y in range(BlockChunk.CHUNK_SIZE.y):
		for x in range(BlockChunk.CHUNK_SIZE.x):
			render_data.chunk_position = Vector2i(x, y)
			var block_index := \
				BlockChunk.get_block_index(render_data.chunk_position)
			
			var block_id := chunk.front_ids[block_index]
			var block := block_types[block_id]
			
			if block.renderer == null:
				continue
			
			var block_rect := Rect2(render_data.chunk_position, Vector2.ONE)
			render_data.layer.draw_rect(block_rect, Color.WHITE)

func create_chunk(chunk_position: Vector2i) -> void:
	var chunk: BlockChunk = chunk_scene.instantiate()
	
	chunk.position = chunk_position * BlockChunk.CHUNK_SIZE
	chunks.add_child(chunk)
	
	chunk_map[chunk_position] = chunk
	
	generator.generate_chunk(chunk)
	create_colliders(chunk)
	
	chunk.front_layer.draw.connect(func() -> void: draw_chunk_front(chunk))
	chunk.back_layer.draw.connect(func() -> void: draw_chunk_back(chunk))
	chunk.shadow_layer.draw.connect(func() -> void: draw_chunk_shadow(chunk))

func update_chunk(chunk: BlockChunk) -> void:
	chunk.redraw_chunk()
	
	for collider in chunk.colliders.get_children():
		collider.free()
	
	create_colliders(chunk)

func create_particles(block_id: int, block_position: Vector2i):
	var block := block_types[block_id]
	
	if block.renderer == null:
		return
	
	var particle_texture := block.renderer.particle_texture
	
	if particle_texture == null:
		return
	
	var particle_position = block_to_world(block_position, true)
	
	for i in range(5):
		var particle: BlockParticle = particle_scene.instantiate()
		particles.add_child(particle)
		
		particle.global_position = particle_position
		particle.sprite.texture = particle_texture

func _ready() -> void:
	for y in range(2):
		for x in range(2):
			create_chunk(Vector2i(x, y))
