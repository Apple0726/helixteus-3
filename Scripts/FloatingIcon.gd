extends Sprite2D

var end_pos:Vector2
var duration:float = 1.0

func _ready():
	var tween = create_tween()
	tween.tween_property(self, "position", end_pos, duration).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN_OUT)
	tween.start()
	await tween.tween_all_completed
	queue_free()
