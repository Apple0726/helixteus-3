extends Control

export var science:String
var main_tree
var is_over:bool = false
onready var game = get_node("/root/Game")

func _ready():
	var font = theme.default_font
	$Panel.connect("mouse_entered", self, "on_mouse_entered")
	$Panel.connect("mouse_exited", self, "on_mouse_exited")
	$Panel/HBox/Texture.texture = load("res://Graphics/Science/" + science + ".png")
	refresh()
	rect_min_size.x = font.get_string_size(get_science_name(science)).x + 80
	if game.science_unlocked[science]:
		$Panel/HBox/VBox/Label["custom_colors/font_color"] = Color(0, 1, 0, 1)

func refresh():
	if modulate == Color.white:
		$Panel/HBox/VBox/Label.text = get_science_name(science)
		$Panel/HBox/VBox/Resource/Text.text = String(Data.science_unlocks[science].cost)
	else:
		$Panel/HBox/VBox/Label.text = "?"
		$Panel/HBox/VBox/Resource/Text.text = "-"

func get_science_name(sc:String):
	match sc:
		"SA":
			return tr("SPACE_AGRICULTURE")
		"RC":
			return tr("ROVER_CONSTRUCTION")
		"OL":
			return tr("ORANGE_LASER").format({"laser":tr("LASER")})
		"YL":
			return tr("YELLOW_LASER").format({"laser":tr("LASER")})
		"GL":
			return tr("GREEN_LASER").format({"laser":tr("LASER")})

func on_mouse_entered():
	is_over = true
	game.show_tooltip(tr(science.to_upper() + "_DESC"))

func on_mouse_exited():
	is_over = false
	game.hide_tooltip()

func _input(event):
	if Input.is_action_just_released("left_click") and is_over:
		if game.SP >= Data.science_unlocks[science].cost:
			game.SP -= Data.science_unlocks[science].cost
			game.science_unlocked[science] = true
			if science == "SA":
				game.long_popup(tr("SA_DONE"), tr("RESEARCH_SUCCESS"))
			elif science == "RC":
				game.long_popup(tr("RC_DONE"), tr("RESEARCH_SUCCESS"))
			else:
				game.popup(tr("RESEARCH_SUCCESS"), 1.5)
			game.HUD.refresh()
			$Panel/HBox/VBox/Label["custom_colors/font_color"] = Color(0, 1, 0, 1)
			main_tree.refresh(main_tree)
		else:
			game.popup(tr("NOT_ENOUGH_SP"), 1.5)
