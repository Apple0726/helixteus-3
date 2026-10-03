extends Control

@onready var game = get_node("/root/Game")

signal done

func _ready() -> void:
	$Seed.text = str(int(Time.get_unix_time_from_system()))
	$BasicSettingsGroup/SizeOfCOSHBox/Medium._on_Button_pressed()
	$BasicSettingsGroup/DensityOfCOSHBox/Normal._on_Button_pressed()
	var planet_tile_dimensions_node = $AdvancedSettingsGroup/ScrollContainer/Control/PlanetTileDimensions
	planet_tile_dimensions_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":0.0}, planet_tile_dimensions_node))
	planet_tile_dimensions_node.mouse_exited.connect(game.hide_tooltip)
	var max_planet_tile_dimensions_node = $AdvancedSettingsGroup/ScrollContainer/Control/MaxPlanetTileDimensions
	max_planet_tile_dimensions_node.mouse_entered.connect(line_edit_show_tooltip.bind({"rec_min":3, "rec_max":300}, max_planet_tile_dimensions_node))
	max_planet_tile_dimensions_node.mouse_exited.connect(game.hide_tooltip)
	max_planet_tile_dimensions_node.text_changed.connect(update_max_planet_tile_dimensions_label_2)
	var lake_coverage_node = $AdvancedSettingsGroup/ScrollContainer/Control/LakeCoverage
	lake_coverage_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":0.0, "max":1.0}, lake_coverage_node))
	lake_coverage_node.mouse_exited.connect(game.hide_tooltip)
	var cave_spawn_frequency_node = $AdvancedSettingsGroup/ScrollContainer/Control/CaveSpawnFrequency
	cave_spawn_frequency_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":0.0, "rec_max":20.0}, cave_spawn_frequency_node))
	cave_spawn_frequency_node.mouse_exited.connect(game.hide_tooltip)
	var cave_tile_dimensions_node = $AdvancedSettingsGroup/ScrollContainer/Control/CaveTileDimensions
	cave_tile_dimensions_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":0.0, "rec_max":3.0}, cave_tile_dimensions_node))
	cave_tile_dimensions_node.mouse_exited.connect(game.hide_tooltip)
	var cave_depth_node = $AdvancedSettingsGroup/ScrollContainer/Control/CaveDepth
	cave_depth_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":0.0}, cave_depth_node))
	cave_depth_node.mouse_exited.connect(game.hide_tooltip)
	var cave_floor_diff_node = $AdvancedSettingsGroup/ScrollContainer/Control/CaveFloorDifficulty
	cave_floor_diff_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":1.0}, cave_floor_diff_node))
	cave_floor_diff_node.mouse_exited.connect(game.hide_tooltip)
	var cave_wall_coverage_node = $AdvancedSettingsGroup/ScrollContainer/Control/CaveWallCoverage
	cave_wall_coverage_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":0.0, "max":1.0}, cave_wall_coverage_node))
	cave_wall_coverage_node.mouse_exited.connect(game.hide_tooltip)
	var distance_between_planets_node = $AdvancedSettingsGroup/ScrollContainer/Control/DistanceBetweenPlanets
	distance_between_planets_node.mouse_entered.connect(line_edit_show_tooltip.bind({"rec_min":0.1, "rec_max":10.0}, distance_between_planets_node))
	distance_between_planets_node.mouse_exited.connect(game.hide_tooltip)
	var max_planets_in_system_node = $AdvancedSettingsGroup/ScrollContainer/Control/MaxPlanetsInSystem
	max_planets_in_system_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":1, "rec_max":50}, max_planets_in_system_node))
	max_planets_in_system_node.mouse_exited.connect(game.hide_tooltip)
	var star_system_density_node = $AdvancedSettingsGroup/ScrollContainer/Control/StarSystemDensity
	star_system_density_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":0.0, "rec_min":0.1, "rec_max":10.0}, star_system_density_node))
	star_system_density_node.mouse_exited.connect(game.hide_tooltip)
	var elliptical_galaxy_min_size_node = $AdvancedSettingsGroup/ScrollContainer/Control/EllipticalGalaxyMinSize
	elliptical_galaxy_min_size_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":1}, elliptical_galaxy_min_size_node))
	elliptical_galaxy_min_size_node.mouse_exited.connect(game.hide_tooltip)
	var elliptical_galaxy_max_size_node = $AdvancedSettingsGroup/ScrollContainer/Control/EllipticalGalaxyMaxSize
	elliptical_galaxy_max_size_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":1, "rec_max":50000}, elliptical_galaxy_max_size_node))
	elliptical_galaxy_max_size_node.mouse_exited.connect(game.hide_tooltip)
	var spiral_galaxy_min_size_node = $AdvancedSettingsGroup/ScrollContainer/Control/SpiralGalaxyMinSize
	spiral_galaxy_min_size_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":1}, spiral_galaxy_min_size_node))
	spiral_galaxy_min_size_node.mouse_exited.connect(game.hide_tooltip)
	var spiral_galaxy_max_size_node = $AdvancedSettingsGroup/ScrollContainer/Control/SpiralGalaxyMaxSize
	spiral_galaxy_max_size_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":1, "rec_max":50000}, spiral_galaxy_max_size_node))
	spiral_galaxy_max_size_node.mouse_exited.connect(game.hide_tooltip)
	var dwarf_elliptical_galaxy_raito_node = $AdvancedSettingsGroup/ScrollContainer/Control/DwarfEllipticalGalaxyRatio
	dwarf_elliptical_galaxy_raito_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":0.0, "max":1.0}, dwarf_elliptical_galaxy_raito_node))
	dwarf_elliptical_galaxy_raito_node.mouse_exited.connect(game.hide_tooltip)
	var elliptical_spiral_galaxy_ratio_node = $AdvancedSettingsGroup/ScrollContainer/Control/EllipticalSpiralGalaxyRatio
	elliptical_spiral_galaxy_ratio_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":0.0, "max":1.0}, elliptical_spiral_galaxy_ratio_node))
	elliptical_spiral_galaxy_ratio_node.mouse_exited.connect(game.hide_tooltip)
	var galaxy_density_node = $AdvancedSettingsGroup/ScrollContainer/Control/GalaxyDensity
	galaxy_density_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":0.0, "rec_min":0.3, "rec_max":10.0}, galaxy_density_node))
	galaxy_density_node.mouse_exited.connect(game.hide_tooltip)
	var min_number_of_galaxies_node = $AdvancedSettingsGroup/ScrollContainer/Control/MinNumberOfGalaxies
	min_number_of_galaxies_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":1}, min_number_of_galaxies_node))
	min_number_of_galaxies_node.mouse_exited.connect(game.hide_tooltip)
	var max_number_of_galaxies_node = $AdvancedSettingsGroup/ScrollContainer/Control/MaxNumberOfGalaxies
	max_number_of_galaxies_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":1, "rec_max":50000}, max_number_of_galaxies_node))
	max_number_of_galaxies_node.mouse_exited.connect(game.hide_tooltip)
	var galaxy_group_ratio_node = $AdvancedSettingsGroup/ScrollContainer/Control/GalaxyGroupRatio
	galaxy_group_ratio_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":0.0, "max":1.0}, galaxy_group_ratio_node))
	galaxy_group_ratio_node.mouse_exited.connect(game.hide_tooltip)
	var cluster_density_node = $AdvancedSettingsGroup/ScrollContainer/Control/ClusterDensity
	cluster_density_node.mouse_entered.connect(line_edit_show_tooltip.bind({"rec_min":0.1, "rec_max":10.0}, cluster_density_node))
	cluster_density_node.mouse_exited.connect(game.hide_tooltip)
	var number_of_clusters_node = $AdvancedSettingsGroup/ScrollContainer/Control/NumberOfClusters
	number_of_clusters_node.mouse_entered.connect(line_edit_show_tooltip.bind({"min":1, "rec_max":50000}, number_of_clusters_node))
	number_of_clusters_node.mouse_exited.connect(game.hide_tooltip)

func update_max_planet_tile_dimensions_label_2(new_text:String):
	$AdvancedSettingsGroup/ScrollContainer/Control/MaxPlanetTileDimensionsLabel2.text = "= " + tr("OBJECT_COUNT").format({
		"num": Helper.format_num(pow(int(new_text), 2), false, 308),
		"object":tr("TILES"),
	})

func line_edit_show_tooltip(min_max_values:Dictionary, line_edit_node):
	var tooltip = ""
	if min_max_values.has("min"):
		tooltip += "{min_text}: {min}\n".format({"min_text":tr("MINIMUM"), "min":min_max_values.min})
	if min_max_values.has("rec_min"):
		tooltip += "{rec_min_text}: {min}\n".format({"rec_min_text":tr("RECOMMENDED_MINIMUM"), "min":min_max_values.rec_min})
	if min_max_values.has("rec_max"):
		tooltip += "{rec_max_text}: {max}\n".format({"rec_max_text":tr("RECOMMENDED_MAXIMUM"), "max":min_max_values.rec_max})
	if min_max_values.has("max"):
		tooltip += "{max_text}: {max}\n".format({"max_text":tr("MAXIMUM"), "max":min_max_values.max})
	tooltip += get_warning_text(min_max_values.get("rec_min", NAN), min_max_values.get("rec_max", NAN), line_edit_node)
	game.show_tooltip(tooltip)

func get_warning_text(min_value:float, max_value:float, line_edit_node):
	if is_nan(min_value) and is_nan(max_value):
		return ""
	var current_value = float(line_edit_node.text)
	var warning_text = "\n[color=#FFAA00]"
	if not is_nan(max_value) and current_value > max_value:
		return warning_text + tr("HIGHER_THAN_REC_MAX") + "\n\n" + tr("PROCGEN_ABSURD_VALUE_WARNING")
	elif not is_nan(min_value) and current_value < min_value:
		return warning_text + tr("LOWER_THAN_REC_MIN") + "\n\n" + tr("PROCGEN_ABSURD_VALUE_WARNING")
	return ""

func _on_start_game_pressed() -> void:
	emit_signal("done")


func _on_advanced_settings_pressed() -> void:
	$AdvancedSettingsGroup.show()
	$BasicSettingsGroup.hide()


func _on_basic_settings_pressed() -> void:
	$BasicSettingsGroup.show()
	$AdvancedSettingsGroup.hide()
