shader_type canvas_item;

uniform vec4 color:source_color = vec4(3.0, 1.5, 1.0, 1.0);
uniform float speed = 0.03;
uniform float alpha = 0.0;

void fragment() {
	vec2 uv = vec2(UV.x * 2.5, UV.y * 1.406);
	vec2 uv1 = vec2(uv.x + TIME * speed, uv.y);
	vec2 uv2 = vec2(uv.x - TIME * speed, uv.y);
	vec2 uv3 = vec2(uv.x, uv.y + TIME * speed);
	
	float noise_r = texture(TEXTURE, uv1).r;
	float noise_g = texture(TEXTURE, uv2).g;
	float noise_b = texture(TEXTURE, uv3).b;
	
	float new_alpha = noise_r * noise_g * noise_b;
	
	vec3 new_color = vec3(noise_r, noise_g, noise_b);
	COLOR.rgb = color.rgb;
	COLOR.a = new_alpha * 5.0 * alpha;
}