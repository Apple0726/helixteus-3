extends "Panel.gd"

var target:Dictionary = {}
var star:Dictionary
var planet_btn_scene = preload("res://Scenes/PlanetData.tscn")
func _ready():
	set_polygon($Background.rect_size)

func select_planet(p_i:Dictionary, btn):
	target = p_i.duplicate(true)
	refresh_planet_info()
	for child in $Scroll/Planets.get_children():
		if child != btn:
			child.pressed = false

func refresh():
	for child in $Scroll/Planets.get_children():
		$Scroll/Planets.remove_child(child)
		child.free()
	for p_i in game.planet_data:
		var btn = planet_btn_scene.instance()
		$Scroll/Planets.add_child(btn)
		btn.get_node("HBoxContainer/TextureRect").texture = game.planet_textures[p_i.type - 3]
		btn.get_node("HBoxContainer/Diameter").text = "%s km" % [p_i.size]
		btn.get_node("HBoxContainer/Distance").text = "%s AU" % [Helper.clever_round(p_i.distance / 569.25, 3)]
		btn.connect("pressed", self, "select_planet", [p_i, btn])

func refresh_planet_info():
	var value = $Control/HSlider.value
	var cost = pow(target.size / 10000.0, 3) * 10000
	var time_base = cost / star.luminosity * 10
	var time = time_base * (1 - value)
	var additional_energy = 100000000000000 * time_base * value
	$Control.visible = true
	$Control/EnergyCost.text = Helper.format_num(additional_energy)
	$Control/TimeCost.text = Helper.time_to_str(time * 1000 * 1800 / 10000)
	var R = target.size * 1000.0 / 2#in meters
	var surface_volume = get_sph_V(R, R - target.crust_start_depth)#in m^3
	var crust_volume = get_sph_V(R - target.crust_start_depth, R - target.mantle_start_depth)
	var mantle_volume = get_sph_V(R - target.mantle_start_depth, R - target.core_start_depth)
	var core_volume = get_sph_V(R - target.core_start_depth)
	var stone = {}
	add_stone(stone, target.crust, (surface_volume + crust_volume) * ((5600 + target.mantle_start_depth * 0.01) / 2.0))
	add_stone(stone, target.mantle, mantle_volume * ((5690 + (target.mantle_start_depth + target.core_start_depth) * 0.01) / 2.0))
	add_stone(stone, target.core, core_volume * ((5700 + (target.core_start_depth + R) * 0.01) / 2.0))
	var rsrc:Dictionary = {"stone":stone}
	for mat in target.surface:
		rsrc[mat] = surface_volume * target.surface[mat].chance * target.surface[mat].amount
	for met in game.met_info:
		rsrc[met] = get_sph_V(R - game.met_info[met].min_depth, R - game.met_info[met].max_depth) * 0.425 * game.met_info[met].amount / game.met_info[met].rarity
	Helper.put_rsrc($Control/ScrollContainer/GridContainer, 36, rsrc)

#get_sphere_volume
func get_sph_V(outer:float, inner:float = 0):
	return 4/3 * PI * (pow(outer, 3) - pow(inner, 3))

func add_stone(stone:Dictionary, layer:Dictionary, amount:float):
	for comp in layer:
		if stone.has(comp):
			stone[comp] += layer[comp] * amount
		else:
			stone[comp] = layer[comp] * amount

func _on_HSlider_value_changed(value):
	refresh_planet_info()
