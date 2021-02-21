extends Node2D

onready var game = get_node("/root/Game")
var tween:Tween
var tut_num:int = 1
var click_anywhere:bool = false
var BG_blocked:bool = true
var PP_built:int = 0

func _ready():
	tween = Tween.new()
	add_child(tween)
	yield(get_tree().create_timer(1.5), "timeout")
	$AnimationPlayer.play("Blinking")
	modulate.a = 0
	begin()

func begin():
	click_anywhere = tut_num in [1, 16, 17, 22, 23, 25, 26, 27, 30, 31]
	if tut_num == 2:
		game.show.construct_button = true
		game.planet_HUD.get_node("VBoxContainer/Construct").visible = true
	elif tut_num == 10:
		game.objective = {"type":game.ObjectiveType.BUILD, "data":"ME", "current":0, "goal":6}
		game.HUD.refresh()
	elif tut_num == 17:
		game.objective = {"type":game.ObjectiveType.BUILD, "data":"RL", "current":0, "goal":1}
		game.HUD.refresh()
	elif tut_num == 31:
		yield(get_tree().create_timer(5.0), "timeout")
		game.objective = {"type":game.ObjectiveType.BUILD, "data":"RCC", "current":0, "goal":1}
		game.HUD.refresh()
	var node = get_node(String(tut_num))
	var node_label
	if node.has_node("Label"):
		node_label = node.get_node("Label")
		if click_anywhere:
			node_label.text = "%s (%s)" % [tr("TUTORIAL_%s" % tut_num), tr("CLICK_ANYWHERE_TO_CONTINUE")]
		else:
			node_label.text = tr("TUTORIAL_%s" % tut_num)
		node_label.visible = true
	node.visible = true
	BG_blocked = node.visible and node.has_node("Polygon")
	tween.interpolate_property(self, "modulate", null, Color.white, 0.4)
	tween.start()
	visible = true

func _input(event):
	if visible and Input.is_action_just_released("left_click") and click_anywhere:
		fade()

func fade(spd:float = 0.4, begin:bool = true):
	if tween.is_active():
		return
	tween.interpolate_property(self, "modulate", null, Color(1, 1, 1, 0), spd)
	tween.start()
	yield(tween, "tween_all_completed")
	if tut_num == 31:
		click_anywhere = false
		BG_blocked = false
		return
	get_node(String(tut_num)).visible = false
	tut_num += 1
	var node = get_node(String(tut_num))
	BG_blocked = node.visible and node.has_node("Polygon")
	if tut_num == 4:
		game.objective = {"type":game.ObjectiveType.BUILD, "data":"ME", "current":0, "goal":5}
		game.HUD.refresh()
		$EnergyCheckTimer.start()
	elif tut_num == 6:
		game.objective = {"type":game.ObjectiveType.BUILD, "data":"PP", "current":0, "goal":3}
		game.HUD.refresh()
	elif tut_num == 9:
		game.objective = {"type":game.ObjectiveType.BUILD, "data":"PP", "current":0, "goal":4}
		game.HUD.refresh()
	elif tut_num in [18, 26, 28, 31]:
		begin = false
	elif tut_num == 20:
		$RLCheckTimer.start()
	elif tut_num == 22:
		$RLCheckTimer2.start()
	elif tut_num == 24:
		game.objective = {"type":game.ObjectiveType.SAVE, "data":"SP", "current":game.SP, "goal":10}
		game.HUD.refresh()
		begin = false
	elif tut_num == 27:
		game.objective = {"type":game.ObjectiveType.BUILD, "data":"SC", "current":0, "goal":1}
		game.HUD.refresh()
	elif tut_num == 30:
		game.objective = {"type":game.ObjectiveType.SAVE, "data":"mats/silicon", "current":game.mats.silicon, "goal":20}
		game.HUD.refresh()
	if begin:
		begin()
	else:
		visible = false

func _on_RsrcCheckTimer_timeout():
	var curr_time = OS.get_system_time_msecs()
	for tile in game.tile_data:
		if not tile:
			continue
		if tile.has("bldg") and tile.bldg.name == "ME":
			if tile.bldg.stored > 0:
				begin()
				$RsrcCheckTimer.stop()

func _on_EnergyCheckTimer_timeout():
	if game.energy == 0 and game.objective.empty():
		begin()
		$EnergyCheckTimer.stop()

func _on_RsrcCheckTimer2_timeout():
	if game.money >= 300 and game.objective.empty():
		game._on_BottomInfo_close_button_pressed()
		begin()
		$RsrcCheckTimer2.stop()

func _on_RLCheckTimer_timeout():
	for tile in game.tile_data:
		if not tile:
			continue
		if tile.has("bldg") and tile.bldg.name == "RL" and not tile.bldg.is_constructing:
			begin()
			$RLCheckTimer.stop()


func _on_RLCheckTimer2_timeout():
	for tile in game.tile_data:
		if not tile:
			continue
		if tile.has("bldg") and tile.bldg.name == "RL" and tile.bldg.has("overclock_date"):
			begin()
			$RLCheckTimer2.stop()


func _on_SCCheckTimer_timeout():
	pass # Replace with function body.
