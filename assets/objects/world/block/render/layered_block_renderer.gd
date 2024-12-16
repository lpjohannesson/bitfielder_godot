extends BlockRenderer
class_name LayeredBlockRenderer

@export var renderers: Array[BlockRenderer]

func draw_block(render_data: BlockRenderData) -> void:
	for renderer in renderers:
		renderer.draw_block(render_data)
