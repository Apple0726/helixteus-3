extends Label

var delay:float = 0.0
# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("Fade")
	$Timer.start(0.2 + delay)


func _on_timer_timeout():
	$AnimationPlayer.play_backwards("Fade")


func _on_animation_player_animation_finished(anim_name):
	if modulate.a == 0.0:
		queue_free()
