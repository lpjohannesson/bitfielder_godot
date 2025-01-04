extends BlockRenderer
class_name AutoBlockRenderer

const SHIFT_HORIZONAL := 1
const SHIFT_VERTICAL := 2

const FRAME_OFFSETS := [0, 0, 4, 4, 2, 2, 6, 8]

const CORNER_SIZE := Vector2.ONE * 0.5
const CORNER_SOURCE_SIZE := Vector2.ONE * 8.0

@export var texture: Texture2D

func is_neighbor_partial(render_data: BlockRenderData, block_id: int):
	var block := render_data.blocks.block_types[block_id]
	
	if block.renderer == null:
		return true
	
	return block.properties.is_partial

func get_neighbor_mask(
		render_data: BlockRenderData,
		block_position: Vector2i,
		offset: Vector2i) -> int:
	
	# Get address
	var neighbor_address := \
		render_data.block_sample.get_block_address(block_position + offset)
	
	if neighbor_address == null:
		return 0
	
	# Check front
	var neighbor_front_id := \
		neighbor_address.chunk.front_ids[neighbor_address.block_index]
	
	if not is_neighbor_partial(render_data, neighbor_front_id):
		return 1
	
	# Check back
	if not render_data.on_front_layer:
		var neighbor_back_id := \
			neighbor_address.chunk.back_ids[neighbor_address.block_index]
		
		if not is_neighbor_partial(render_data, neighbor_back_id):
			return 1
	
	# Check same block on same layer
	var neighbor_ids := neighbor_address.chunk.get_layer(render_data.on_front_layer)
	var neighbor_id := neighbor_ids[neighbor_address.block_index]
	
	if render_data.block_id == neighbor_id:
		return 1
	
	# Check same category
	var neighbor_block := render_data.blocks.block_types[neighbor_id]
	
	var category := render_data.block.category
	
	if category != null and category == neighbor_block.category:
		return 1
	
	return 0

func draw_corner(render_data: BlockRenderData, frame: int, offset: Vector2) -> void:
	var block_sprite := BlockSprite.new()
	
	block_sprite.texture = texture
	
	block_sprite.rect = Rect2(
		Vector2(render_data.chunk_position) + offset * CORNER_SIZE,
		CORNER_SIZE)
	
	block_sprite.region = Rect2(
		Vector2(offset.x + frame, offset.y) * CORNER_SOURCE_SIZE,
		CORNER_SOURCE_SIZE)
	
	render_data.sprites.push_back(block_sprite)

func draw_block(render_data: BlockRenderData) -> void:
	# Create render data
	var block_position := BlockWorld.get_block_position(
		render_data.chunk_position,
		render_data.chunk.chunk_index)
	
	# Get bitmasks for neighbors
	var left_mask := \
		get_neighbor_mask(render_data, block_position, Vector2i.LEFT)
	var right_mask := \
		get_neighbor_mask(render_data, block_position, Vector2i.RIGHT)
	var top_mask := \
		get_neighbor_mask(render_data, block_position, Vector2i.UP)
	var bottom_mask := \
		get_neighbor_mask(render_data, block_position, Vector2i.DOWN)
	var top_left_mask := \
		get_neighbor_mask(render_data, block_position, Vector2i.UP + Vector2i.LEFT)
	var top_right_mask := \
		get_neighbor_mask(render_data, block_position, Vector2i.UP + Vector2i.RIGHT)
	var bottom_left_mask := \
		get_neighbor_mask(render_data, block_position, Vector2i.DOWN + Vector2i.LEFT)
	var bottom_right_mask := \
		get_neighbor_mask(render_data, block_position, Vector2i.DOWN + Vector2i.RIGHT)
	
	# Shift bitmasks
	left_mask <<= SHIFT_HORIZONAL
	right_mask <<= SHIFT_HORIZONAL
	top_mask <<= SHIFT_VERTICAL
	bottom_mask <<= SHIFT_VERTICAL
	
	# Combine bitmasks to get frames
	var top_left_frame = FRAME_OFFSETS[left_mask | top_mask | top_left_mask]
	var top_right_frame = FRAME_OFFSETS[right_mask | top_mask | top_right_mask]
	var bottom_left_frame = FRAME_OFFSETS[left_mask | bottom_mask | bottom_left_mask]
	var bottom_right_frame = FRAME_OFFSETS[right_mask | bottom_mask | bottom_right_mask]
	
	draw_corner(render_data, top_left_frame, Vector2.ZERO)
	draw_corner(render_data, top_right_frame, Vector2.RIGHT)
	draw_corner(render_data, bottom_left_frame, Vector2.DOWN)
	draw_corner(render_data, bottom_right_frame, Vector2.RIGHT + Vector2.DOWN)
