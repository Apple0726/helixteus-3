extends Control

@onready var game = get_node("/root/Game")
var selected_MS:String = ""

func _ready():
	set_process_input(false)

func refresh():
	for btn in $Panel/ScrollContainer/VBoxContainer.get_children():
		btn.queue_free()
	var stars:Array = game.system_data[game.c_s].stars
	for i in len(stars):
		var star:Dictionary = stars[i]
		var btn = preload("res://Scenes/StarButton.tscn").instantiate()
		btn.set_star_info(star.type, star["class"], star.temperature, star.size, star.mass, star.luminosity)
		$Panel/ScrollContainer/VBoxContainer.add_child(btn)
		btn.get_node("MS").visible = star.has("MS")
		var construct_btn = btn.get_node("Construct")
		var destroy_btn = btn.get_node("Destroy")
		if star.has("repair_cost"):
			construct_btn.text = tr("REPAIR") + " (F)"
		elif star.has("MS"):
			construct_btn.text = tr("UPGRADE") + " (F)"
		else:
			construct_btn.text = tr("CONSTRUCT")
		construct_btn.visible = game.science_unlocked.has("MAE") and selected_MS == ""
		destroy_btn.visible = game.science_unlocked.has("MAE") and star.has("MS")
		if not construct_btn.visible and not destroy_btn.visible:
			btn.custom_minimum_size.y = 100.0
		construct_btn.disabled = not game.system_data[game.c_s].has("conquered")
		destroy_btn.disabled = not game.system_data[game.c_s].has("conquered")
		if game.system_data[game.c_s].has("conquered"):
			construct_btn.pressed.connect(game.space_HUD.toggle_MS_construct_panel.bind(i))
			destroy_btn.pressed.connect(destroy_MS.bind(i))
			if star.MS_lv >= Data.MS_num_stages[star.MS] or not game.science_unlocked.has("{name}{stage}".format({"name":star.MS, "stage":star.MS_lv + 1})):
				construct_btn.disabled = true
				construct_btn.mouse_entered.connect(game.show_tooltip.bind(tr("NO_RESEARCH_TO_UPGRADE_MS")))
				construct_btn.mouse_exited.connect(game.hide_tooltip)
		else:
			construct_btn.mouse_entered.connect(game.show_tooltip.bind(tr("STAR_MS_ERROR")))
			construct_btn.mouse_exited.connect(game.hide_tooltip)
			destroy_btn.mouse_entered.connect(game.show_tooltip.bind(tr("STAR_MS_ERROR")))
			destroy_btn.mouse_exited.connect(game.hide_tooltip)
		btn.get_node("MS").mouse_entered.connect(game.show_tooltip.bind(tr("STAR_HAS_MS")))
		btn.get_node("MS").mouse_exited.connect(game.hide_tooltip)
		var star_node = get_tree().get_nodes_in_group("stars_system")[i]
		btn.mouse_entered.connect(game.view.obj.show_MS_construct_info.bind(star, star_node))
		btn.mouse_exited.connect(game.view.obj.on_star_out.bind(star_node))
		btn.pressed.connect(zoom_to_star.bind(star))
		btn.pressed.connect(game.view.obj.on_star_pressed.bind(i))


func destroy_MS(star_index):
	pass

var tween

func zoom_to_star(star:Dictionary):
	if game.bottom_info_action in ["building_DS", "building_CBS", "building_PK", "building_MB"]:
		return
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	var final_scale:float = min(200.0, 5.0 / star.size / game.view.obj.scale_mult)
	tween.tween_property(game.view, "scale", Vector2.ONE * final_scale, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(game.view, "position", Vector2(640, 360) - star.pos * final_scale * game.view.obj.scale_mult, 1.0).set_trans(Tween.TRANS_CUBIC)
	

func _input(event):
	if event is InputEventMouseMotion:
		var rect:Rect2 = Rect2($Panel.position, $Panel.size)
		game.block_scroll = rect.has_point(event.position)
	if visible and (Input.is_action_just_released("cancel") or Input.is_action_just_released("right_click")):
		hide_panel()

func _unhandled_input(event):
	if Input.is_action_just_released("left_click") and visible:
		hide_panel()

func hide_panel():
	if not $AnimationPlayer.is_playing():
		$AnimationPlayer.play_backwards("Fade")
		set_process_input(false)
		await get_tree().process_frame
		game.block_scroll = false


func _on_animation_player_animation_finished(anim_name):
	if $Panel.modulate.a == 0.0:
		visible = false


func _on_visibility_changed() -> void:
	if visible:
		refresh()
