extends Node
class_name EntityDataManager

enum EntityType {
	PLAYER
}

enum DataType {
	ID,
	TYPE,
	POSITION,
	VELOCITY,
	FLIP_X,
	ANIMATION
}

@export var entities: EntityManager

@export var player_scene: PackedScene

static func save_entity_position(entity: GameEntity, entity_data: Dictionary) -> void:
	entity_data[DataType.POSITION] = entity.body.global_position

static func save_entity_velocity(entity: GameEntity, entity_data: Dictionary) -> void:
	entity_data[DataType.VELOCITY] = entity.body.velocity

static func save_entity_flip_x(entity: GameEntity, entity_data: Dictionary) -> void:
	entity_data[DataType.FLIP_X] = entity.sprite.flip_h

static func save_entity_animation(entity: GameEntity, entity_data: Dictionary) -> void:
	entity_data[DataType.ANIMATION] = entity.animation_player.current_animation

static func create_entity_data(entity: GameEntity) -> Dictionary:
	var entity_data := {}
	entity_data[DataType.ID] = entity.entity_id
	
	return entity_data

static func create_entity_update_data(entity: GameEntity) -> Dictionary:
	var entity_data := create_entity_data(entity)
	
	if entity.body != null:
		save_entity_position(entity, entity_data)
		save_entity_velocity(entity, entity_data)
	
	if entity.sprite != null:
		save_entity_flip_x(entity, entity_data)
	
	if entity.animation_player != null:
		if entity.animation_player.is_playing():
			save_entity_animation(entity, entity_data)
	
	return entity_data

static func create_entity_spawn_data(entity: GameEntity) -> Dictionary:
	var entity_data := create_entity_update_data(entity)
	entity_data[DataType.TYPE] = entity.entity_type
	
	return entity_data

static func load_entity_data(entity: GameEntity, entity_data: Dictionary) -> void:
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

func create_entity_by_type(entity_type: EntityType) -> GameEntity:
	match entity_type:
		EntityType.PLAYER:
			var player := player_scene.instantiate()
			return player.entity
	
	return null

func create_entity(entity_data: Dictionary) -> GameEntity:
	var entity_type: EntityType = entity_data[DataType.TYPE]
	var entity := create_entity_by_type(entity_type)
	
	entity.entity_id = entity_data[DataType.ID]
	
	load_entity_data(entity, entity_data)
	entities.add_entity(entity)
	
	return entity
