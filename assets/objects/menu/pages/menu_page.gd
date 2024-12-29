extends Control
class_name MenuPage

@export var starting_button: Button

func select_menu_page() -> void:
	show()
	starting_button.grab_focus()
