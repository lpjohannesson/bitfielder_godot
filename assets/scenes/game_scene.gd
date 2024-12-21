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

func update_block(
		block_specifier: BlockSpecifier,
		address: BlockAddress,
		show_effects: bool) -> void:
	
	var block_ids := block_specifier.get_layer(address.chunk)
	
	# Skip if already the same block
	if block_ids[address.block_index] == block_specifier.block_id:
		return
	
	var block_world := world.block_world
	
	if show_effects:
		var effect_position := block_world.block_to_world(
			block_specifier.block_position, true)
		
		if block_specifier.block_id == 0:
			block_world_renderer.spawn_particles(
				block_ids[address.block_index], effect_position)
			
			spawn_effect_sprite("break", effect_position)
		else:
			spawn_effect_sprite("place", effect_position)
	
	block_specifier.write_address(address)
	
	for chunk in block_world.get_block_chunks(block_specifier.block_position):
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

func _on_click_surface_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	
	var action: String
	
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			action = "break_front"
		MOUSE_BUTTON_RIGHT:
			action = "break_back"
		_:
			return
	
	if event.pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)
