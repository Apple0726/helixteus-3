class_name STMHX
extends Node2D

var HP:int = 3

# Called when the node enters the scene tree for the first time.
func _ready():
	position.x = 1400
	position.y = randf_range(50, 670)
	var target_position = Vector2(randf_range(850, 1200), randf_range(50, 670))
	var travel_duration = (position - target_position).length() / 200.0 * scale.x
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, travel_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	for i in HP:
		var HP_dot = TextureRect.new()
		HP_dot.texture = preload("res://Graphics/Misc/bullet.png")
		HP_dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		HP_dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		HP_dot.custom_minimum_size.x = 48
		$HPBar.add_child(HP_dot)

func hit(damage:int):
	HP -= damage
	if HP <= 0:
		queue_free()
	else:
		for i in damage:
			$HPBar.get_child(0).queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
