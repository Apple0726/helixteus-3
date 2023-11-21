shader_type canvas_item;

uniform float progress:hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float alpha:hint_range(0.0, 1.0, 0.01) = 0.0;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	float p = smoothstep(progress*1.2, progress*1.2+0.2, 1.2-UV.y);
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), p);
	if (COLOR.a > 0.0) {
		COLOR.a = mix(COLOR.a, 1.0, p);
	}
	COLOR.a *= alpha;
}
