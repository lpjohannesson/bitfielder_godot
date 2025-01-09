shader_type canvas_item;

uniform int sunlight_range = 8;
uniform int block_light_range = 8;

uniform int[128] heightmap;
uniform int top_height;

uniform sampler2D block_lightmap: filter_nearest;

struct LightProperties {
	vec2 uv;
	vec2 pixel_size;
	float light_distance;
};

float ease_out(float value) {
	return 1.0 - (1.0 - value) * (1.0 - value);
}

int get_sunlight(ivec2 block_position, int offset_x) {
	int block_height = heightmap[block_position.x + offset_x];

	int sunlight = clamp(
		sunlight_range - (block_position.y - block_height),
		0, sunlight_range);

	return max(0, sunlight - abs(offset_x));
}

vec3 get_block_light(LightProperties properties, ivec2 offset) {
	vec2 light_position = properties.uv + vec2(offset) * properties.pixel_size;
	vec3 light_sample = texture(block_lightmap, light_position).rgb;

	return max(vec3(0.0), light_sample - properties.light_distance);
}

void fragment() {
	// Block light
	LightProperties properties;

	properties.uv = UV;
	properties.pixel_size = SCREEN_PIXEL_SIZE;
	properties.light_distance = 0.0;

	vec3 block_light = get_block_light(properties, ivec2(0));

	for (int i = 1; i < block_light_range; i++) {
		properties.light_distance = float(i) / float(block_light_range);

		for (int j = 0; j < i; j++) {
			ivec2 light_offset = ivec2(i - j, -j);

			block_light = max(block_light, get_block_light(
				properties, light_offset));

			block_light = max(block_light, get_block_light(
				properties, ivec2(-light_offset.y, light_offset.x)));

			block_light = max(block_light, get_block_light(
				properties, -light_offset));

			block_light = max(block_light, get_block_light(
				properties, ivec2(light_offset.y, -light_offset.x)));
		}
	}

	vec3 block_light_value = vec3(
		ease_out(block_light.r),
		ease_out(block_light.g),
		ease_out(block_light.b));

	// Sunlight
	ivec2 block_position = ivec2(UV / SCREEN_PIXEL_SIZE);
	ivec2 sunlight_position = ivec2(block_position.x, block_position.y + top_height);

	int sunlight = get_sunlight(sunlight_position, 0);

	for (int i = 0; i < sunlight_range; i++) {
		sunlight = max(sunlight, get_sunlight(sunlight_position, i));
		sunlight = max(sunlight, get_sunlight(sunlight_position, -i));
	}

	float sunlight_value = ease_out(float(sunlight) / float(sunlight_range));

	// Mix
	COLOR.rgb = max(vec3(sunlight_value), block_light_value);
}