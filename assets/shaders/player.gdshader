shader_type canvas_item;

uniform sampler2D skin_uv_texture : filter_nearest;
uniform sampler2D skin_texture : filter_nearest;

void fragment() {
	vec2 skin_uv = texture(skin_uv_texture, UV).rg;

	vec4 skin_color = texture(skin_texture, skin_uv);
	vec4 overlay_color = texture(TEXTURE, UV);

	COLOR = skin_color * overlay_color;
}
