class_name BattleGUI
extends Control

@onready var game = get_node("/root/Game")
@onready var main_panel = get_node("MainPanel")
@onready var turn_order_hbox = get_node("TurnOrderHBox")
var battle_scene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Helper.set_back_btn($Back)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	Helper.set_back_btn($Back)

func _on_back_pressed() -> void:
	if battle_scene.hard_battle:
		game.switch_music(load("res://Audio/ambient%s.ogg" % randi_range(1, 3)), game.u_i.time_speed)
	game.switch_view("system")
