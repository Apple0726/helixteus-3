extends Sprite

onready var tween:Tween = $Tween
var end_pos:Vector2
var duration:float = 1.0

func _ready():
	tween.interpolate_property(self, "position", null, end_pos, duration, Tween.TRANS_CIRC, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	get_parent().remove_child(self)
	queue_free()
