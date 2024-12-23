extends Node2D
class_name GameScene

const SHADOW_TRANSFORM := Transform2D(0.0, Vector2.ONE * 2.0)

static var instance: GameScene

@export var world: GameWorld
@export var blocks_renderer: BlockWorldRenderer
@export var packet_manager: GamePacketManager
@export var hud: HUD

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
	
	var block_id := block_specifier.get_layer(address.chunk)[address.block_index]
	
	# Skip if already the same block
	if block_id == block_specifier.block_id:
		return
	
	var blocks := world.blocks
	
	if show_effects:
		var effect_position := blocks.block_to_world(
			block_specifier.block_position, true)
		
		if block_specifier.block_id == 0:
			blocks_renderer.spawn_particles(
				block_id, effect_position)
			
			spawn_effect_sprite("break", effect_position)
		else:
			spawn_effect_sprite("place", effect_position)
	
	block_specifier.write_address(address)
	
	for chunk in blocks.get_block_chunks(block_specifier.block_position):
		blocks.update_chunk(chunk)
		chunk.redraw_chunk()

func select_item(item_index: int) -> void:
	if player.inventory == null:
		return
	
	player.inventory.selected_index = item_index
	hud.item_bar.show_item_arrow(item_index)
	
	var packet := GamePacket.create_packet(
		Packets.ClientPacket.SELECT_ITEM,
		item_index
	)
	
	server.send_packet(packet)

func move_item_selection(select_direction: int) -> void:
	select_item(posmod(
		player.inventory.selected_index + select_direction,
		ItemInventory.ITEM_COUNT))

func try_select_items() -> void:
	var select_direction = \
		int(Input.is_action_just_pressed("select_right")) - \
		int(Input.is_action_just_pressed("select_left"))
	
	if select_direction == 0:
		return
	
	move_item_selection(select_direction)

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
		try_select_items()
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
			action = "use_front"
		MOUSE_BUTTON_RIGHT:
			action = "use_back"
		MOUSE_BUTTON_WHEEL_UP:
			action = "select_left"
		MOUSE_BUTTON_WHEEL_DOWN:
			action = "select_right"
		_:
			return
	
	if event.pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)
