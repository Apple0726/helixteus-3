extends "Panel.gd"

onready var hbox = $ScrollContainer/HBox
var p_i:Dictionary
var tile_num:int
var seeds_to_plant:String
var fertilizer:bool

func refresh():
	$Plant.visible = false
	seeds_to_plant = ""
	$CostLabel.text = ""
	set_polygon(rect_size)
	$Label.text = "%s %s" % [tile_num, tr("GREENHOUSES").to_lower()]
	for slot in hbox.get_children():
		hbox.remove_child(slot)
		slot.queue_free()
	for _seed in game.craft_agriculture_info:
		if not fertilizer and game.craft_agriculture_info[_seed].has("produce") or fertilizer and game.craft_agriculture_info[_seed].has("speed_up_time"):
			var num:int = game.get_item_num(_seed)
			if num == 0:
				continue
			var slot = game.slot_scene.instance()
			slot.get_node("Label").text = String(num)
			slot.get_node("TextureRect").texture = load("res://Graphics/Agriculture/" + _seed + ".png")
			slot.get_node("Button").connect("mouse_entered", self, "on_slot_over", [_seed])
			slot.get_node("Button").connect("mouse_exited", self, "on_slot_out")
			slot.get_node("Button").connect("pressed", self, "on_slot_press", [_seed])
			hbox.add_child(slot)
	if fertilizer:
		$Plant.text = tr("USE")
	else:
		$Plant.text = tr("PLANT_V")
	if len(hbox.get_children()) == 0:
		if fertilizer:
			$CostLabel.text = tr("NO_FERTILIZERS")
		else:
			$CostLabel.text = tr("NO_SEEDS")
			

func on_slot_over (_name:String):
	game.show_tooltip(Helper.get_item_name(_name))

func on_slot_out():
	game.hide_tooltip()

func on_slot_press(_name:String):
	seeds_to_plant = _name
	$Plant.visible = true
	$CostLabel.text = tr("YOU_WILL_NEED_X_SEEDS").format({"num":tile_num, "seeds":tr("X_SEEDS") % tr(seeds_to_plant.split("_")[0].to_upper()).to_lower()})

func _on_Plant_pressed():
	if game.get_item_num(seeds_to_plant) >= tile_num:
		game.remove_items(seeds_to_plant, tile_num)
		var curr_time = OS.get_system_time_msecs()
		if fertilizer:
			p_i.plant.plant_date -= game.craft_agriculture_info[seeds_to_plant].speed_up_time
			if curr_time > p_i.plant.plant_date + p_i.plant.grow_time:
				_on_close_button_pressed()
			game.popup("FERTILIZERS_USED", 1.5)
		else:
			p_i.plant = {}
			p_i.plant.name = seeds_to_plant
			p_i.plant.plant_date = curr_time
			p_i.plant.grow_time = game.craft_agriculture_info[seeds_to_plant].grow_time
			if p_i.has("bldg") and p_i.bldg.name == "GH":
				p_i.plant.grow_time /= p_i.bldg.path_1_value
			p_i.plant.grow_time /= 2
			p_i.plant.is_growing = true
			game.view.obj.refresh_planets()
			game.get_node("PlantingSounds/%s" % [Helper.rand_int(1,3)]).play()
			_on_close_button_pressed()
