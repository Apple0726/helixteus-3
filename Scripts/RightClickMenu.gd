extends PanelContainer

var items:Array
var button_hovered = false

func _ready():
	for btn in $VBoxContainer.get_children():
		btn.queue_free()
	for item in items:
		if not item.has("button_text") or not item.has("button_callable"):
			continue
		var button = Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = item.button_text
		button.mouse_entered.connect(func() : button_hovered = true)
		button.mouse_exited.connect(func() : button_hovered = false)
		button.pressed.connect(item.button_callable)
		button.pressed.connect(queue_free)
		$VBoxContainer.add_child(button)

func _input(event):
	if event is InputEventKey or Input.is_action_just_pressed("left_click") and not button_hovered:
		queue_free()
