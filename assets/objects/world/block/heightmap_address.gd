class_name HeightmapAddress

var heightmap: Variant
var height_index: int

func get_height() -> int:
	return heightmap[height_index]

func set_height(height: int) -> void:
	heightmap[height_index] = height
