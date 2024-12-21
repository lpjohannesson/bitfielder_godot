extends Node
class_name GameEntity

@export var entity_type: String
@export var entity_node: Node
@export var body: CharacterBody2D
@export var sprite: Sprite2D
@export var collider: CollisionShape2D
@export var animation_player: AnimationPlayer

var entity_id := 0
var entity_data := {}
var on_server = false

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
