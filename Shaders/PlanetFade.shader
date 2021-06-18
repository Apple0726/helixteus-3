shader_type canvas_item;

uniform vec2 tiled_factor = vec2(5.0, 5.0);
uniform float aspect_ratio = 0.5;
const float PI = 3.14159265358979323846;

void fragment() {
//	vec2 tiled_uvs = UV * tiled_factor;
//	tiled_uvs.y *= 0.01;
	//float offset = cos(UV.y * PI * 4.0) * 0.05;
	//float t = cos((UV.x + offset + TIME / 8.0) * 2.0 * PI * 2.0) * 0.5 + 0.5;
	//COLOR = vec4(t, t, t, t);
//	vec2 wave_offset = vec2(cos(TIME) + tiled_uvs.x + tiled_uvs.y, sin(TIME) + tiled_uvs.x + tiled_uvs.y);
//	COLOR = vec4(wave_offset, 0.0, 1.0);
	COLOR = texture(TEXTURE, UV) + vec4(cos(UV.x * 11.0) / 10.0, 0.0, 0.0, 0.0);
	//COLOR = texture(TEXTURE, UV + vec2(cos(TIME + UV.x) * 0.05, sin(TIME + UV.y * 1.0) * 0.05));
}