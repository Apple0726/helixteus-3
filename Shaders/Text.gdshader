shader_type canvas_item;

void fragment() {
	COLOR.a = texture(TEXTURE, UV).a;
	COLOR.rgb = vec3(1.0 - step(0.5, length(textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb)));
}