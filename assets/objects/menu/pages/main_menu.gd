extends MenuPage
class_name MainMenu

signal local_play_selected
signal remote_play_selected

func _on_local_play_button_pressed() -> void:
	local_play_selected.emit()

func _on_remote_play_button_pressed() -> void:
	remote_play_selected.emit()
