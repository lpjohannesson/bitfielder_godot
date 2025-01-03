extends Control
class_name MenuBackground

const BOARD_SIZE := Vector2i(32, 24)

@export var cell_scene: PackedScene
@export var grid: GridContainer
@export var colors: Array[Color]

var swapped := false
var swap_color: Color

func get_background_cell(cell_position: Vector2i) -> MenuBackgroundCell:
	if cell_position.x < 0 or cell_position.x >= BOARD_SIZE.x:
		return null
	
	if cell_position.y < 0 or cell_position.y >= BOARD_SIZE.y:
		return null
	
	return grid.get_child(cell_position.y * BOARD_SIZE.x + cell_position.x)

func cell_has_swapped_neighbors(cell_position: Vector2i) -> bool:
	for offset in Direction.NEIGHBOR_OFFSETS_FOUR:
		var neighbor_cell := get_background_cell(cell_position + offset)
		
		if neighbor_cell == null:
			continue
		
		if neighbor_cell.swapped != swapped:
			continue
		
		return true
	
	return false

func pick_new_swap_color() -> void:
	while true:
		var random_color: Color = colors.pick_random()
		
		if swap_color == random_color:
			continue
		
		swap_color = random_color
		break

func swap_cell(cell: MenuBackgroundCell) -> void:
	cell.swap_to_color(swap_color)
	cell.swapped = swapped

func start_swap_cells() -> void:
	swapped = not swapped
	pick_new_swap_color()
	
	var cell_position: Vector2i
	
	match randi() % 4:
		0:
			cell_position = Vector2i.ZERO
		1:
			cell_position = Vector2i(BOARD_SIZE.x - 1, 0)
		2:
			cell_position = Vector2i(0, BOARD_SIZE.y - 1)
		3:
			cell_position = BOARD_SIZE - Vector2i.ONE
	
	var corner_cell := get_background_cell(cell_position)
	swap_cell(corner_cell)

func step_cells() -> void:
	var queued_cells: Array[MenuBackgroundCell] = []
	var cells_finished := true
	
	for y in range(BOARD_SIZE.y):
		for x in range(BOARD_SIZE.x):
			var cell_position := Vector2i(x, y)
			var cell := get_background_cell(cell_position)
			
			if cell.swapped == swapped:
				continue
			
			cells_finished = false
			
			if not cell_has_swapped_neighbors(cell_position):
				continue
			
			if randf() < 0.5:
				continue
			
			queued_cells.push_back(cell)
	
	if cells_finished:
		start_swap_cells()
	else:
		for cell in queued_cells:
			swap_cell(cell)

func _ready() -> void:
	grid.columns = BOARD_SIZE.x
	
	pick_new_swap_color()
	
	for i in range(BOARD_SIZE.x * BOARD_SIZE.y):
		var cell: MenuBackgroundCell = cell_scene.instantiate()
		grid.add_child(cell)
		
		cell.start_color(swap_color)
	
	start_swap_cells()

func _on_move_timer_timeout() -> void:
	step_cells()
