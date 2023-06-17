extends Control

@onready var game = get_node("/root/Game")
var sc_tree

func _ready():
	Helper.set_back_btn($Back)
	if game.help.has("science_tree"):
		$ZoomHelp.visible = true
		$ZoomHelp.text = tr("SC_TREE_ZOOM")
		game.help.erase("science_tree")


func _on_Back_pressed():
	if modulate.a == 1.0:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.2)
		tween.tween_property(game.get_node("ScienceTreeBG"), "modulate", Color(1, 1, 1, 0), 0.1)
	game.switch_view(game.l_v)


func _on_MainBranch_mouse_entered():
	game.show_tooltip(tr("MAIN_BRANCH"))


func _on_mouse_exited():
	game.hide_tooltip()


func _on_OtherBranches_mouse_entered():
	game.show_tooltip(tr("OTHER_BRANCHES"))


func _on_InfiniteResearch_mouse_entered():
	game.show_tooltip(tr("INFINITE_RESEARCH"))


func _on_MainBranch_pressed():
	$Panel/MainBranch/TextureRect.modulate = Color.GREEN
	$Panel/OtherBranches/TextureRect.modulate = Color.WHITE
	$Panel/InfiniteResearch/TextureRect.modulate = Color.WHITE
	sc_tree.get_node("%sAnim" % sc_tree.sc_type).play_backwards("Fade")
	sc_tree.sc_type = "Main"


func _on_OtherBranches_pressed():
	$Panel/MainBranch/TextureRect.modulate = Color.WHITE
	$Panel/OtherBranches/TextureRect.modulate = Color.GREEN
	$Panel/InfiniteResearch/TextureRect.modulate = Color.WHITE
	sc_tree.get_node("%sAnim" % sc_tree.sc_type).play_backwards("Fade")
	sc_tree.sc_type = "Other"


func _on_InfiniteResearch_pressed():
	$Panel/MainBranch/TextureRect.modulate = Color.WHITE
	$Panel/OtherBranches/TextureRect.modulate = Color.WHITE
	$Panel/InfiniteResearch/TextureRect.modulate = Color.GREEN
	sc_tree.get_node("%sAnim" % sc_tree.sc_type).play_backwards("Fade")
	sc_tree.sc_type = "IR"
