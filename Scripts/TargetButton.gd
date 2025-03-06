extends Control

var shortcut_str:String = ""

func _ready() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)
	$Label.text = shortcut_str

func _on_TextureButton_mouse_entered():
	create_tween().tween_property($TextureButton, "scale", Vector2.ONE * 1.2, 0.1)

func _on_TextureButton_mouse_exited():
	create_tween().tween_property($TextureButton, "scale", Vector2.ONE, 0.1)
