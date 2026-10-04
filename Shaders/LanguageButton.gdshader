shader_type canvas_item;

instance uniform float progress:hint_range(0.0, 1.0, 0.01) = 1.0;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	COLOR.rgb *= vec3(1.0 - 0.7 * step(progress, UV.x));
}