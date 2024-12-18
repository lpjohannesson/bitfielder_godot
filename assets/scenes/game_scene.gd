extends Node2D
class_name GameScene

const SHADOW_TRANSFORM := Transform2D(0.0, Vector2.ONE * 2.0)

static var instance: GameScene

@export var world: GameWorld
@export var block_serializer: BlockSerializer
@export var block_world_renderer: BlockWorldRenderer
@export var packet_manager: GamePacketManager

@export var particles: Node2D
@export var shadow_viewport: SubViewport
@export var shadow_shader: ShaderMaterial

@export var effect_sprite_scene: PackedScene

@onready var viewport := get_viewport()

var server: ServerConnection
var player: Player

func spawn_effect_sprite(effect_name: String, effect_position: Vector2) -> void:
	var effect_sprite: EffectSprite = effect_sprite_scene.instantiate()
	particles.add_child(effect_sprite)
	
	effect_sprite.global_position = effect_position
	effect_sprite.play(effect_name)

func update_block(block_position: Vector2i) -> void:
	var block_world := world.block_world
	
	for chunk in block_world.get_block_chunks(block_position):
		block_world.update_chunk(chunk)
		chunk.redraw_chunk()

func resize() -> void:
	shadow_viewport.size = viewport.get_visible_rect().size

func _init() -> void:
	instance = self

func _ready() -> void:
	shadow_shader.set_shader_parameter(
		"shadow_viewport", shadow_viewport.get_texture())
	
	resize()
	viewport.size_changed.connect(resize)

func _process(_delta: float) -> void:
	shadow_viewport.canvas_transform = \
		viewport.canvas_transform * SHADOW_TRANSFORM
	
	if player != null:
		player.player_input.read_inputs(server)

func _on_player_position_timer_timeout() -> void:
	if player != null:
		packet_manager.send_check_player_position()
