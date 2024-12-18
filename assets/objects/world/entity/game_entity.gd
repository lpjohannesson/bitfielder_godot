extends Node
class_name GameEntity

@export var entity_type: String
@export var entity_node: Node
@export var body: CharacterBody2D

var entity_id := 0
var on_server = false

signal position_changed

func get_game_world() -> GameWorld:
	return GameServer.instance.world if on_server else GameScene.instance.world

func spawn_block_particles(block_id: int, block_position: Vector2i) -> void:
	if not on_server:
		GameScene.instance.block_world_renderer.spawn_particles(
			block_id, block_position)

func spawn_effect_sprite(effect_name: String, effect_position: Vector2) -> void:
	if not on_server:
		GameScene.instance.spawn_effect_sprite(effect_name, effect_position)

func update_block(block_specifier: BlockSpecifier) -> void:
	if on_server:
		GameServer.instance.update_block(block_specifier)
	else:
		GameScene.instance.update_block(block_specifier.block_position)
		GameScene.instance.packet_manager.send_check_block_update(block_specifier)
