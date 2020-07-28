extends KinematicBody2D
onready var tile = preload("res://Scenes/Tile.tscn")

var acceleration = 90
var max_speed = 1000
var friction = 150

var velocity = Vector2.ZERO

func _ready():
	var wid = 10
	
	for i in range(0, pow(wid, 2)):
		var tileMC = tile.instance()
		tileMC.position = Vector2((i % wid) * 200, floor(i / wid) * 200)
		self.add_child(tileMC)

#var mouse_position = Vector2.ZERO
const ZOOM_FACTOR = 1.1
var zooming = ""
var progress = 0
var mouse_position = Vector2.ZERO

func _physics_process(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
	input_vector.y = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	input_vector = input_vector.normalized()
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * max_speed, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction)
	velocity = move_and_slide(velocity)
	if zooming == "in":
		_zoom_at_point(-ease(progress, 0.1) * (ZOOM_FACTOR - 1) + ZOOM_FACTOR)
		progress += 0.03
	if zooming == "out":
		_zoom_at_point(ease(progress, 0.1) * (1 - 1 / ZOOM_FACTOR) + 1 / ZOOM_FACTOR)
		progress += 0.03
	if progress >= 1:
		zooming = ""
		progress = 0

func _input(event):
	if event is InputEventMouse:
		if event.is_action_released("scroll_down"):
			zooming = "out"
			progress = 0
		elif event.is_action_released("scroll_up"):
			zooming = "in"
			progress = 0
		mouse_position = event.position


func _zoom_at_point(zoom_change):
	scale = scale * zoom_change
	var delta_x = (mouse_position.x - global_position.x) * (zoom_change - 1)
	var delta_y = (mouse_position.y - global_position.y) * (zoom_change - 1)
	global_position.x -= delta_x
	global_position.y -= delta_y
