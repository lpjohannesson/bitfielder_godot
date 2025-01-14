extends Node2D
class_name CursorManager

enum CursorState { NONE, BUTTON, MOUSE }

@export var scene: GameScene
@export var button_cursor: Node2D

@export var cursor_image: Texture2D
@export var cursor_disabled_image: Texture2D

@export var move_timer: Timer
@export var reset_timer: Timer

var cursor_state := CursorState.NONE
var use_data := ItemUseData.new()

var mouse_block_position: Vector2i
var mouse_in_range := false

var button_cursor_offset := Vector2i.ZERO

func use_cursor_item(block_position: Vector2i) -> void:
	use_data.block_position = block_position
	scene.player.use_item(use_data)
	
	use_data.just_pressed = false

func start_use_cursor_item(
		block_position: Vector2i,
		on_front_layer: bool) -> void:
	
	use_data.player = scene.player
	use_data.on_front_layer = on_front_layer
	use_data.just_pressed = true
	
	use_data.clicked = true
	
	var address := scene.world.blocks.get_block_address(block_position)
	
	if address != null:
		var block_id := address.chunk.get_layer(use_data.on_front_layer)[address.block_index]
		use_data.breaking = block_id != 0
	
	use_cursor_item(block_position)

func get_button_cursor_position() -> Vector2i:
	return scene.player.center_block_position + button_cursor_offset

func try_start_button_cursor() -> void:
	if button_cursor_offset == Vector2i.ZERO:
		return
	
	var on_front_layer: bool
	
	if Input.is_action_just_pressed("use_front"):
		on_front_layer = true
	elif Input.is_action_just_pressed("use_back"):
		on_front_layer = false
	else:
		return
	
	start_use_cursor_item(get_button_block_position(), on_front_layer)
	cursor_state = CursorState.BUTTON

func use_button_cursor() -> void:
	reset_timer.start()
	
	if use_data.on_front_layer:
		if Input.is_action_just_released("use_front"):
			cursor_state = CursorState.NONE
			return
	else:
		if Input.is_action_just_released("use_back"):
			cursor_state = CursorState.NONE
			return
	
	use_cursor_item(get_button_block_position())

func update_action(action1: String, action2: String) -> void:
	if Input.is_action_just_pressed(action1):
		Input.action_press(action2)
	
	elif Input.is_action_just_released(action1):
		Input.action_release(action2)

func use_buttons_without_cursor() -> void:
	update_action("use_front", "use_button_front")
	update_action("use_back", "use_button_back")

func get_button_block_position() -> Vector2i:
	var player_block_position := scene.player.center_block_position
	return player_block_position + button_cursor_offset

func move_button_cursor() -> void:
	if not move_timer.is_stopped():
		return
	
	var cursor_direction := Vector2i(
		int(Input.is_action_pressed("cursor_right")) - \
		int(Input.is_action_pressed("cursor_left")),
		int(Input.is_action_pressed("cursor_down")) - \
		int(Input.is_action_pressed("cursor_up")),
	)
	
	if cursor_direction == Vector2i.ZERO:
		return

	button_cursor_offset = (button_cursor_offset + cursor_direction).clamp(
		-Player.BLOCK_PLACE_EXTENTS,
		Player.BLOCK_PLACE_EXTENTS
	)
	
	Input.action_release("use_button_front")
	Input.action_release("use_button_back")
	
	move_timer.start()
	reset_timer.start()

func update_button_cursor() -> void:
	move_button_cursor()
	
	if cursor_state != CursorState.BUTTON and button_cursor_offset == Vector2i.ZERO:
		button_cursor.hide()
		use_buttons_without_cursor()
	else:
		var button_block_position := get_button_block_position()
		
		var cursor_position := scene.world.blocks.block_to_world(
			button_block_position, true)
		
		button_cursor.global_position = cursor_position
		button_cursor.show()

func update_mouse_cursor() -> void:
	var mouse_position := get_global_mouse_position()
	
	mouse_block_position = scene.world.blocks.world_to_block(mouse_position)
	mouse_in_range = scene.player.is_block_in_range(mouse_block_position)
	
	if scene.hud.hud_focused or mouse_in_range:
		reset_cursor()
	else:
		Input.set_custom_mouse_cursor(cursor_disabled_image)

func get_mouse_action(event: InputEvent) -> String:
	var action: String
	
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			return "use_button_front"
		
		MOUSE_BUTTON_RIGHT:
			return "use_button_back"
	
	return ""

func try_start_use_mouse(event: InputEvent) -> void:
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			start_use_cursor_item(mouse_block_position, true)
			
		MOUSE_BUTTON_RIGHT:
			start_use_cursor_item(mouse_block_position, false)
		
		_:
			return
	
	cursor_state = CursorState.MOUSE

func try_stop_use_mouse(event: InputEvent) -> void:
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if not use_data.on_front_layer:
				return
			
			cursor_state = CursorState.NONE
		
		MOUSE_BUTTON_RIGHT:
			if use_data.on_front_layer:
				return
			
			cursor_state = CursorState.NONE

func _physics_process(_delta: float) -> void:
	if scene.paused:
		return
	
	if scene.player == null:
		return
	
	update_mouse_cursor()
	update_button_cursor()
	
	match cursor_state:
		CursorState.NONE:
			try_start_button_cursor()
		
		CursorState.BUTTON:
			use_button_cursor()
		
		CursorState.MOUSE:
			if not mouse_in_range:
				return
			
			use_cursor_item(mouse_block_position)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	
	if event.pressed:
		if cursor_state != CursorState.NONE:
			return
		
		if mouse_in_range:
			try_start_use_mouse(event)
		else:
			var action := get_mouse_action(event)
			
			if action == "":
				return
			
			Input.action_press(action)
	else:
		match cursor_state:
			CursorState.NONE:
				var action := get_mouse_action(event)
				
				if action == "":
					return
				
				Input.action_release(action)
			
			CursorState.MOUSE:
				try_stop_use_mouse(event)

func reset_cursor() -> void:
	Input.set_custom_mouse_cursor(cursor_image)

func _exit_tree() -> void:
	reset_cursor()

func _on_reset_timer_timeout() -> void:
	button_cursor_offset = Vector2i.ZERO
