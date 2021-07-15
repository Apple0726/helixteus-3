shader_type canvas_item;
uniform float amplitude = 5;
uniform float frequency = 3.0;

void vertex() {
  VERTEX += vec2(0, amplitude * sin(frequency * TIME));
}