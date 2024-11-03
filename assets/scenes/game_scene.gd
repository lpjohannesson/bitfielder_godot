extends Node2D
class_name GameScene

static var scene: GameScene

@export var block_world: BlockWorld

func _ready() -> void:
	scene = self
