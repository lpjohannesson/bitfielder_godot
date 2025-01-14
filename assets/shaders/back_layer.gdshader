shader_type canvas_item;

uniform sampler2D shadow_viewport;
uniform float back_shade;
uniform float shadow_shade;

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);
	base_color.rgb -= back_shade;

	if (texture(shadow_viewport, SCREEN_UV).a > 0.0) {
		base_color.rgb -= shadow_shade;
	}

	COLOR = base_color;
}