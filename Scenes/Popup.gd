extends Control

func init_popup(txt:String, dur:float):
	$Text.text = txt
	var font = $Text.get_font("font")
	font.get_string_size($Text.text)
	$Text.rect_size.x = font.get_string_size($Text.text).x + 30
	$Text.rect_position.x = -$Text.rect_size.x / 2
	if $AnimationPlayer.is_playing():
		$AnimationPlayer.stop()
	if $AnimationPlayer.has_animation("FadeIn"):
		$AnimationPlayer.remove_animation("FadeIn")
	var fade_in = Animation.new()
	var anim_index = fade_in.add_track(Animation.TYPE_VALUE)
	var anim_index2 = fade_in.add_track(Animation.TYPE_VALUE)
	fade_in.track_set_path(anim_index, "Text:rect_position")
	fade_in.track_set_path(anim_index2, "Text:modulate")
	fade_in.track_insert_key(anim_index, 0, Vector2(-$Text.rect_size.x / 2, -12.5))
	fade_in.track_insert_key(anim_index, 0.15, Vector2(-$Text.rect_size.x / 2, -17.5))
	fade_in.track_insert_key(anim_index2, 0, Color(1, 1, 1, 0))
	fade_in.track_insert_key(anim_index2, 0.15, Color(1, 1, 1, 1))
	fade_in.length = 0.15
	$AnimationPlayer.add_animation("FadeIn", fade_in)
	$AnimationPlayer.play("FadeIn")
	$Timer.wait_time = dur + 0.15
	$Timer.start()


func _on_Timer_timeout():
	$AnimationPlayer.play_backwards()
