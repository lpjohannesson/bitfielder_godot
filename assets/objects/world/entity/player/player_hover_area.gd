extends Area2D
class_name UsernameDisplay

@export var label: Label

func _ready() -> void:
	label.hide()

func _on_mouse_entered() -> void:
	label.show()

func _on_mouse_exited() -> void:
	label.hide()
