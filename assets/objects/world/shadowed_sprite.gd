extends Sprite2D
class_name ShadowedSprite

var shadow: Sprite2D

func _ready() -> void:
	# Check is on client
	if GameScene.instance == null:
		return
	
	# Check shadow is on main viewport
	if get_viewport() != GameScene.instance.foreground_viewport:
		return
	
	shadow = Sprite2D.new()
	
	var shadow_viewport := GameScene.instance.shadow_viewport
	shadow_viewport.add_child(shadow)
	
	SpriteCopy.copy_sprite(self, shadow)
	
	texture_changed.connect(func() -> void:
		shadow.texture = texture)
	
	frame_changed.connect(func() -> void:
		shadow.frame = frame)
	
	tree_exited.connect(shadow.queue_free)

func _process(_delta: float) -> void:
	if shadow == null:
		return
	
	SpriteCopy.copy_sprite_update(self, shadow)
