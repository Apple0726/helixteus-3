extends Node2D

var queue_free_delay:float

func _ready():
	await get_tree().create_timer(queue_free_delay).timeout
	queue_free()

