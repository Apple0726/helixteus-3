extends Node2D

@onready var game = get_node("/root/Game")

var battle_GUI:BattleGUI

var HP:int
var total_HP:int
var attack:int
var defense:int
var accuracy:int
var agility:int
var initiative:int
var turn_index:int
var movement_remaining:float
var total_movement:float
var type:int

var attack_buff:int = 0
var defense_buff:int = 0
var accuracy_buff:int = 0
var agility_buff:int = 0

func initialize_stats(data:Dictionary):
	HP = data.HP
	total_HP = data.HP
	attack = data.attack
	defense = data.defense
	accuracy = data.accuracy
	agility = data.agility
	movement_remaining = data.agility * 10.0
	total_movement = data.agility * 10.0

func roll_initiative():
	var range:int = 2 + log(randf()) / log(0.2)
	initiative = randi_range(agility - range, agility + range)

func take_turn():
	battle_GUI.turn_order_hbox.get_child(turn_index).get_node("AnimationPlayer").play("ChangeSize")

func end_turn():
	battle_GUI.turn_order_hbox.get_child(turn_index).get_node("AnimationPlayer").play_backwards("ChangeSize")
