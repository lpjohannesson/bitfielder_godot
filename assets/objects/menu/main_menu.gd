extends Control
class_name MainMenu

signal singleplayer_selected
signal mulitplayer_selected

func _on_singleplayer_button_button_down() -> void:
	singleplayer_selected.emit()

func _on_multiplayer_button_button_down() -> void:
	mulitplayer_selected.emit()
