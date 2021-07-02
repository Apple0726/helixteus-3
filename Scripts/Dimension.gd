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
	$UnivInfo/Label.text += "%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s\n" % [
		tr("VPC_EPSILON"),
		tr("VPC_MU"),
		tr("SPEED_OF_LIGHT"),
		tr("PLANCK_CTE"),
		tr("GRAVITATIONAL_CTE"),
		tr("ELEMENTARY_CHARGE"),
		tr("STRONG_FORCE"),
		tr("WEAK_FORCE")]
	$UnivInfo/Label.text += "%s\n" % tr("MULTIPLIERS")
	$UnivInfo/Label.text += "%s: %s\n%s: %s\n%s: %s" % [
		tr("TIME_SPEED"),
		tr("ANTIMATTER"),
		tr("UNIVERSE_VALUE")]

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
