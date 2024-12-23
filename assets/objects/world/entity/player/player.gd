extends CharacterBody2D
class_name Player

const ACCELERATION = 300.0
const SPEED = 100.0
const JUMP_VELOCITY = 150.0
const GRAVITY_ACCELERATION = 300.0
const GRAVITY_SPEED = 300.0
const JUMP_MIDSTOP = 0.5

@export var entity: GameEntity
@export var sprite: Sprite2D
@export var collider: CollisionShape2D
@export var animation_player: AnimationPlayer
@export var coyote_timer: Timer
@export var jump_timer: Timer
@export var modify_block_timer: Timer
@export var slide_effect_timer: Timer
@export var punch_timer: Timer
@export var floor_point: Node2D
@export var ceiling_point: Node2D

var move_direction := 0.0
var look_direction := 0.0
var midstopped := false
var modify_block_tween: Tween
var inventory: ItemInventory

var last_surface := 0.0
var player_input := PlayerInput.new()

func get_facing_sign() -> float:
	return -1.0 if sprite.flip_h else 1.0

func is_sliding() -> bool:
	return velocity.x != 0.0 and sign(velocity.x) != get_facing_sign()

func walk(delta: float) -> void:
	if is_on_floor() or move_direction != 0.0:
		velocity.x = Direction.target_axis(
			velocity.x,
			move_direction * SPEED,
			ACCELERATION * delta)

func aim() -> void:
	move_direction = sign(player_input.get_axis("move_left", "move_right"))
	look_direction = sign(player_input.get_axis("look_up", "look_down"))
	
	if move_direction != 0.0:
		sprite.flip_h = move_direction < 0.0

func jump() -> void:
	if player_input.is_action_just_pressed("jump"):
		jump_timer.start()
	
	if jump_timer.is_stopped() or coyote_timer.is_stopped():
		return
	
	jump_timer.stop()
	coyote_timer.stop()
	
	velocity.y = -JUMP_VELOCITY
	midstopped = false

func midstop_jump():
	if not midstopped and \
		velocity.y < 0.0 and \
		not player_input.is_action_pressed("jump"):
		
		midstopped = true
		velocity.y *= JUMP_MIDSTOP

func punch() -> void:
	if not punch_timer.is_stopped():
		return
	
	play_punch_animation()
	punch_timer.start()

func try_use_item() -> void:
	if inventory == null:
		return
	
	var on_front_layer: bool
	
	var pressed_action: String
	var just_pressed: bool
	
	if player_input.is_action_pressed("use_front"):
		on_front_layer = true
		pressed_action = "use_front"
	elif player_input.is_action_pressed("use_back"):
		on_front_layer = false
		pressed_action = "use_back"
	else:
		return
	
	just_pressed = player_input.is_action_just_pressed(pressed_action)
	
	var item_slot := inventory.items[inventory.selected_index]
	
	if item_slot.item_id == 0:
		if not try_modify_block(0, on_front_layer) and just_pressed:
			punch()
		
		return
	
	var item := entity.get_game_world().items.item_types[item_slot.item_id]
	
	if item.properties == null:
		return
	
	var use_data := ItemUseData.new()
	use_data.player = self
	use_data.on_front_layer = on_front_layer
	
	item.properties.use_item(use_data)

func play_punch_animation() -> void:
	animation_player.stop()
	
	if look_direction < 0.0:
		animation_player.play("punch_up")
	elif look_direction > 0.0:
		animation_player.play("punch_down")
	else:
		animation_player.play("punch_forward")

func animate() -> void:
	if animation_player.current_animation.begins_with("punch_"):
		return
	
	if is_on_floor():
		if move_direction == 0.0 or velocity.x == 0.0:
			if look_direction < 0.0:
				animation_player.play("look_up")
			elif look_direction > 0.0:
				animation_player.play("look_down")
			else:
				animation_player.play("idle")
		else:
			if is_sliding():
				animation_player.play("slide")
			else:
				animation_player.play("walk")
	else:
		if velocity.y < 0.0:
			animation_player.play("jump")
		else:
			animation_player.play("fall")

func is_block_breakable(block_index: int, block_ids: PackedInt32Array) -> bool:
	return block_ids[block_index] != 0

func is_front_block_breakable(address: BlockAddress) -> bool:
	return is_block_breakable(address.block_index, address.chunk.front_ids)

func is_back_block_breakable(address: BlockAddress) -> bool:
	return is_block_breakable(address.block_index, address.chunk.back_ids)

func try_modify_block(block_id: int, on_front_layer: bool) -> bool:
	if not modify_block_timer.is_stopped():
		return false
	
	# Get block position
	var blocks := entity.get_game_world().blocks
	
	var center_block_position := blocks.world_to_block(global_position)
	var forward_block_position := center_block_position
	
	if look_direction == 0.0:
		forward_block_position.x += int(get_facing_sign())
	else:
		forward_block_position.y += int(look_direction)
	
	# Get block addresses
	var center_address := blocks.get_block_address(center_block_position)
	var forward_address := blocks.get_block_address(forward_block_position)
	
	# Determine if placing or breaking
	var breaking: bool
	
	if on_front_layer:
		if center_address == null:
			if forward_address == null:
				return false
			
			if not is_front_block_breakable(forward_address):
				return false
			
			breaking = true
		elif forward_address == null:
			breaking = false
		else:
			breaking = is_front_block_breakable(forward_address)
	else:
		if center_address == null:
			return false
		
		# Check for blocks in front
		if forward_address != null:
			var forward_front_ids := forward_address.chunk.front_ids
			var forward_front_id := forward_front_ids[forward_address.block_index]
			var forward_front_block := blocks.block_types[forward_front_id]
			
			if forward_front_block.properties.is_solid:
				return false
		
		breaking = is_back_block_breakable(center_address)
	
	# Place or break
	var block_specifier := BlockSpecifier.new()
	block_specifier.on_front_layer = on_front_layer
	
	var address: BlockAddress
	
	if breaking:
		if on_front_layer:
			address = forward_address
			block_specifier.block_position = forward_block_position
		else:
			address = center_address
			block_specifier.block_position = center_block_position
		
		block_specifier.block_id = 0
	else:
		if block_id == 0:
			return false
		
		address = center_address
		
		block_specifier.block_position = center_block_position
		block_specifier.block_id = block_id
	
	# Start movement
	velocity = Vector2.ZERO
	
	modify_block_tween = create_tween()\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUAD)
	
	modify_block_tween.tween_property(self, "global_position",
		blocks.block_to_world(forward_block_position, true),
		modify_block_timer.wait_time)
	
	play_punch_animation()
	animation_player.queue("fall")
	
	modify_block_timer.start()
	collider.disabled = true
	
	entity.update_block(block_specifier, address)
	
	return true

func show_ground_effects() -> void:
	var surface: float
	var surface_point: Node2D
	
	if is_on_floor():
		surface = 1.0
		surface_point = floor_point
		
		if slide_effect_timer.is_stopped() and is_sliding():
			entity.spawn_effect_sprite("slide", floor_point.global_position)
			slide_effect_timer.start()
		
	elif is_on_ceiling():
		surface = -1.0
		surface_point = ceiling_point
	else:
		last_surface = 0.0
		return
	
	if surface == last_surface:
		return
	
	entity.spawn_effect_sprite("ground", surface_point.global_position)
	last_surface = surface

func controls(delta: float) -> void:
	try_use_item()
	
	if not modify_block_timer.is_stopped():
		return
	
	velocity.y = Direction.target_axis(
		velocity.y,
		GRAVITY_SPEED,
		GRAVITY_ACCELERATION * delta)
	
	aim()
	walk(delta)
	jump()
	
	if is_on_floor():
		coyote_timer.start()
	else:
		midstop_jump()
	
	move_and_slide()
	
	show_ground_effects()
	animate()

func stop_modify_block() -> void:
	if modify_block_tween != null:
		modify_block_tween.kill()
		modify_block_tween = null

func _ready() -> void:
	entity.position_changed.connect(stop_modify_block)

func _physics_process(delta: float) -> void:
	# Check if remote controlled player
	if not entity.on_server and GameScene.instance.player != self:
		move_and_slide()
		show_ground_effects()
		return
	
	if modify_block_timer.is_stopped():
		controls(delta)
	
	player_input.update_inputs()

func _on_modify_block_timer_timeout() -> void:
	collider.disabled = false
	aim()
