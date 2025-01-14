extends Node2D
class_name GameParallax

@export var parallax_factor := Vector2.ONE

func _process(_delta: float) -> void:
	transform = get_viewport().canvas_transform
	transform.origin *= parallax_factor
