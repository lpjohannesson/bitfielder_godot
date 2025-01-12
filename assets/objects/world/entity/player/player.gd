extends CharacterBody2D
class_name Player

enum PlayerState { GROUND, MODIFYING_BUTTON_BLOCK, CLIMBING, SWIMMING }

const GROUND_WALK_ACCELERATION := 400.0
const GROUND_RUN_ACCELERATION := 450.0
const AIR_ACCELERATION := 250.0

const GROUND_WALK_SPEED := 110.0
const GROUND_RUN_SPEED := 180.0

const WATER_ACCELERATION := 200.0
const WATER_SPEED := 75.0
const WATER_GROUND_SPEED := 20.0

const GRAVITY_ACCELERATION := 350.0
const GRAVITY_SPEED := 300.0
const WALL_GRAVITY_SPEED := 70.0

const WATER_GRAVITY_ACCELERATION := 100.0
const WATER_GRAVITY_SPEED := 70.0

const JUMP_VELOCITY := 180.0
const WATER_JUMP_VELOCITY := 100.0

const JUMP_MIDSTOP := 0.5
const CLIMB_SPEED := 50.0
const CLIMB_JUMP_SPEED := 50.0
const GROUND_VOLUME := -12.0
const MODIFY_BLOCK_TWEEN_TIME := 0.3

const BLOCK_PLACE_EXTENTS := Vector2i(4, 4)

@export var entity: GameEntity
@export var username_display: UsernameDisplay

@export var floor_point: Node2D
@export var ceiling_point: Node2D
@export var wall_point: Node2D

@export var coyote_timer: Timer
@export var jump_timer: Timer
@export var modify_button_block_timer: Timer
@export var modify_cursor_block_timer: Timer
@export var slide_effect_timer: Timer
@export var punch_timer: Timer
@export var bubble_timer: Timer

@export var run_start_timer: Timer
@export var run_effect_timer: Timer
@export var run_sprite_scene: PackedScene

@export var bubble_scene: PackedScene

var move_direction := 0.0
var running := false
var backflipping := false

var block_place_direction = 0.0
var midstopped := false
var modify_block_tween: Tween
var inventory: ItemInventory
var username: String
var run_effect_offset := 0

var center_block_position: Vector2i
var last_center_block_position: Vector2i

var last_surface := 0.0
var last_is_sliding := false

var player_input := PlayerInput.new()
var player_state := PlayerState.GROUND

func is_block_in_range(block_position: Vector2i) -> bool:
	var block_extents := Rect2i(
		center_block_position - BLOCK_PLACE_EXTENTS,
		BLOCK_PLACE_EXTENTS * 2 + Vector2i.ONE)
	
	return block_extents.has_point(block_position)

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

func walk(walk_speed: float, walk_acceleration: float, delta: float) -> void:
	if is_on_floor() or move_direction != 0.0:
		velocity.x = Direction.target_axis(
			velocity.x,
			move_direction * walk_speed,
			walk_acceleration * delta)

func get_move_direction() -> int:
	return sign(player_input.get_axis("move_left", "move_right"))

func get_look_direction() -> int:
	return sign(player_input.get_axis("look_up", "look_down"))

func aim() -> void:
	move_direction = get_move_direction()
	
	if is_on_floor():
		if move_direction != 0.0:
			entity.sprite.flip_h = move_direction < 0.0
	else:
		if not backflipping:
			if is_on_wall():
				entity.sprite.flip_h = get_wall_normal().x < 0.0
			else:
				var move_just_pressed := get_move_just_pressed()
				
				if move_just_pressed != 0.0:
					entity.sprite.flip_h = move_just_pressed < 0.0
	
	if player_state != PlayerState.MODIFYING_BUTTON_BLOCK:
		block_place_direction = get_look_direction()

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

func jump(jump_velocity: float) -> void:
	if velocity.y <= -jump_velocity:
		return
	
	velocity.y = -jump_velocity
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
	
	jump(JUMP_VELOCITY)
	
	if get_is_sliding():
		backflipping = true
		velocity.x = move_direction * GROUND_WALK_SPEED
	else:
		backflipping = false

func midstop_jump():
	if velocity.y < 0.0:
		if not midstopped and not player_input.is_action_pressed("jump"):
			midstopped = true
			velocity.y *= JUMP_MIDSTOP
	else:
		midstopped = true

func punch(look_direction: float) -> void:
	if not punch_timer.is_stopped():
		return
	
	play_punch_animation(look_direction)
	punch_timer.start()
	
	entity.play_sound("punch")

func use_item(use_data: ItemUseData) -> void:
	var item_slot := inventory.items[inventory.selected_index]
	
	if item_slot.item_id == 0:
		modify_block_or_punch(0, use_data)
		return
	
	var item := entity.get_game_world().items.item_types[item_slot.item_id]
	
	if item.properties == null:
		return
	
	item.properties.use_item(use_data)

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
	
	use_item(use_data)

func play_punch_animation(look_direction: float) -> void:
	if player_state == PlayerState.CLIMBING:
		return
	
	entity.animation_player.stop()
	
	if look_direction < 0.0:
		entity.animation_player.play("punch_up")
	elif look_direction > 0.0:
		entity.animation_player.play("punch_down")
	else:
		entity.animation_player.play("punch_forward")

func aim_block_placement(block_position: Vector2i) -> void:
	var block_distance := block_position - center_block_position
	
	if block_distance.x != 0:
		entity.sprite.flip_h = block_distance.x < 0

func animate() -> void:
	if entity.animation_player.current_animation.begins_with("punch_"):
		return
	
	var animation_name: String
	var look_direction := get_look_direction()
	
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
				if running:
					animation_name = "run"
				else:
					animation_name = "walk"
	else:
		if is_on_wall():
			animation_name = "slide"
		else:
			if backflipping:
				animation_name = "backflip"
			else:
				if velocity.y < 0.0:
					animation_name = "jump"
				else:
					animation_name = "fall"
	
	entity.animation_player.play(animation_name)

func change_player_state(new_state: PlayerState) -> void:
	if new_state != PlayerState.GROUND:
		running = false
		backflipping = false
	
	player_state = new_state

func end_modify_button_block_tween() -> void:
	modify_block_tween = null
	entity.collider.disabled = false

func end_modify_button_block() -> void:
	change_player_state(PlayerState.GROUND)

func modify_button_block(
		address: BlockAddress,
		block_specifier: BlockSpecifier,
		blocks: BlockWorld,
		next_block_position: Vector2i) -> void:
	
	velocity = Vector2.ZERO
	
	if next_block_position.x != center_block_position.x:
		entity.sprite.flip_h = next_block_position.x < center_block_position.x
	
	modify_block_tween = create_tween()\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUAD)
	
	modify_block_tween.tween_property(self, "global_position",
		blocks.block_to_world(next_block_position, true),
		MODIFY_BLOCK_TWEEN_TIME)
	
	modify_block_tween.finished.connect(end_modify_button_block_tween)
	
	change_player_state(PlayerState.MODIFYING_BUTTON_BLOCK)
	
	modify_button_block_timer.start()
	entity.collider.disabled = true
	
	# Update block
	entity.update_block(block_specifier, address)

func cast_block(look_offset: Vector2) -> BlockCollider:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + look_offset)
	
	# Only check block layer
	query.collision_mask = 2
	
	var result := space_state.intersect_ray(query)
	
	if result.is_empty():
		return null
	
	var collider = result.collider.get_child(result.shape)
	
	if not collider is BlockCollider:
		return null
	
	return collider

func try_modify_button_block(block_id: int, on_front_layer: bool) -> bool:
	if modify_block_tween != null:
		return false
	
	# Get look offset
	var look_direction = get_look_direction()
	var look_offset := Vector2i.ZERO
	
	if look_direction == 0.0:
		if move_direction == 0.0:
			look_offset.x = get_facing_sign()
		else:
			look_offset.x = move_direction
	else:
		look_offset.y = look_direction
	
	# Create block info
	var blocks := entity.get_game_world().blocks
	
	var block_specifier := BlockSpecifier.new()
	block_specifier.on_front_layer = on_front_layer
	
	# Check center
	var center_address := blocks.get_block_address(center_block_position)
	
	if not blocks.is_block_address_passable(center_address):
		if not on_front_layer:
			return false
		
		var casted_block := cast_block(Vector2(look_offset) * blocks.scale)
		
		if casted_block == null:
			return false
		
		# Break facing
		var cast_position := casted_block.block_position
		block_specifier.block_position = cast_position
		
		var cast_address := blocks.get_block_address(cast_position)
		
		modify_button_block(
			cast_address,
			block_specifier,
			blocks,
			cast_position)
		
		return true
	
	# Check forward
	var forward_block_position := center_block_position + look_offset
	var forward_address := blocks.get_block_address(forward_block_position)
	
	if not blocks.is_block_address_passable(forward_address):
		if not on_front_layer:
			return false
		
		# Break forward
		block_specifier.block_position = forward_block_position
		
		modify_button_block(
			forward_address,
			block_specifier,
			blocks,
			forward_block_position)
		
		return true
	
	# Modify center
	if center_address == null:
		return false
	
	# Place or break center
	block_specifier.block_position = center_block_position
	
	# Check if on air
	if block_specifier.read_address(center_address) == 0:
		if block_id == 0:
			return false
		
		if not blocks.is_block_placeable(center_address, block_specifier, self):
			return false
		
		# Set placing block
		block_specifier.block_id = block_id
	
	modify_button_block(
		center_address,
		block_specifier,
		blocks,
		forward_block_position)
	
	return true

func try_modify_cursor_block(block_id: int, use_data: ItemUseData) -> bool:
	if player_state == PlayerState.MODIFYING_BUTTON_BLOCK:
		return false
	
	if not modify_cursor_block_timer.is_stopped():
		return false
	
	var blocks := entity.get_game_world().blocks
	var address := blocks.get_block_address(use_data.block_position)
	
	if address == null:
		return false
	
	# Check if back block is covered
	if not use_data.on_front_layer:
		var front_id := address.chunk.front_ids[address.block_index]
		
		if not blocks.is_block_passable(front_id):
			return false
	
	var block_specifier := BlockSpecifier.new()
	
	block_specifier.block_position = use_data.block_position
	block_specifier.on_front_layer = use_data.on_front_layer
	
	var layer := address.chunk.get_layer(use_data.on_front_layer)
	var old_block_id := layer[address.block_index]
	
	if old_block_id == 0:
		if use_data.breaking:
			return false
		
		if block_id == 0:
			return false
		
		block_specifier.block_id = block_id
		
		if not blocks.is_block_placeable(
				address,
				block_specifier,
				null):
			
			return false
	else:
		if not use_data.breaking:
			return false
		
		block_specifier.block_id = 0
	
	entity.update_block(block_specifier, address)
	
	if not entity.on_server:
		var packet := GamePacket.create_packet(
			Packets.ClientPacket.USE_CURSOR_ITEM,
			[use_data.block_position, use_data.on_front_layer, use_data.just_pressed]
		)
		
		GameScene.instance.server.send_packet(packet)
	
	modify_cursor_block_timer.start()
	
	return true

func modify_block_or_punch(block_id: int, use_data: ItemUseData) -> void:
	if use_data.clicked:
		aim_block_placement(use_data.block_position)
		
		if try_modify_cursor_block(block_id, use_data):
			play_punch_animation(get_look_direction())
			return
	else:
		if try_modify_button_block(block_id, use_data.on_front_layer):
			play_punch_animation(get_look_direction())
			entity.animation_player.queue("fall")
			return
	
	if use_data.just_pressed:
		punch(get_look_direction())

func show_wall_effects() -> void:
	if is_on_floor():
		return
	
	if not is_on_wall():
		return
	
	var wall_position := global_position - wall_point.position * get_wall_normal().x
	
	try_spawn_slide_effect(wall_position)

func show_ground_effects() -> void:
	var surface: float
	var surface_point: Node2D
	
	if is_on_floor():
		surface = 1.0
		surface_point = floor_point
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
	
	var blocks := entity.get_game_world().blocks
	
	# Play block sound
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		
		if collision.get_normal().y == 0.0:
			continue
		
		var shape := collision.get_collider_shape()
		
		if not shape is BlockCollider:
			continue
		
		var block_position: Vector2i = shape.block_position
		
		var address := blocks.get_block_address(block_position)
		var block_id := address.chunk.front_ids[address.block_index]
		var block := blocks.block_types[block_id]
		
		var sound := GameScene.instance.spawn_block_sound(
			block, surface_point.global_position)
		
		if sound != null:
			sound.volume_db = GROUND_VOLUME
		
		break
	
	last_surface = surface

func try_spawn_slide_effect(effect_position: Vector2) -> void:
	if not slide_effect_timer.is_stopped():
		return
	
	entity.spawn_effect_sprite("slide", effect_position)
	slide_effect_timer.start()

func show_slide_effects() -> void:
	var is_sliding := get_is_sliding()
	
	if is_on_floor() and is_sliding:
		if not last_is_sliding:
			entity.play_sound("slide")
		
		try_spawn_slide_effect(floor_point.global_position)
	
	last_is_sliding = is_sliding

func show_swimming_effects() -> void:
	var blocks := entity.get_game_world().blocks
	
	var center_block := get_interaction_block(center_block_position, blocks)
	var last_center_block := get_interaction_block(last_center_block_position, blocks)
	
	var swimming := false
	var last_swimming := false
	
	if center_block != null:
		swimming = center_block.is_swimmable
	
	if last_center_block != null:
		last_swimming = last_center_block.is_swimmable
	
	if swimming:
		if bubble_timer.is_stopped():
			var bubble: WaterBubble = bubble_scene.instantiate()
			GameScene.instance.particles.add_child(bubble)
			bubble.start_bubble(global_position)
			
			bubble_timer.start(randf_range(1.0, 2.0))
		
		if not last_swimming:
			if center_block_position.y > last_center_block_position.y and \
					velocity.y > 0.0:
				
				spawn_water_splash(center_block_position, blocks)
	else:
		if last_swimming:
			if center_block_position.y < last_center_block_position.y and \
					velocity.y < 0.0:
				
				spawn_water_splash(last_center_block_position, blocks)

func try_climbing(block: BlockType, blocks: BlockWorld) -> bool:
	if not (\
			player_input.is_action_just_pressed("interact") or \
			player_input.is_action_just_pressed("look_up")):
		
		return false
	
	if not block.is_climbable:
		return false
	
	# Start climbing
	velocity = Vector2.ZERO
	global_position.x = blocks.block_to_world(center_block_position, true).x
	
	change_player_state(PlayerState.CLIMBING)
	
	entity.play_sound("climb")
	
	return true

func stop_climbing() -> void:
	velocity.x = move_direction * CLIMB_JUMP_SPEED
	change_player_state(PlayerState.GROUND)

func climb() -> void:
	if player_input.is_action_just_pressed("interact"):
		stop_climbing()
		entity.play_sound("climb")
		return
	
	if player_input.is_action_just_pressed("jump"):
		stop_climbing()
		jump(JUMP_VELOCITY)
		
		return
	
	var blocks := entity.get_game_world().blocks
	var block := get_interaction_block(center_block_position, blocks)
	
	if block == null or not block.is_climbable:
		stop_climbing()
		return
	
	var look_direction := get_look_direction()
	velocity.y = look_direction * CLIMB_SPEED
	
	if look_direction == 0.0:
		entity.animation_player.play("climb_idle")
	else:
		entity.animation_player.play("climb")

func spawn_water_splash(block_position: Vector2i, blocks: BlockWorld) -> void:
	var above_position := Vector2i(block_position.x, block_position.y - 1)
	var above_address := blocks.get_block_address(above_position)
	
	if above_address == null:
		return
	
	var above_id := above_address.chunk.front_ids[above_address.block_index]
	var above_block = blocks.block_types[above_id]
	
	if not above_block.is_partial or above_block.is_swimmable:
		return
	
	var block_world_position := blocks.block_to_world(above_position, true)
	var effect_position := Vector2(global_position.x, block_world_position.y)
	entity.spawn_effect_sprite("splash", effect_position)
	
	entity.play_sound("splash")

func try_swimming(block: BlockType) -> bool:
	if not block.is_swimmable:
		return false
	
	# Start swimming
	change_player_state(PlayerState.SWIMMING)
	
	if center_block_position.y > last_center_block_position.y:
		velocity.y *= 0.2
	
	return true

func swim(delta: float) -> void:
	var blocks := entity.get_game_world().blocks
	var block := get_interaction_block(center_block_position, blocks)
	
	if block == null or not block.is_swimmable:
		change_player_state(PlayerState.GROUND)
		
		if center_block_position.y < last_center_block_position.y:
			velocity.y = max(velocity.y * 1.5, -JUMP_VELOCITY)
		
		return
	
	fall(WATER_GRAVITY_SPEED, WATER_GRAVITY_ACCELERATION, delta)
	
	if is_on_floor():
		walk(WATER_GROUND_SPEED, WATER_ACCELERATION, delta)
	else:
		walk(WATER_SPEED, WATER_ACCELERATION, delta)
		midstop_jump()
	
	if player_input.is_action_just_pressed("jump"):
		if not try_jump_down():
			jump(WATER_JUMP_VELOCITY)
			
			if is_on_wall():
				velocity.x = WATER_SPEED * get_wall_normal().x
			
			entity.animation_player.play("punch_down")
			entity.play_sound("splash", -10.0)
	
	animate()

func get_interaction_block(block_position: Vector2i, blocks: BlockWorld) -> BlockType:
	var address := blocks.get_block_address(block_position)
	
	if address == null:
		return null
	
	var block_id := address.chunk.front_ids[address.block_index]
	return blocks.block_types[block_id]

func interact_center_block() -> bool:
	var blocks := entity.get_game_world().blocks
	var block := get_interaction_block(center_block_position, blocks)
	
	if block == null:
		return false
	
	if try_climbing(block, blocks):
		return true
	
	if try_swimming(block):
		return true
	
	return false

func fall(fall_speed: float, fall_acceleration: float, delta: float) -> void:
	velocity.y = Direction.target_axis(
		velocity.y,
		fall_speed,
		fall_acceleration * delta)

func get_move_just_pressed() -> float:
	return \
		float(player_input.is_action_just_pressed("move_right")) - \
		float(player_input.is_action_just_pressed("move_left"))

func try_running() -> void:
	if is_on_wall() or move_direction == 0.0 or get_is_sliding():
		running = false
		return
	
	# Check if can start running
	if not is_on_floor():
		return
	
	var move_just_pressed := get_move_just_pressed()
	
	if move_just_pressed == 0.0:
		return
	
	if run_start_timer.is_stopped():
		run_start_timer.start()
	else:
		run_start_timer.stop()
		
		running = true
		entity.play_sound("run")

func try_wall_jump() -> void:
	if not is_on_wall():
		return
	
	backflipping = false
	
	if not player_input.is_action_just_pressed("jump"):
		return
	
	var wall_x := get_wall_normal().x
	
	velocity.x = wall_x * GROUND_WALK_SPEED
	entity.sprite.flip_h = wall_x < 0.0
	
	jump(JUMP_VELOCITY)

func update_modify_button_block() -> void:
	if modify_block_tween != null:
		return
	
	# Jump midair after block
	if player_input.is_action_pressed("jump"):
		jump(JUMP_VELOCITY)
		end_modify_button_block()
		return
	
	if modify_button_block_timer.is_stopped():
		end_modify_button_block()
		return
	
	# Check if climbing
	var blocks := entity.get_game_world().blocks
	var interaction_block := get_interaction_block(center_block_position, blocks)

	if interaction_block != null:
		if try_climbing(interaction_block, blocks):
			return

func controls(delta: float) -> void:
	aim()
	update_jump_timer()
	try_use_item()
	
	match player_state:
		PlayerState.GROUND:
			if interact_center_block():
				return
			
			if is_on_wall():
				fall(WALL_GRAVITY_SPEED, GRAVITY_ACCELERATION, delta)
			else:
				fall(GRAVITY_SPEED, GRAVITY_ACCELERATION, delta)
			
			try_running()
			
			if running:
				if is_on_floor():
					walk(GROUND_RUN_SPEED, GROUND_RUN_ACCELERATION, delta)
				else:
					walk(GROUND_RUN_SPEED, AIR_ACCELERATION, delta)
			else:
				walk(GROUND_WALK_SPEED, GROUND_WALK_ACCELERATION, delta)
			
			if is_on_floor():
				coyote_timer.start()
				backflipping = false
			else:
				midstop_jump()
				try_wall_jump()
			
			try_jump()
			
			animate()
		
		PlayerState.MODIFYING_BUTTON_BLOCK:
			update_modify_button_block()
		
		PlayerState.CLIMBING:
			climb()
		
		PlayerState.SWIMMING:
			swim(delta)
	
	move_and_slide()

func update_center_block_position() -> void:
	last_center_block_position = center_block_position

func get_skin_texture() -> Texture2D:
	return entity.sprite.material.get_shader_parameter("skin_texture")

func show_run_effects() -> void:
	if not run_effect_timer.is_stopped():
		return
	
	if abs(velocity.x) <= GROUND_WALK_SPEED:
		return
	
	var effect_sprite := run_sprite_scene.instantiate()
	GameScene.instance.particles.add_child(effect_sprite)
	
	SpriteCopy.copy_sprite(entity.sprite, effect_sprite)
	
	var skin_texture := get_skin_texture()
	
	var effect_material: ShaderMaterial = effect_sprite.material
	var skin_uv := (Vector2.DOWN * run_effect_offset) / Vector2(PlayerSkinManager.SKIN_SIZE)
	
	run_effect_offset = (run_effect_offset + 1) % 3
	
	effect_material.set_shader_parameter("skin_texture", skin_texture)
	effect_material.set_shader_parameter("skin_uv", skin_uv)
	
	run_effect_timer.start()

func player_teleported() -> void:
	if modify_block_tween != null:
		modify_block_tween.kill()
		end_modify_button_block_tween()

func _ready() -> void:
	entity.position_changed.connect(player_teleported)

func _physics_process(delta: float) -> void:
	center_block_position = entity.get_game_world().blocks.world_to_block(global_position)
	
	# Check if remote controlled player
	if not entity.on_server:
		show_ground_effects()
		show_wall_effects()
		show_slide_effects()
		show_swimming_effects()
		show_run_effects()
		
		if GameScene.instance.player != self:
			move_and_slide()
			update_center_block_position()
			return
	
	controls(delta)
	update_center_block_position()
	
	player_input.update_inputs()
