extends CharacterBody2D
class_name Player

enum PlayerState { GROUND, MODIFYING_BLOCK, CLIMBING }

const ACCELERATION := 300.0
const SPEED := 100.0
const JUMP_VELOCITY := 150.0
const GRAVITY_ACCELERATION := 300.0
const GRAVITY_SPEED := 300.0
const JUMP_MIDSTOP := 0.5
const CLIMB_SPEED := 50.0
const CLIMB_JUMP_SPEED := 50.0
const GROUND_VOLUME := -12.0
const MODIFY_BLOCK_TWEEN_TIME := 0.35

@export var entity: GameEntity
@export var floor_point: Node2D
@export var ceiling_point: Node2D
@export var username_display: UsernameDisplay

@export var coyote_timer: Timer
@export var jump_timer: Timer
@export var modify_block_timer: Timer
@export var slide_effect_timer: Timer
@export var punch_timer: Timer

var move_direction := 0.0
var look_direction := 0.0
var midstopped := false
var modify_block_tween: Tween
var inventory: ItemInventory
var username: String

var last_surface := 0.0
var last_is_sliding := false

var player_input := PlayerInput.new()
var player_state := PlayerState.GROUND

func show_username(new_username: String) -> void:
	username = new_username
	
	var username_text: String
	
	if GameScene.instance.player == self:
		username_text = username + " (You)"
	else:
		username_text = username
	
	username_display.label.text = username_text

func get_facing_sign() -> float:
	return -1.0 if entity.sprite.flip_h else 1.0

func get_is_sliding() -> bool:
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
		entity.sprite.flip_h = move_direction < 0.0

func try_jump_down() -> bool:
	if not player_input.is_action_pressed("look_down"):
		return false
	
	var collision_count := get_slide_collision_count()
	
	if collision_count == 0:
		return false
	
	# Check every floor is one-way
	for i in range(collision_count):
		var collision := get_slide_collision(i)
		
		if collision.get_normal().y >= 0.0:
			continue
		
		var collider := collision.get_collider_shape()
		
		if not collider.one_way_collision:
			return false
	
	global_position.y += 1.0
	entity.play_sound("jump")
	
	return true

func jump() -> void:
	velocity.y = -JUMP_VELOCITY
	midstopped = false
	entity.play_sound("jump")

func update_jump_timer() -> void:
	if player_input.is_action_just_pressed("jump"):
		jump_timer.start()

func try_jump() -> void:
	if jump_timer.is_stopped() or coyote_timer.is_stopped():
		return
	
	jump_timer.stop()
	coyote_timer.stop()
	
	if try_jump_down():
		return
	
	jump()

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
	
	var use_data := ItemUseData.new()
	use_data.player = self
	use_data.on_front_layer = on_front_layer
	use_data.just_pressed = just_pressed
	
	var item_slot := inventory.items[inventory.selected_index]
	
	if item_slot.item_id == 0:
		modify_block_or_punch(0, use_data)
		return
	
	var item := entity.get_game_world().items.item_types[item_slot.item_id]
	
	if item.properties == null:
		return
	
	item.properties.use_item(use_data)

func play_punch_animation() -> void:
	entity.animation_player.stop()
	
	if look_direction < 0.0:
		entity.animation_player.play("punch_up")
	elif look_direction > 0.0:
		entity.animation_player.play("punch_down")
	else:
		entity.animation_player.play("punch_forward")

func animate() -> void:
	if entity.animation_player.current_animation.begins_with("punch_"):
		return
	
	var animation_name: String
	
	if is_on_floor():
		if move_direction == 0.0 or velocity.x == 0.0:
			if look_direction < 0.0:
				animation_name = "look_up"
			elif look_direction > 0.0:
				animation_name = "look_down"
			else:
				animation_name = "idle"
		else:
			if get_is_sliding():
				animation_name = "slide"
			else:
				animation_name = "walk"
	else:
		if velocity.y < 0.0:
			animation_name = "jump"
		else:
			animation_name = "fall"
	
	entity.animation_player.play(animation_name)

func is_block_breakable(block_id: int) -> bool:
	return block_id != 0

func is_front_block_breakable(address: BlockAddress) -> bool:
	return is_block_breakable(address.chunk.front_ids[address.block_index])

func is_back_block_breakable(address: BlockAddress) -> bool:
	return is_block_breakable(address.chunk.back_ids[address.block_index])

func is_block_placeable(block_id: int) -> bool:
	return block_id == 0

func is_block_attachable(block_id: int) -> bool:
	return block_id != 0

func block_has_neighbors(block_position: Vector2i, on_front_layer: bool) -> bool:
	var blocks := entity.get_game_world().blocks
	
	for offset in Direction.NEIGHBOR_OFFSETS_FOUR:
		var neighbor_position := block_position + offset
		var neighbor_address := blocks.get_block_address(neighbor_position)
		
		if neighbor_address == null:
			continue
		
		var neighbor_front_id := \
			neighbor_address.chunk.front_ids[neighbor_address.block_index]
		
		if is_block_attachable(neighbor_front_id):
			return true
		
		if not on_front_layer:
			var neighbor_back_id := \
				neighbor_address.chunk.back_ids[neighbor_address.block_index]
			
			if is_block_attachable(neighbor_back_id):
				return true
	
	return false

func is_entity_above_block(block_position: Vector2i) -> bool:
	var blocks := entity.get_game_world().blocks
	
	var shape_rid := PhysicsServer2D.rectangle_shape_create()
	var shape_extents := blocks.scale * 0.5
	PhysicsServer2D.shape_set_data(shape_rid, shape_extents)
	
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape_rid = shape_rid
	params.transform = Transform2D(0.0, blocks.block_to_world(block_position, true))
	params.collision_mask = 1
	
	var space_state := get_world_2d().direct_space_state
	var collisions := space_state.intersect_shape(params)
	
	PhysicsServer2D.free_rid(shape_rid)
	
	for collision in collisions:
		var collider: Node = collision["collider"]
		
		if collider == self:
			continue
		
		return true
	
	return false

func is_front_block_placeable(address: BlockAddress, block_position: Vector2i) -> bool:
	if not is_block_placeable(address.chunk.front_ids[address.block_index]):
		return false
	
	if is_entity_above_block(block_position):
		return false
	
	if is_block_attachable(address.chunk.back_ids[address.block_index]):
		return true
	
	if block_has_neighbors(block_position, true):
		return true
	
	return false

func is_back_block_placeable(address: BlockAddress, block_position: Vector2i) -> bool:
	if not is_block_placeable(address.chunk.back_ids[address.block_index]):
		return false
	
	if block_has_neighbors(block_position, false):
		return true
	
	return false

func end_modify_block_tween() -> void:
	modify_block_tween = null

func end_modify_block() -> void:
	player_state = PlayerState.GROUND
	entity.collider.disabled = false

func try_modify_block(block_id: int, on_front_layer: bool) -> bool:
	if modify_block_tween != null:
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
		# Skip if placing air
		if block_id == 0:
			return false
		
		if on_front_layer:
			if not is_front_block_placeable(center_address, center_block_position):
				return false
		else:
			if not is_back_block_placeable(center_address, center_block_position):
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
		MODIFY_BLOCK_TWEEN_TIME)
	
	modify_block_tween.finished.connect(end_modify_block_tween)
	
	play_punch_animation()
	entity.animation_player.queue("fall")
	
	modify_block_timer.start()
	entity.collider.disabled = true
	
	entity.update_block(block_specifier, address)
	
	player_state = PlayerState.MODIFYING_BLOCK
	
	return true

func modify_block_or_punch(block_id: int, use_data: ItemUseData) -> void:
	var modify_success := try_modify_block(block_id, use_data.on_front_layer)
	
	if not modify_success and use_data.just_pressed:
		punch()

func show_ground_effects() -> void:
	var surface: float
	var surface_point: Node2D
	
	if is_on_floor():
		surface = 1.0
		surface_point = floor_point
		
		var is_sliding := get_is_sliding()
		
		if is_sliding:
			if not last_is_sliding:
				entity.play_sound("slide")
			
			if slide_effect_timer.is_stopped():
				entity.spawn_effect_sprite("slide", floor_point.global_position)
				slide_effect_timer.start()
		
		last_is_sliding = is_sliding
		
	elif is_on_ceiling():
		surface = -1.0
		surface_point = ceiling_point
	else:
		last_surface = 0.0
		return
	
	if surface == last_surface:
		return
	
	entity.spawn_effect_sprite("ground", surface_point.global_position)
	
	entity.play_sound("ground")
	
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		
		if collision.get_normal().y == 0.0:
			continue
		
		var shape := collision.get_collider_shape()
		
		if not shape is BlockCollider:
			continue
		
		var block_position: Vector2i = shape.block_position
		
		var blocks := entity.get_game_world().blocks
		var address := blocks.get_block_address(block_position)
		var block_id := address.chunk.front_ids[address.block_index]
		var block := blocks.block_types[block_id]
		
		var sound := GameScene.instance.spawn_block_sound(
			block, surface_point.global_position)
		
		if sound != null:
			sound.volume_db = GROUND_VOLUME
		
		break
	
	last_surface = surface

func get_climbable_block(blocks: BlockWorld, block_position: Vector2i) -> BlockType:
	var address := blocks.get_block_address(block_position)
	
	if address == null:
		return null
	
	var block_id := address.chunk.front_ids[address.block_index]
	var block := blocks.block_types[block_id]
	
	if block.properties.is_climbable:
		return block
	else:
		return null

func try_climbing() -> bool:
	if not (\
			player_input.is_action_just_pressed("interact") or \
			player_input.is_action_just_pressed("look_up")):
		
		return false
	
	var blocks := entity.get_game_world().blocks
	var block_position := blocks.world_to_block(global_position)
	var block := get_climbable_block(blocks, block_position)
	
	if block == null:
		return false
	
	# Start climbing
	velocity = Vector2.ZERO
	global_position.x = blocks.block_to_world(block_position, true).x
	
	player_state = PlayerState.CLIMBING
	
	return true

func stop_climbing() -> void:
	velocity.x = move_direction * CLIMB_JUMP_SPEED
	player_state = PlayerState.GROUND
	
func climb() -> void:
	if player_input.is_action_just_pressed("interact"):
		stop_climbing()
		return
	
	if player_input.is_action_just_pressed("jump"):
		stop_climbing()
		jump()
		
		return
	
	var blocks := entity.get_game_world().blocks
	var block_position := blocks.world_to_block(global_position)
	var block := get_climbable_block(blocks, block_position)
	
	if block == null:
		stop_climbing()
		return
	
	velocity.y = look_direction * CLIMB_SPEED
	
	if look_direction == 0.0:
		entity.animation_player.play("climb_idle")
	else:
		entity.animation_player.play("climb")

func controls(delta: float) -> void:
	aim()
	update_jump_timer()
	try_use_item()
	
	match player_state:
		PlayerState.GROUND:
			if try_climbing():
				return
			
			velocity.y = Direction.target_axis(
				velocity.y,
				GRAVITY_SPEED,
				GRAVITY_ACCELERATION * delta)
			
			walk(delta)
			try_jump()
			
			if is_on_floor():
				coyote_timer.start()
			else:
				midstop_jump()
			
			animate()
		
		PlayerState.MODIFYING_BLOCK:
			if modify_block_tween == null:
				# Jump midair after block
				if player_input.is_action_pressed("jump"):
					jump()
					end_modify_block()
			
			if modify_block_timer.is_stopped():
				end_modify_block()
		
		PlayerState.CLIMBING:
			climb()
	
	move_and_slide()

func stop_modify_block() -> void:
	if modify_block_tween != null:
		modify_block_tween.kill()
		modify_block_tween = null

func _ready() -> void:
	entity.position_changed.connect(stop_modify_block)

func _physics_process(delta: float) -> void:
	# Check if remote controlled player
	if not entity.on_server:
		show_ground_effects()
		
		if GameScene.instance.player != self:
			move_and_slide()
			return
	
	controls(delta)
	
	player_input.update_inputs()
