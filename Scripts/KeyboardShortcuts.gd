extends Panel

var keys:Array = []
var center_position:Vector2

func _ready():
	refresh()

func refresh():
	for key in $KeyInfo.get_children():
		key.queue_free()
	for key in $Keys.get_children():
		key.queue_free()
	for key in keys:
		var label = preload("res://Scenes/Key.tscn").instance()
		label.text = key.name
		$Keys.add_child(label)
		var label2 = Label.new()
		label2.rect_min_size.y = 34
		label2.valign = Label.VALIGN_CENTER
		label2.text = tr(key.desc)
		$KeyInfo.add_child(label2)

func add_key(_name:String, desc:String):
	keys.append({"name":_name, "desc":desc})

func _on_Keys_resized():
	$KeyInfo.rect_position.x = $Keys.rect_position.x + $Keys.rect_size.x + 30
	rect_size.x = max($Keys.rect_position.x + $Keys.rect_size.x + $KeyInfo.rect_size.x + 40, $Label.rect_size.x)
	rect_size.y = $Keys.rect_size.y + 52
	rect_position.x = center_position.x - rect_size.x / 2.0
	rect_position.y = center_position.y - rect_size.y / 2.0


func _on_Panel_mouse_entered():
	modulate.a = 0.2


func _on_Panel_mouse_exited():
	modulate.a = 1.0
