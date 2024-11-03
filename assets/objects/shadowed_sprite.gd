extends Sprite2D
class_name ShadowedSprite

var shadow: Sprite2D

func _ready() -> void:
	shadow = Sprite2D.new()
	
	var shadow_viewport := GameScene.scene.shadow_viewport
	shadow_viewport.add_child(shadow)
	
	shadow.texture = texture
	shadow.hframes = hframes
	shadow.vframes = vframes
	shadow.frame = frame
	
	texture_changed.connect(func() -> void:
		shadow.texture = texture)
	
	frame_changed.connect(func() -> void:
		shadow.frame = frame)
	
	tree_exited.connect(shadow.queue_free)

func _process(_delta: float) -> void:
	shadow.global_transform = global_transform
	shadow.flip_h = flip_h
