extends ColorRect

func _ready():
	var tween = create_tween()
	tween.tween_property(self, "color", Color(0, 0, 0, 0.4), 0.1)

func set_OK_text(txt:String):
	$Panel/VBoxContainer/HBoxContainer/OK.text = txt

func set_text(txt:String):
	var default_font = preload("res://Resources/default_theme.tres").default_font
	if default_font.get_multiline_string_size(txt).x > 800:
		$Panel/VBoxContainer/Label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		$Panel/VBoxContainer/Label.custom_minimum_size.x = 800
	$Panel/VBoxContainer/Label.text = txt

func set_align(align:int):
	$Panel/VBoxContainer/Label.horizontal_alignment = align

func add_button(btn_str:String, callable):
	var btn = Button.new()
	btn.text = btn_str
	btn.connect("pressed", callable)
	btn.connect("pressed", Callable(self, "_on_ok_pressed"))
	$Panel/VBoxContainer/HBoxContainer.add_child(btn)
	$Panel/VBoxContainer/HBoxContainer.move_child(btn, 0)

func _on_ok_pressed():
	queue_free()
