extends Node
class_name BlockWorldRenderer

@export var world: GameWorld
@export var particle_scene: PackedScene

var mutex := Mutex.new()

func connect_chunk_signal(chunk_signal: Signal, callable: Callable) -> void:
	chunk_signal.connect(callable, ConnectFlags.CONNECT_ONE_SHOT)

func draw_block_sprites(layer: Node2D, sprites: Array[BlockSprite]) -> void:
	for sprite in sprites:
		if sprite.texture == null:
			layer.draw_rect(sprite.rect, Color.WHITE)
			continue
		
		layer.draw_texture_rect_region(
			sprite.texture,
			sprite.rect,
			sprite.region)

func redraw_chunk_async(
		thread: Thread,
		chunk: BlockChunk,
		block_sample: BlockSample) -> void:
	
	mutex.lock()
	
	var front_sprites: Array[BlockSprite] = []
	var back_sprites: Array[BlockSprite] = []
	var shadow_sprites: Array[BlockSprite] = []
	
	var render_data := BlockRenderData.new()
	
	render_data.blocks = world.blocks
	render_data.block_sample = block_sample
	render_data.chunk = chunk
	
	var block_types := world.blocks.block_types
	
	for y in range(BlockChunk.CHUNK_SIZE.y):
		for x in range(BlockChunk.CHUNK_SIZE.x):
			var chunk_position = Vector2i(x, y)
			render_data.chunk_position = chunk_position
			
			var block_index := BlockChunk.get_block_index(chunk_position)
			
			var front_id := chunk.front_ids[block_index]
			var back_id := chunk.back_ids[block_index]
			
			var front_block := block_types[front_id]
			var back_block := block_types[back_id]
			
			# Draw front
			if front_block.renderer != null:
				render_data.block_id = front_id
				render_data.block = front_block
				render_data.on_front_layer = true
				render_data.sprites = front_sprites
				
				front_block.renderer.draw_block(render_data)
				
				# Draw shadow
				if front_block.casts_shadow:
					if front_block.is_partial:
						render_data.sprites = shadow_sprites
						front_block.renderer.draw_block(render_data)
					else:
						var rect_sprite := BlockSprite.new()
						rect_sprite.rect = Rect2(chunk_position, Vector2.ONE)
						
						shadow_sprites.push_back(rect_sprite)
			
			# Draw back
			if back_block.renderer != null:
				if front_block.is_partial:
					render_data.block_id = back_id
					render_data.block = back_block
					render_data.on_front_layer = false
					render_data.sprites = back_sprites
					
					back_block.renderer.draw_block(render_data)
	
	call_deferred(
		"end_redraw_chunk_async",
		thread,
		chunk,
		front_sprites,
		back_sprites,
		shadow_sprites)
	
	mutex.unlock()

func end_redraw_chunk_async(
		thread: Thread,
		chunk: BlockChunk,
		front_sprites: Array[BlockSprite],
		back_sprites: Array[BlockSprite],
		shadow_sprites: Array[BlockSprite]) -> void:
	
	thread.wait_to_finish()
	
	connect_chunk_signal(chunk.front_layer.draw, func() -> void:
		draw_block_sprites(chunk.front_layer, front_sprites))
	
	connect_chunk_signal(chunk.back_layer.draw, func() -> void:
		draw_block_sprites(chunk.back_layer, back_sprites))
	
	connect_chunk_signal(chunk.shadow_layer.draw, func() -> void:
		draw_block_sprites(chunk.shadow_layer, shadow_sprites))
	
	chunk.redraw_chunk()

func redraw_chunk_deferred(chunk: BlockChunk) -> void:
	var block_sample := BlockSample.sample_chunks(
		chunk.chunk_index - Vector2i.ONE,
		chunk.chunk_index + Vector2i.ONE,
		world.blocks)
	
	var thread := Thread.new()
	thread.start(redraw_chunk_async.bind(thread, chunk, block_sample))

func redraw_chunk(chunk: BlockChunk) -> void:
	if chunk.redrawing_chunk:
		return
	
	chunk.redrawing_chunk = true
	
	call_deferred("redraw_chunk_deferred", chunk)

func start_chunk(chunk: BlockChunk) -> void:
	# Create shadow
	chunk.back_layer.material = GameScene.instance.shadow_shader
	
	chunk.shadow_layer = Node2D.new()
	GameScene.instance.shadow_viewport.add_child(chunk.shadow_layer)
	
	chunk.shadow_layer.global_transform = chunk.global_transform
	
	chunk.tree_exited.connect(chunk.shadow_layer.queue_free)
	
	# Draw chunks
	redraw_chunk(chunk)
	
	for chunk_offset in Direction.NEIGHBOR_OFFSETS_EIGHT:
		var neighbor_chunk_index := chunk.chunk_index + chunk_offset
		var neighbor_chunk := world.blocks.get_chunk(neighbor_chunk_index)
		
		if neighbor_chunk == null:
			continue
		
		# Update chunks after frame finished
		redraw_chunk(neighbor_chunk)

func spawn_particles(block: BlockType, particle_position: Vector2):
	if block.particle_texture == null:
		return
	
	for i in range(5):
		var particle: BlockParticle = particle_scene.instantiate()
		GameScene.instance.particles.add_child(particle)
		
		particle.global_position = particle_position
		particle.sprite.texture = block.particle_texture
