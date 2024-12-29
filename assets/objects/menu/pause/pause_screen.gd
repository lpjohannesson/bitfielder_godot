extends CanvasLayer
class_name PauseScreen

@export var scene: GameScene
@export var skin_file_dialog: FileDialog
@export var starting_button: Button

signal continue_selected
signal quit_selected

func show_screen(paused: bool) -> void:
	visible = paused
	
	if paused:
		starting_button.grab_focus()

func _on_continue_button_button_down() -> void:
	continue_selected.emit()

func _on_change_skin_button_button_down() -> void:
	skin_file_dialog.popup()

func _on_quit_button_button_down() -> void:
	quit_selected.emit()

func _on_skin_file_dialog_file_selected(path: String) -> void:
	PlayerSkinManager.change_skin(scene.player, path)
