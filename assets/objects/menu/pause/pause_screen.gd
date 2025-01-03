extends CanvasLayer
class_name PauseScreen

@export var scene: GameScene
@export var skin_file_dialog: FileDialog
@export var starting_button: Button

signal continue_selected

func show_screen(paused: bool) -> void:
	visible = paused
	
	if paused:
		starting_button.grab_focus()

func _on_continue_button_pressed() -> void:
	continue_selected.emit()

func _on_change_skin_button_pressed() -> void:
	skin_file_dialog.popup()

func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	scene.return_to_menu()

func _on_skin_file_dialog_file_selected(path: String) -> void:
	PlayerSkinManager.change_skin(scene.player, path)
