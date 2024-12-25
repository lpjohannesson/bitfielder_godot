extends Control
class_name LightingDisplay

const VIEWPORT_SIZE := GameServer.CHUNK_LOAD_EXTENTS * BlockChunk.CHUNK_SIZE * 2

@export var world: GameWorld
@export var light_viewport: SubViewport
@export var light_canvas: ColorRect

var chunk_index: Vector2i

func show_lightmap() -> void:
	var center_position := chunk_index * BlockChunk.CHUNK_SIZE
	var top_left_position := center_position - VIEWPORT_SIZE / 2
	
	global_position = Vector2(top_left_position) * scale
	
	# Pass heightmap to shader for sunlight
	var shader_heightmap: PackedInt32Array = []
	shader_heightmap.resize(VIEWPORT_SIZE.x)
	
	for i in range(GameServer.CHUNK_LOAD_EXTENTS.x * 2):
		var chunk_x = i - GameServer.CHUNK_LOAD_EXTENTS.x + chunk_index.x
		var heightmap = world.blocks.get_heightmap(chunk_x)
		
		if heightmap == null:
			continue
		
		var start_index = i * BlockChunk.CHUNK_SIZE.x
		
		for x in range(BlockChunk.CHUNK_SIZE.x):
			shader_heightmap[start_index + x] = heightmap[x]
	
	light_canvas.material.set_shader_parameter("heightmap", shader_heightmap)
	light_canvas.material.set_shader_parameter("top_height", top_left_position.y)

func _ready():
	scale = world.blocks.scale
	
	size = VIEWPORT_SIZE
	light_viewport.size = VIEWPORT_SIZE
	light_canvas.size = VIEWPORT_SIZE
	
	material.set_shader_parameter(
		"viewport_texture", light_viewport.get_texture())
