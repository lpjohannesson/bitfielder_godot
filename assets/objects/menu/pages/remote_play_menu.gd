extends MenuPage
class_name RemotePlayMenu

signal connect_selected(address: String, port: int)
signal cancel_selected

@export var address_text: LineEdit
@export var username_text: LineEdit

func get_login_info() -> ClientLoginInfo:
	var login_info := ClientLoginInfo.new()
	login_info.username = username_text.text
	
	return login_info

func _on_connect_button_pressed() -> void:
	connect_selected.emit(address_text.text, ServerHost.PORT)

func _on_cancel_button_pressed() -> void:
	cancel_selected.emit()
