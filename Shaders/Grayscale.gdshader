shader_type canvas_item;
uniform bool gray = false;
uniform float darkness = 9.0;

void fragment() {
	if (gray) {
		vec3 c = texture(TEXTURE, UV).rgb;
		COLOR.rgb = vec3((c.r + c.g + c.b) / darkness);
	}
}
