shader_type canvas_item;

uniform int[64] heightmap;
uniform int top_height;
uniform int sunlight_max = 8;

float ease_out(float value) {
	return 1.0 - (1.0 - value) * (1.0 - value);
}

int get_sunlight(ivec2 block_position, int offset_x) {
	int block_height = heightmap[block_position.x + offset_x];
	
	int sunlight = clamp(
		sunlight_max - (block_position.y - block_height),
		0, sunlight_max);
	
	return max(0, sunlight - abs(offset_x));
}

void fragment() {
	ivec2 block_position = ivec2(UV / SCREEN_PIXEL_SIZE);
	block_position.y += top_height;
	
	int sunlight = get_sunlight(block_position, 0);
	
	for (int i = 0; i < sunlight_max; i++) {
		sunlight = max(sunlight, get_sunlight(block_position, i));
		sunlight = max(sunlight, get_sunlight(block_position, -i));
	}
	
	COLOR.rgb = vec3(ease_out(float(sunlight) / float(sunlight_max)));
}