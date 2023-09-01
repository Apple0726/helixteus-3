shader_type canvas_item;
uniform float threshold = 0.66;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	float s = (COLOR.r + COLOR.g + COLOR.b) / 3.0;
	if (UV.x > threshold) {
		COLOR.rgb = mix(COLOR.rgb, vec3(pow(s, 3)), min((UV.x - threshold) * 30.0, 1.0));
	}
}
