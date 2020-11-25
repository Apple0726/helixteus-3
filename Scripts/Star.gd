extends Node2D

func _ready():
	$Twinkle.play("Twinkle", -1, rand_range(0.4, 0.5))
	$Twinkle.seek(randf(), true)
