shader_type canvas_item;
uniform bool gray = false;
uniform float darkness = 9.0;

void fragment() {
	if (gray) {
		COLOR = texture(TEXTURE, UV);
		COLOR.rgb = vec3((COLOR.r + COLOR.g + COLOR.b) / darkness);
	}
}
