extends Node2D
class_name GameScene

const SHADOW_TRANSFORM := Transform2D(0.0, Vector2.ONE * 2.0)

static var scene: GameScene

@export var world: GameWorld
@export var block_serializer: BlockSerializer
@export var block_world_renderer: BlockWorldRenderer

@export var particles: Node2D
@export var shadow_viewport: SubViewport
@export var shadow_shader: ShaderMaterial

@export var effect_sprite_scene: PackedScene

@onready var viewport := get_viewport()

func spawn_effect_sprite() -> EffectSprite:
	var effect_sprite: EffectSprite = effect_sprite_scene.instantiate()
	particles.add_child(effect_sprite)
	
	return effect_sprite

func update_block(block_position: Vector2i) -> void:
	var block_world := world.block_world
	
	for chunk in block_world.get_block_chunks(block_position):
		block_world.update_chunk(chunk)
		chunk.redraw_chunk()

func load_chunk(packet: ServerPacket) -> void:
	var block_world := world.block_world
	var chunk := block_world.create_chunk(packet.data["index"])
	
	block_serializer.load_chunk(chunk, packet.data)
	block_world.update_chunk(chunk)
	
	block_world_renderer.start_chunk(chunk)

func recieve_packet(packet: ServerPacket) -> void:
	match packet.type:
		ServerPacket.PacketType.BLOCK_CHUNK:
			load_chunk(packet)

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
