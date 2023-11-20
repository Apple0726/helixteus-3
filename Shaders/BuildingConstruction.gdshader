shader_type canvas_item;

uniform float progress:hint_range(0.0, 1.0, 0.01) = 0.0;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	float p = smoothstep(progress, progress+0.1, 1.0-UV.y);
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), p);
}
