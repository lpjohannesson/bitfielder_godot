extends BlockRenderer
class_name AutoBlockRenderer

const SHIFT_HORIZONAL := 0
const SHIFT_VERTICAL := 1
const SHIFT_DIAGONAL := 2

const FRAME_OFFSETS := [0, 4, 2, 6, 0, 4, 2, 8]

const CORNER_SIZE := Vector2.ONE * 0.5
const CORNER_SOURCE_SIZE := Vector2.ONE * 8.0

@export var texture: Texture2D

func get_neighbor_mask(
	render_data: BlockRenderData,
	block_position: Vector2i,
	offset: Vector2i) -> int:
	
	# Get address
	var block_world := GameScene.scene.block_world
	var address := block_world.get_block_address(block_position + offset)
	
	if address == null:
		return 0
	
	# Check front
	var front_ids := address.chunk.front_ids
	
	if front_ids[address.block_index] != 0:
		return 1
	
	# Check back
	if not render_data.on_front_layer:
		var back_ids := address.chunk.back_ids
		
		if back_ids[address.block_index] != 0:
			return 1
	
	return 0

func draw_corner(render_data: BlockRenderData, frame: int, offset: Vector2) -> void:
	var corner_position := \
		Vector2(render_data.chunk_position) + offset * CORNER_SIZE
	var corner_rect := Rect2(corner_position, CORNER_SIZE)
	
	var corner_source_position := \
		Vector2(offset.x + frame, offset.y) * CORNER_SOURCE_SIZE
	var corner_source_rect := Rect2(corner_source_position, CORNER_SOURCE_SIZE)
	
	render_data.layer.draw_texture_rect_region(
		texture, corner_rect, corner_source_rect)

func draw_block(render_data: BlockRenderData) -> void:
	# Get block position
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
	top_left_mask <<= SHIFT_DIAGONAL
	top_right_mask <<= SHIFT_DIAGONAL
	bottom_left_mask <<= SHIFT_DIAGONAL
	bottom_right_mask <<= SHIFT_DIAGONAL
	
	# Combine bitmasks to get frames
	var top_left_frame = FRAME_OFFSETS[left_mask | top_mask | top_left_mask]
	var top_right_frame = FRAME_OFFSETS[right_mask | top_mask | top_right_mask]
	var bottom_left_frame = FRAME_OFFSETS[left_mask | bottom_mask | bottom_left_mask]
	var bottom_right_frame = FRAME_OFFSETS[right_mask | bottom_mask | bottom_right_mask]
	
	draw_corner(render_data, top_left_frame, Vector2.ZERO)
	draw_corner(render_data, top_right_frame, Vector2.RIGHT)
	draw_corner(render_data, bottom_left_frame, Vector2.DOWN)
	draw_corner(render_data, bottom_right_frame, Vector2.RIGHT + Vector2.DOWN)
