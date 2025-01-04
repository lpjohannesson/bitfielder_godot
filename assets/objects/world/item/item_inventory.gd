class_name ItemInventory

const ROW_ITEM_COUNT = 10
const ROW_COUNT = 3
const ITEM_COUNT = ROW_ITEM_COUNT * ROW_COUNT

var items: Array[ItemSlot]
var selected_index: int

func get_item_page() -> int:
	return int(selected_index / ROW_ITEM_COUNT)

func get_item_page_start() -> int:
	return get_item_page() * ROW_ITEM_COUNT

func get_page_item_index() -> int:
	var page_start := get_item_page_start()
	return posmod(selected_index - page_start, ROW_ITEM_COUNT)

func select_page_item(item_index: int) -> void:
	var page_start := get_item_page_start()
	selected_index = page_start + item_index

func move_page_item(direction: int) -> void:
	var page_start := get_item_page_start()
	
	var page_item_index := posmod(
		selected_index + direction - page_start, ROW_ITEM_COUNT)
	
	selected_index = page_start + page_item_index

func move_item_page(direction: int) -> void:
	selected_index = posmod(
		selected_index + direction * ROW_ITEM_COUNT, ITEM_COUNT)

func _init() -> void:
	for _i in range(ITEM_COUNT):
		items.push_back(ItemSlot.new())
