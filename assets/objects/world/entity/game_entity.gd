extends Node
class_name GameEntity

@export var entity_type: String
@export var entity_node: Node
@export var body: CharacterBody2D
@export var sprite: Sprite2D
@export var collider: CollisionShape2D
@export var animation_player: AnimationPlayer
@export var player: Player
@export var sounds: Array[WorldSound]

var entity_id := 0
var entity_data: Dictionary
var on_server = false

var sound_map := {}

signal position_changed

func send_position_changed() -> void:
	position_changed.emit()

func get_game_world() -> GameWorld:
	return GameServer.instance.world if on_server else GameScene.instance.world

func spawn_effect_sprite(effect_name: String, effect_position: Vector2) -> void:
	if not on_server:
		GameScene.instance.spawn_effect_sprite(effect_name, effect_position)

func update_block(block_specifier: BlockSpecifier, address: BlockAddress) -> void:
	if on_server:
		GameServer.instance.update_block(block_specifier, address, true)
	else:
		GameScene.instance.update_block(block_specifier, address, true)
		GameScene.instance.packet_manager.send_check_block_update(block_specifier)

func play_sound(sound_name: String, volume: float = 0.0) -> void:
	if on_server:
		var sound_packet := GamePacket.create_packet(
			Packets.ServerPacket.PLAY_ENTITY_SOUND,
			[entity_id, sound_name]
		)
		
		# Send sound to others
		for client in GameServer.instance.clients:
			if client.player == entity_node:
				continue
			
			client.send_packet(sound_packet)
	else:
		if not sound_map.has(sound_name):
			return
		
		var sound_stream: AudioStream = sound_map[sound_name]
		var sound := GameScene.instance.spawn_world_sound(sound_stream, body.global_position)
		sound.volume_db = volume

func _ready() -> void:
	if not on_server:
		for sound in sounds:
			sound_map[sound.sound_name] = sound.sound_stream

func _physics_process(_delta: float) -> void:
	if body != null:
		var blocks := get_game_world().blocks
		
		var collided_blocks: Array[Vector2i] = []
		
		for i in range(body.get_slide_collision_count()):
			var collision = body.get_slide_collision(i)
			
			if not collision.get_collider_shape() is BlockCollider:
				continue
			
			var block_collider: BlockCollider = collision.get_collider_shape()
			var block_position := block_collider.block_position
			
			if collided_blocks.has(block_position):
				continue
			
			collided_blocks.push_back(block_position)
			
			var address := blocks.get_block_address(block_position)
			var block_id := address.chunk.front_ids[address.block_index]
			var block := blocks.block_types[block_id]
			
			if block.properties != null:
				block.properties.block_entity_collision(self, collision)
