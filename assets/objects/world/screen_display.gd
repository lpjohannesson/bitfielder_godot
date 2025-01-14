extends Control
class_name ScreenDisplay

@export var foreground_viewport: SubViewport
@export var light_viewport: LightViewport
@export var world: GameWorld

func move_display() -> void:
	global_position = Vector2(light_viewport.top_left_position) * scale

func _ready():
	scale = world.blocks.scale
	size = LightViewport.VIEWPORT_SIZE
	
	material.set_shader_parameter(
		"foreground_texture", foreground_viewport.get_texture())
	
	material.set_shader_parameter(
		"light_texture", light_viewport.get_texture())
