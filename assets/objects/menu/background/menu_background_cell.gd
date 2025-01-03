extends Control
class_name MenuBackgroundCell

@export var color_rect1: ColorRect
@export var color_rect2: ColorRect
@export var animation_player: AnimationPlayer

var swapped := false

func start_color(color: Color) -> void:
	color_rect1.color = color
	color_rect2.hide()

func swap_to_color(color: Color) -> void:
	color_rect2.color = color
	color_rect2.show()
	
	animation_player.play("swap")

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	color_rect1.color = color_rect2.color
	color_rect2.hide()
