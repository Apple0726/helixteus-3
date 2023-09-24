shader_type canvas_item;

uniform float amount: hint_range(0.0, 1.0) = 0.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec4 tex = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);
	COLOR.rgb = mix(tex.rgb, vec3((tex.r + tex.g + tex.b) / 6.0), amount);
}
