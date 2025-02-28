class_name BattleGUI
extends Control

@onready var game = get_node("/root/Game")
@onready var main_panel = get_node("MainPanel")
@onready var turn_order_hbox = get_node("TurnOrderHBox")
var battle_scene
var ship_node
enum {
	BULLET,
	LASER,
	BOMB,
	LIGHT,
	MOVE,
	PUSH,
	NONE,
}
var action_selected = NONE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Helper.set_back_btn($Back)
	$MainPanel/Bullet.mouse_exited.connect(game.hide_tooltip)
	$MainPanel/Laser.mouse_exited.connect(game.hide_tooltip)
	$MainPanel/Bomb.mouse_exited.connect(game.hide_tooltip)
	$MainPanel/Light.mouse_exited.connect(game.hide_tooltip)
	$MainPanel/Move.mouse_entered.connect(game.show_tooltip.bind(tr("BATTLE_MOVE_DESC")))
	$MainPanel/Move.mouse_exited.connect(game.hide_tooltip)
	$MainPanel/Push.mouse_entered.connect(game.show_tooltip.bind(tr("BATTLE_PUSH_DESC") + "\n" + tr("BATTLE_PUSH_HELP")))
	$MainPanel/Push.mouse_exited.connect(game.hide_tooltip)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	Helper.set_back_btn($Back)
	game.block_scroll = false
	if action_selected != NONE:
		if Input.is_action_just_pressed("cancel"):
			$MainPanel/AnimationPlayer.play("Fade")
			action_selected = NONE
			restore_default_enemy_tooltips()
			ship_node.cancel_action()
		elif Input.is_action_just_released("left_click") and not game.view.dragged and not $MainPanel/AnimationPlayer.is_playing():
			ship_node.fire_weapon(action_selected)
			action_selected = NONE
	if action_selected == NONE and is_instance_valid(ship_node):
		if Input.is_action_just_pressed("1"):
			_on_bullet_pressed()
		elif Input.is_action_just_pressed("2"):
			_on_laser_pressed()
		elif Input.is_action_just_pressed("3"):
			_on_bomb_pressed()
		elif Input.is_action_just_pressed("4"):
			_on_light_pressed()
		elif Input.is_action_just_pressed("5"):
			_on_move_pressed()
		elif Input.is_action_just_pressed("6"):
			_on_push_pressed()
	elif action_selected == LIGHT:
		if Input.is_action_pressed("shift"):
			game.block_scroll = true
			if Input.is_action_just_pressed("scroll_down"):
				ship_node.light_cone.target_angle_deviation = min(ship_node.light_cone.target_angle_deviation + PI / 64.0, 0.3 * PI)
				ship_node.light_cone.update_cone()
				override_enemy_tooltips()
			if Input.is_action_just_pressed("scroll_up"):
				ship_node.light_cone.target_angle_deviation = max(ship_node.light_cone.target_angle_deviation - PI / 64.0, PI / 64.0)
				ship_node.light_cone.update_cone()
				override_enemy_tooltips()

func _on_back_pressed() -> void:
	if battle_scene.hard_battle:
		game.switch_music(load("res://Audio/ambient%s.ogg" % randi_range(1, 3)), game.u_i.time_speed)
	game.switch_view("system")


func _on_bullet_mouse_entered() -> void:
	if not is_instance_valid(ship_node):
		return
	var tooltip_txt = tr("BASE_DAMAGE") + ": " + str(Data.bullet_data[ship_node.bullet_lv-1].damage)
	tooltip_txt += "\n" + tr("BASE_ACCURACY") + ": " + str(Data.bullet_data[ship_node.bullet_lv-1].accuracy)
	game.show_tooltip(tooltip_txt)


func _on_laser_mouse_entered() -> void:
	if not is_instance_valid(ship_node):
		return
	var tooltip_txt = tr("BASE_DAMAGE") + ": " + str(Data.laser_data[ship_node.laser_lv-1].damage)
	tooltip_txt += "\n" + tr("BASE_ACCURACY") + ": " + str(Data.laser_data[ship_node.laser_lv-1].accuracy)
	game.show_tooltip(tooltip_txt)


func _on_bomb_mouse_entered() -> void:
	if not is_instance_valid(ship_node):
		return
	var tooltip_txt = tr("BASE_DAMAGE") + ": " + str(Data.bomb_data[ship_node.bomb_lv-1].damage)
	tooltip_txt += "\n" + tr("BASE_ACCURACY") + ": " + str(Data.bomb_data[ship_node.bomb_lv-1].accuracy)
	game.show_tooltip(tooltip_txt)


func _on_light_mouse_entered() -> void:
	if not is_instance_valid(ship_node):
		return
	var tooltip_txt = tr("BASE_DAMAGE") + ": " + str(Data.light_data[ship_node.light_lv-1].damage)
	tooltip_txt += "\n" + tr("BASE_ACCURACY") + ": " + str(Data.light_data[ship_node.light_lv-1].accuracy)
	game.show_tooltip(tooltip_txt)


func _on_bullet_pressed() -> void:
	$MainPanel/AnimationPlayer.play_backwards("Fade")
	action_selected = BULLET
	override_enemy_tooltips()
	ship_node.get_node("FireWeaponAim").show()
	game.hide_tooltip()


func _on_laser_pressed() -> void:
	$MainPanel/AnimationPlayer.play_backwards("Fade")
	action_selected = LASER
	override_enemy_tooltips()
	ship_node.get_node("FireWeaponAim").show()
	game.hide_tooltip()


func _on_bomb_pressed() -> void:
	$MainPanel/AnimationPlayer.play_backwards("Fade")
	action_selected = BOMB
	override_enemy_tooltips()
	ship_node.get_node("FireWeaponAim").show()
	game.hide_tooltip()


func _on_light_pressed() -> void:
	action_selected = LIGHT
	override_enemy_tooltips()
	$MainPanel/AnimationPlayer.play_backwards("Fade")
	ship_node.add_light_cone()
	game.hide_tooltip()


func _on_move_pressed() -> void:
	action_selected = MOVE
	$MainPanel/AnimationPlayer.play_backwards("Fade")


func _on_push_pressed() -> void:
	action_selected = PUSH
	$MainPanel/AnimationPlayer.play_backwards("Fade")
	game.hide_tooltip()

func override_enemy_tooltips():
	if action_selected == BULLET:
		ship_node.weapon_accuracy_mult = Data.bullet_data[ship_node.bullet_lv-1].accuracy
	elif action_selected == LASER:
		ship_node.weapon_accuracy_mult = Data.laser_data[ship_node.laser_lv-1].accuracy
	elif action_selected == BOMB:
		ship_node.weapon_accuracy_mult = Data.bomb_data[ship_node.bomb_lv-1].accuracy
	elif action_selected == LIGHT:
		ship_node.weapon_accuracy_mult = Data.light_data[ship_node.light_lv-1].accuracy
	for HX_node in battle_scene.HX_nodes:
		var damage_multiplier:float
		var attack_defense_difference:int = ship_node.attack + ship_node.attack_buff - HX_node.defense - HX_node.defense_buff
		if attack_defense_difference >= 0:
			damage_multiplier = attack_defense_difference * 0.125 + 1.0
		else:
			damage_multiplier = 1.0 / (1.0 - 0.125 * attack_defense_difference)
		var tooltip_txt = tr("DAMAGE_MULTIPLIER") + ": " + "%.2f (%s){light_intensity_mult}{light_intensity_mult_info}" % [damage_multiplier, tr("SHIP_ATK_VS_ENEMY_DEF") % [ship_node.attack + ship_node.attack_buff, HX_node.defense + HX_node.defense_buff]]
		tooltip_txt += "\n" + tr("CHANCE_OF_HITTING") + ": " + "%.1f%% (%s)" % [(100.0 * (1.0 - 1.0 / (1.0 + exp(((ship_node.accuracy + ship_node.accuracy_buff) * ship_node.weapon_accuracy_mult - HX_node.agility - HX_node.agility_buff + 9.2) / 5.8)))),
		tr("SHIP_ATK_VS_ENEMY_DEF") % [ship_node.accuracy + ship_node.accuracy_buff, HX_node.agility + HX_node.agility_buff]]
		HX_node.override_tooltip_text = tooltip_txt

func restore_default_enemy_tooltips():
	for HX_node in battle_scene.HX_nodes:
		HX_node.override_tooltip_text = ""
		HX_node.override_tooltip_dict = HX_node.default_override_tooltip_dict.duplicate()
