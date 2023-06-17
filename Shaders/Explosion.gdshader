shader_type canvas_item;
render_mode blend_add;

uniform vec4 color:source_color = vec4(1.0);
uniform float alpha:hint_range(0.0, 1.0) = 1.0;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	COLOR.rgba *= color + vec4(0.8);
	COLOR.a *= alpha;
}