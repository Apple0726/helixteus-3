extends Node2D

onready var game = get_node('/root/Game')
var sc_over:String = ""
var sc_type:String = "Main"

func _ready():
	yield(get_tree().create_timer(0), "timeout")
	refresh()

func refresh():
	for sc in get_node(sc_type).get_children():
		if not sc is Line2D and not sc is Node2D and not Data.science_unlocks.has(sc.name):
			continue
		if sc.get_script():#A way of checking whether the node is a button
			var p_scs:Array = Data.science_unlocks[sc.name].parents
			sc.main_tree = self
			#parent_science
			if p_scs.empty():
				continue
			var available:bool = true
			for p_sc in p_scs:
				if not game.science_unlocked.has(p_sc):
					available = false
					break
			if available:
				sc.modulate = Color.white
				sc.get_node("Texture").modulate = Color.white
				sc.mouse_filter = Control.MOUSE_FILTER_PASS
			else:
				sc.modulate = Color(0.5, 0.5, 0.5, 1)
				sc.get_node("Texture").modulate = Color.black
				sc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sc.is_over = false
			sc.refresh()
		else:
			var sc_to:String = sc.name.split("_")[1]#The science the line points to
			if game.science_unlocked.has(sc_to):
				if sc is Line2D:
					sc.default_color = Color(0.4, 1.0, 0.46, 1)
				elif sc is Node2D:
					for line in sc.get_children():
						line.default_color = Color(0.4, 1.0, 0.46, 1)
			else:
				if sc is Line2D:
					sc.default_color = Color(0, 0.33, 0, 1)
				elif sc is Node2D:
					for line in sc.get_children():
						line.default_color = Color(0, 0.33, 0, 1)

func _on_ScienceTree_tree_exited():
	queue_free()


func _on_IRAnim_animation_finished(anim_name):
	if $IR.modulate.a == 0:
		$IR.visible = false
		get_node(sc_type).visible = true
		get_node("%sAnim" % sc_type).play("Fade")
		refresh()


func _on_MainAnim_animation_finished(anim_name):
	if $Main.modulate.a == 0:
		$Main.visible = false
		get_node(sc_type).visible = true
		get_node("%sAnim" % sc_type).play("Fade")
		refresh()


func _on_OtherAnim_animation_finished(anim_name):
	if $Other.modulate.a == 0:
		$Other.visible = false
		get_node(sc_type).visible = true
		get_node("%sAnim" % sc_type).play("Fade")
		refresh()
