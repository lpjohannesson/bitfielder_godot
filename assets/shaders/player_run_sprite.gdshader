shader_type canvas_item;

uniform sampler2D skin_texture : filter_nearest;
uniform vec2 skin_uv;

void fragment() {
	vec3 skin_color = texture(skin_texture, skin_uv).rgb;
	vec4 sprite_color = texture(TEXTURE, UV);
	
	COLOR.rgb = skin_color;
	COLOR.a *= sprite_color.a;
}