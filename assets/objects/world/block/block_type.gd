extends Resource
class_name BlockType

@export var category: BlockCategory
@export var properties: BlockProperties

@export var renderer: BlockRenderer
@export var particle_texture: Texture2D
@export var block_sounds: BlockSounds

@export var is_solid := true
@export var is_one_way := false
@export var is_climbable := false
@export var is_swimmable := false

@export var needs_ground := false
@export var is_ground := true

@export var draws_above_entities := false
@export var is_partial := false
@export var is_transparent := false
@export var casts_shadow := true

@export var block_light: BlockLight
@export var collider: Shape2D

var block_name: String
