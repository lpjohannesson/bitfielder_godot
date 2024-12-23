extends Node
class_name ItemManager

@export var world: GameWorld
@export var serializer: ItemSerializer

@export var item_types: Array[ItemType]
var item_type_map := {}

func get_item_id(item_name: String) -> int:
	return item_type_map[item_name]

func _ready() -> void:
	# Create item types
	for i in range(1, item_types.size()):
		var item := item_types[i]
		
		assert(not item_type_map.has(item.item_name))
		item_type_map[item.item_name] = i
		
		if item.properties != null:
			item.properties.start_item(item, world)
