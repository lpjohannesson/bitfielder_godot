extends Node2D
class_name GameWorld

@export var block_world: BlockWorld

static var instance: GameWorld

signal effect_sprite_spawned(effect_name: String, effect_position: Vector2)
signal block_updated(block_position: Vector2i)
signal block_particles_spawned(block_id: int, block_position: Vector2i)
