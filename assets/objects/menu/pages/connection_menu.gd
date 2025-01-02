extends MenuPage
class_name ConnectionMenu

@export var connecting_text: String
@export var disconnected_text: String
@export var connection_timed_out_text: String
@export var logging_in_text: String
@export var connection_rejected_text: String
@export var username_in_use_text: String

@export var status_label: Label

signal back_selected

func show_status(status_text: String) -> void:
	status_label.text = status_text

func _on_back_button_pressed() -> void:
	back_selected.emit()
