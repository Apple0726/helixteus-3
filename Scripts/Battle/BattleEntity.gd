extends Node2D

@onready var game = get_node("/root/Game")

var METERS_PER_AGILITY:float
var PIXELS_PER_METER:float

var battle_scene:Node2D
var battle_GUI:BattleGUI

var HP:int
var total_HP:int
var attack:int
var defense:int
var accuracy:int
var agility:int:
	get:
		return agility
	set(value):
		agility = value
		agility_updated_callback()
var initiative:int
var turn_index:int
var type:int

var attack_buff:int = 0
var defense_buff:int = 0
var accuracy_buff:int = 0
var agility_buff:int = 0:
	get:
		return agility_buff
	set(value):
		agility_buff = value
		agility_updated_callback()

func initialize_stats(data:Dictionary):
	HP = data.HP
	total_HP = data.HP
	attack = data.attack
	defense = data.defense
	accuracy = data.accuracy
	agility = data.agility

func roll_initiative():
	var range:int = 2 + log(randf()) / log(0.2)
	initiative = randi_range(agility - range, agility + range)

func take_turn():
	battle_GUI.turn_order_hbox.get_child(turn_index).get_node("AnimationPlayer").play("ChangeSize")

func end_turn():
	battle_GUI.turn_order_hbox.get_child(turn_index).get_node("AnimationPlayer").play_backwards("ChangeSize")

func agility_updated_callback():
	if has_node("CollisionShapeFinder/CollisionShape2D"):
		$CollisionShapeFinder/CollisionShape2D.shape.radius = (agility + agility_buff) * METERS_PER_AGILITY * PIXELS_PER_METER
