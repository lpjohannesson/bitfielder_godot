extends Sprite2D
class_name BlockParticle

const MAGNITUDE_MIN = 75
const MAGNITUDE_MAX = 150
const GRAVITY = 300.0

var motion := Vector2.ZERO

func _ready() -> void:
	var magnitude = randf_range(MAGNITUDE_MIN, MAGNITUDE_MAX)
	motion = Vector2.RIGHT.rotated(randf_range(0, PI * 2.0)) * magnitude
	frame = randi() % 3

func _physics_process(delta: float) -> void:
	motion.y += GRAVITY * delta
	position += motion * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
