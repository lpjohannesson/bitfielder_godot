extends Control
class_name ItemBar

@export var item_display_scene: PackedScene
@export var items: Container
@export var item_arrow: Control

func show_item_arrow(item_index: int) -> void:
	var item_display: ItemDisplay = items.get_child(item_index)
	item_arrow.global_position = item_display.arrow_point.global_position

func show_inventory(inventory: ItemInventory) -> void:
	var page_start := inventory.get_item_page_start()
	
	for i in range(ItemInventory.ROW_ITEM_COUNT):
		var item_index := page_start + i
		
		var item_slot := inventory.items[item_index]
		items.get_child(i).show_item_slot(item_slot)

func _ready() -> void:
	for _i in range(ItemInventory.ROW_ITEM_COUNT):
		items.add_child(item_display_scene.instantiate())
	
	show_item_arrow(0)
