extends Camera2D
class_name PlayerCamera

const DRAG_DISTANCE := Vector2(12.0, 24.0)
const DRAG_SPEED := 0.5
const MAX_DRAG_OFFSET := Vector2(48.0, 48.0)

func get_player() -> Player:
	return GameScene.instance.player

func reset_camera() -> void:
	global_position = get_player().global_position
	offset = Vector2.ZERO
	
	reset_smoothing()

func _physics_process(_delta: float) -> void:
	var player := get_player()
	
	if player == null:
		return
	
	var dragged_position := global_position.clamp(
		player.global_position - DRAG_DISTANCE,
		player.global_position + DRAG_DISTANCE)
	
	global_position = dragged_position
	
	var drag_amount = (dragged_position - global_position) * DRAG_SPEED
	offset = (offset + drag_amount).clamp(-MAX_DRAG_OFFSET, MAX_DRAG_OFFSET)
