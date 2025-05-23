extends Node
class_name BlockWorldRenderer

class BlockSpriteSet:
	var front_sprites: Array[BlockSprite] = []
	var above_entity_sprites: Array[BlockSprite] = []
	var back_sprites: Array[BlockSprite] = []
	var shadow_sprites: Array[BlockSprite] = []

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
		chunk: BlockChunk,
		block_sample: BlockSample) -> void:
	
	mutex.lock()
	
	var sprites := BlockSpriteSet.new()
	
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
			
			var is_back_drawn := front_block.is_partial or front_block.is_transparent
			
			# Draw front
			if front_block.renderer != null:
				render_data.block_id = front_id
				render_data.block = front_block
				render_data.on_front_layer = true
				
				if not front_block.is_partial or front_block.draws_above_entities:
					render_data.sprites = sprites.above_entity_sprites
				else:
					render_data.sprites = sprites.front_sprites
				
				front_block.renderer.draw_block(render_data)
				
				# Draw shadow
				if front_block.casts_shadow:
					if is_back_drawn:
						render_data.sprites = sprites.shadow_sprites
						front_block.renderer.draw_block(render_data)
					else:
						var rect_sprite := BlockSprite.new()
						rect_sprite.rect = Rect2(chunk_position, Vector2.ONE)
						
						sprites.shadow_sprites.push_back(rect_sprite)
			
			# Draw back
			if is_back_drawn:
				if back_block.renderer != null:
					render_data.block_id = back_id
					render_data.block = back_block
					render_data.on_front_layer = false
					render_data.sprites = sprites.back_sprites
					
					back_block.renderer.draw_block(render_data)
	
	call_deferred("end_redraw_chunk_async", chunk, sprites)
	
	mutex.unlock()

func end_redraw_chunk_async(chunk: BlockChunk, sprites: BlockSpriteSet) -> void:
	chunk.drawing_thread.wait_to_finish()
	chunk.drawing_thread = null
	
	connect_chunk_signal(chunk.front_layer.draw, func() -> void:
		draw_block_sprites(chunk.front_layer, sprites.front_sprites))
	
	connect_chunk_signal(chunk.back_layer.draw, func() -> void:
		draw_block_sprites(chunk.back_layer, sprites.back_sprites))
	
	connect_chunk_signal(chunk.above_entity_layer.draw, func() -> void:
		draw_block_sprites(chunk.above_entity_layer, sprites.above_entity_sprites))
	
	connect_chunk_signal(chunk.shadow_layer.draw, func() -> void:
		draw_block_sprites(chunk.shadow_layer, sprites.shadow_sprites))
	
	chunk.redraw_chunk()

func redraw_chunk_deferred(chunk: BlockChunk) -> void:
	# Used when chunk is deleted
	if not chunk.redrawing_chunk:
		return
	
	var block_sample := BlockSample.sample_chunks(
		chunk.chunk_index - Vector2i.ONE,
		chunk.chunk_index + Vector2i.ONE,
		world.blocks)
	
	if chunk.drawing_thread != null:
		chunk.drawing_thread.wait_to_finish()
	
	chunk.drawing_thread = Thread.new()
	chunk.drawing_thread.start(redraw_chunk_async.bind(chunk, block_sample))

func redraw_chunk(chunk: BlockChunk) -> void:
	if chunk.redrawing_chunk:
		return
	
	chunk.redrawing_chunk = true
	
	call_deferred("redraw_chunk_deferred", chunk)

func start_chunk(chunk: BlockChunk) -> void:
	# Set materials
	chunk.back_layer.material = GameScene.instance.back_layer_shader
	
	# Create shadow
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
