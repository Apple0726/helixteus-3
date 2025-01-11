extends CanvasItem

func _ready() -> void:
	material = ShaderMaterial.new()
	material.shader = preload("res://Shaders/Highlight.gdshader")

func _on_mouse_entered() -> void:
	material.set_shader_parameter("highlight_strength", 0.15)

func _on_mouse_exited() -> void:
	material.set_shader_parameter("highlight_strength", 0.0)
