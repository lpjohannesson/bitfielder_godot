extends ItemProperties
class_name DirectionalBlockItemProperties

var horizontal_block_id: int
var vertical_block_id: int

func start_item(item: ItemType, world: GameWorld) -> void:
	horizontal_block_id = world.blocks.get_block_id(item.item_name + "_horizontal")
	vertical_block_id = world.blocks.get_block_id(item.item_name + "_vertical")

func use_item(use_data: ItemUseData) -> void:
	var player := use_data.player
	
	if player.block_place_direction == 0.0:
		player.modify_block_or_punch(horizontal_block_id, use_data)
	else:
		player.modify_block_or_punch(vertical_block_id, use_data)
