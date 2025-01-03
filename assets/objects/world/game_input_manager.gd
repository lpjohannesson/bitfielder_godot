extends Node
class_name GameInputManager

@export var scene: GameScene

func _process(delta: float) -> void:
	if scene.player != null:
		scene.player.player_input.read_inputs(scene.server)
