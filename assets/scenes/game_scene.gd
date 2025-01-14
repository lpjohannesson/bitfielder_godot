extends Node2D
class_name GameScene

const SHADOW_TRANSFORM := Transform2D(0.0, Vector2.ONE * 2.0)
const SOUND_PITCH_RANGE := 0.1

static var instance: GameScene

@export var world: GameWorld
@export var blocks_renderer: BlockWorldRenderer
@export var hud: HUD
@export var player_camera: PlayerCamera

@export var light_viewport: LightViewport
@export var screen_display: ScreenDisplay

@export var packet_manager: GamePacketManager
@export var input_manager: GameInputManager
@export var item_select_manager: ItemSelectManager
@export var cursor_manager: CursorManager

@export var particles: Node2D

@export var foreground_viewport: SubViewport
@export var shadow_viewport: SubViewport

@export var back_layer_shader: ShaderMaterial

@export var effect_sprite_scene: PackedScene

@export var break_sound: AudioStream
@export var place_sound: AudioStream

@export var sounds: Array[WorldSound]

@onready var screen_viewport := get_viewport()

var server: ServerConnection
var player: Player

var paused := false

var sound_map := {}

func return_to_menu() -> void:
	get_tree().change_scene_to_file("res://assets/scenes/menu_scene.tscn")

func quit_server() -> void:
	server.send_packet(GamePacket.create_packet(
		Packets.ClientPacket.QUIT_SERVER,
		null
	))

func spawn_effect_sprite(effect_name: String, effect_position: Vector2) -> void:
	var effect_sprite: EffectSprite = effect_sprite_scene.instantiate()
	particles.add_child(effect_sprite)
	
	effect_sprite.global_position = effect_position
	effect_sprite.play(effect_name)

func spawn_world_sound(
		sound_stream: AudioStream, 
		sound_position: Vector2) -> AudioStreamPlayer2D:
	
	var world_sound := AudioStreamPlayer2D.new()
	add_child(world_sound)
	
	world_sound.finished.connect(world_sound.queue_free)
	
	world_sound.global_position = sound_position
	world_sound.stream = sound_stream
	world_sound.pitch_scale = randf_range(1.0 - SOUND_PITCH_RANGE, 1.0 + SOUND_PITCH_RANGE)
	world_sound.play()
	
	return world_sound

func spawn_block_sound(block: BlockType, sound_position: Vector2) -> AudioStreamPlayer2D:
	if block.block_sounds == null:
		return null
	
	var sound_stream: AudioStream = block.block_sounds.sounds.pick_random()
	return spawn_world_sound(sound_stream, sound_position)

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
		var block: BlockType
		
		var effect_position := blocks.block_to_world(
			block_specifier.block_position, true)
		
		if block_specifier.block_id == 0:
			block = blocks.block_types[block_id]
			
			blocks_renderer.spawn_particles(block, effect_position)
			
			spawn_effect_sprite("break", effect_position)
			spawn_world_sound(break_sound, effect_position)
		else:
			block = blocks.block_types[block_specifier.block_id]
			
			spawn_effect_sprite("place", effect_position)
			spawn_world_sound(place_sound, effect_position)
		
		spawn_block_sound(block, effect_position)
	
	block_specifier.write_address(address)
	
	for chunk in blocks.get_neighboring_chunks(block_specifier.block_position):
		blocks.update_chunk(chunk)
		blocks_renderer.redraw_chunk(chunk)
	
	blocks.heightmaps.update_height(block_specifier, false)
	light_viewport.show_lightmap()

func resize() -> void:
	var viewport_size := screen_viewport.get_visible_rect().size
	foreground_viewport.size = viewport_size
	shadow_viewport.size = viewport_size
	
	for chunk in world.blocks.chunk_map.values():
		blocks_renderer.redraw_chunk(chunk)

func _init() -> void:
	instance = self

func _ready() -> void:
	back_layer_shader.set_shader_parameter(
		"shadow_viewport", shadow_viewport.get_texture()
	)
	
	resize()
	screen_viewport.size_changed.connect(resize)
	
	for sound in sounds:
		sound_map[sound.sound_name] = sound.sound_stream

func _process(_delta: float) -> void:
	screen_viewport.canvas_transform = foreground_viewport.canvas_transform
	
	shadow_viewport.canvas_transform = \
		foreground_viewport.canvas_transform * SHADOW_TRANSFORM

func _on_player_position_timer_timeout() -> void:
	if player != null:
		packet_manager.send_check_player_position()
