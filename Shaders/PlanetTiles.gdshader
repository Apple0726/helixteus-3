shader_type canvas_item;
render_mode blend_disabled;

uniform float strength = 0.1;
uniform float offset = 0.0;
uniform vec4 star_mod = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	COLOR = texture(TEXTURE, UV);
	//COLOR = mix(COLOR, star_mod, 0.5);
	//COLOR.rgb += offset;
	COLOR.rgb = min(COLOR.rgb * star_mod.rgb * strength, vec3(1.0));
}