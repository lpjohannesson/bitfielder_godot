extends Node
class_name ItemManager

const ITEMS_FOLDER = "res://assets/resources/items"

@export var world: GameWorld
@export var serializer: ItemSerializer

var item_types: Array[ItemType] = [null]
var item_type_map := {}

func get_item_id(item_name: String) -> int:
	return item_type_map[item_name]

func set_item_name(item: ItemType, item_name: String) -> void:
	item.item_name = item_name

func _ready() -> void:
	GameResourceLoader.load_resources(
		ITEMS_FOLDER,
		item_types,
		item_type_map,
		set_item_name)
	
	for i in range(1, item_types.size()):
		var item := item_types[i]
		
		if item.properties != null:
			item.properties.start_item(item, world)
