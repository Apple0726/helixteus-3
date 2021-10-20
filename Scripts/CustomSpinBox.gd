extends LineEdit

export var step:float = 0.1
export var value:float = 0.0

func _on_Up_pressed():
	if editable:
		if Input.is_action_pressed("shift"):
			text = String(stepify(value + step * 10.0, step))
			value = stepify(value + step * 10.0, step)
		else:
			text = String(stepify(value + step, step))
			value = stepify(value + step, step)

func _on_Down_pressed():
	if editable:
		if Input.is_action_pressed("shift"):
			text = String(stepify(value - step * 10.0, step))
			value = stepify(value - step * 10.0, step)
		else:
			text = String(stepify(value - step, step))
			value = stepify(value - step, step)

func _on_CustomSpinBox_text_changed(new_text):
	value = float(new_text)

func set_value(_value:float):
	value = _value
	text = String(_value)
