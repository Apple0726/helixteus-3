extends HBoxContainer

@onready var game = get_node("/root/Game")

var rsrc_type:String
var rsrc_name:String
var rsrc_display_name:String
var mass_str:String
var rsrc:float = 0.0
var rsrcs_required:float = 0.0
var show_available = false

func _ready() -> void:
	update_info()

func _process(delta: float) -> void:
	update_info()

func update_info():
	if show_available:
		if rsrc_type != "":
			rsrc = game[rsrc_type][rsrc_name]
		elif rsrc_name in ["money", "minerals", "energy", "SP"]:
			rsrc = game[rsrc_name]
		elif rsrc_name == "stone":
			rsrc = Helper.get_sum_of_dict(game.stone)
		$Texture2D.material.set_shader_parameter("fill", rsrc / rsrcs_required)
		if rsrc < rsrcs_required:
			$Texture2D/IsEnough.texture = preload("res://Graphics/Icons/Annotator/cross.png")
		else:
			$Texture2D/IsEnough.texture = preload("res://Graphics/Icons/Annotator/check.png")
	Helper.format_text($Text, $Texture2D, "", show_available, rsrcs_required, rsrc, mass_str)
	
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
