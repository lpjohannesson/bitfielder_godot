extends Node2D
class_name BlockChunk

const CHUNK_SIZE := Vector2i(8, 8)
const BLOCK_COUNT := CHUNK_SIZE.x * CHUNK_SIZE.y

@export var front_layer: Node2D
@export var back_layer: Node2D
@export var colliders: StaticBody2D

var shadow_layer: Node2D

var front_ids: PackedInt32Array
var back_ids: PackedInt32Array

var chunk_index: Vector2i

var redrawing_chunk := false

static func get_block_index(chunk_position: Vector2i) -> int:
	return chunk_position.y * CHUNK_SIZE.x + chunk_position.x

func get_layer(on_front_layer: bool) -> PackedInt32Array:
	if on_front_layer:
		return front_ids
	else:
		return back_ids

func redraw_chunk() -> void:
	front_layer.queue_redraw()
	back_layer.queue_redraw()
	shadow_layer.queue_redraw()
	
	await front_layer.draw
	redrawing_chunk = false

func _init() -> void:
	front_ids.resize(BLOCK_COUNT)
	back_ids.resize(BLOCK_COUNT)
