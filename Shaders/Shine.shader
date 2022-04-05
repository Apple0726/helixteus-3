shader_type canvas_item;
render_mode blend_add;

float random(float u) {
    return fract(sin(dot(vec2(u, u),
        vec2(12.9898,78.233))) *
            43758.5453123);
}

void fragment() {
	vec2 c = UV - vec2(0.5);
	float dist = clamp(length(c), 0.0, 1.0);
	float th = atan(c.y, c.x) + TIME;
	float a_1 = random(round(th * 20.0) / 20.0) * exp(-12.0 * dist) * 2.8;
	
	float th2 = atan(c.y, c.x) - TIME / 2.5;
	float a_2 = random(round(th2 * 10.0) / 10.0) * exp(-12.0 * dist) * 1.4;
	
	COLOR.a = a_1 + a_2;
}