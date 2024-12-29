extends Node
class_name EntityManager

@export var serializer: EntitySerializer

var entities: Array[GameEntity] = []
var entity_id_map := {}

func add_entity(entity: GameEntity) -> void:
	entities.push_back(entity)
	entity_id_map[entity.entity_id] = entity
	
	entity.entity_data = serializer.create_entity_spawn_data(entity)
	
	add_child(entity.entity_node)

func remove_entity(entity: GameEntity) -> void:
	entities.erase(entity)
	entity_id_map.erase(entity.entity_id)
	
	entity.entity_node.queue_free()

func get_entity(entity_id: int) -> GameEntity:
	if not entity_id_map.has(entity_id):
		return null
	
	return entity_id_map[entity_id]
