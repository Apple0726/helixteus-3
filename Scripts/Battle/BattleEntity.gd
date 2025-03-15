class_name BattleEntity
extends Node2D

signal next_turn

@onready var game = get_node("/root/Game")

@export var type:int

var METERS_PER_AGILITY:float
var PIXELS_PER_METER:float

var battle_scene:Node2D
var battle_GUI:BattleGUI

var lv:int
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
var turn_index:int = -1
var go_through_movement_cost:float # in meters
var velocity:Vector2 = Vector2.ZERO:
	get:
		return velocity
	set(value):
		velocity = value
		update_velocity_arrow()

var attack_buff:int = 0
var defense_buff:int = 0
var accuracy_buff:int = 0
var agility_buff:int = 0:
	get:
		return agility_buff
	set(value):
		agility_buff = value
		agility_updated_callback()

var default_tooltip_text:String
var override_tooltip_text:String = ""
var default_override_tooltip_dict = {
	"light_intensity_mult": "",
	"light_intensity_mult_info": "",
}
var override_tooltip_dict:Dictionary
var override_tooltip_icons = [Data.attack_icon, Data.defense_icon, Data.accuracy_icon, Data.agility_icon]

func _ready() -> void:
	override_tooltip_dict = default_override_tooltip_dict.duplicate()
	if has_node("Info/Initiative"):
		$Info/Initiative.modulate.a = 0.0

func initialize_stats(data:Dictionary):
	lv = data.lv
	HP = data.HP
	total_HP = data.HP
	attack = data.attack
	defense = data.defense
	accuracy = data.accuracy
	agility = data.agility

func roll_initiative():
	var range:int = 2 + log(randf()) / log(0.2)
	initiative = randi_range(agility - range, agility + range)

func show_initiative(_initiative: int):
	$Info/Initiative.text = tr("INITIATIVE") + ": " + str(_initiative)
	var tween = create_tween()
	tween.tween_property($Info/Initiative, "modulate:a", 1.0, 0.5)
	tween.tween_property($Info/Initiative, "modulate:a", 0.0, 1.0).set_delay(2.0)
	create_tween().tween_property($Info/Initiative, "position:y", $Info/Initiative.position.y - 15.0, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)

func take_turn():
	if turn_index != -1:
		battle_GUI.turn_order_hbox.get_child(turn_index).get_node("AnimationPlayer").play("ChangeSize")
	if velocity != Vector2.ZERO:
		var move_tween = create_tween()
		move_tween.tween_property(self, "position", position + velocity, 1.0)
		await move_tween.finished

func end_turn():
	battle_GUI.turn_order_hbox.get_child(turn_index).get_node("AnimationPlayer").play_backwards("ChangeSize")
	emit_signal("next_turn")

func agility_updated_callback():
	if has_node("CollisionShapeFinder/CollisionShape2D"):
		$CollisionShapeFinder/CollisionShape2D.shape.radius = (agility + agility_buff) * METERS_PER_AGILITY * PIXELS_PER_METER

func damage_entity(weapon_data: Dictionary):
	var dodged = 1.0 / (1.0 + exp((weapon_data.weapon_accuracy - agility - agility_buff + 9.2) / 5.8)) > randf()
	if dodged:
		battle_scene.add_damage_text(true, position)
	else:
		var damage_multiplier:float
		var attack_defense_difference:int = weapon_data.shooter_attack - defense - defense_buff
		if attack_defense_difference >= 0:
			damage_multiplier = attack_defense_difference * 0.125 + 1.0
		else:
			damage_multiplier = 1.0 / (1.0 - 0.125 * attack_defense_difference)
		var actual_damage:int = max(1, weapon_data.damage * damage_multiplier)
		var critical = randf() < (weapon_data.crit_hit_chance if weapon_data.weapon_accuracy == INF else 0.005 * weapon_data.weapon_accuracy)
		if critical:
			actual_damage *= 2
		HP -= actual_damage
		$Info/HP.value = HP
		battle_scene.add_damage_text(false, position, actual_damage, critical, weapon_data.damage_label_initial_velocity)
	return not dodged

func update_velocity_arrow(offset: Vector2 = Vector2.ZERO):
	$VelocityArrow.scale = Vector2.ONE * (velocity + offset).length() / 100.0 / scale
	$VelocityArrow.rotation = (velocity + offset).angle()


func push_entity_attempt(agility_pusher: int, agility_pushee: int):
	return 1.0 / (1.0 + exp((agility_pusher - agility_pushee + 9.2) / 5.8)) < randf()
