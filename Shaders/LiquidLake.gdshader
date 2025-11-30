shader_type canvas_item;
uniform float u_time;
uniform vec3 shallow_color:source_color = vec3(0.8, 0.85, 0.9);
uniform vec3 deep_color:source_color = vec3(0.2, 0.5, 0.8);
uniform vec3 reflection_color:source_color = vec3(0.1, 0.3, 0.5);
uniform float UV_scale = 20.0;
uniform bool should_render = false;
uniform float time_factor = 0.1;

float rand(vec2 coord) {
	return fract(sin(dot(coord, vec2(12.9898, 78.233)))* 43758.5453123);
}

float noise(vec2 coord) {
	vec2 i = floor(coord);
	vec2 f = fract(coord);

	// 4 corners of a rectangle surrounding our point
	float a = rand(i);
	float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0));
	float d = rand(i + vec2(1.0, 1.0));

	vec2 cubic = f * f * (3.0 - 2.0 * f);

	return mix(a, b, cubic.x) + (c - a) * cubic.y * (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
	float value = 0.0;
	float scale = 0.5;

	for (int i = 0; i < 5; i++) {
		value += noise(coord) * scale;
		coord *= 2.0;
		scale *= 0.5;
	}
	return value;
}

void fragment() {
	float offset = TIME * time_factor;
	vec2 waveUV = UV * UV_scale;

	float wave = sin(TIME) * fbm(waveUV * 2.0 + vec2(offset, 0.0));

	vec3 color = mix(shallow_color, deep_color, wave * 0.8 + 0.2);

	float reflection = smoothstep(0.4, 1.0, wave + sin(u_time * 0.3) * 0.1);
	color += reflection_color * reflection * 0.5;

	if (should_render) {
		COLOR = vec4(color, 1.0);
	}
}