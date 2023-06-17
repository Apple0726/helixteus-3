extends Node2D

@onready var btn = $Sprite2D
var over:bool = false

func _process(delta):
	if over:
		btn.scale = btn.scale.move_toward(Vector2(0.48, 0.48), btn.scale.distance_to(Vector2(0.48, 0.48)) * delta * 25)
	else:
		btn.scale = btn.scale.move_toward(Vector2(0.427, 0.427), btn.scale.distance_to(Vector2(0.427, 0.427)) * delta * 25)

func _on_TextureButton_mouse_entered():
	over = true

func _on_TextureButton_mouse_exited():
	over = false
