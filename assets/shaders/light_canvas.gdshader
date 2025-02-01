shader_type canvas_item;
render_mode blend_disabled;

uniform int sunlight_range = 8;
uniform int block_light_range = 8;

uniform int[128] heightmap;
uniform int top_height;

uniform sampler2D block_lightmap : filter_nearest;

float get_final_channel(float value) {
	return 1.0 - (1.0 - value) * (1.0 - value);
}

float get_sunlight(ivec2 block_position, int offset_x) {
	int offset_position_x = block_position.x + offset_x;
	int offset_height = heightmap[offset_position_x];

	if (block_position.y <= offset_height) {
		return float(sunlight_range) - float(abs(offset_x));
	}

	ivec2 offset_position = ivec2(offset_position_x, offset_height);
	return float(sunlight_range) - distance(vec2(block_position), vec2(offset_position));
}

void fragment() {
	// Block light
	vec3 block_light = vec3(0.0);

	for (int i = -block_light_range; i <= block_light_range; i++) {
		for (int j = -block_light_range; j <= block_light_range; j++) {
			vec2 offset = vec2(float(i), float(j));
			vec2 light_position = UV + offset * SCREEN_PIXEL_SIZE;
			
			vec3 light_sample = texture(block_lightmap, light_position).rgb;
			vec3 light_amount = light_sample - (length(offset) / float(block_light_range));
			
			block_light = max(block_light, light_amount);
		}
	}

	vec3 block_light_value = vec3(
		get_final_channel(block_light.r),
		get_final_channel(block_light.g),
		get_final_channel(block_light.b));

	// Sunlight
	ivec2 block_position = ivec2(UV / SCREEN_PIXEL_SIZE);
	ivec2 sunlight_position = ivec2(block_position.x, block_position.y + top_height);

	float sunlight = get_sunlight(sunlight_position, 0);

	for (int i = 0; i < sunlight_range; i++) {
		sunlight = max(sunlight, get_sunlight(sunlight_position, i));
		sunlight = max(sunlight, get_sunlight(sunlight_position, -i));
	}

	float sunlight_value = get_final_channel(float(sunlight) / float(sunlight_range));

	COLOR = vec4(block_light_value, sunlight_value);
}