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

static func get_block_position(
	chunk_position: Vector2i,
	chunk_index: Vector2i) -> Vector2i:
	
	return chunk_position + chunk_index * BlockChunk.CHUNK_SIZE

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
			var block_id := chunk.front_ids[block_index]
			var block := block_types[block_id]
			
			if not block.properties.is_solid:
				continue
			
			var collider := CollisionShape2D.new()
			chunk.colliders.add_child(collider)
			
			collider.position = Vector2(chunk_position) + Vector2.ONE * 0.5
			collider.shape = RectangleShape2D.new()
			collider.shape.size = Vector2.ONE
			
			collider.one_way_collision = block.properties.is_one_way

func create_render_data(
	chunk: BlockChunk,
	block_ids: PackedInt32Array,
	layer: Node2D,
	on_front_layer: bool) -> BlockRenderData:
	
	var render_data := BlockRenderData.new()
	render_data.block_world = self
	
	render_data.chunk = chunk
	render_data.block_ids = block_ids
	
	render_data.layer = layer
	render_data.on_front_layer = on_front_layer
	
	return render_data

func get_render_block(render_data: BlockRenderData) -> BlockType:
	var block_index := \
		BlockChunk.get_block_index(render_data.chunk_position)
	
	render_data.block_id = render_data.block_ids[block_index]
	return block_types[render_data.block_id]

func draw_chunk(render_data: BlockRenderData) -> void:
	for y in range(BlockChunk.CHUNK_SIZE.y):
		for x in range(BlockChunk.CHUNK_SIZE.x):
			render_data.chunk_position = Vector2i(x, y)
			var block := get_render_block(render_data)
			
			if block.renderer == null:
				continue
			
			block.renderer.draw_block(render_data)

func draw_chunk_front(chunk: BlockChunk) -> void:
	var render_data := \
		create_render_data(chunk, chunk.front_ids, chunk.front_layer, true)
	
	draw_chunk(render_data)

func draw_chunk_back(chunk: BlockChunk) -> void:
	var render_data := \
		create_render_data(chunk, chunk.back_ids, chunk.back_layer, false)
	
	draw_chunk(render_data)

func draw_chunk_shadow(chunk: BlockChunk) -> void:
	var render_data := \
		create_render_data(chunk, chunk.front_ids, chunk.shadow_layer, true)
	
	for y in range(BlockChunk.CHUNK_SIZE.y):
		for x in range(BlockChunk.CHUNK_SIZE.x):
			render_data.chunk_position = Vector2i(x, y)
			var block := get_render_block(render_data)
			
			if block.renderer == null:
				continue
			
			if not block.renderer_properties.casts_shadow:
				continue
			
			if block.renderer_properties.is_partial:
				block.renderer.draw_block(render_data)
			else:
				var block_rect := Rect2(render_data.chunk_position, Vector2.ONE)
				render_data.layer.draw_rect(block_rect, Color.WHITE)

func create_chunk(chunk_index: Vector2i) -> void:
	var chunk: BlockChunk = chunk_scene.instantiate()
	
	chunk.chunk_index = chunk_index
	chunk.position = chunk_index * BlockChunk.CHUNK_SIZE
	chunks.add_child(chunk)
	
	chunk_map[chunk_index] = chunk
	
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

func update_block(block_position: Vector2i):
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
			
			update_chunk(chunk)

func create_particles(block_id: int, block_position: Vector2i):
	var block := block_types[block_id]
	
	if block.particle_texture == null:
		return
	
	var particle_position = block_to_world(block_position, true)
	
	for i in range(5):
		var particle: BlockParticle = particle_scene.instantiate()
		particles.add_child(particle)
		
		particle.global_position = particle_position
		particle.sprite.texture = block.particle_texture

func _ready() -> void:
	for y in range(4):
		for x in range(4):
			create_chunk(Vector2i(x, y))
