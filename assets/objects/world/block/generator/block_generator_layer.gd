extends Resource
class_name BlockGeneratorLayer

@export var height: int

func get_ground_level(properties: BlockGeneratorProperties, noise: Noise, x: int) -> int:
	var noise_sample = (noise.get_noise_1d(x) + 1.0) * 0.5
	
	return lerp(
		properties.start_y,
		properties.start_y + height,
		noise_sample)

func start_layer(_blocks: BlockWorld) -> void:
	pass

func generate_layer(_properties: BlockGeneratorProperties) -> void:
	pass
