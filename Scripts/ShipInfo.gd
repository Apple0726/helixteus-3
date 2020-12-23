extends Panel

onready var game = get_node("/root/Game")
export var victory_screen = true
export var id:int
var show_weapon_XPs:bool

func _ready():
	$Bullet/Label.visible = victory_screen
	$Laser/Label.visible = victory_screen
	$Bomb/Label.visible = victory_screen
	$Light/Label.visible = victory_screen
	$XP/Label.visible = victory_screen

func set_visibility():
	$Bullet.visible = show_weapon_XPs
	$Laser.visible = show_weapon_XPs
	$Bomb.visible = show_weapon_XPs
	$Light.visible = show_weapon_XPs
	$Stats.visible = not show_weapon_XPs

func refresh():
	$XP/TextureProgress.value = game.ship_data[id].XP
	$XP/TextureProgress2.value = game.ship_data[id].XP
	$XP/TextureProgress.max_value = game.ship_data[id].XP_to_lv
	$XP/TextureProgress2.max_value = game.ship_data[id].XP_to_lv
	$Lv.text = "%s %s" % [tr("LV"), game.ship_data[id].lv]
	for weapon in ["Bullet", "Laser", "Bomb", "Light"]:
		var weapon_data = game.ship_data[id][weapon.to_lower()]
		get_node("%s/TextureProgress" % [weapon]).value = weapon_data.XP
		get_node("%s/TextureProgress" % [weapon]).max_value = INF if weapon_data.lv == 7 else weapon_data.XP_to_lv
		get_node("%s/TextureProgress2" % [weapon]).value = weapon_data.XP
		get_node("%s/TextureProgress2" % [weapon]).max_value = INF if weapon_data.lv == 7 else weapon_data.XP_to_lv
		get_node("%s/TextureRect" % [weapon]).texture = load("res://Graphics/Weapons/%s%s.png" % [weapon.to_lower(), weapon_data.lv])
		get_node("%s/Label2" % [weapon]).text = "%s / %s" % [weapon_data.XP, weapon_data.XP_to_lv]
	$XP/Label2.text = "%s / %s" % [game.ship_data[id].XP, game.ship_data[id].XP_to_lv]
	set_visibility()
	$Stats/HP.text = String(game.ship_data[id].total_HP)
	$Stats/Atk.text = String(game.ship_data[id].atk)
	$Stats/Def.text = String(game.ship_data[id].def)
	$Stats/Acc.text = String(game.ship_data[id].acc)
	$Stats/Eva.text = String(game.ship_data[id].eva)
	
func _on_icon_mouse_entered(stat:String):
	game.show_tooltip(tr(stat))

func _on_icon_mouse_exited():
	game.hide_tooltip()

func _on_weapon_mouse_entered(weapon:String):
	game.show_tooltip("%s\n%s" % [tr(weapon), tr("%s_DESC" % [weapon])])
