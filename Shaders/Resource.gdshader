shader_type canvas_item;

uniform float fill:hint_range(0.0, 1.0, 0.1) = 0.0;

void fragment() {
	float fill_angle = fill * 2.0 * PI;
	float th = atan((1.0 - UV.x) - 0.5, UV.y - 0.5);
	COLOR.rgb *= 0.7 * step(th, fill_angle - PI) + 0.3;
}