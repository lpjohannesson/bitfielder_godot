extends Control
class_name HUD

@export var item_bar: ItemBar

var hud_focused := false

func _on_item_bar_mouse_entered() -> void:
	hud_focused = true

func _on_item_bar_mouse_exited() -> void:
	hud_focused = false
