extends Node
class_name EntitySerializer

class DataRequest:
	var entity: GameEntity
	var entity_data: Dictionary
	var always_write: bool
	
	static func create(
			init_entity: GameEntity,
			init_entity_data: Dictionary,
			init_always_write: bool) -> DataRequest:
		
		var request := DataRequest.new()
		
		request.entity = init_entity
		request.entity_data = init_entity_data
		request.always_write = init_always_write
		
		return request

class EntityType:
	const PLAYER = "player"

class DataType:
	const ID = "id"
	const TYPE = "type"
	const POSITION = "pos"
	const VELOCITY = "vel"
	const FLIP_X = "flipx"
	const ANIMATION = "anim"
	const COLLIDING = "col"

@export var entities: EntityManager

@export var player_scene: PackedScene

func save_entity_data(
		request: DataRequest,
		data_type: String,
		value: Variant) -> void:
	
	# Check if entity data already set
	if not request.always_write and request.entity.entity_data.get(data_type) == value:
		return
	
	request.entity_data[data_type] = value
	request.entity.entity_data[data_type] = value

func save_entity_position(request: DataRequest) -> void:
	save_entity_data(request, DataType.POSITION,
		request.entity.body.global_position)

func save_entity_velocity(request: DataRequest) -> void:
	save_entity_data(request, DataType.VELOCITY,
		request.entity.body.velocity)

func save_entity_flip_x(request: DataRequest) -> void:
	save_entity_data(request, DataType.FLIP_X,
		request.entity.sprite.flip_h)

func save_entity_animation(request: DataRequest) -> void:
	save_entity_data(request, DataType.ANIMATION,
		request.entity.animation_player.current_animation)

func save_entity_colliding(request: DataRequest) -> void:
	save_entity_data(request, DataType.COLLIDING,
		not request.entity.collider.disabled)

func create_entity_data(entity: GameEntity) -> Dictionary:
	var entity_data := {}
	entity_data[DataType.ID] = entity.entity_id
	
	return entity_data

func create_entity_update_data(entity: GameEntity, spawning: bool) -> Dictionary:
	var entity_data := create_entity_data(entity)
	
	var request := DataRequest.create(entity, entity_data, spawning)
	
	if entity.body != null:
		save_entity_position(request)
		save_entity_velocity(request)
	
	if entity.sprite != null:
		save_entity_flip_x(request)
	
	if entity.animation_player != null:
		if entity.animation_player.is_playing():
			save_entity_animation(request)
	
	if entity.collider != null:
		save_entity_colliding(request)
	
	return entity_data

func create_entity_spawn_data(entity: GameEntity) -> Dictionary:
	var entity_data := create_entity_update_data(entity, true)
	entity_data[DataType.TYPE] = entity.entity_type
	
	return entity_data

func load_entity_data(entity: GameEntity, entity_data: Dictionary) -> void:
	for data_type in entity_data.keys():
		match data_type:
			DataType.POSITION:
				entity.body.global_position = entity_data[DataType.POSITION]
				entity.send_position_changed()
			
			DataType.VELOCITY:
				entity.body.velocity = entity_data[DataType.VELOCITY]
			
			DataType.FLIP_X:
				entity.sprite.flip_h = entity_data[DataType.FLIP_X]
			
			DataType.ANIMATION:
				entity.animation_player.play(entity_data[DataType.ANIMATION])
			
			DataType.COLLIDING:
				entity.collider.disabled = not entity_data[DataType.COLLIDING]

func create_entity_by_type(entity_type: String) -> GameEntity:
	match entity_type:
		EntityType.PLAYER:
			var player := player_scene.instantiate()
			return player.entity
	
	return null

func create_entity(entity_data: Dictionary) -> GameEntity:
	var entity_type: String = entity_data[DataType.TYPE]
	var entity := create_entity_by_type(entity_type)
	
	entity.entity_id = entity_data[DataType.ID]
	
	load_entity_data(entity, entity_data)
	entities.add_entity(entity)
	
	return entity
