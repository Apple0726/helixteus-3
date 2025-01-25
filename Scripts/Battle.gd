extends Node

@onready var game = get_node("/root/Game")

var hard_battle:bool = false
var time_speed:float = 1.0

func _ready() -> void:
	time_speed = Helper.set_logarithmic_time_speed(game.subject_levels.dimensional_power, game.u_i.time_speed)
	$Ship1.position = game.ship_data[0].initial_position
	$Ship2.position = game.ship_data[1].initial_position
	$Ship3.position = game.ship_data[2].initial_position
	$Ship4.position = game.ship_data[3].initial_position
	$Ship1/Sprite2D.material.set_shader_parameter("frequency", 6 * time_speed)
	$Ship2/Sprite2D.material.set_shader_parameter("frequency", 6 * time_speed)
	$Ship3/Sprite2D.material.set_shader_parameter("frequency", 6 * time_speed)
	$Ship4/Sprite2D.material.set_shader_parameter("frequency", 6 * time_speed)

func _input(event: InputEvent) -> void:
	Helper.set_back_btn($GUI/Back)

func _process(delta: float) -> void:
	pass

func _on_back_pressed() -> void:
	if hard_battle:
		game.switch_music(load("res://Audio/ambient" + str(Helper.rand_int(1, 3)) + ".ogg"), game.u_i.time_speed)
	game.switch_view("system")
