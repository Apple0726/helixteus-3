shader_type canvas_item;
uniform float amplitude = 20.0;
uniform float frequency = 6.0;
uniform float hurt_flash:hint_range(0.0, 1.0, 0.1) = 0.0;

void vertex() {
	VERTEX += vec2(0, amplitude * sin(frequency * TIME));
}

void fragment() {
	COLOR = texture(TEXTURE, UV);
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0, 0.0, 0.0), hurt_flash);
}