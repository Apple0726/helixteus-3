shader_type canvas_item;
uniform float amplitude = 5;
uniform float frequency = 3.0;
uniform bool aurora = false;
uniform float light = 1.0;
uniform float alpha:hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float flash:hint_range(0.0, 1.0, 0.1) = 0.0;
uniform vec3 flash_color:source_color = vec3(1.0, 1.0, 1.0);

void vertex() {
  VERTEX += vec2(0, amplitude * sin(frequency * TIME));
}
void fragment() {
	COLOR = texture(TEXTURE, UV);
	if (aurora) {
		COLOR.rb += 0.3 * sin((UV.x + UV.y) * 6.0 + TIME * 10.0) + 0.3;
	}
	COLOR.rgb *= light;
	COLOR.a *= alpha;
	COLOR.rgb = mix(COLOR.rgb, flash_color, flash);
}