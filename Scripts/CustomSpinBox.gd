extends LineEdit

signal value_changed

@export var step:float = 0.1
@export var value:float = 0.0
@export var min_value:float = 0.0
@export var max_value:float = INF
@export var is_integer:bool = false

func _on_Up_pressed():
	if editable:
		var new_value:float
		if Input.is_action_pressed("shift"):
			new_value = min(snapped(value + step * 10.0, step), max_value)
		else:
			new_value = min(snapped(value + step, step), max_value)
		text = str(new_value)
		value = new_value
		emit_signal("value_changed", new_value)

func _on_Down_pressed():
	if editable:
		var new_value:float
		if Input.is_action_pressed("shift"):
			new_value = max(snapped(value - step * 10.0, step), min_value)
		else:
			new_value = max(snapped(value - step, step), min_value)
		text = str(new_value)
		value = new_value
		emit_signal("value_changed", new_value)

func _on_CustomSpinBox_text_changed(new_text):
	var new_value = clamp(float(new_text), min_value, max_value)
	if is_integer:
		new_value = round(new_value)
	emit_signal("value_changed", new_value)
	value = new_value
	if float(new_text) != new_value:
		text = str(new_value)
		caret_column = len(text)

func set_value(_value:float):
	value = _value
	text = str(_value)
