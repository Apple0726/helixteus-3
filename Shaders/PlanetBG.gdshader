shader_type canvas_item;

uniform float strength = 0.1;
uniform float lum = 0.3;
uniform float u = 0.0;
uniform vec4 star_mod = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	COLOR = texture(TEXTURE, UV);
	float mult = max(0.0, 1.0 - length(UV - vec2(u, 0.0))) * lum;
	COLOR.rgb *= star_mod.rgb * strength;
	COLOR.rgb += mult;
}