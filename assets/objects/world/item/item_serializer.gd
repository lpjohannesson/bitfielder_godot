extends Node
class_name ItemSerializer

@export var items: ItemManager

func save_item_slot(item_slot: ItemSlot) -> Variant:
	if item_slot.item_id == 0:
		return null
	
	return items.item_types[item_slot.item_id].item_name

func load_item_slot(slot_data: Variant, item_slot: ItemSlot) -> void:
	if slot_data == null:
		item_slot.item_id = 0
		return
	
	item_slot.item_id = items.get_item_id(slot_data)

func save_inventory(inventory: ItemInventory) -> Array:
	var inventory_data := []
	
	for item_slot in inventory.items:
		inventory_data.push_back(save_item_slot(item_slot))
	
	return inventory_data

func load_inventory(inventory_data: Array, inventory: ItemInventory) -> void:
	for i in range(inventory_data.size()):
		load_item_slot(inventory_data[i], inventory.items[i])
