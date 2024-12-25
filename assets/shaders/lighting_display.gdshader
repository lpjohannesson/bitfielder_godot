shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D viewport_texture : filter_linear;
uniform float sample_round = 0.25;

void fragment() {
	vec3 screen_color = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	
	vec2 viewport_size = 1.0 / vec2(textureSize(viewport_texture, 0));
	vec2 sample_scale = viewport_size * sample_round;
	
	vec2 light_uv = round(UV / sample_scale) * sample_scale;
	vec3 light_color = texture(viewport_texture, light_uv).rgb;
	
	COLOR.rgb = screen_color - (vec3(1.0) - light_color);
}