extends MenuPage
class_name RemotePlayMenu

signal connect_selected(address: String, port: int)
signal cancel_selected

@export var address_text: LineEdit

func _on_connect_button_pressed() -> void:
	connect_selected.emit(address_text.text, ServerHost.PORT)

func _on_cancel_button_pressed() -> void:
	cancel_selected.emit()
