shader_type canvas_item;
render_mode blend_add;

uniform float time_offset = 0.0;
uniform float brightness_offset = 1.0;
uniform float twinkle_speed = 3.0;
uniform float amplitude = 0.5;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	float mult = amplitude * (sin(TIME * twinkle_speed + time_offset) + 1.0) + brightness_offset;
	COLOR.a *= mult * COLOR.a;
	COLOR.rgb *= max(1.0, COLOR.a);
}