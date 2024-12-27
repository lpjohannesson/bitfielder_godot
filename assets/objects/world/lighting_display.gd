extends Control
class_name LightingDisplay

const VIEWPORT_SIZE := GameServer.CHUNK_LOAD_EXTENTS * BlockChunk.CHUNK_SIZE * 2

@export var world: GameWorld
@export var light_viewport: SubViewport
@export var light_canvas: ColorRect

var chunk_index: Vector2i
var shader_heightmap: PackedInt32Array
var block_lightmap: Image

func get_block_color(block_id: int) -> BlockColor:
	var block := world.blocks.block_types[block_id]
	return block.properties.block_color

func show_lightmap() -> void:
	var load_zone := GameServer.get_chunk_load_zone(chunk_index)
	var top_left_position := load_zone.position * BlockChunk.CHUNK_SIZE
	
	global_position = Vector2(top_left_position) * scale
	
	# Pass heightmap to shader for sunlight
	for chunk_x in range(load_zone.position.x, load_zone.end.x):
		var heightmap = world.blocks.get_heightmap(chunk_x)
		
		if heightmap == null:
			continue
		
		var start_index = (chunk_x - load_zone.position.x) * BlockChunk.CHUNK_SIZE.x
		
		for x in range(BlockChunk.CHUNK_SIZE.x):
			shader_heightmap[start_index + x] = heightmap[x]
	
	light_canvas.material.set_shader_parameter("heightmap", shader_heightmap)
	light_canvas.material.set_shader_parameter("top_height", top_left_position.y)
	
	# Pass block lights
	block_lightmap.fill(Color.BLACK)
	
	for chunk_x in range(load_zone.position.x, load_zone.end.x):
		for chunk_y in range(load_zone.position.y, load_zone.end.y):
			var load_chunk_index := Vector2i(chunk_x, chunk_y)
			var load_chunk := world.blocks.get_chunk(load_chunk_index)
			
			if load_chunk == null:
				continue
			
			for y in range(BlockChunk.CHUNK_SIZE.y):
				for x in range(BlockChunk.CHUNK_SIZE.x):
					var chunk_position := Vector2i(x, y)
					var block_index := BlockChunk.get_block_index(chunk_position)
					
					var front_color := get_block_color(load_chunk.front_ids[block_index])
					
					if front_color == null:
						continue
					
					var pixel_position := \
						(load_chunk_index - load_zone.position) * BlockChunk.CHUNK_SIZE + chunk_position
					
					block_lightmap.set_pixel(
						pixel_position.x,
						pixel_position.y,
						front_color.color)
	
	var block_lightmap_texture := ImageTexture.create_from_image(block_lightmap)
	light_canvas.material.set_shader_parameter("block_lightmap", block_lightmap_texture)

func _ready():
	scale = world.blocks.scale
	
	size = VIEWPORT_SIZE
	light_viewport.size = VIEWPORT_SIZE
	light_canvas.size = VIEWPORT_SIZE
	
	material.set_shader_parameter(
		"viewport_texture", light_viewport.get_texture())
	
	shader_heightmap.resize(VIEWPORT_SIZE.x)
	block_lightmap = Image.create(VIEWPORT_SIZE.x, VIEWPORT_SIZE.y, false, Image.FORMAT_RGBA8)
