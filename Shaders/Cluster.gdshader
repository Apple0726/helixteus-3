shader_type canvas_item;

// Gonkee's fog shader for Godot 3 - full tutorial https://youtu.be/QEaTsz_0o44
// If you use this shader, I would prefer it if you gave credit to me and my channel

uniform vec4 color: source_color = vec4(0.35, 0.48, 0.95, 1.0);
uniform float fog_size: hint_range(0.01, 50.0) = 7.2;
uniform float fog_mvt_spd = 0.0;
uniform int OCTAVES = 4;
uniform int seed = 1;

float rand(vec2 coord){
	return fract(sin(dot(coord, vec2(12.9898, 78.233)))* 43758.5453123);
}

float noise(vec2 coord){
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

float fbm(vec2 coord){
	float value = 0.0;
	float scale = 0.5;

	for(int i = 0; i < OCTAVES; i++){
		value += noise(coord) * scale;
		coord *= 2.0;
		scale *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 coord = UV * fog_size + mod(vec2(float(seed)), 100.0);
	vec2 coord2 = UV * fog_size + mod(vec2(float(seed) + 2.0), 100.0);
	vec2 motion = vec2( fbm(coord + vec2(TIME * -fog_mvt_spd, TIME * fog_mvt_spd)) );

	float final = fbm(coord + motion) + fbm(coord2) * 0.3;
	COLOR.rgb = color.rgb;
	//COLOR.a = max(final - 0.4, 0.0) * 2.5;
	COLOR.a = final * 2.5;
	//COLOR.r = COLOR.a * 2.0;
	COLOR.rgb += 2.5 * (pow(0.708 - distance(UV, vec2(0.5, 0.5)), 2.5));
	//COLOR.rgb += pow(COLOR.a * 1.0, 1.0);
	//COLOR.b += pow(COLOR.a * 1.0, 2.0);
	COLOR.a = max(0.0, pow(COLOR.a * 1.3, 1.2) * (1.0 - 1.2 * pow(distance(UV, vec2(0.5, 0.5)), 0.3)));
}