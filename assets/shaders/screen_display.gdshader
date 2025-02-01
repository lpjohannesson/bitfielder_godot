shader_type canvas_item;

uniform sampler2D background_texture : hint_screen_texture;
uniform sampler2D foreground_texture : filter_nearest;
uniform sampler2D light_texture : filter_linear;

uniform float sample_round = 1.0;
uniform float light_overflow = 1.0;

uniform vec3 sunlight_shade : source_color = vec3(1.0);

void fragment() {
	vec3 background_color = textureLod(background_texture, SCREEN_UV, 0.0).rgb;
	vec4 foreground_color = texture(foreground_texture, SCREEN_UV);

	vec2 light_size = vec2(textureSize(light_texture, 0));
	vec2 sample_scale = sample_round / light_size;

	vec2 light_uv = round(UV / sample_scale) * sample_scale;
	vec4 light_sample = texture(light_texture, light_uv);

	vec3 sunlight_color = vec3(light_sample.a);
	vec3 source_light_color = (light_sample.rgb * (1.0 + light_overflow) - light_overflow);
	
	COLOR.rgb = mix(
		background_color - (1.0 - sunlight_color),
		foreground_color.rgb - (vec3(1.0) - max(sunlight_color * sunlight_shade, source_light_color)),
		foreground_color.a);
}