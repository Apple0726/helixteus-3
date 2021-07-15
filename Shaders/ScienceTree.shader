shader_type canvas_item;

float random(float x, float time) {
    return fract(sin(x * 10.0 + time * 10.0));
}

float razor(float x) {
	float h = 3.0;
	return pow(-abs(mod(x, 2.0) - 1.0) + 1.0, h) / h;
}

void fragment() {
	vec2 uv = UV * 12.0;
	COLOR.g = random(uv.y, TIME * 0.4) * 4.0;
	COLOR.b = random(uv.y, TIME * 0.2) * 2.0;
	COLOR.rgb += razor(uv.y * 0.1 + TIME * 0.3) * 15.0;
	COLOR.rgb *= pow(min(0.18, random(uv.y, TIME * 0.2)), 2);
	//COLOR.b += random(uv.x, TIME) * pow(min(0.9, random2(uv.y)), 10);
	//COLOR.b += sin(uv.y + TIME * 3.0) + sin(4.0 * TIME);
}