shader_type canvas_item;
uniform float amplitude = 20.0;
uniform float frequency = 6.0;
uniform float flash:hint_range(0.0, 1.0, 0.1) = 0.0;
uniform vec3 flash_color:source_color = vec3(1.0, 1.0, 1.0);

void vertex() {
	VERTEX += vec2(0, amplitude * sin(frequency * TIME));
}

void fragment() {
	COLOR = texture(TEXTURE, UV);
	COLOR.rgb = mix(COLOR.rgb, flash_color, flash);
}