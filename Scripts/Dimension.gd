extends Control

onready var game = get_node("/root/Game")
onready var univs = game.universe_data
var univ_icon = preload("res://Graphics/Misc/Universe.png")
const DUR = 0.6
const TWEEN_TYPE = Tween.TRANS_EXPO
const TWEEN_EASE = Tween.EASE_OUT
var new_dim_DRs = 0#DRs you will get once you renew dimensions

func _ready():
	refresh_univs()
	$TopInfo/DRs.text = tr("DR_TITLE") + ": %s" % [game.DRs]
	$TopInfo/Reset.text = String(tr("NEW_DIMENSION") + " (+ %s " + tr("DR") + ")") % [new_dim_DRs]
	if new_dim_DRs == 0:
		$TopInfo/Reset.disabled = true
	if game.DRs == 0:
		for node in $ScrollContainer2/GridContainer.get_children():
			node.get_node("Invest").disabled = true
	$TopInfo/DimensionN.text = tr("DIMENSION") + " #1"
	$DiscoveredUnivs/Label.text = tr("DISCOVERED_UNIVERSES")

func refresh_univs():
	for univ in $ScrollContainer/VBoxContainer.get_children():
		$ScrollContainer/VBoxContainer.remove_child(univ)
		univ.queue_free()
	for univ_info in univs:
		var univ = TextureButton.new()
		univ.texture_normal = univ_icon
		var id = univ_info["id"]
		$ScrollContainer/VBoxContainer.add_child(univ)
		univ.connect("mouse_entered", self, "on_univ_over", [id])
		univ.connect("mouse_exited", self, "on_univ_out")
		univ.connect("pressed", self, "on_univ_press", [id])

func on_univ_out():
	game.hide_tooltip()
	$UnivInfo/Label.text = ""

func on_univ_over(id:int):
	var u_i = game.universe_data[id] #universe_info
	game.show_tooltip("%s\n%s: %s" % [u_i.name, tr("SUPERCLUSTERS"), u_i.supercluster_num])
	$UnivInfo/Label.text = tr("FUNDAMENTAL_PROPERTIES") + "\n"
	if id == 0:
		$UnivInfo/Label.text += "%s c = %s m·s\u207B\u00B9\n%s h = %s J·s\n%s k = %s J·K\u207B\u00B9\n%s \u03C3 = %s W·m\u207B\u00B2·K\u207B\u2074\n%s G = %s m\u00B3·kg\u207B\u00B9·s\u207B\u00B2\n%s e = %s C\n" % [
			tr("SPEED_OF_LIGHT"),
			Helper.e_notation(e(3, 8)),
			tr("PLANCK_CTE"),
			Helper.e_notation(e(6.626, -34)),
			tr("BOLTZMANN_CTE"),
			Helper.e_notation(e(1.381, -23)),
			tr("S_B_CTE"),
			Helper.e_notation(e(5.67, -8)),
			tr("GRAVITATIONAL_CTE"),
			Helper.e_notation(e(6.674, -11)),
			tr("ELEMENTARY_CHARGE"),
			Helper.e_notation(e(1.6, -19)),
			]
	else:
		$UnivInfo/Label.text += "%s: %sc\n%s: %sh\n%s: %sk\n%s: %s\u03C3\n%s: %sG\n%s: %se\n" % [
			tr("SPEED_OF_LIGHT"),
			u_i.speed_of_light,
			tr("PLANCK_CTE"),
			u_i.planck,
			tr("BOLTZMANN_CTE"),
			u_i.boltzmann,
			tr("S_B_CTE"),
			pow(u_i.boltzmann, 4) / pow(u_i.planck, 3) / pow(u_i.speed_of_light, 2),
			tr("GRAVITATIONAL_CTE"),
			u_i.gravitational,
			tr("ELEMENTARY_CHARGE"),
			u_i.charge,
			]
	$UnivInfo/Label.text += "\n%s\n" % tr("MULTIPLIERS")
	$UnivInfo/Label.text += "%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s" % [
		tr("DARK_ENERGY"),
		u_i.dark_energy,
		tr("DIFFICULTY"),
		u_i.difficulty,
		tr("TIME_SPEED"),
		u_i.time_speed,
		tr("ANTIMATTER"),
		u_i.antimatter,
		tr("UNIVERSE_VALUE"),
		u_i.value,
		]

func e(n, e):
	return n * pow(10, e)

func on_univ_press(id:int):
	var u_i:Dictionary = game.universe_data[id]
	if u_i.has("generated") or u_i.lv > 1:
		game.c_u = id
		game.load_univ()
		if u_i.lv >= 70:
			game.switch_view("universe")
		elif u_i.lv >= 50:
			game.switch_view("supercluster")
		elif u_i.lv >= 35:
			game.switch_view("cluster")
		elif u_i.lv >= 18:
			game.switch_view("galaxy")
		elif u_i.lv >= 8:
			game.switch_view("system")
		else:
			game.switch_view("planet")
	else:
		game.remove_dimension()
		game.new_game(false, id)
		game.HUD.dimension_btn.visible = true
		game.switch_music(load("res://Audio/ambient" + String(Helper.rand_int(1, 3)) + ".ogg"))
	game.HUD.refresh_bookmarks()

func _on_SendProbes_pressed():
	game.toggle_panel(game.send_probes_panel)


func _on_Label_mouse_entered(extra_arg_0):
	game.show_tooltip(tr(extra_arg_0))


func _on_Label_mouse_exited():
	game.hide_tooltip()
