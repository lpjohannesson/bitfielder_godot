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

func _on_texture_display_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	
	if not event.pressed:
		return
	
	if not event.button_index == MOUSE_BUTTON_LEFT:
		return
	
	GameScene.instance.select_page_item(get_index())
