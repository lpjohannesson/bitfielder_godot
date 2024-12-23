extends ItemProperties
class_name BlockItemProperties

var block_id: int

func start_item(item: ItemType, world: GameWorld) -> void:
	block_id = world.blocks.get_block_id(item.item_name)

func use_item(use_data: ItemUseData) -> void:
	use_data.player.try_modify_block(block_id, use_data.on_front_layer)
