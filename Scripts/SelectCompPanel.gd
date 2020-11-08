extends Panel

onready var game = get_node("/root/Game")
onready var hbox = $HBox
var polygon
var g_cmp:String#armor, wheels, CC (g: general)
var s_cmp:String#lead_armor, copper_wheels etc. (s: specific)

func _ready():
	$CostLabel.text = "%s:" % [tr("COSTS")]
	$Select.text = tr("SELECT") + " (S)"

func refresh(type:String, curr_cmp:String):
	$Label.text = tr("SELECT_X").format({"select":tr("SELECT"), "something":tr(type.split("_")[1].to_upper())})
	for node in hbox.get_children():
		hbox.remove_child(node)
	var dir:String = ""
	if type == "rover_armor":
		dir = "Armor"
	elif type == "rover_wheels":
		dir = "Wheels"
	elif type == "rover_CC":
		dir = "CargoContainer"
	g_cmp = type.split("_")[1]
	s_cmp = curr_cmp
	for cmp in Data[type]:
		var slot = game.slot_scene.instance()
		var metal = tr(cmp.split("_")[0].to_upper())
		slot.get_node("TextureRect").texture = load("res://Graphics/Cave/%s/%s.png" % [dir, cmp])
		slot.get_node("Button").connect("mouse_entered", self, "_on_Slot_mouse_entered", [type, cmp, metal])
		slot.get_node("Button").connect("mouse_exited", self, "_on_Slot_mouse_exited")
		slot.get_node("Button").connect("pressed", self, "_on_Slot_pressed", [type, cmp, slot])
		hbox.add_child(slot)
		if cmp == curr_cmp:
			_on_Slot_pressed(type, cmp, slot)

func _on_Slot_mouse_entered(type:String, cmp:String, metal:String):
	var txt
	var metal_comp:String = tr("METAL_COMP").format({"metal":metal, "comp":tr(g_cmp.to_upper())})
	if type == "rover_armor":
		txt = "%s\n+%s %s" % [metal_comp, Data.rover_armor[cmp].defense, tr("DEFENSE")]
	elif type == "rover_wheels":
		txt = "%s\n+%s %s" % [metal_comp, Data.rover_wheels[cmp].speed, tr("MOVEMENT_SPEED")]
	elif type == "rover_CC":
		txt = "%s\n+%s kg %s" % [metal_comp, Data.rover_CC[cmp].capacity, tr("CARGO_CAPACITY")]
	game.show_tooltip(txt)

func _on_Slot_mouse_exited():
	game.hide_tooltip()

func _on_Slot_pressed(type:String, cmp:String, _slot):
	for slot in $HBox.get_children():
		if slot == _slot and not slot.has_node("border"):
			var border = TextureRect.new()
			border.texture = load("res://Graphics/Cave/SlotBorder.png")
			border.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(border)
			border.name = "border"
		elif slot.has_node("border"):
			slot.remove_child(slot.get_node("border"))
	Helper.put_rsrc($Cost, 42, Data[type][cmp].costs)
	s_cmp = cmp

func _input(event):
	if Input.is_action_just_released("ui_down"):
		set_cmp()

func set_cmp():
	get_parent()[g_cmp] = s_cmp
	get_parent().refresh()
	visible = false

func _on_Select_pressed():
	set_cmp()
