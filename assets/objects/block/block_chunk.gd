extends Node2D
class_name BlockChunk

const CHUNK_SIZE := Vector2i(16, 16)
const BLOCK_COUNT := CHUNK_SIZE.x * CHUNK_SIZE.y

@export var colliders: StaticBody2D

var front_ids: PackedInt32Array
var back_ids: PackedInt32Array

static func get_block_index(chunk_position: Vector2i) -> int:
	return chunk_position.y * CHUNK_SIZE.x + chunk_position.x

func _ready() -> void:
	front_ids.resize(BLOCK_COUNT)
	back_ids.resize(BLOCK_COUNT)
