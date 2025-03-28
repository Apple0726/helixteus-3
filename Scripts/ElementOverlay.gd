extends "Panel.gd"
@onready var hbox = $ScrollContainer/HBox
@onready var toggle_btn = $HBoxContainer/ToggleOverlay
@onready var option_btn = $HBoxContainer/OverlayType

func _ready():
	option_btn.add_item(tr("PLANET_INTERIOR"), 0)
	option_btn.add_item(tr("PLANET_ATMOSPHERE"), 1)
	set_polygon(size, Vector2(0, 308))
	toggle_btn.text = tr("TOGGLE") + " (F3)"
	for atom in game.atoms:
		var slot = preload("res://Scenes/InventorySlot.tscn").instantiate()
		slot.custom_minimum_size = Vector2(32, 32)
		slot.name = atom
		slot.get_node("Button").toggle_mode = true
		slot.get_node("TextureRect").texture = load("res://Graphics/Atoms/%s.png" % atom)
		slot.get_node("Button").connect("mouse_entered",Callable(self,"on_atom_entered").bind(tr("%s_NAME" % atom.to_upper())))
		slot.get_node("Button").connect("mouse_exited",Callable(self,"on_atom_exited"))
		slot.get_node("Button").connect("toggled",Callable(self,"on_atom_toggled").bind(atom, slot.get_node("Border")))
		hbox.add_child(slot)

func on_atom_toggled(pressed:bool, atom:String, border):
	border.visible = pressed
	if not pressed:
		game.show_atoms.erase(atom)
	elif not game.show_atoms.has(atom):
		game.show_atoms.append(atom)
	game.view.obj.refresh_planets()
	
func on_atom_entered(st:String):
	game.show_tooltip(st)

func on_atom_exited():
	game.hide_tooltip()


func _on_close_button_pressed():
	visible = false


func _on_LineEdit_text_changed(new_text):
	for atom in hbox.get_children():
		atom.visible = new_text.is_empty() or new_text.to_lower() in tr("%s_NAME" % atom.name.to_upper()).to_lower()


func _on_LineEdit_focus_entered():
	game.view.move_with_keyboard = false

func _on_LineEdit_focus_exited():
	game.view.move_with_keyboard = true


func _on_LineEdit_text_entered(new_text):
	$LineEdit.release_focus()


func _on_overlay_type_item_selected(index):
	game.element_overlay_type = index
	game.view.obj.refresh_planets()


func _on_toggle_overlay_toggled(toggled_on):
	game.element_overlay_enabled = toggled_on
	game.view.obj.refresh_planets()
