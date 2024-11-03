extends Node2D
class_name GameScene

const SHADOW_TRANSFORM := Transform2D(0.0, Vector2.ONE * 2.0)

static var scene: GameScene

@export var block_world: BlockWorld
@export var shadow_viewport: SubViewport
@export var shadow_shader: ShaderMaterial

@onready var viewport := get_viewport()

func resize() -> void:
	shadow_viewport.size = viewport.size

func _init() -> void:
	scene = self

func _ready() -> void:
	shadow_shader.set_shader_parameter(
		"shadow_viewport", shadow_viewport.get_texture())
	
	resize()
	viewport.size_changed.connect(resize)

func _process(_delta: float) -> void:
	shadow_viewport.canvas_transform = \
		viewport.canvas_transform * SHADOW_TRANSFORM
