extends "Panel.gd"

@onready var hbox = $Seeds/HBox
@onready var f_hbox = $Fertilizer/HBox
var p_i:Dictionary
var tile_num:int
var seeds_to_plant:String = ""
var fertilizer:bool
var craft_costs:Dictionary
var c_v:String
var tiles_selected:Array

func _ready():
	for f in game.seeds_produce:
		var slot = game.slot_scene.instantiate()
		slot.get_node("TextureRect").texture = load("res://Graphics/Agriculture/" + f + ".png")
		slot.get_node("Button").connect("mouse_entered",Callable(self,"on_slot_over").bind(f))
		slot.get_node("Button").connect("mouse_exited",Callable(self,"on_slot_out"))
		slot.get_node("Button").connect("pressed",Callable(self,"on_slot_press").bind(f))
		f_hbox.add_child(slot)
	
func refresh():
	$UseFertilizer.visible = game.science_unlocked.has("PF")
	$Plant.visible = false
	set_polygon(size)
	if tile_num == 1:
		$Label.text = tr("GH_NAME")
	else:
		$Label.text = "%s %s" % [Helper.format_num(tile_num), tr("GREENHOUSES").to_lower()]
	for slot in hbox.get_children():
		slot.queue_free()
	for _seed in game.seeds_produce:
		var slot = game.slot_scene.instantiate()
		slot.get_node("TextureRect").texture = load("res://Graphics/Agriculture/" + _seed + ".png")
		slot.get_node("Button").connect("mouse_entered",Callable(self,"on_slot_over").bind(_seed))
		slot.get_node("Button").connect("mouse_exited",Callable(self,"on_slot_out"))
		slot.get_node("Button").connect("pressed",Callable(self,"on_slot_press").bind(_seed))
		hbox.add_child(slot)
	calc_prod_per_sec()
	if seeds_to_plant != "":
		on_slot_press(seeds_to_plant)

func on_slot_over (_name:String):
	game.show_tooltip(Helper.get_item_name(_name))

func on_slot_out():
	game.hide_tooltip()

var calculating = false# Used to prevent _on_UseFertilizer_toggled from firing when setting button state manually

func calc_prod_per_sec():
	calculating = true
	var production:Dictionary = {}
	if c_v == "system" and p_i.has("auto_GH"):
		production = {"cellulose":-p_i.auto_GH.cellulose_drain}
		for p in p_i.auto_GH.produce:
			production[p] = p_i.auto_GH.produce[p]
		if p_i.auto_GH.has("soil_drain"):
			$UseFertilizer.button_pressed = true
			production.soil = production.get("soil", 0.0) - p_i.auto_GH.soil_drain
	elif c_v == "planet":
		for tile in tiles_selected:
			if game.tile_data[tile].has("auto_GH"):
				var tile_p:Dictionary = game.tile_data[tile].auto_GH
				production.cellulose = production.get("cellulose", 0.0) - tile_p.cellulose_drain
				if tile_p.has("soil_drain"):
					$UseFertilizer.button_pressed = true
					production.soil = production.get("soil", 0.0) - tile_p.soil_drain
				for p in tile_p.produce:
					production[p] = tile_p.produce[p] * (Helper.get_au_mult(game.tile_data[tile]) if p in game.met_info.keys() else 1.0) + production.get(p, 0.0)
	Helper.put_rsrc($HBoxContainer, 32, production)
	$ProductionPerSec.visible = $HBoxContainer.get_child_count() != 0
	calculating = false

func set_auto_harvest(obj:Dictionary, produce:Dictionary, _name:String, plant_new:bool = true):
	if obj.has("auto_GH"):
		Helper.remove_GH_produce_from_autocollect(obj.auto_GH.produce, obj.aurora.au_int if obj.has("aurora") else 0.0)
		game.autocollect.mats.cellulose += obj.auto_GH.cellulose_drain
		if obj.auto_GH.has("soil_drain"):
			game.autocollect.mats.soil += obj.auto_GH.soil_drain
		obj.erase("auto_GH")
	if plant_new:
		var cellulose_drain:float = game.seeds_produce[_name].costs.cellulose * obj.bldg.path_1_value * game.biology_bonus.PGSM
		if c_v == "system":
			cellulose_drain *= tile_num
		else:
			if obj.lake_elements.has("CH4"):
				cellulose_drain *= Data.lake_bonus_values.CH4[obj.lake_elements.CH4] / game.biology_bonus.CH4
			if obj.lake_elements.has("CO2"):
				produce.coal = cellulose_drain * Data.lake_bonus_values.CO2[obj.lake_elements.CO2] * game.biology_bonus.CO2
			if obj.lake_elements.has("He"):
				produce.minerals = cellulose_drain * Data.lake_bonus_values.He[obj.lake_elements.He] * game.biology_bonus.He
			if obj.lake_elements.has("Ne"):
				produce.quillite = cellulose_drain * Data.lake_bonus_values.Ne[obj.lake_elements.Ne] * game.biology_bonus.Ne
		Helper.add_GH_produce_to_autocollect(produce, obj.aurora.au_int if obj.has("aurora") else 0.0)
		obj.auto_GH = {
			"produce":produce,
			"cellulose_drain":cellulose_drain,
			"seed":_name,
		}
		game.autocollect.mats.cellulose = game.autocollect.mats.get("cellulose", 0.0) - obj.auto_GH.cellulose_drain

func on_slot_press(_name:String):
	if c_v == "system":
		var produce:Dictionary = game.seeds_produce[_name].produce.duplicate(true)
		for p in produce:
			produce[p] *= tile_num * game.u_i.time_speed * game.u_i.planck * p_i.bldg.path_1_value * p_i.bldg.path_2_value * game.biology_bonus.PGSM * game.biology_bonus.PYM * (p_i.ash.richness if p_i.has("ash") else 1.0)
		set_auto_harvest(p_i, produce, _name, not p_i.has("auto_GH"))
	elif c_v == "planet":
		var harvest:bool = false
		for tile_id in tiles_selected:
			var tile:Dictionary = game.tile_data[tile_id]
			if tile.has("auto_GH"):
				harvest = true
				break
		for tile_id in tiles_selected:
			var tile:Dictionary = game.tile_data[tile_id]
			if tile.bldg.has("is_constructing"):
				continue
			var produce:Dictionary = game.seeds_produce[_name].produce.duplicate(true)
			var H2O_mult = (Data.lake_bonus_values.H2O[tile.lake_elements.H2O] * game.biology_bonus.H2O) if tile.lake_elements.has("H2O") else 1.0
			for p in produce:
				produce[p] *= game.u_i.time_speed * game.u_i.planck * tile.bldg.path_1_value * tile.bldg.path_2_value * game.biology_bonus.PGSM * game.biology_bonus.PYM * H2O_mult * (tile.ash.richness if tile.has("ash") else 1.0)
			if harvest:
				if tile.has("auto_GH") and tile.auto_GH.has("soil_drain"):
					game.view.obj.bldgs[tile_id].get_node("Fertilizer").queue_free()
				game.view.obj.rsrcs[tile_id].set_icon_texture(null)
			else:
				game.view.obj.rsrcs[tile_id].set_icon_texture(load("res://Graphics/Metals/%s.png" % _name.split("_")[0]))
			set_auto_harvest(tile, produce, _name, not harvest)
	if $UseFertilizer.button_pressed:
		_on_UseFertilizer_toggled(true)
	calc_prod_per_sec()


func _on_UseFertilizer_toggled(button_pressed):
	if calculating:
		return
	if c_v == "planet":
		if button_pressed:
			for tile_id in tiles_selected:
				var tile:Dictionary = game.tile_data[tile_id]
				var au_mult = Helper.get_au_mult(tile)
				if tile.has("auto_GH") and not tile.auto_GH.has("soil_drain"):
					var fert_mult = (Data.lake_bonus_values.O[tile.lake_elements.O] * game.biology_bonus.O) if tile.lake_elements.has("O") else 1.0
					var fert_cost_mult = (Data.lake_bonus_values.NH3[tile.lake_elements.NH3] / game.biology_bonus.NH3) if tile.lake_elements.has("NH3") else 1.0
					for p in tile.auto_GH.produce:
						if p in game.met_info.keys():
							var add_amount = tile.auto_GH.produce[p] * (0.5 * fert_mult) * au_mult
							game.autocollect.mets[p] += add_amount
							if tile.has("aurora"):
								game.aurora_prod[tile.aurora.au_int][p] += add_amount
							tile.auto_GH.produce[p] *= 1.0 + 0.5 * fert_mult
						else:
							game.autocollect.mats[p] += tile.auto_GH.produce[p] * (0.5 * fert_cost_mult)
							tile.auto_GH.produce[p] *= 1.0 + 0.5 * fert_cost_mult
					tile.auto_GH.soil_drain = tile.auto_GH.cellulose_drain * 0.5 * fert_cost_mult
					game.autocollect.mats.soil = game.autocollect.mats.get("soil", 0) - tile.auto_GH.soil_drain
					game.autocollect.mats.cellulose -= tile.auto_GH.cellulose_drain * 0.5 * fert_cost_mult
					tile.auto_GH.cellulose_drain *= 1.0 + 0.5 * fert_cost_mult
					var fert = Sprite2D.new()
					fert.texture = preload("res://Graphics/Agriculture/fertilizer.png")
					game.view.obj.bldgs[tile_id].add_child(fert)
					fert.name = "Fertilizer"
		else:
			for tile_id in tiles_selected:
				var tile:Dictionary = game.tile_data[tile_id]
				var au_mult = Helper.get_au_mult(tile)
				if tile.has("auto_GH") and tile.auto_GH.has("soil_drain"):
					var fert_mult = (Data.lake_bonus_values.O[tile.lake_elements.O] * game.biology_bonus.O) if tile.lake_elements.has("O") else 1.0
					var fert_cost_mult = (Data.lake_bonus_values.NH3[tile.lake_elements.NH3] / game.biology_bonus.NH3) if tile.lake_elements.has("NH3") else 1.0
					for p in tile.auto_GH.produce:
						if p in game.met_info.keys():
							tile.auto_GH.produce[p] /= 1.0 + 0.5 * fert_mult
							var subtr_amount = tile.auto_GH.produce[p] * (0.5 * fert_cost_mult) * au_mult
							if tile.has("aurora"):
								game.aurora_prod[tile.aurora.au_int][p] -= subtr_amount
							game.autocollect.mets[p] -= subtr_amount
						else:
							tile.auto_GH.produce[p] /= 1.0 + 0.5 * fert_cost_mult
							game.autocollect.mats[p] -= tile.auto_GH.produce[p] * (0.5 * fert_cost_mult)
					tile.auto_GH.cellulose_drain /= 1.0 + 0.5 * fert_cost_mult
					game.autocollect.mats.soil += tile.auto_GH.soil_drain
					tile.auto_GH.erase("soil_drain")
					game.view.obj.bldgs[tile_id].get_node("Fertilizer").queue_free()
					game.autocollect.mats.cellulose += tile.auto_GH.cellulose_drain * 0.5 * fert_cost_mult
	else:
		if p_i.has("auto_GH"):
			if button_pressed and not p_i.auto_GH.has("soil_drain"):
				for p in p_i.auto_GH.produce:
					if p in game.met_info.keys():
						var add_amount = p_i.auto_GH.produce[p] * 0.5
						game.autocollect.mets[p] += add_amount
						p_i.auto_GH.produce[p] *= 1.5
					else:
						game.autocollect.mats[p] += p_i.auto_GH.produce[p] * 0.5
						p_i.auto_GH.produce[p] *= 1.5
				p_i.auto_GH.soil_drain = p_i.auto_GH.cellulose_drain * 0.5
				game.autocollect.mats.soil = game.autocollect.mats.get("soil", 0) - p_i.auto_GH.soil_drain
				game.autocollect.mats.cellulose -= p_i.auto_GH.cellulose_drain * 0.5
				p_i.auto_GH.cellulose_drain *= 1.5
			elif not button_pressed and p_i.auto_GH.has("soil_drain"):
				for p in p_i.auto_GH.produce:
					if p in game.met_info.keys():
						p_i.auto_GH.produce[p] /= 1.5
						var subtr_amount = p_i.auto_GH.produce[p] * 0.5
						game.autocollect.mets[p] -= subtr_amount
					else:
						p_i.auto_GH.produce[p] /= 1.5
						game.autocollect.mats[p] -= p_i.auto_GH.produce[p] * 0.5
				p_i.auto_GH.cellulose_drain /= 1.5
				game.autocollect.mats.soil += p_i.auto_GH.soil_drain
				p_i.auto_GH.erase("soil_drain")
				game.autocollect.mats.cellulose += p_i.auto_GH.cellulose_drain * 0.5
	calc_prod_per_sec()


func _on_UseFertilizer_mouse_entered():
	game.show_tooltip("FERTILIZER_DESC")


func _on_mouse_exited():
	game.hide_tooltip()
