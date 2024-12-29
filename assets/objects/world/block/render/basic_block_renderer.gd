extends BlockRenderer
class_name BasicBlockRenderer

@export var texture: Texture2D

func draw_block(render_data: BlockRenderData) -> void:
	var block_sprite := BlockSprite.new()
	
	block_sprite.texture = texture
	block_sprite.rect = Rect2(render_data.chunk_position, Vector2.ONE)
	block_sprite.region = Rect2(Vector2.ZERO, texture.get_size())
	
	render_data.sprites.push_back(block_sprite)
