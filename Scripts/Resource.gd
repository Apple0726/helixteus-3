extends HBoxContainer

@onready var game = get_node("/root/Game")

var rsrc_type:String
var rsrc_name:String
var rsrc_display_name:String
var mass_str:String
var rsrc:float
var rsrcs_required:float

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	if rsrc_type != "":
		rsrc = game[rsrc_type][rsrc_name]
	elif rsrc_name in ["money", "minerals", "energy", "SP"]:
		rsrc = game[rsrc_name]
	elif rsrc_name == "stone":
		rsrc = Helper.get_sum_of_dict(game.stone)
	Helper.format_text($Text, $Texture2D, "", true, rsrcs_required, rsrc, mass_str)
	$Texture2D.material.set_shader_parameter("fill", rsrc / rsrcs_required)
	if rsrc < rsrcs_required:
		$Texture2D/IsEnough.texture = preload("res://Graphics/Icons/Annotator/cross.png")
	else:
		$Texture2D/IsEnough.texture = preload("res://Graphics/Icons/Annotator/check.png")

func connect_mouse_events():
	$Texture2D.mouse_entered.connect(show_tooltip)
	$Texture2D.mouse_exited.connect(game.hide_tooltip)

func show_tooltip():
	var tooltip = rsrc_display_name
	if $Texture2D/IsEnough.visible:
		tooltip += ": " + Helper.get_rsrc_available_text(rsrc, rsrcs_required, mass_str, true)
	if rsrc_name == "stone" and not game.show.has("mining"):
		tooltip += "\n%s" % [tr("STONE_HELP")]
	if rsrc_name == "silicon" and not game.show.has("silicon"):
		tooltip += "\n%s" % [tr("HOW2SILICON")]
	game.show_tooltip(tooltip)
