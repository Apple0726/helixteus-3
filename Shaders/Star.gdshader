shader_type canvas_item;
//render_mode blend_add;

uniform float time_offset = 0.0;
uniform float brightness_offset = 1.0;
uniform float twinkle_speed = 0.8;
uniform float amplitude = 0.1;
uniform float alpha = 1.0;
uniform vec4 color:source_color = vec4(1.0);

void fragment() {
	COLOR = texture(TEXTURE, UV);
	float mult = amplitude * (sin(TIME * twinkle_speed + time_offset) + 1.0);
	//COLOR.a *= mult * COLOR.a;
	COLOR.rgb *= color.rgb;
	COLOR.rgb += max(0, COLOR.a - 0.7 + mult);
	COLOR.a *= alpha;
}