shader_type canvas_item;
render_mode blend_add;

uniform vec4 laser_color: source_color = vec4(1.0);

void fragment() {
	COLOR = texture(TEXTURE, UV);
	COLOR.rgb = laser_color.rgb + smoothstep(0.9, 1.0, COLOR.a) * (vec3(1.0) - laser_color.rgb);
}
