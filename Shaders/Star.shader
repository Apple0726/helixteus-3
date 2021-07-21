shader_type canvas_item;

uniform float time_offset = 0.0;
uniform float brightness_offset = 1.5;
uniform float twinkle_speed = 3.0;
uniform float amplitude = 0.5;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	float mult = amplitude * sin(TIME * twinkle_speed + time_offset) + brightness_offset;
	COLOR.a *= mult;
	COLOR.rgb *= max(1.0, COLOR.a);
}