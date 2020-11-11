extends Node2D

onready var game = get_node("/root/Game")

func _ready():
	scale *= rand_range(0.04, 0.06)
	rotation = rand_range(-7, 7)
	position = Vector2(rand_range(0, 1280), rand_range(0, 720))
	while not Geometry.is_point_in_polygon(position, game.get_node("Title/Background/AllowedStarArea").polygon):
		position = Vector2(rand_range(0, 1280), rand_range(0, 720))
	$Twinkle.play("Twinkle", -1, rand_range(0.4, 0.5))
	$Twinkle.seek(randf(), true)
