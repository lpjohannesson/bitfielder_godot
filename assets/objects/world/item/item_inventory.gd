class_name ItemInventory

const ITEM_COUNT = 50

var items: Array[ItemSlot]
var selected_index: int

func _init() -> void:
	for _i in range(ITEM_COUNT):
		items.push_back(ItemSlot.new())
