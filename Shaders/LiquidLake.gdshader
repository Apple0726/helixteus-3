shader_type canvas_item;

uniform vec4 modul:source_color = vec4(1.0);
uniform float speed = 1.0;

void fragment() {
	vec4 c1 = texture(TEXTURE, 0.8 * UV + vec2(0, -0.03 * speed * TIME));
	vec4 c2 = texture(TEXTURE, 2.0 * UV + vec2(0, -0.02 * speed * TIME));
	COLOR.rgb = vec3(pow(length(1.0-c2), 10.0))/40.0+c1.rgb;
	COLOR *= modul;
}