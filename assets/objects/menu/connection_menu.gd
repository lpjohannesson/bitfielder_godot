extends Control
class_name ConnectionMenu

@export var connecting_text: String
@export var connection_timed_out_text: String
@export var disconnected_text: String

@export var status_label: Label

signal back_selected

func show_connecting() -> void:
	status_label.text = connecting_text

func show_connection_timed_out() -> void:
	status_label.text = connection_timed_out_text

func show_disconnected() -> void:
	status_label.text = disconnected_text

func _on_back_button_button_down() -> void:
	back_selected.emit()
