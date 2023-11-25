shader_type canvas_item;

uniform float progress:hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float red:hint_range(0.0, 1.0, 0.01) = 0.0;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	float p = smoothstep(progress*1.2, progress*1.2+0.2, UV.y);
	COLOR.rgb = mix(COLOR.rgb, mix(COLOR.rgb, vec3(1.0, 0.0, 0.0), red), p);
	if (COLOR.a > 0.0) {
		COLOR.a = mix(COLOR.a, p, red);
	}
}
