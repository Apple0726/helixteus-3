extends Control

onready var game = get_node("/root/Game")
onready var p_i = game.planet_data[game.c_p]
onready var id:int = game.c_t
onready var tile = game.tile_data[id]
onready var tile_texture = load("res://Graphics/Tiles/" + String(p_i["type"]) + ".jpg")
var progress = 0#Mining tile progress
var total_mass = 0
var contents = []
var tween:Tween
var layer:String
onready var met_info = game.met_info

func _ready():
	$Pickaxe/Sprite.texture = load("res://Graphics/Pickaxes/" + game.pickaxe.name + ".png")
	$Back.text = "<- " + tr("BACK") + " (Z)"
	$Tile/TextureRect.texture = tile_texture
	generate_rock(false)
	if not tile.has("mining_progress"):
		tile.mining_progress = 0.0
	progress = tile.mining_progress
	$Help.visible = game.help.mining
	$Help/Label.text = tr("MINE_HELP")
	$LayerInfo.visible = game.show.mining_layer
	update_info()

func update_info():
	var upper_depth
	var lower_depth 
	if tile.depth <= p_i.crust_start_depth:
		layer = "surface"
		upper_depth = 0
		lower_depth = p_i.crust_start_depth
		$LayerInfo/Upper.text = String(upper_depth) + " m"
		$LayerInfo/Lower.text = String(lower_depth) + " m"
	elif tile.depth <= p_i.mantle_start_depth:
		layer = "crust"
		upper_depth = p_i.crust_start_depth + 1
		lower_depth = p_i.mantle_start_depth
		$LayerInfo/Upper.text = String(upper_depth) + " m"
		$LayerInfo/Lower.text = String(lower_depth) + " m"
	elif tile.depth <= p_i.core_start_depth:
		layer = "mantle"
		upper_depth = floor(p_i.mantle_start_depth / 1000.0)
		lower_depth = floor(p_i.core_start_depth / 1000.0)
		$LayerInfo/Upper.text = String(upper_depth) + " km"
		$LayerInfo/Lower.text = String(lower_depth) + " km"
	else:
		layer = "core"
		upper_depth = floor(p_i.core_start_depth / 1000.0)
		lower_depth = floor(p_i.size / 2.0)
		$LayerInfo/Upper.text = String(upper_depth) + " km"
		$LayerInfo/Lower.text = String(lower_depth) + " km"
	$LayerInfo/Layer.text = tr("LAYER") + ": " + tr(layer.to_upper())
	$LayerInfo/Depth.position.y = range_lerp(tile.depth, upper_depth, lower_depth, 172, 628)
	$LayerInfo/Depth/Label.text = String(tile.depth) + " m"
	$Tile/Bar1.value = progress * 8
	$Tile/Bar2.value = (progress - 12.5) * 4
	$Tile/Bar3.value = (progress - 37.5) * 4
	$Tile/Bar4.value = (progress - 62.5) * 4
	$Tile/Bar5.value = (progress - 87.5) * 8
	$Tile/Cracks.frame = min(floor(progress / 20), 4)
	$Durability/Numbers.text = "%s / %s" % [game.pickaxe.durability, game.pickaxe_info[game.pickaxe.name].durability]	
	$Durability/Bar.value = game.pickaxe.durability / float(game.pickaxe_info[game.pickaxe.name].durability) * 100

func generate_rock(new:bool):
	contents = []
	if tween:
		remove_child(tween)
	tween = Tween.new()
	add_child(tween)
	tween.interpolate_property($Tile, "rect_scale", Vector2(0.3, 0.3), Vector2(1, 1), 0.4, Tween.TRANS_CIRC, Tween.EASE_OUT)
	tween.start()
	for thing in $Panel/VBoxContainer.get_children():
		$Panel/VBoxContainer.remove_child(thing)
	if tile.contents == [] or new:
		total_mass = 0
		var other_volume = 0#in m^3
		#We assume all materials have a density of 1.5g/cm^3 to simplify things
		var rho = 1.5
		for mat in p_i.surface.keys():
			if randf() < p_i.surface[mat].chance / max(1, 1 + (tile.depth - p_i.crust_start_depth) / float(p_i.crust_start_depth)):
				var amount = game.clever_round(p_i.surface[mat].amount * rand_range(0.8, 1.2), 3)
				contents.append({"name":mat, "type":"Materials", "amount":amount})
				other_volume += amount / rho / 1000
		if layer != "surface":
			for met in met_info:
				if met_info[met].min_depth < tile.depth and tile.depth < met_info[met].max_depth:
					if randf() < 0.25 / met_info[met].rarity:
						var amount = game.clever_round(met_info[met].amount * rand_range(0.2, 3))
						contents.append({"name":met, "type":"Metals", "amount":amount})
						other_volume += amount / game.met_info[met].density / 1000
		#   									                          	    V Every km, rock density goes up by 0.01
		var stone_amount = game.clever_round((1 - other_volume) * 1000 * (2.85 + tile.depth / 100000.0), 3)
		contents.push_front({"name":"stone", "type":"Icons", "amount":stone_amount})
		tile.contents = contents
	else:
		contents = tile.contents
	for obj in contents:
		total_mass += obj.amount
		var rsrc = game.rsrc_scene.instance()
		var texture = rsrc.get_node("Texture")
		texture.texture_normal = load("res://Graphics/" + obj.type + "/" + obj.name + ".png")
		texture.rect_min_size = Vector2(42, 42)
		rsrc.get_node("Text").text = String(obj.amount) + " kg"
		$Panel/VBoxContainer.add_child(rsrc)
	$Panel.visible = false
	$Panel.visible = true#A weird workaround to make sure Panel has the right rekt_size

var mouse_pos

func _input(event):
	if event is InputEventMouse:
		mouse_pos = event.position
		$Pickaxe.position = mouse_pos - Vector2(512, 576)

func _on_Back_pressed():
	game.switch_view("planet")

var crumbles = []

func place_crumbles(num:int, sc:float, v:float):
	for i in num:
		var crumble = Sprite.new()
		crumble.texture = tile_texture
		crumble.scale *= sc
		crumble.centered = true
		add_child(crumble)
		crumble.position = mouse_pos
		crumbles.append({"sprite":crumble, "velocity":Vector2(rand_range(-2, 2), rand_range(-8, -4)) * v, "angular_velocity":rand_range(-0.08, 0.08)})

func hide_help():
	$Help.visible = false
	game.help.mining = false

var help_counter = 0
func pickaxe_hit():
	if not game.pickaxe:
		return
	if $Help.visible:
		help_counter += 1
		if help_counter >= 10:
			$HelpAnim.play("Help fade")
	place_crumbles(5, 0.1, 1)
	progress += game.pickaxe.speed / total_mass * 3000
	game.pickaxe.durability -= 1
	tile.mining_progress = progress
	if progress >= 100:
		for content in contents:
			if content.type == "Materials":
				game.mats[content.name] += content.amount
			elif content.type == "Metals":
				game.mets[content.name] += content.amount
			else:
				game[content.name] += content.amount
			if game.show.has(content.name):
				game.show[content.name] = true
		progress -= 100
		tile.depth += 1
		game.show.stone = true
		if not $LayerInfo.visible and tile.depth >= 5:
			game.show.mining_layer = true
			$LayerAnim.play("Layer fade")
			$LayerInfo.visible = true
		place_crumbles(15, 0.2, 2)
		generate_rock(true)
	update_info()
	if game.pickaxe.durability == 0:
		var curr_pick_info = game.pickaxe_info[game.pickaxe.name]
		var pick_cost = curr_pick_info.money_cost
		if $AutoReplace.pressed and game.money >= pick_cost:
				game.money -= pick_cost
				game.pickaxe.durability = curr_pick_info.durability
				update_info()
		else:
			game.pickaxe = null
			game.popup(tr("PICKAXE_BROKE"), 1.5)
			$Pickaxe.visible = false

func _process(_delta):
	for cr in crumbles:
		cr.sprite.position += cr.velocity
		cr.velocity.y += 0.6
		cr.sprite.rotation += cr.angular_velocity
		if cr.sprite.position.y > 1000:
			remove_child(cr.sprite)
			crumbles.erase(cr)

func _on_Button_button_down():
	$PickaxeAnim.get_animation("Pickaxe swing").loop = true
	$PickaxeAnim.play("Pickaxe swing")

func _on_Button_button_up():
	$PickaxeAnim.get_animation("Pickaxe swing").loop = false

func _on_CheckBox_mouse_entered():
	game.show_tooltip("AUTO_REPLACE_DESC")

func _on_CheckBox_mouse_exited():
	game.hide_tooltip()
