extends Node
class_name ItemSelectManager

@export var scene: GameScene

@export var select_item_sound: AudioStreamPlayer
@export var select_page_sound: AudioStreamPlayer

@export var page_timer: Timer
@export var sound_timer: Timer

func send_item_selection() -> void:
	var packet := GamePacket.create_packet(
		Packets.ClientPacket.SELECT_ITEM,
		scene.player.inventory.selected_index)
	
	scene.server.send_packet(packet)

func can_update_items() -> bool:
	return scene.player != null and scene.player.inventory != null

func update_page_item() -> void:
	send_item_selection()
	
	var page_item_index := scene.player.inventory.get_page_item_index()
	scene.hud.item_bar.show_item_arrow(page_item_index)
	
	if sound_timer.is_stopped():
		sound_timer.start()
		select_item_sound.play()

func select_page_item(item_index: int) -> void:
	if not can_update_items():
		return
	
	scene.player.inventory.select_page_item(item_index)
	update_page_item()

func move_page_item(direction: int) -> void:
	if not can_update_items():
		return
	
	scene.player.inventory.move_page_item(direction)
	update_page_item()

func move_item_page(direction: int) -> void:
	if not can_update_items():
		return
	
	scene.player.inventory.move_item_page(direction)
	send_item_selection()
	
	scene.hud.item_bar.show_inventory(scene.player.inventory)
	select_page_sound.play()

func get_pressed_select_direction() -> int:
	return \
		int(Input.is_action_pressed("select_right")) - \
		int(Input.is_action_pressed("select_left"))

func try_select_items() -> void:
	if scene.paused:
		return
	
	var page_direction := \
		int(Input.is_action_just_pressed("item_page_right")) - \
		int(Input.is_action_just_pressed("item_page_left"))
	
	if page_direction != 0:
		move_item_page(page_direction)
	
	var select_direction := \
		int(Input.is_action_just_pressed("select_right")) - \
		int(Input.is_action_just_pressed("select_left"))
	
	if select_direction != 0:
		move_page_item(select_direction)
	
	if get_pressed_select_direction() == 0:
		page_timer.stop()
	else:
		if page_timer.is_stopped():
			page_timer.start()

func _process(_delta: float) -> void:
	try_select_items()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	
	var action: String
	
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			action = "select_left"
		
		MOUSE_BUTTON_WHEEL_DOWN:
			action = "select_right"
		_:
			return
	
	if event.pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)

func _on_item_page_timer_timeout() -> void:
	move_item_page(get_pressed_select_direction())
