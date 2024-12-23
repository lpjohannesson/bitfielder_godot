extends Node
class_name BlockWorldRenderer

const CHUNK_NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.UP + Vector2i.LEFT,
	Vector2i.UP + Vector2i.RIGHT,
	Vector2i.DOWN + Vector2i.LEFT,
	Vector2i.DOWN + Vector2i.RIGHT,
]

@export var world: GameWorld
@export var particle_scene: PackedScene

func create_render_data(
		chunk: BlockChunk,
		block_ids: PackedInt32Array,
		layer: Node2D,
		on_front_layer: bool) -> BlockRenderData:
	
	var render_data := BlockRenderData.new()
	render_data.blocks = world.blocks
	
	render_data.chunk = chunk
	render_data.block_ids = block_ids
	
	render_data.layer = layer
	render_data.on_front_layer = on_front_layer
	
	return render_data

func get_render_block(render_data: BlockRenderData) -> BlockType:
	var block_index := \
		BlockChunk.get_block_index(render_data.chunk_position)
	
	render_data.block_id = render_data.block_ids[block_index]
	return world.blocks.block_types[render_data.block_id]

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

func start_chunk(chunk: BlockChunk) -> void:
	# Create shadow
	chunk.back_layer.material = GameScene.instance.shadow_shader
	
	chunk.shadow_layer = Node2D.new()
	GameScene.instance.shadow_viewport.add_child(chunk.shadow_layer)
	
	chunk.shadow_layer.global_transform = chunk.global_transform
	
	# Create signals
	chunk.front_layer.draw.connect(func() -> void: draw_chunk_front(chunk))
	chunk.back_layer.draw.connect(func() -> void: draw_chunk_back(chunk))
	chunk.shadow_layer.draw.connect(func() -> void: draw_chunk_shadow(chunk))
	
	chunk.tree_exited.connect(chunk.shadow_layer.queue_free)
	
	# Update neighbors
	for chunk_offset in CHUNK_NEIGHBOR_OFFSETS:
		var neighbor_chunk_index := chunk.chunk_index + chunk_offset
		var neighbor_chunk := world.blocks.get_chunk(neighbor_chunk_index)
		
		if neighbor_chunk == null:
			continue
		
		neighbor_chunk.redraw_chunk()

func spawn_particles(block_id: int, particle_position: Vector2):
	var blocks := world.blocks
	var block := blocks.block_types[block_id]
	
	if block.particle_texture == null:
		return
	
	for i in range(5):
		var particle: BlockParticle = particle_scene.instantiate()
		GameScene.instance.particles.add_child(particle)
		
		particle.global_position = particle_position
		particle.sprite.texture = block.particle_texture
