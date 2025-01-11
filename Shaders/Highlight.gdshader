shader_type canvas_item;

uniform float highlight_strength: hint_range(0.0, 1.0, 0.1) = 0.0;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	COLOR.rgb += highlight_strength;
}
