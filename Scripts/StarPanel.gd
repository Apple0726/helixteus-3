extends Control

@onready var game = get_node("/root/Game")

func refresh():
	for btn in $Panel/ScrollContainer/VBoxContainer.get_children():
		btn.queue_free()
	var stars:Array = game.system_data[game.c_s].stars
	for i in len(stars):
		var btn = preload("res://Scenes/StarButton.tscn").instantiate()
		btn.set_star_info(stars[i].type, stars[i]["class"], stars[i].temperature, stars[i].size, stars[i].mass, stars[i].luminosity)
		$Panel/ScrollContainer/VBoxContainer.add_child(btn)
		btn.pressed.connect(self.zoom_to_star.bind(stars[i]))

var tween

func zoom_to_star(star:Dictionary):
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	var final_scale:float = min(200.0, 5.0 / star.size / game.view.obj.scale_mult)
	tween.tween_property(game.view, "scale", Vector2.ONE * final_scale, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(game.view, "position", Vector2(640, 360) - star.pos * final_scale * game.view.obj.scale_mult, 1.0).set_trans(Tween.TRANS_CUBIC)
	

func _input(event):
	if visible and (Input.is_action_just_released("cancel") or Input.is_action_just_released("right_click")):
		hide_panel()

func _unhandled_input(event):
	if Input.is_action_just_released("left_click") and visible:
		hide_panel()

func hide_panel():
	if not $AnimationPlayer.is_playing():
		$AnimationPlayer.play_backwards("Fade")
		game.block_scroll = false


func _on_animation_player_animation_finished(anim_name):
	if $Panel.modulate.a == 0.0:
		visible = false
