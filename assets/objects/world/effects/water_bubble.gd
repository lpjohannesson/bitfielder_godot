extends Node2D
class_name WaterBubble

const UP_SPEED := 15.0
const MOVE_RANGE := 4.0
const MOVE_FREQUENCY := 3.0

var center_x := 0.0
var move_time := 0.0

func check_liquid() -> void:
	var blocks := GameScene.instance.world.blocks
	var block_position := blocks.world_to_block(global_position)
	var address := blocks.get_block_address(block_position)
	
	if address == null:
		return
	
	var block_id := address.chunk.front_ids[address.block_index]
	var block := blocks.block_types[block_id]
	
	if not block.properties.is_swimmable:
		queue_free()

func start_bubble(bubble_position: Vector2) -> void:
	global_position = bubble_position
	center_x = bubble_position.x

func _process(delta: float) -> void:
	global_position.y -= UP_SPEED * delta
	
	global_position.x = center_x + sin(move_time) * MOVE_RANGE
	move_time += MOVE_FREQUENCY * delta
	
	check_liquid()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
