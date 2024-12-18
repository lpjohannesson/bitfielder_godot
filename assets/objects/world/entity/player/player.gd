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

var move_direction := 0.0
var look_direction := 0.0
var midstopped := false
var modify_block_tween: Tween

var last_on_surface := false

var player_input := PlayerInput.new()

func get_facing_sign():
	return -1 if sprite.flip_h else 1

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

func animate() -> void:
	if is_on_floor():
		if move_direction == 0.0 or velocity.x == 0.0:
			if look_direction < 0.0:
				animation_player.play("look_up")
			elif look_direction > 0.0:
				animation_player.play("look_down")
			else:
				animation_player.play("idle")
		else:
			if sign(velocity.x) == sign(move_direction):
				animation_player.play("walk")
			else:
				animation_player.play("slide")
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

func modify_block() -> bool:
	if not modify_block_timer.is_stopped():
		return false
	
	# Determine block layer
	var on_front_layer: bool
	
	if player_input.is_action_pressed("break_front"):
		on_front_layer = true
	elif player_input.is_action_pressed("break_back"):
		on_front_layer = false
	else:
		return false
	
	# Get block position
	var block_world := entity.get_game_world().block_world
	
	var center_block_position := block_world.world_to_block(global_position)
	var forward_block_position := center_block_position
	
	if look_direction == 0.0:
		forward_block_position.x += get_facing_sign()
	else:
		forward_block_position.y += int(look_direction)
	
	# Get block addresses
	var center_address := block_world.get_block_address(center_block_position)
	var forward_address := block_world.get_block_address(forward_block_position)
	
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
			var forward_front_block := block_world.block_types[forward_front_id]
			
			if forward_front_block.properties.is_solid:
				return false
		
		breaking = is_back_block_breakable(center_address)
	
	# Place or break
	var block_specifier := BlockSpecifier.new()
	block_specifier.on_front_layer = on_front_layer
	
	if breaking:
		var address: BlockAddress
		var block_ids: PackedInt32Array
		var block_position: Vector2i
		
		if on_front_layer:
			address = forward_address
			block_ids = forward_address.chunk.front_ids
			block_position = forward_block_position
		else:
			address = center_address
			block_ids = center_address.chunk.back_ids
			block_position = center_block_position
		
		var block_id := block_ids[address.block_index]
		entity.spawn_block_particles(block_id, block_position)
		
		block_ids[address.block_index] = 0
		
		entity.spawn_effect_sprite(
			"break",
			block_world.block_to_world(block_position, true)
		)
		
		block_specifier.block_position = block_position
		block_specifier.block_id = 0
	else:
		var block_ids: PackedInt32Array
		
		if on_front_layer:
			block_ids = center_address.chunk.front_ids
		else:
			block_ids = center_address.chunk.back_ids
		
		entity.spawn_effect_sprite(
			"place",
			block_world.block_to_world(center_block_position, true)
		)
		
		var block_id := block_world.get_block_id("wood_log")
		block_ids[center_address.block_index] = block_id
		
		block_specifier.block_position = center_block_position
		block_specifier.block_id = block_id
	
	entity.update_block(block_specifier)
	
	# Start movement
	velocity = Vector2.ZERO
	
	modify_block_tween = create_tween()\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUAD)
	
	modify_block_tween.tween_property(self, "global_position",
		block_world.block_to_world(forward_block_position, true),
		modify_block_timer.wait_time)
	
	animation_player.stop()
	
	if look_direction < 0.0:
		animation_player.play("punch_up")
	elif look_direction > 0.0:
		animation_player.play("punch_down")
	else:
		animation_player.play("punch_forward")
	
	modify_block_timer.start()
	collider.disabled = true
	
	return true

func controls(delta: float) -> void:
	if modify_block():
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
	animate()
	
	var on_surface := false
	
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		
		if collision.get_normal().y == 0.0:
			continue
		
		on_surface = true
		
		if last_on_surface:
			break
		
		entity.spawn_effect_sprite(
			"ground",
			Vector2(global_position.x, collision.get_position().y)
		)
		
		break
	
	last_on_surface = on_surface

func stop_modify_block() -> void:
	if modify_block_tween != null:
		modify_block_tween.kill()
		modify_block_tween = null

func _ready() -> void:
	entity.position_changed.connect(stop_modify_block)

func _physics_process(delta: float) -> void:
	if modify_block_timer.is_stopped():
		controls(delta)
	
	player_input.update_inputs()

func _on_modify_block_timer_timeout() -> void:
	collider.disabled = false
	aim()
