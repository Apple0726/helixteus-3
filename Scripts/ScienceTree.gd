extends Node2D

onready var game = get_node('/root/Game')
var sc_over:String = ""

func show_tooltip(sc:String):
	sc_over = sc
	game.show_tooltip(tr(sc.to_upper() + "_DESC"))

func hide_tooltip():
	sc_over = ""
	game.hide_tooltip()

func _input(event):
	if sc_over != "" and Input.is_action_just_released("left_click") and not game.science_unlocked[sc_over]:
		if game.SP >= Data.science_unlocks[sc_over].cost:
			game.SP -= Data.science_unlocks[sc_over].cost
			game.science_unlocked[sc_over] = true
			game.popup(tr("RESEARCH_SUCCESS"), 1.5)
		else:
			game.popup(tr("NOT_ENOUGH_SP"), 1.5)
