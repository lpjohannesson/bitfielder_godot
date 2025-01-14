extends SubViewport
class_name LightViewport

const VIEWPORT_SIZE := GameServer.CHUNK_LOAD_EXTENTS * BlockChunk.CHUNK_SIZE * 2

@export var scene: GameScene
@export var light_canvas: ColorRect

var top_left_position: Vector2
var chunk_index: Vector2i
var shader_heightmap: PackedInt32Array
var block_lightmap: Image

func get_block_light(block_id: int) -> BlockLight:
	var block := scene.world.blocks.block_types[block_id]
	return block.block_light

func show_lightmap() -> void:
	var load_zone := GameServer.get_chunk_load_zone(chunk_index)
	top_left_position = load_zone.position * BlockChunk.CHUNK_SIZE
	
	# Pass heightmap to shader for sunlight
	for chunk_x in range(load_zone.position.x, load_zone.end.x):
		var heightmap = scene.world.blocks.heightmaps.get_heightmap(chunk_x)
		
		if heightmap == null:
			continue
		
		var start_index = (chunk_x - load_zone.position.x) * BlockChunk.CHUNK_SIZE.x
		
		for x in range(BlockChunk.CHUNK_SIZE.x):
			shader_heightmap[start_index + x] = heightmap.light_data[x]
	
	light_canvas.material.set_shader_parameter("heightmap", shader_heightmap)
	light_canvas.material.set_shader_parameter("top_height", top_left_position.y)
	
	# Pass block lights
	block_lightmap.fill(Color.BLACK)
	
	for chunk_x in range(load_zone.position.x, load_zone.end.x):
		for chunk_y in range(load_zone.position.y, load_zone.end.y):
			var load_chunk_index := Vector2i(chunk_x, chunk_y)
			var load_chunk := scene.world.blocks.get_chunk(load_chunk_index)
			
			if load_chunk == null:
				continue
			
			var pixel_start := (load_chunk_index - load_zone.position) * BlockChunk.CHUNK_SIZE
			
			for y in range(BlockChunk.CHUNK_SIZE.y):
				for x in range(BlockChunk.CHUNK_SIZE.x):
					var chunk_position := Vector2i(x, y)
					
					var block_index := BlockChunk.get_block_index(chunk_position)
					var front_light := get_block_light(load_chunk.front_ids[block_index])
					
					if front_light == null:
						continue
					
					var pixel_position := pixel_start + chunk_position
					
					block_lightmap.set_pixel(
						pixel_position.x,
						pixel_position.y,
						front_light.color)
	
	var block_lightmap_texture := ImageTexture.create_from_image(block_lightmap)
	light_canvas.material.set_shader_parameter("block_lightmap", block_lightmap_texture)

func _ready():
	size = VIEWPORT_SIZE
	light_canvas.size = VIEWPORT_SIZE
	
	shader_heightmap.resize(VIEWPORT_SIZE.x)
	block_lightmap = Image.create(VIEWPORT_SIZE.x, VIEWPORT_SIZE.y, false, Image.FORMAT_RGBA8)
