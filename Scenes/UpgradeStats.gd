extends Panel

func _ready():
	_refresh()

func _refresh():
	for i in self.get_children():
		i.visible = false

func _display_upgrades(id):
	$Label.visible = true
	$Cost.visible = true
	$Boost.visible = true
	$Label2.visible = true
	$Cost2.visible = true
	$Boost2.visible = true
	$Cost.text = "Cost: " + String(get_parent().costs[get_parent().lvs[id]])
	$Boost.text = "Boost: " + String(get_parent().lvs[id] * 10) + "%"
	$Cost2.text = "Cost: " + String(get_parent().costs[(get_parent().lvs[id]) + 1])
	$Boost2.text = "Boost: " + String(((get_parent().lvs[id]) + 1) * 10) + "%"

func _on_Hp_mouse_entered():
	_display_upgrades(0)

func _on_Atk_mouse_entered():
	_display_upgrades(1)

func _on_Def_mouse_entered():
	_display_upgrades(2)

func _on_Acc_mouse_entered():
	_display_upgrades(3)

func _on_Eva_mouse_entered():
	_display_upgrades(4)
