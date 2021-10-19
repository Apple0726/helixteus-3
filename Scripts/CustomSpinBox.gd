extends LineEdit

export var step:float = 0.1
export var value:float = 0.0

func _on_Up_pressed():
	if editable:
		text = String(stepify(value + step, step))

func _on_Down_pressed():
	if editable:
		text = String(stepify(value - step, step))

func _on_CustomSpinBox_text_changed(new_text):
	value = float(new_text)

func set_value(_value:float):
	value = _value
	text = String(_value)
