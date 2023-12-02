extends Button


func set_star_info(type:int, _class:String, temperature:float, radius:float, mass:float, luminosity:float):
	$Star.texture = load("res://Graphics/Effects/spotlight_%s.png" % [int(temperature) % 3 + 4])
	$Star.material.set_shader_parameter("time_offset", 10.0 * randf())
	$Star.material.set_shader_parameter("color", Helper.get_star_modulate(_class))
	var star_type_str:String
	var star_tier:String = ""
	match type:
		StarType.MAIN_SEQUENCE:
			star_type_str = tr("MAIN_SEQUENCE")
		StarType.WHITE_DWARF:
			star_type_str = tr("WHITE_DWARF")
		StarType.BROWN_DWARF:
			star_type_str = tr("BROWN_DWARF")
		StarType.GIANT:
			star_type_str = tr("GIANT")
		StarType.SUPERGIANT:
			star_type_str = tr("SUPERGIANT")
	if type >= StarType.HYPERGIANT + 1:
		star_type_str = tr("HYPERGIANT")
		star_tier = " " + Helper.get_roman_num(type - StarType.HYPERGIANT)
	$ClassType.text = "%s %s" % [_class, star_type_str + star_tier]
	$Temperature.text = "%s K" % Helper.format_num(temperature, false, 9)
	$Radius.text = "%s R☉" % Helper.clever_round(radius, 3, true) if radius < 1000 else Helper.format_num(radius)
	$Mass.text = "%s M☉" % Helper.clever_round(mass, 3, true) if mass < 1000 else Helper.format_num(mass)
	$Luminosity.text = "%s L☉" % Helper.clever_round(luminosity, 3, true) if luminosity < 1000 else Helper.format_num(luminosity)
