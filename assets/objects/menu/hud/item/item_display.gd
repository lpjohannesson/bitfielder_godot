extends Control
class_name ItemDisplay

@export var texture_display: TextureRect
@export var arrow_point: Control

func show_item_slot(item_slot: ItemSlot) -> void:
	if item_slot.item_id == 0:
		texture_display.texture = null
		return
	
	var item := GameScene.instance.world.items.item_types[item_slot.item_id]
	texture_display.texture = item.item_texture
