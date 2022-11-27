extends "Panel.gd"

var el:String = ""
var default_l:PoolVector2Array = []
var default_g:PoolVector2Array = []
var default_sc:PoolVector2Array = []

func _ready():
	set_polygon(rect_size)

func refresh():
	$Title.text = "%s (%s)" % [tr("PHASE_DIAGRAM_EDITOR"), tr(el.to_upper() + "_NAME")]
	default_l = load("res://Scenes/PhaseDiagrams/%s.tscn" % el).instance().get_node("Liquid").polygon
	default_g = load("res://Scenes/PhaseDiagrams/%s.tscn" % el).instance().get_node("Gas").polygon
	default_sc = load("res://Scenes/PhaseDiagrams/%s.tscn" % el).instance().get_node("Superfluid").polygon
	$Liquid.polygon = default_l
	$Gas.polygon = default_g
	$Supercritical.polygon = default_sc
