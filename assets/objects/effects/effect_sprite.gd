extends AnimatedSprite2D
class_name EffectSprite

func _on_animation_finished() -> void:
	queue_free()
