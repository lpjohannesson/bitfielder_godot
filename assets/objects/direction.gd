class_name Direction

const NEIGHBOR_OFFSETS_FOUR: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT,
]

const NEIGHBOR_OFFSETS_EIGHT: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.UP + Vector2i.LEFT,
	Vector2i.UP + Vector2i.RIGHT,
	Vector2i.DOWN + Vector2i.LEFT,
	Vector2i.DOWN + Vector2i.RIGHT,
]

static func target_axis(
		current: float,
		target: float,
		change: float) -> float:
	
	if current < target:
		return min(target, current + change)
	else:
		return max(target, current - change)
