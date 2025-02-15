extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Initiative.modulate.a = 0.0


func show_initiative(initiative: int, animation_delay: float):
	$Initiative/Label.text = str(initiative)
	$Initiative.modulate.a = 1.0
	create_tween().tween_property($Initiative, "modulate:a", 0.0, 1.0).set_delay(animation_delay)

func set_texture(texture):
	$TextureRect.texture = texture
