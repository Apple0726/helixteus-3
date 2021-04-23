extends Node2D

onready var game = get_node("/root/Game")
onready var rover = $Rover
onready var camera = $Camera2D

var ruins_id:int
var velocity = Vector2.ZERO
var max_speed = 1000
var acceleration = 12000
var friction = 12000
var rover_size:float = 1.0
var speed_mult:float = 1.0
var rover_data:Dictionary = {"spd":1}
var moving_fast:bool = false

func _ready():
	speed_mult = rover_data.spd
	set_process(false)
	var ruins = load("res://Scenes/Ruins/%s.tscn"  % ruins_id).instance()
	add_child(ruins)
	if ruins_id == 1:
		if game.planet_data[game.c_p].has("MS") and game.planet_data[game.c_p].MS == "M_SE" and game.planet_data[game.c_p].MS_lv == 3:
			$Ruins/NPC1.visible = false
			$Ruins/NPC2.visible = false
			$Ruins/Letter.visible = true
			$Ruins/Letter.connect("body_entered", self, "_on_Letter_body_entered")
			$Ruins/Letter.connect("body_exited", self, "_on_Letter_body_exited")
			game.fourth_ship_hints.SE_constructed = true
		else:
			$Ruins/NPC1.connect_events(1, $UI/Dialogue)
			$Ruins/NPC2.connect_events(1, $UI/Dialogue)
	else:
		if game.fourth_ship_hints.SE_constructed:
			$Ruins/NPC1.connect_events(2, $UI/Dialogue)
			$Ruins/NPC2.connect_events(2, $UI/Dialogue)
		else:
			$Ruins/NPC1.visible = false
			$Ruins/NPC2.visible = false

func _physics_process(delta):
	var speed_mult2 = min(2.5, (speed_mult if moving_fast else 1.0) * rover_size)
	var input_vector = Vector2.ZERO
	if OS.get_latin_keyboard_variant() == "AZERTY":
		input_vector.x = int(Input.is_action_pressed("D")) - int(Input.is_action_pressed("Q"))
		input_vector.y = int(Input.is_action_pressed("S")) - int(Input.is_action_pressed("Z"))
	else:
		input_vector.x = int(Input.is_action_pressed("D")) - int(Input.is_action_pressed("A"))
		input_vector.y = int(Input.is_action_pressed("S")) - int(Input.is_action_pressed("W"))
	input_vector = input_vector.normalized()
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * max_speed * speed_mult2, acceleration * delta * speed_mult2)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta * speed_mult2)
	velocity = rover.move_and_slide(velocity)
	camera.position = rover.position

func _on_NPC_body_entered(body, _NPC_id:int, _dialogue_id:int):
	$UI/Dialogue.NPC_id = _NPC_id
	$UI/Dialogue.dialogue_id = _dialogue_id
	$UI/Dialogue/HBox.visible = true

func _on_NPC_body_exited(body):
	if $UI/Dialogue.visible:
		$UI/Dialogue.dialogue_id = -1
		$UI/Dialogue.dialogue_part_id = -1
	$UI/Dialogue.NPC_id = -1
	$UI/Dialogue/HBox.visible = false

func _on_Letter_body_entered(body):
	if $Ruins/Letter.visible:
		$UI/Letter.visible = true
		$UI/LetterText.visible = true


func _on_Letter_body_exited(body):
	if $Ruins/Letter.visible:
		$UI/Letter.visible = false
		$UI/LetterText.visible = false


func _on_Exit_body_entered(body):
	call_deferred("exit_ruins")

func exit_ruins():
	game.switch_view("planet")
	queue_free()
