class_name SpriteCopy

static func copy_sprite_update(sprite: Sprite2D, sprite_copy: Sprite2D) -> void:
	sprite_copy.global_transform = sprite.global_transform
	sprite_copy.flip_h = sprite.flip_h

static func copy_sprite(sprite: Sprite2D, sprite_copy: Sprite2D) -> void:
	sprite_copy.texture = sprite.texture
	sprite_copy.hframes = sprite.hframes
	sprite_copy.vframes = sprite.vframes
	sprite_copy.frame = sprite.frame
	
	copy_sprite_update(sprite, sprite_copy)
