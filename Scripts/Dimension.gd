extends Control

onready var game = get_parent()
onready var univs = game.universe_data
onready var univ_scene = preload("res://Scenes/UniverseIcon.tscn")
var tween:Tween

const DUR = 0.6
const TWEEN_TYPE = Tween.TRANS_EXPO
const TWEEN_EASE = Tween.EASE_OUT
var new_dim_DRs = 0#DRs you will get once you renew dimensions

var is_half_size = false

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
		for node in $GridContainer.get_children():
			node.get_node("Invest").disabled = true
	$TopInfo/DimensionN.text = tr("DIMENSION") + " #1"
	$DiscoveredUnivs/Label.text = tr("DISCOVERED_UNIVERSES")

func set_tween():
	tween.interpolate_property($GridContainer, "margin_left", 320, 800, DUR, TWEEN_TYPE, TWEEN_EASE)
	for node in $GridContainer.get_children():
		var tex = node.get_node("TextureRect")
		tween.interpolate_property(tex, "rect_scale", tex.rect_scale, tex.rect_scale / 2.0, DUR, TWEEN_TYPE, TWEEN_EASE)

func set_rev_tween():
	tween.interpolate_property($GridContainer, "margin_left", 800, 320, DUR, TWEEN_TYPE, TWEEN_EASE)
	for node in $GridContainer.get_children():
		var tex = node.get_node("TextureRect")
		tween.interpolate_property(tex, "rect_scale", tex.rect_scale, tex.rect_scale * 2.0, DUR, TWEEN_TYPE, TWEEN_EASE)
		
func on_univ_press(id:int):
	if not tween.is_active() and not is_half_size:
		set_tween()
		tween.start()
		tween.connect("tween_all_completed", self, "on_tween_complete")
	var u_i = game.universe_data[id] #universe_info
	$UnivInfo/Label.text = u_i["name"] + "\nSuperclusters: " + String(u_i["supercluster_num"]) + "\n\nFundamental properties\nVacuum permittivity constant ε\u2080 = " + game.e_notation(u_i["epsilon_zero"]) + " F·m\u207B\u00B9\nVacuum permeability constant μ\u2080 = " + game.e_notation(u_i["mu_zero"]) + " H·m\u207B\u00B9\nSpeed of light c = " + game.e_notation(pow(u_i["epsilon_zero"] * u_i["mu_zero"], -0.5)) + " m·s\u207B\u00B9\nPlanck constant h = " + game.e_notation(u_i["planck"]) + " J·s\nGravitational constant G = " + game.e_notation(u_i["gravitational"]) + " m\u00B3·kg\u207B\u00B9·s\u207B\u00B2\nElementary charge e = " + game.e_notation(u_i["charge"]) + " C\nStrong force: " + String(u_i["strong_force"]) + "\nWeak force: " + String(u_i["weak_force"])+ "\nDark matter: " + String(u_i["dark_matter"]) + "\n\nMultipliers\nDifficulty: " + String(u_i["difficulty"]) + "\nMultistar systems: " + String(u_i["multistar_systems"]) + "\nRare stars: " + String(u_i["rare_stars"]) + "\nRare materials: " + String(u_i["rare_materials"]) + "\nTime speed: " + String(u_i["time_speed"]) + "\nRadiation: " + String(u_i["radiation"]) + "\nAntimatter: " + String(u_i["antimatter"]) + "\nUniverse value: " + String(u_i["value"])

func on_univ_double_click(id:int):
	game.c_u = id
	game.switch_view("universe")

func _on_ExpandUpgs_pressed():
	$ExpandUpgs.visible = false
	set_rev_tween()
	tween.start()
	is_half_size = false

func on_tween_complete():
	$ExpandUpgs.visible = true
	is_half_size = true
	tween.disconnect("tween_all_completed", self, "on_tween_complete")
