extends "Panel.gd"

var target:Dictionary = {}
var p_id:int
var star:Dictionary
var planet_btn_scene = preload("res://Scenes/PlanetData.tscn")
var additional_energy:float
var charging_time:float
var rekt_planet:bool = false
var rsrc:Dictionary

func _ready():
	set_process(false)
	set_polygon($Background.rect_size)

func select_planet(p_i:Dictionary, id:int, btn):
	for child in $Scroll/Planets.get_children():
		if child != btn:
			child.pressed = false
	if star.has("charging_time"):
		return
	p_id = id
	target = p_i
	refresh_planet_info()

func refresh():
	for child in $Scroll/Planets.get_children():
		$Scroll/Planets.remove_child(child)
		child.free()
	for i in len(game.planet_data):
		var p_i = game.planet_data[i]
		if p_i.empty():
			continue
		var btn = planet_btn_scene.instance()
		$Scroll/Planets.add_child(btn)
		btn.get_node("HBoxContainer/TextureRect").texture = game.planet_textures[p_i.type - 3]
		btn.get_node("HBoxContainer/Diameter").text = "%s km" % [p_i.size]
		btn.get_node("HBoxContainer/Distance").text = "%s AU" % [Helper.clever_round(p_i.distance / 569.25, 3)]
		btn.connect("pressed", self, "select_planet", [p_i, i, btn])
	if star.has("charging_time"):
		target = game.planet_data[star.p_id]
		set_process(true)
		$Control.visible = false
		$Control2.visible = true
	else:
		set_process(false)
		$Control.visible = true
		$Control2.visible = false

func refresh_planet_info():
	var value = $Control/HSlider.value
	var cost = pow(target.size / 10000.0, 3) * 10000
	var time_base = cost / star.luminosity * 50
	charging_time = time_base * (1 - value)
	additional_energy = 100000000000000 * time_base * value
	$Control.visible = true
	$StartCharging.visible = true
	$Control/EnergyCost.text = Helper.format_num(additional_energy)
	charging_time *= 1800 / 10.0
	if charging_time <= 1000:
		charging_time = 1000
	$Control/TimeCost.text = Helper.time_to_str(charging_time)
	var R = target.size * 1000.0 / 2#in meters
	var surface_volume = get_sph_V(R, R - target.crust_start_depth)#in m^3
	var crust_volume = get_sph_V(R - target.crust_start_depth, R - target.mantle_start_depth)
	var mantle_volume = get_sph_V(R - target.mantle_start_depth, R - target.core_start_depth)
	var core_volume = get_sph_V(R - target.core_start_depth)
	var stone = {}
	add_stone(stone, target.crust, (surface_volume + crust_volume) * ((5600 + target.mantle_start_depth * 0.01) / 2.0))
	add_stone(stone, target.mantle, mantle_volume * ((5690 + (target.mantle_start_depth + target.core_start_depth) * 0.01) / 2.0))
	add_stone(stone, target.core, core_volume * ((5700 + (target.core_start_depth + R) * 0.01) / 2.0))
	rsrc = {"stone":stone}
	for mat in target.surface:
		rsrc[mat] = surface_volume * target.surface[mat].chance * target.surface[mat].amount
	for met in game.met_info:
		rsrc[met] = get_sph_V(R - game.met_info[met].min_depth, R - game.met_info[met].max_depth) * 0.425 * game.met_info[met].amount / game.met_info[met].rarity
	Helper.put_rsrc($Control/ScrollContainer/GridContainer, 36, rsrc)

#get_sphere_volume
func get_sph_V(outer:float, inner:float = 0):
	outer /= 200.0#I have to reduce the size of planets otherwise it's too OP
	inner /= 200.0
	return 4/3.0 * PI * (pow(outer, 3) - pow(inner, 3))

func add_stone(stone:Dictionary, layer:Dictionary, amount:float):
	for comp in layer:
		if stone.has(comp):
			stone[comp] += layer[comp] * amount
		else:
			stone[comp] = layer[comp] * amount

func _on_HSlider_value_changed(value):
	refresh_planet_info()


func _on_StartCharging_pressed():
	if rekt_planet:
		if game.c_v != "system":
			return
		game.popup(tr("PLANET_REKT") % target.name, 2.5)
		var dir = Directory.new()
		if dir.file_exists("user://Save1/Planets/%s.hx3" % target.id):
			dir.remove("user://Save1/Planets/%s.hx3" % target.id)
		target.clear()
		game.view.obj.refresh_planets()
		game.toggle_panel(self)
		game.add_resources(star.rsrc)
		star.erase("charging_time")
		star.erase("charge_start_date")
		star.erase("p_id")
		star.erase("rsrc")
		set_process(false)
		rekt_planet = false
		game.HUD.refresh()
	elif star.has("charging_time"):
		star.erase("charging_time")
		star.erase("charge_start_date")
		$Control.visible = true
		$Control2.visible = false
		set_process(false)
		$StartCharging.text = tr("START_CHARGING")
	elif star.MS_lv == 0 and target.size <= 3000 or star.MS_lv == 1 and target.size <= 30000 or star.MS_lv == 2:
		if game.energy >= additional_energy:
			game.energy -= additional_energy
			star.charge_start_date = OS.get_system_time_msecs()
			star.charging_time = charging_time
			star.p_id = p_id
			star.rsrc = rsrc.duplicate(true)
			$Control.visible = false
			$Control2.visible = true
			$StartCharging.text = tr("CANCEL_CHARGING")
			set_process(true)
		else:
			game.popup(tr("NOT_ENOUGH_ENERGY"), 1.5)
	else:
		game.popup(tr("PLANET_TOO_OP"), 2.0)

func _process(delta):
	var curr_time = OS.get_system_time_msecs()
	var start_date = star.charge_start_date
	var length = star.charging_time
	var progress = (curr_time - start_date) / float(length)
	$Control2/TimeCost.text = Helper.time_to_str(length - (curr_time - start_date))
	$Control2/TextureProgress.value = progress
	if progress <= 0.5:
		$Control2/Charging.text = tr("PK_CHARGING_MESSAGE_1")
	elif progress <= 0.9:
		$Control2/Charging.text = tr("PK_CHARGING_MESSAGE_2")
	elif progress <= 1:
		$Control2/Charging.text = tr("PK_CHARGING_MESSAGE_3")
	elif progress >= 1:
		$Control2/TimeCost.text = ""
		$Control2/Charging.text = tr("PLANET_READY_TO_BE_REKT") % target.name
		set_process(false)
		$StartCharging.text = tr("FIRE")
		rekt_planet = true
