extends BlockRenderer
class_name BasicBlockRenderer

@export var texture: Texture2D

func draw_block(render_data: BlockRenderData) -> void:
	var block_rect := Rect2(render_data.chunk_position, Vector2.ONE)
	render_data.chunk.draw_texture_rect(
		texture, block_rect, false, render_data.color)
