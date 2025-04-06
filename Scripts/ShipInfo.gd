extends Panel

@onready var game = get_node("/root/Game")
@export var victory_screen = true
@export var id:int
var show_weapon_XPs:bool
var tween

func _ready():
	$XP/Label.visible = victory_screen
	$Ship.texture_normal = load("res://Graphics/Ships/Ship%s.png" % id)
	$Ship.texture_click_mask = load("res://Graphics/Ships/Ship%sCM.png" % id)

func set_visibility():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	$Ship.texture_normal = load("res://Graphics/Ships/Ship%s.png" % id)
	if show_weapon_XPs:
		tween.tween_property($Stats, "modulate", Color(1, 1, 1, 0), 0.15)
		$Bullet.visible = true
		$Laser.visible = true
		$Bomb.visible = true
		$Light.visible = true
		if not victory_screen:
			tween.tween_property($Bullet, "modulate", Color(1, 1, 1, 1), 0.15)
			tween.tween_property($Laser, "modulate", Color(1, 1, 1, 1), 0.15).set_delay(0.05)
			tween.tween_property($Bomb, "modulate", Color(1, 1, 1, 1), 0.15).set_delay(0.05)
			tween.tween_property($Light, "modulate", Color(1, 1, 1, 1), 0.15).set_delay(0.05)
			await tween.finished
			$Stats.visible = false
	else:
		$Stats.visible = true
		tween.tween_property($Stats, "modulate", Color(1, 1, 1, 1), 0.15)
		tween.tween_property($Bullet, "modulate", Color(1, 1, 1, 0), 0.15)
		tween.tween_property($Laser, "modulate", Color(1, 1, 1, 0), 0.15)
		tween.tween_property($Bomb, "modulate", Color(1, 1, 1, 0), 0.15)
		tween.tween_property($Light, "modulate", Color(1, 1, 1, 0), 0.15)
		await tween.finished
		$Bullet.visible = false
		$Laser.visible = false
		$Bomb.visible = false
		$Light.visible = false

func refresh():
	if id >= len(game.ship_data):
		return
	$XP/TextureProgressBar.max_value = game.ship_data[id].XP_to_lv
	$XP/TextureProgressGained.max_value = game.ship_data[id].XP_to_lv
	$XP/TextureProgressBar.value = game.ship_data[id].XP
	$XP/TextureProgressGained.value = game.ship_data[id].XP
	$Lv.text = "%s %s" % [tr("LV"), game.ship_data[id].lv]
	$XP/Label2.text = "%s / %s" % [Helper.format_num(round(game.ship_data[id].XP)), Helper.format_num(game.ship_data[id].XP_to_lv)]
	set_visibility()
	$Stats/HP.text = Helper.format_num(game.ship_data[id].HP)
	$Stats/Attack.text = Helper.format_num(game.ship_data[id].attack)
	$Stats/Defense.text = Helper.format_num(game.ship_data[id].defense)
	$Stats/Accuracy.text = Helper.format_num(game.ship_data[id].accuracy)
	$Stats/Agility.text = Helper.format_num(game.ship_data[id].agility)
	if game.ship_data[id].respec_count == 0:
		$Respec.text = "%s (%s)" % [tr("RESPEC"), tr("FREE")]
	else:
		$Respec.text = "%s (-0.5 %s)" % [tr("RESPEC"), tr("LV")]
	
func _on_icon_mouse_entered(stat:String):
	game.show_tooltip(tr(stat))

func _on_icon_mouse_exited():
	game.hide_tooltip()

func _on_weapon_mouse_entered(weapon:String):
	game.show_tooltip("%s\n%s" % [tr(weapon), tr("%s_DESC" % [weapon])])

func _on_Ship_mouse_entered():
	if game.bottom_info_action == "use_hx_core":
		$XP/TextureProgressGained.value = $XP/TextureProgressBar.value + game.other_items_info[game.item_to_use.name].XP * game.item_to_use.num
		$XP/Label.visible = true
		$XP/Label.text = "+ %s" % [game.other_items_info[game.item_to_use.name].XP * game.item_to_use.num]

func _on_Ship_mouse_exited():
	if not victory_screen:
		$XP/TextureProgressGained.value = $XP/TextureProgressBar.value
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


func _on_respec_pressed() -> void:
	game.toggle_panel("ships_panel")
	game.switch_view("ship_customize_screen", {"ship_id":id})
