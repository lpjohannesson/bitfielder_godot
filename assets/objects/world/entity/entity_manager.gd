extends Node
class_name EntityManager

@export var player_scene: PackedScene

var entities: Array[GameEntity] = []
var entity_id_map := {}

func add_entity(
		entity: GameEntity,
		entity_id: int,
		on_server: bool) -> void:
	
	entities.push_back(entity)
	entity.on_server = on_server
	
	entity.entity_id = entity_id
	entity_id_map[entity_id] = entity
	
	add_child(entity.entity_node)

func remove_entity(entity: GameEntity) -> void:
	entities.erase(entity)
	entity_id_map.erase(entity.entity_id)
	
	entity.entity_node.queue_free()

func get_entity(entity_id: int) -> GameEntity:
	if not entity_id_map.has(entity_id):
		return null
	
	return entity_id_map[entity_id]

func create_entity_by_type(
		entity_id: int,
		entity_type: String,
		on_server: bool) -> void:
	
	match entity_type:
		"player":
			var player := player_scene.instantiate()
			add_entity(player.entity, entity_id, on_server)
