shader_type canvas_item;

// Gonkee's fog shader for Godot 3 - full tutorial https://youtu.be/QEaTsz_0o44
// If you use this shader, I would prefer it if you gave credit to me and my channel

uniform vec4 color: source_color = vec4(1.0, 0.53, 0.0, 1.0);
uniform float fog_size: hint_range(0.01, 20.0) = 8.0;
uniform float fog_mvt_spd = 1.0;
uniform int OCTAVES = 4;
uniform int seed = 3;

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
	vec2 coord = UV * fog_size + vec2(float(seed));
	vec2 motion = vec2( fbm(coord + vec2(TIME * -fog_mvt_spd, TIME * fog_mvt_spd)) );

	float final = fbm(coord + motion);
	COLOR.rgb = color.rgb;
	COLOR.a = max(final - 0.4, 0.02) * 1.7;
	//COLOR.r = COLOR.a * 2.0;
	COLOR.rgb += pow(COLOR.a * 1.0, 2.0);
	//COLOR.b += pow(COLOR.a * 1.0, 2.0);
	//COLOR.a = max(0.0, 2.0 * COLOR.a * (1.0 - 5.0 * distance(UV, vec2(0.5, 0.5))));
	
}