extends Control

signal button_pressed
signal double_click
signal button_over
signal button_out
var is_button_over = false
export var double_click_enabled = false
export var strength = 0.1
export var fade_duration = 0.1
var anim_player

#export var btn_text = ""

# Called when the node enters the scene tree for the first time.
#func _ready():
#	var font = $Label.get_font("font")
#	#print(font.get_string_size($Label.text))
#	$Label.text = btn_text
#	$Label.rect_size.x = font.get_string_size($Label.text).x + 5
#	$Label.rect_position.x = -$Label.rect_size.x / 2.0
	#$TextureButton.rect_scale = 


func reset_button ():
	is_button_over = false
	$AnimationPlayer.play_backwards("FadeIn")

func _input(event):
	if event is InputEventMouseButton and Input.is_action_just_pressed("left_click"):
		if double_click_enabled and is_button_over and event.doubleclick:
			emit_signal("double_click")

func _on_TextureButton_mouse_entered():
	is_button_over = true
	anim_player = AnimationPlayer.new()
	self.add_child(anim_player)
	anim_player.name = "AnimationPlayer"
	var fade_in = Animation.new()
	var anim_index = fade_in.add_track(Animation.TYPE_VALUE)
	fade_in.track_set_path(anim_index, "ColorRect:color")
	fade_in.track_insert_key(anim_index, 0, Color(1, 1, 1, 0))
	fade_in.track_insert_key(anim_index, fade_duration, Color(1, 1, 1, strength))
	fade_in.length = fade_duration
	$AnimationPlayer.add_animation("FadeIn", fade_in)
	emit_signal("button_over")
	$AnimationPlayer.play("FadeIn")


func _on_TextureButton_mouse_exited():
	is_button_over = false
	emit_signal("button_out")
	$AnimationPlayer.play_backwards("FadeIn")


func _on_TextureButton_pressed():
	emit_signal("button_pressed")
