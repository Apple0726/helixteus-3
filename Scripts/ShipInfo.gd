extends Panel

@onready var game = get_node("/root/Game")
@export var victory_screen = true
@export var id:int
var show_weapon_XPs:bool
var tween

func _ready():
	$Bullet/Label.visible = victory_screen
	$Laser/Label.visible = victory_screen
	$Bomb/Label.visible = victory_screen
	$Light3D/Label.visible = victory_screen
	$XP/Label.visible = victory_screen
	$Ship.texture_normal = load("res://Graphics/Ships/Ship%s.png" % id)
	$Ship.texture_click_mask = load("res://Graphics/Ships/Ship%sCM.png" % id)

func set_visibility():
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.set_parallel(true)
	$Ship.texture_normal = load("res://Graphics/Ships/Ship%s.png" % id)
	if show_weapon_XPs:
		tween.tween_property($Stats, "modulate", Color(1, 1, 1, 0), 0.15)
		$Bullet.visible = true
		$Laser.visible = true
		$Bomb.visible = true
		$Light3D.visible = true
		if not victory_screen:
			tween.tween_property($Bullet, "modulate", Color(1, 1, 1, 1), 0.15)
			tween.tween_property($Laser, "modulate", Color(1, 1, 1, 1), 0.15).set_delay(0.05)
			tween.tween_property($Bomb, "modulate", Color(1, 1, 1, 1), 0.15).set_delay(0.05)
			tween.tween_property($Light3D, "modulate", Color(1, 1, 1, 1), 0.15).set_delay(0.05)
			await tween.finished
			$Stats.visible = false
	else:
		$Stats.visible = true
		tween.tween_property($Stats, "modulate", Color(1, 1, 1, 1), 0.15)
		tween.tween_property($Bullet, "modulate", Color(1, 1, 1, 0), 0.15)
		tween.tween_property($Laser, "modulate", Color(1, 1, 1, 0), 0.15)
		tween.tween_property($Bomb, "modulate", Color(1, 1, 1, 0), 0.15)
		tween.tween_property($Light3D, "modulate", Color(1, 1, 1, 0), 0.15)
		await tween.finished
		$Bullet.visible = false
		$Laser.visible = false
		$Bomb.visible = false
		$Light3D.visible = false

func refresh():
	if id >= len(game.ship_data):
		return
	$XP/TextureProgressBar.max_value = game.ship_data[id].XP_to_lv
	$XP/TextureProgress2.max_value = game.ship_data[id].XP_to_lv
	$XP/TextureProgressBar.value = game.ship_data[id].XP
	$XP/TextureProgress2.value = game.ship_data[id].XP
	$Lv.text = "%s %s" % [tr("LV"), game.ship_data[id].lv]
	for weapon in ["Bullet", "Laser", "Bomb", "Light3D"]:
		var weapon_data = game.ship_data[id][weapon.to_lower()]
		get_node("%s/TextureProgressBar" % [weapon]).max_value = INF if weapon_data.lv == 5 else weapon_data.XP_to_lv
		get_node("%s/TextureProgress2" % [weapon]).max_value = INF if weapon_data.lv == 5 else weapon_data.XP_to_lv
		get_node("%s/TextureProgressBar" % [weapon]).value = weapon_data.XP
		get_node("%s/TextureProgress2" % [weapon]).value = weapon_data.XP
		get_node("%s/TextureRect" % [weapon]).texture = load("res://Graphics/Weapons/%s%s.png" % [weapon.to_lower(), weapon_data.lv])
		get_node("%s/Label2" % [weapon]).text = "%s / %s" % [round(weapon_data.XP), weapon_data.XP_to_lv]
	$XP/Label2.text = "%s / %s" % [Helper.format_num(round(game.ship_data[id].XP)), Helper.format_num(game.ship_data[id].XP_to_lv)]
	set_visibility()
	$Stats/HP.text = Helper.format_num(game.ship_data[id].total_HP * game.ship_data[id].HP_mult)
	$Stats/Atk.text = Helper.format_num(game.ship_data[id].atk * game.ship_data[id].atk_mult)
	$Stats/Def.text = Helper.format_num(game.ship_data[id].def * game.ship_data[id].def_mult)
	$Stats/Acc.text = Helper.format_num(game.ship_data[id].acc * game.ship_data[id].acc_mult)
	$Stats/Eva.text = Helper.format_num(game.ship_data[id].eva * game.ship_data[id].eva_mult)
	$TextEdit.text = game.ship_data[id].name
	
func _on_icon_mouse_entered(stat:String):
	game.show_tooltip(tr(stat))

func _on_icon_mouse_exited():
	game.hide_tooltip()

func _on_weapon_mouse_entered(weapon:String):
	game.show_tooltip("%s\n%s" % [tr(weapon), tr("%s_DESC" % [weapon])])

func _on_Ship_mouse_entered():
	if game.bottom_info_action == "use_hx_core":
		$XP/TextureProgress2.value = $XP/TextureProgressBar.value + game.other_items_info[game.item_to_use.name].XP * game.item_to_use.num
		$XP/Label.visible = true
		$XP/Label.text = "+ %s" % [game.other_items_info[game.item_to_use.name].XP * game.item_to_use.num]

func _on_Ship_mouse_exited():
	if not victory_screen:
		$XP/TextureProgress2.value = $XP/TextureProgressBar.value
		$XP/Label.visible = false


func _on_Ship_pressed():
	if game.bottom_info_action == "use_hx_core":
		if game.get_item_num(game.item_to_use.name) >= game.item_to_use.num:
			game.remove_items(game.item_to_use.name, game.item_to_use.num)
			Helper.add_ship_XP(id, game.other_items_info[game.item_to_use.name].XP * game.item_to_use.num)
			refresh()
			if game.get_item_num(game.item_to_use.name) > 0:
				_on_Ship_mouse_entered()
			else:
				game.item_to_use.num = 0
				game.update_item_cursor()
				_on_Ship_mouse_exited()


func _on_TextEdit_text_changed():
	game.ship_data[id].name = $TextEdit.text
