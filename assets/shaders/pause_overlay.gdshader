shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform vec3 overlay_color : source_color;

void fragment() {
	vec3 screen_color = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	float screen_luma =
		screen_color.r * 0.3 +
		screen_color.g * 0.5 +
		screen_color.b * 0.2;
	
	COLOR.rgb = overlay_color - (1.0 - screen_luma);
}