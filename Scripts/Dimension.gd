extends Control

onready var game = get_node("/root/Game")
onready var univs = game.universe_data
onready var univ_scene = preload("res://Scenes/UniverseIcon.tscn")
var tween:Tween

const DUR = 0.6
const TWEEN_TYPE = Tween.TRANS_EXPO
const TWEEN_EASE = Tween.EASE_OUT
var new_dim_DRs = 0#DRs you will get once you renew dimensions

func _ready():
	tween = Tween.new()
	add_child(tween)
	for univ_info in univs:
		var univ = univ_scene.instance()
		var id = univ_info["id"]
		#univ.id = id
		$ScrollContainer/VBoxContainer.add_child(univ)
		univ.connect("pressed", self, "on_univ_press", [id])
		univ.connect("double_click", self, "on_univ_double_click", [id])
		#univ.position = Vector2(150, 150 + v_offset)
	$TopInfo/DRs.text = tr("DR_TITLE") + ": %s" % [game.DRs]
	$TopInfo/Reset.text = String(tr("NEW_DIMENSION") + " (+ %s " + tr("DR") + ")") % [new_dim_DRs]
	if new_dim_DRs == 0:
		$TopInfo/Reset.disabled = true
	if game.DRs == 0:
		for node in $ScrollContainer2/GridContainer.get_children():
			node.get_node("VBoxContainer/HBoxContainer/Invest").disabled = true
	$TopInfo/DimensionN.text = tr("DIMENSION") + " #1"
	$DiscoveredUnivs/Label.text = tr("DISCOVERED_UNIVERSES")

func set_tween():
	tween.interpolate_property($ScrollContainer2, "margin_left", 320, 800, DUR, TWEEN_TYPE, TWEEN_EASE)

func set_rev_tween():
	tween.interpolate_property($ScrollContainer2, "margin_left", 800, 320, DUR, TWEEN_TYPE, TWEEN_EASE)
		
func on_univ_press(id:int):
	if not tween.is_active():
		set_tween()
		tween.start()
		tween.connect("tween_all_completed", self, "on_tween_complete")
	var u_i = game.universe_data[id] #universe_info
	$UnivInfo/Label.text = "%s\n%s: %s\n\n%s\n" % [u_i.name, tr("SUPERCLUSTERS"), u_i.supercluster_num, tr("FUNDAMENTAL_PROPERTIES")]
	$UnivInfo/Label.text += "%s: %s m·s\u207B\u00B9\n%s h = %s J·s\n%s k = %s J·K\u207B\u00B9\n%s G = %s m\u00B3·kg\u207B\u00B9·s\u207B\u00B2\n%s e = %s C\n" % [
		tr("SPEED_OF_LIGHT"),
		#Helper.e_notation(u_i.speed_of_light),
		Helper.e_notation(300000000),
		tr("PLANCK_CTE"),
		Helper.e_notation(u_i.planck),
		tr("BOLTZMANN_CTE"),
		#Helper.e_notation(u_i.boltzmann),
		Helper.e_notation(1),
		tr("GRAVITATIONAL_CTE"),
		Helper.e_notation(u_i.gravitational),
		tr("ELEMENTARY_CHARGE"),
		Helper.e_notation(u_i.charge),
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

func on_univ_double_click(id:int):
	game.c_u = id
	game.switch_view("universe")

func _on_ExpandUpgs_pressed():
	$ExpandUpgs.visible = false
	set_rev_tween()
	tween.start()

func on_tween_complete():
	$ExpandUpgs.visible = true
	tween.disconnect("tween_all_completed", self, "on_tween_complete")


func _on_SendProbes_pressed():
	game.toggle_panel(game.send_probes_panel)
