shader_type canvas_item;

uniform float progress:hint_range(0.0, 1.0, 0.01) = 0.0;
uniform vec4 color:source_color = vec4(0.0, 1.0, 1.0, 1.0);

void fragment() {
	COLOR = texture(TEXTURE, UV);
	float p = min(2.0 * exp(-pow(UV.y + 8.0 * progress - 4.0, 2)), 1.0);
	COLOR.rgb = mix(COLOR.rgb, color.rgb, p);
}
