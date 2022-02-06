extends "Panel.gd"
onready var hbox = $ScrollContainer/HBox
onready var toggle_btn = $HBoxContainer/CheckBox
onready var option_btn = $HBoxContainer/OptionButton

func _ready():
	option_btn.add_item(tr("PLANET_INTERIOR"), 0)
	option_btn.add_item(tr("PLANET_ATMOSPHERE"), 1)
	set_polygon(rect_size, Vector2(0, 308))
	toggle_btn.text = tr("TOGGLE") + " (F3)"
	for atom in game.atoms:
		var slot = preload("res://Scenes/InventorySlot.tscn").instance()
		slot.rect_min_size = Vector2(32, 32)
		slot.name = atom
		slot.get_node("Button").toggle_mode = true
		slot.get_node("TextureRect").texture = load("res://Graphics/Atoms/%s.png" % atom)
		slot.get_node("Button").connect("mouse_entered", self, "on_atom_entered", [tr("%s_NAME" % atom.to_upper())])
		slot.get_node("Button").connect("mouse_exited", self, "on_atom_exited")
		slot.get_node("Button").connect("toggled", self, "on_atom_toggled", [atom, slot.get_node("Border")])
		hbox.add_child(slot)

func on_atom_toggled(pressed:bool, atom:String, border):
	border.visible = pressed
	if not pressed:
		game.view.obj.show_atoms.erase(atom)
	elif not game.view.obj.show_atoms.has(atom):
		game.view.obj.show_atoms.append(atom)
	game.view.obj.refresh_planets()
	
func on_atom_entered(st:String):
	game.show_tooltip(st)

func on_atom_exited():
	game.hide_tooltip()

func _on_CheckBox_toggled(button_pressed):
	game.view.obj.refresh_planets()


func _on_OptionButton_item_selected(index):
	game.view.obj.refresh_planets()

func _on_close_button_pressed():
	visible = false


func _on_LineEdit_text_changed(new_text):
	for atom in hbox.get_children():
		atom.visible = new_text.empty() or new_text.to_lower() in tr("%s_NAME" % atom.name.to_upper()).to_lower()


func _on_LineEdit_focus_entered():
	game.view.move_with_keyboard = false

func _on_LineEdit_focus_exited():
	game.view.move_with_keyboard = true


func _on_LineEdit_text_entered(new_text):
	$LineEdit.release_focus()
