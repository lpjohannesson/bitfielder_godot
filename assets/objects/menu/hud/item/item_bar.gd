extends Control
class_name ItemBar

@export var item_display_scene: PackedScene
@export var items: Container
@export var item_arrow: Control

func show_item_arrow(selected_index: int) -> void:
	var item_display: ItemDisplay = items.get_child(selected_index)
	item_arrow.global_position = item_display.arrow_point.global_position

func show_inventory(inventory: ItemInventory) -> void:
	for i in range(ItemInventory.ITEM_COUNT):
		var item_slot := inventory.items[i]
		items.get_child(i).show_item_slot(item_slot)

func _ready() -> void:
	for _i in range(ItemInventory.ITEM_COUNT):
		items.add_child(item_display_scene.instantiate())
	
	show_item_arrow(0)
