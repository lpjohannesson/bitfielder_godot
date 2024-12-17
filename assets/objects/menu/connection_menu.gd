extends Control
class_name ConnectionMenu

@export var connecting_text: String
@export var connection_failed_text: String

signal cancel_selected

func _on_cancel_button_button_down() -> void:
	cancel_selected.emit()
