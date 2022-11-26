extends LineEdit

export var step:float = 0.1
export var value:float = 0.0
export var min_value:float = 0.0
export var max_value:float = INF
export var is_integer:bool = false

func _on_Up_pressed():
	if editable:
		var new_value:float
		if Input.is_action_pressed("shift"):
			new_value = min(stepify(value + step * 10.0, step), max_value)
		else:
			new_value = min(stepify(value + step, step), max_value)
		text = String(new_value)
		value = new_value

func _on_Down_pressed():
	if editable:
		var new_value:float
		if Input.is_action_pressed("shift"):
			new_value = max(stepify(value - step * 10.0, step), min_value)
		else:
			new_value = max(stepify(value - step, step), min_value)
		text = String(new_value)
		value = new_value

func _on_CustomSpinBox_text_changed(new_text):
	var new_value = clamp(float(new_text), min_value, max_value)
	if is_integer:
		new_value = round(new_value)
	value = new_value

func set_value(_value:float):
	value = _value
	text = String(_value)
