extends CanvasLayer
class_name PauseScreen

signal continue_selected
signal quit_selected

func _on_continue_button_button_down() -> void:
	continue_selected.emit()

func _on_quit_button_button_down() -> void:
	quit_selected.emit()
