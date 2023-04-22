extends Panel

var keys:Array = []
var center_position:Vector2
var tween

func _ready():
	modulate.a = 0
	tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	refresh()

func refresh():
	for key in $KeyInfo.get_children():
		key.queue_free()
	for key in $Keys.get_children():
		key.queue_free()
	for key in keys:
		var label = preload("res://Scenes/Key.tscn").instantiate()
		label.text = key.name
		$Keys.add_child(label)
		var label2 = Label.new()
		label2.custom_minimum_size.y = 32
		label2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label2.text = tr(key.desc)
		$KeyInfo.add_child(label2)

func add_key(_name:String, desc:String):
	keys.append({"name":_name, "desc":desc})

func remove_key(_name:String):
	for i in len(keys):
		if keys[i].name == _name:
			keys.remove_at(i)
			break

func _on_Keys_resized():
	$KeyInfo.position.x = $Keys.position.x + $Keys.size.x + 30
	size.x = max($Keys.position.x + $Keys.size.x + $KeyInfo.size.x + 40, $Label.size.x)
	size.y = $Keys.size.y + 52
	position.x = center_position.x - size.x / 2.0
	position.y = center_position.y - size.y / 2.0


func _on_Panel_mouse_entered():
	modulate.a = 0.2


func _on_Panel_mouse_exited():
	modulate.a = 1.0

func close():
	name = "BuildingShortcutsClosing"
	tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.1)
	await tween.finished
	queue_free()
