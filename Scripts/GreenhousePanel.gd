extends "Panel.gd"

onready var hbox = $Seeds/HBox
onready var f_hbox = $Fertilizer/HBox
var p_i:Dictionary
var tile_num:int
var seeds_to_plant:String = ""
var fertilizer:bool
var craft_costs:Dictionary
var c_v:String
var tiles_selected:Array
var sys_au_mult:float = 1.0

func _ready():
	for f in game.seeds_produce:
		var slot = game.slot_scene.instance()
		slot.get_node("TextureRect").texture = load("res://Graphics/Agriculture/" + f + ".png")
		slot.get_node("Button").connect("mouse_entered", self, "on_slot_over", [f])
		slot.get_node("Button").connect("mouse_exited", self, "on_slot_out")
		slot.get_node("Button").connect("pressed", self, "on_slot_press", [f])
		f_hbox.add_child(slot)
	
func refresh():
	$Plant.visible = false
	set_polygon(rect_size)
	if c_v == "system":
		$AuroraMult.visible = true
		var max_star_temp = game.get_max_star_prop(game.c_s, "temperature")
		var au_int = 12000.0 * game.galaxy_data[game.c_g].B_strength * max_star_temp
		sys_au_mult = pow(1 + au_int, Helper.get_AIE())
		$AuroraMult.bbcode_text = "[aurora au_int=%s]%s: %s  %s" % [au_int, tr("AURORA_MULTIPLIER"), Helper.format_num(Helper.clever_round(sys_au_mult, 4)), "[img]Graphics/Icons/help.png[/img]"]
		if game.science_unlocked.has("GHA"):
			$AuroraMult.help_text = "%s\n%s" % [tr("GH_AURORA"), tr("MMM_DESC")]
		else:
			$AuroraMult.help_text = tr("MMM_DESC")
	else:
		$AuroraMult.visible = false
		sys_au_mult = 1.0
	if tile_num == 1:
		$Label.text = tr("GH_NAME")
	else:
		$Label.text = "%s %s" % [Helper.format_num(tile_num), tr("GREENHOUSES").to_lower()]
	for slot in hbox.get_children():
		slot.queue_free()
	for _seed in game.seeds_produce:
		var slot = game.slot_scene.instance()
		slot.get_node("TextureRect").texture = load("res://Graphics/Agriculture/" + _seed + ".png")
		slot.get_node("Button").connect("mouse_entered", self, "on_slot_over", [_seed])
		slot.get_node("Button").connect("mouse_exited", self, "on_slot_out")
		slot.get_node("Button").connect("pressed", self, "on_slot_press", [_seed])
		hbox.add_child(slot)
	calc_prod_per_sec()
	if seeds_to_plant != "":
		on_slot_press(seeds_to_plant)

func on_slot_over (_name:String):
	game.show_tooltip(Helper.get_item_name(_name))

func on_slot_out():
	game.hide_tooltip()

func calc_prod_per_sec():
	var production:Dictionary = {}
	if c_v == "system" and p_i.has("auto_GH"):
		production = {"cellulose":-p_i.auto_GH.cellulose_drain}
		for p in p_i.auto_GH.produce:
			production[p] = p_i.auto_GH.produce[p]
	elif c_v == "planet":
		for tile in tiles_selected:
			if game.tile_data[tile].has("auto_GH"):
				var tile_p:Dictionary = game.tile_data[tile].auto_GH
				for p in tile_p.produce:
					production.cellulose = production.get("cellulose", 0.0) -tile_p.cellulose_drain
					production[p] = tile_p.produce[p] + production.get(p, 0.0)
	Helper.put_rsrc($HBoxContainer, 32, production)
	$ProductionPerSec.visible = $HBoxContainer.get_child_count() != 0

func set_auto_harvest(obj:Dictionary, produce:Dictionary, _name:String, plant_new:bool = true):
	if obj.has("auto_GH"):
		Helper.remove_GH_produce_from_autocollect(obj.auto_GH.produce)
		game.autocollect.mats.cellulose += obj.auto_GH.cellulose_drain
		obj.erase("auto_GH")
	if plant_new:
		var cellulose_drain:float = game.seeds_produce[_name].costs.cellulose * obj.bldg.path_1_value
		if obj.lake_elements.has("CH4"):
			if obj.lake_elements.CH4 == "l":
				cellulose_drain *= 0.6
			elif obj.lake_elements.CH4 == "sc":
				cellulose_drain *= 0.3
			else:
				cellulose_drain *= 0.8
		if obj.lake_elements.has("CO2"):
			if obj.lake_elements.CO2 == "l":
				produce.coal = cellulose_drain * 10
			elif obj.lake_elements.CO2 == "sc":
				produce.coal = cellulose_drain * 15
			else:
				produce.coal = cellulose_drain * 7
		if obj.lake_elements.has("He"):
			if obj.lake_elements.He == "l":
				produce.minerals = cellulose_drain * 150
			elif obj.lake_elements.He == "sc":
				produce.minerals = cellulose_drain * 200
			else:
				produce.minerals = cellulose_drain * 100
		if obj.lake_elements.has("Ne"):
			if obj.lake_elements.Ne == "l":
				produce.quillite = cellulose_drain * 0.2
			elif obj.lake_elements.Ne == "sc":
				produce.quillite = cellulose_drain * 0.3
			else:
				produce.quillite = cellulose_drain * 0.1
		Helper.add_GH_produce_to_autocollect(produce)
		if c_v == "system":
			cellulose_drain *= 2 * tile_num
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
			produce[p] *= 2.0 * tile_num * game.u_i.time_speed * 1000.0 * p_i.bldg.path_1_value * p_i.bldg.path_2_value * pow(sys_au_mult, 2.0)
		set_auto_harvest(p_i, produce, _name, not p_i.has("auto_GH"))
	elif c_v == "planet":
		for tile_id in tiles_selected:
			var produce:Dictionary = game.seeds_produce[_name].produce.duplicate(true)
			var tile:Dictionary = game.tile_data[tile_id]
			for p in produce:
				produce[p] *= game.u_i.time_speed * tile.bldg.path_1_value * tile.bldg.path_2_value * Helper.get_H2O_mult(tile)
				produce[p] *= Helper.get_au_mult(tile)
			set_auto_harvest(tile, produce, _name, not tile.has("auto_GH"))
	calc_prod_per_sec()
