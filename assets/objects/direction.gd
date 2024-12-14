class_name Direction

static func target_axis(
		current: float,
		target: float,
		change: float) -> float:
	
	if current < target:
		return min(target, current + change)
	else:
		return max(target, current - change)
