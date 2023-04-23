extends ColorRect
signal confirm

@onready var game = get_node("/root/Game")
@onready var input = $Panel/LineEdit
@export var label_text = ""
@export var error_text = ""
@export var confirm_button_text = "CONFIRM"
var check_input:Callable

func _ready():
	$Panel/Label.text = tr(label_text)
	$Panel/Confirm.text = tr(confirm_button_text)
	var tween = create_tween()
	tween.tween_property(self, "color", Color(0, 0, 0, 0.4), 0.1)

func _on_close_button_pressed():
	visible = false

func _on_confirm_pressed():
	if check_input == null:
		emit_signal("confirm")
		queue_free()
	else:
		if check_input.call($Panel/LineEdit.text):
			emit_signal("confirm")
			queue_free()
		else:
			$Panel/Error.text = error_text
