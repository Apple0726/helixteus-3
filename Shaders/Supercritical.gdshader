shader_type canvas_item;

uniform vec4 color:source_color = vec4(1.1, 1.1, 1.1, 1.0);
uniform float speed = 0.2;

void fragment() {
	vec2 uv = vec2(UV.x * 1.4, UV.y * 1.406);
	vec2 uv1 = vec2(uv.x + TIME * speed, uv.y);
	vec2 uv2 = vec2(uv.x - TIME * speed, uv.y);
	vec2 uv3 = vec2(uv.x, uv.y + TIME * speed);
	
	float noise_r = texture(TEXTURE, uv1).r;
	float noise_g = texture(TEXTURE, uv2).g;
	float noise_b = texture(TEXTURE, uv3).b;
	
	float new_alpha = sqrt(noise_r * noise_g * noise_b);
	
	vec3 new_color = vec3(noise_r, noise_g, noise_b);
	COLOR.rgb = color.rgb * new_alpha * 3.0;
	//COLOR.a = new_alpha * 5.0;
}