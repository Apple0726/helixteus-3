extends Control

@onready var game = get_node("/root/Game")

func _ready():
	set_process_input(false)

func refresh():
	for btn in $Panel/ScrollContainer/VBoxContainer.get_children():
		btn.queue_free()
	var stars:Array = game.system_data[game.c_s].stars
	for i in len(stars):
		var btn = preload("res://Scenes/StarButton.tscn").instantiate()
		btn.set_star_info(stars[i].type, stars[i]["class"], stars[i].temperature, stars[i].size, stars[i].mass, stars[i].luminosity)
		$Panel/ScrollContainer/VBoxContainer.add_child(btn)
		btn.get_node("MS").visible = stars[i].has("MS")
		btn.get_node("MS").mouse_entered.connect(game.show_tooltip.bind(tr("STAR_HAS_MS")))
		btn.get_node("MS").mouse_exited.connect(game.hide_tooltip)
		btn.mouse_entered.connect(game.view.obj.show_MS_construct_info.bind(stars[i]))
		btn.mouse_exited.connect(game.view.obj.on_btn_out)
		btn.pressed.connect(self.zoom_to_star.bind(stars[i]))
		btn.pressed.connect(game.view.obj.on_star_pressed.bind(i))

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
