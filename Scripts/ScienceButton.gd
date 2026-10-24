extends Panel

@export var icon_texture:Texture2D
@onready var game = get_node('/root/Game')
var main_tree
var available = true
var prereq_also_locked = false
var prereqs:Dictionary
var sc_id:int
var sc_lv:int
var sc_cost:float
var infinite_research
var num_levels:int
var max_level:bool

func _ready():
	$Texture2D.texture = icon_texture
	sc_id = Science.names.find(name)
	prereqs = Data.science_unlocks[sc_id].prereqs
	infinite_research = Data.science_unlocks[sc_id].get("infinite_research", null)
	num_levels = len(Data.science_unlocks[sc_id].cost)
	var square_size = 12.0
	var inf_research_offset = 0
	if infinite_research:
		var color_rect = create_color_rect(Vector2.ONE * square_size)
		color_rect.color = Color.DARK_CYAN
		color_rect.name = "InfiniteResearch"
		var label = Label.new()
		label["theme_override_font_sizes/font_size"] = 10
		label["theme_override_colors/font_color"] = Color.LIGHT_CYAN
		label["theme_override_colors/font_shadow_color"] = Color(0.0, 0.0, 0.0, 0.4)
		label.name = "Label"
		label.position.y = -1.0
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		color_rect.add_child(label)
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		$GridContainer.add_child(color_rect)
		inf_research_offset = 1
	if num_levels + inf_research_offset > 5:
		square_size = 8.0
	for i in range(num_levels - 1, -1, -1):
		var color_rect = create_color_rect(Vector2.ONE * square_size)
		color_rect.name = str(i + 1)
		$GridContainer.add_child(color_rect)
		$GridContainer.move_child(color_rect, 0)
	$GridContainer.columns = clamp(num_levels + inf_research_offset, 1, 6)
	$GridContainer["theme_override_constants/h_separation"] = max(4, int(196.0 / (pow(num_levels + inf_research_offset, 2) + 10)))
	$Research.mouse_entered.connect(show_tooltip)
	$Research.mouse_exited.connect(game.hide_tooltip)
	$Research.pressed.connect(on_research)
	refresh()

func calculate_available():
	available = true
	prereq_also_locked = false
	for p_sc_id in prereqs:
		if game.science_level[p_sc_id] < prereqs[p_sc_id]:
			available = false
			for p_p_sc_id in Data.science_unlocks[p_sc_id].prereqs:
				if game.science_level[p_p_sc_id] == 0:
					prereq_also_locked = true
	
func show_tooltip():
	calculate_available()
	var num_levels = len(Data.science_unlocks[sc_id].cost)
	var sc_loc_name = tr("%s_SC" % name.to_upper())
	var sc_loc_desc = tr("%s_SC_DESC" % name.to_upper())
	var alternate_name = false
	if infinite_research and max_level:
		sc_loc_name = tr("%s_INF_SC" % [name.to_upper()])
		sc_loc_desc = tr("%s_INF_SC_DESC" % [name.to_upper()]) % game.maths_bonus.IRM
		sc_loc_desc += "\n{current_mult}: {mult}".format({
			"current_mult":tr("CURRENT_MULT"),
			"mult":Helper.clever_round(pow(game.maths_bonus.IRM, sc_lv - num_levels)),
		})
	elif sc_lv >= 1: # Some sciences have different names at different levels
		var key = "%s_%s_SC" % [name.to_upper(), sc_lv]
		if tr(key) != key:
			sc_loc_name = tr(key)
			sc_loc_desc = tr("%s_%s_SC_DESC" % [name.to_upper(), sc_lv])
			alternate_name = true
	if not available:
		var sc_to_research = ""
		for p_sc in prereqs:
			sc_to_research += tr("%s_SC" % Science.names[p_sc].to_upper())
			if prereqs[p_sc] > 1:
				sc_to_research += " " + str(prereqs[p_sc])
		var locked_st = "[color=#999999][font_size=20]({locked}) {title}[/font_size]\n\n{desc}".format({
			"locked":tr("LOCKED"),
			"title":sc_loc_name,
			"desc":tr("UNLOCK_BY_RESEARCHING_X").format({"science":sc_to_research}),
		})
		game.show_tooltip(locked_st)
		return
	var cost:float
	if infinite_research and max_level:
		cost = infinite_research.cost * pow(infinite_research.pw, sc_lv)
	else:
		if max_level:
			cost = Data.science_unlocks[sc_id].cost[sc_lv-1]
		else:
			cost = Data.science_unlocks[sc_id].cost[sc_lv]
	var display_sc_lv = sc_lv
	if max_level and not infinite_research:
		display_sc_lv -= 1
	var st = "[font_size=20]{title} {N}[/font_size]\n\n{desc}\n\n{cost_text}: [img height=1em]res://Graphics/Icons/SP.png[/img] {cost}".format({
		"title":sc_loc_name,
		"N":"" if alternate_name or display_sc_lv == 0 else str(display_sc_lv + 1),
		"desc":sc_loc_desc,
		"cost_text":tr("COST"),
		"cost":Helper.format_num(cost, true)
	})
	game.show_tooltip(st)

func refresh_cost():
	sc_cost = 0.0
	if infinite_research and max_level:
		sc_cost = infinite_research.cost * pow(infinite_research.pw, sc_lv - num_levels)
	elif not max_level:
		sc_cost = Data.science_unlocks[sc_id].cost[sc_lv]

func on_research():
	if sc_cost == 0.0:
		return
	if game.SP >= sc_cost:
		game.SP -= sc_cost
		sc_lv += 1
		game.science_level[sc_id] = sc_lv
		if sc_id == Science.ADVANCED_SPACE_CONSTRUCTION:
			game.show.bldg_upgrade = true
			game.popup_window(tr("YOU_MAY_NOW_UPGRADE_BLDGS"))
		elif sc_id == Science.ROVER_CONSTRUCTION and sc_lv == 1:
			Helper.show_bldg_unlocked_popup(Building.ROVER_CONSTRUCTION_CENTER)
			game.show.vehicles_button = true
			game.HUD.get_node("Buttons/Vehicles").visible = true
		elif sc_id == Science.SPACE_AGRICULTURE:
			Helper.show_bldg_unlocked_popup(Building.GREENHOUSE)
		elif sc_id == Science.ATOM_MANIPULATION:
			game.show.atoms = true
			Helper.show_bldg_unlocked_popup(Building.ATMOSPHERE_EXTRACTOR)
			Helper.show_bldg_unlocked_popup(Building.ATOM_MANIPULATOR)
		elif sc_id == Science.SUBATOMIC_PARTICLES:
			game.show.particles = true
			Helper.show_bldg_unlocked_popup(Building.SUBATOMIC_PARTICLE_REACTOR)
		elif sc_id == Science.COMPACT_ITEMS:
			if sc_lv == 1:
				game.stack_size = 32
			elif sc_lv == 2:
				game.stack_size = 64
			elif sc_lv == 3:
				game.stack_size = 128
		elif sc_id == Science.AUTO_MINING:
			Helper.show_bldg_unlocked_popup(Building.BORING_MACHINE)
		elif sc_id == Science.FIGHTERS and sc_lv == 1:
			Helper.show_bldg_unlocked_popup(Building.SHIPYARD)
		game.popup(tr("RESEARCH_SUCCESS"), 1.5)
		game.HUD.refresh()
		game.hide_tooltip()
		main_tree.refresh()
	else:
		game.popup(tr("NOT_ENOUGH_SP"), 1.5)


func create_color_rect(min_size:Vector2):
	var color_rect = ColorRect.new()
	color_rect.custom_minimum_size = min_size
	color_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	color_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return color_rect

func refresh():
	calculate_available()
	sc_lv = game.science_level[sc_id]
	max_level = sc_lv >= num_levels
	refresh_cost()
	if sc_lv >= 1:
		self_modulate = Color.GREEN
	else:
		self_modulate = Color.WHITE
	if available:
		modulate = Color.WHITE
		$Research.disabled = false
		$Texture2D.material.set_shader_parameter("gray", sc_lv == 0)
		$Texture2D.material.set_shader_parameter("darkness", 4.0)
	else:
		if prereq_also_locked:
			modulate = Color.BLACK
		else:
			$Texture2D.material.set_shader_parameter("gray", true)
			$Texture2D.material.set_shader_parameter("darkness", 12.0)
			self_modulate = Color.DIM_GRAY
		$Research.disabled = true
	for i in len(Data.science_unlocks[sc_id].cost):
		if sc_lv >= 1:
			if sc_lv >= i + 1:
				get_node("GridContainer/%s" % (i + 1)).color = Color.GREEN
			else:
				get_node("GridContainer/%s" % (i + 1)).color = Color.DARK_GREEN
			if infinite_research:
				get_node("GridContainer/InfiniteResearch").color = Color.DARK_CYAN
		else:
			get_node("GridContainer/%s" % (i + 1)).color = Color.BLACK
			if infinite_research:
				get_node("GridContainer/InfiniteResearch").color = Color.BLACK
	if infinite_research:
		var inf_lv:int = sc_lv - num_levels
		if inf_lv >= 0:
			$GridContainer/InfiniteResearch/Label.text = str(inf_lv)
