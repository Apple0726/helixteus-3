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
var NPC_id:int = -1
var dialogue_id:int = -1
var dialogue_lengths:Array = [5, 3, 3, 1]

func _ready():
	speed_mult = rover_data.spd
	set_process(false)
	var ruins = load("res://Scenes/Ruins/%s.tscn"  % ruins_id).instance()
	add_child(ruins)
	if ruins_id == 1:
		if game.planet_data[game.c_p].has("MS") and game.planet_data[game.c_p].MS == "M_SE" and game.planet_data[game.c_p].MS_lv == 3:
			$Ruins/Letter.connect("body_entered", self, "_on_Letter_body_entered")
			$Ruins/Letter.connect("body_exited", self, "_on_Letter_body_exited")
		else:
			$Ruins/NPC1.connect("body_entered", self, "_on_NPC_body_entered", [1])
			$Ruins/NPC1.connect("body_exited", self, "_on_NPC_body_exited")
			$Ruins/NPC2.connect("body_entered", self, "_on_NPC_body_entered", [2])
			$Ruins/NPC2.connect("body_exited", self, "_on_NPC_body_exited")
	else:
		$Ruins/NPC1.connect("body_entered", self, "_on_NPC_body_entered", [3])
		$Ruins/NPC1.connect("body_exited", self, "_on_NPC_body_exited")
		$Ruins/NPC2.connect("body_entered", self, "_on_NPC_body_entered", [4])
		$Ruins/NPC2.connect("body_exited", self, "_on_NPC_body_exited")

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

func _on_NPC_body_entered(body, id:int):
	NPC_id = id
	$UI/HBox.visible = true

func _on_NPC_body_exited(body):
	if $UI/Dialogue.visible:
		$UI/Dialogue.visible = false
		dialogue_id = -1
	NPC_id = -1
	$UI/HBox.visible = false

func _input(event):
	var F_released = Input.is_action_just_released("F")
	if (Input.is_action_just_released("left_click") or F_released) and $UI/Dialogue.visible:
		if dialogue_id >= dialogue_lengths[NPC_id - 1] and $UI/Dialogue.visible_characters >= len($UI/Dialogue.text):
			$UI/Dialogue.visible = false
			dialogue_id = -1
			set_process(false)
		else:
			if $UI/Dialogue.visible_characters < len($UI/Dialogue.text):
				$UI/Dialogue.visible_characters = len($UI/Dialogue.text)
			else:
				dialogue_id += 1
				set_dialogue_text()
	elif F_released:
		if NPC_id != -1 and not $UI/Dialogue.visible:
			$UI/Dialogue.visible = true
			dialogue_id = 1
			set_dialogue_text()
			set_process(true)

func set_dialogue_text():
	$UI/Dialogue.visible_characters = 0
	$UI/Dialogue.text = tr("NPC_%s_%s" % [NPC_id, dialogue_id])
	
func _process(delta):
	if $UI/Dialogue.visible_characters < len($UI/Dialogue.text):
		$UI/Dialogue.visible_characters += ceil(delta * 30)


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
