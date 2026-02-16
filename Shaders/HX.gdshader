shader_type canvas_item;
uniform float amplitude = 5;
uniform float frequency = 3.0;
uniform bool aurora = false;
uniform float light_amount = 1.0;
uniform float alpha:hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float flash:hint_range(0.0, 1.0, 0.1) = 0.0;
uniform vec3 flash_color:source_color = vec3(1.0, 1.0, 1.0);
uniform float starlight_angle:hint_range(0.0, 2.0 * 3.1415) = 0.0;
uniform bool starlight_enabled = false;
uniform vec3 starlight_color:source_color = vec3(1.0);
uniform float starlight_energy:hint_range(0.0, 2.0) = 1.0;

void vertex() {
  VERTEX += vec2(0, amplitude * sin(frequency * TIME));
}
void fragment() {
	COLOR = texture(TEXTURE, UV);
	if (aurora) {
		COLOR.rb += 0.3 * sin((UV.x + UV.y) * 6.0 + TIME * 10.0) + 0.3;
	}
	COLOR.rgb *= light_amount;
	COLOR.a *= alpha;
	if (starlight_enabled) {
		vec2 center = 0.4 * vec2(cos(starlight_angle + 3.1415), sin(starlight_angle + 3.1415)) + vec2(0.5);
		float shade = cos(starlight_angle) * 1.5 * (UV.x - center.x) + sin(starlight_angle) * 1.5 * (UV.y - center.y);
		float shade2 = starlight_energy * smoothstep(0.0, 1.0, shade) + 0.1;
		COLOR.rgb *= vec3(shade2) * mix(vec3(1.0), starlight_color, shade2 * 0.8);
	}
	COLOR.rgb = mix(COLOR.rgb, flash_color, flash);
}

void light() {
	LIGHT = vec4(LIGHT_COLOR.rgb * LIGHT_ENERGY, LIGHT_COLOR.a);
}