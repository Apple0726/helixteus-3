extends Control

@onready var game = get_node("/root/Game")
@onready var planet_tile_dimensions_node = $AdvancedSettingsGroup/ScrollContainer/Control/PlanetTileDimensions
@onready var max_planet_tile_dimensions_node = $AdvancedSettingsGroup/ScrollContainer/Control/MaxPlanetTileDimensions
@onready var lake_coverage_node = $AdvancedSettingsGroup/ScrollContainer/Control/LakeCoverage
@onready var cave_spawn_frequency_node = $AdvancedSettingsGroup/ScrollContainer/Control/CaveSpawnFrequency
@onready var cave_tile_dimensions_node = $AdvancedSettingsGroup/ScrollContainer/Control/CaveTileDimensions
@onready var cave_depth_node = $AdvancedSettingsGroup/ScrollContainer/Control/CaveDepth
@onready var cave_floor_diff_node = $AdvancedSettingsGroup/ScrollContainer/Control/CaveFloorDifficulty
@onready var cave_wall_coverage_node = $AdvancedSettingsGroup/ScrollContainer/Control/CaveWallCoverage
@onready var distance_between_planets_node = $AdvancedSettingsGroup/ScrollContainer/Control/DistanceBetweenPlanets
@onready var max_planets_in_system_node = $AdvancedSettingsGroup/ScrollContainer/Control/MaxPlanetsInSystem
@onready var star_system_density_node = $AdvancedSettingsGroup/ScrollContainer/Control/StarSystemDensity
@onready var elliptical_galaxy_min_size_node = $AdvancedSettingsGroup/ScrollContainer/Control/EllipticalGalaxyMinSize
@onready var elliptical_galaxy_max_size_node = $AdvancedSettingsGroup/ScrollContainer/Control/EllipticalGalaxyMaxSize
@onready var spiral_galaxy_min_size_node = $AdvancedSettingsGroup/ScrollContainer/Control/SpiralGalaxyMinSize
@onready var spiral_galaxy_max_size_node = $AdvancedSettingsGroup/ScrollContainer/Control/SpiralGalaxyMaxSize
@onready var dwarf_elliptical_galaxy_ratio_node = $AdvancedSettingsGroup/ScrollContainer/Control/DwarfEllipticalGalaxyRatio
@onready var elliptical_spiral_galaxy_ratio_node = $AdvancedSettingsGroup/ScrollContainer/Control/EllipticalSpiralGalaxyRatio
@onready var galaxy_density_node = $AdvancedSettingsGroup/ScrollContainer/Control/GalaxyDensity
@onready var min_number_of_galaxies_node = $AdvancedSettingsGroup/ScrollContainer/Control/MinNumberOfGalaxies
@onready var max_number_of_galaxies_node = $AdvancedSettingsGroup/ScrollContainer/Control/MaxNumberOfGalaxies
@onready var galaxy_group_ratio_node = $AdvancedSettingsGroup/ScrollContainer/Control/GalaxyGroupRatio
@onready var cluster_density_node = $AdvancedSettingsGroup/ScrollContainer/Control/ClusterDensity
@onready var number_of_clusters_node = $AdvancedSettingsGroup/ScrollContainer/Control/NumberOfClusters

signal done

var min_max_values:Dictionary

func _ready() -> void:
	min_max_values = {
		planet_tile_dimensions_node: {"min":0.0, "default": ProcGenSettings.default_values.planet_tile_dimensions},
		max_planet_tile_dimensions_node: {"min":1, "rec_min":3, "rec_max":250, "default": ProcGenSettings.default_values.max_planet_tile_dimensions},
		lake_coverage_node: {"min":0.0, "max":1.0, "default": ProcGenSettings.default_values.lake_coverage},
		cave_spawn_frequency_node: {"min":0.0, "rec_max":20.0, "default": ProcGenSettings.default_values.cave_spawn_frequency},
		cave_tile_dimensions_node: {"min":0.0, "rec_max":3.0, "default": ProcGenSettings.default_values.cave_tile_dimensions},
		cave_depth_node: {"min":0.0, "default": ProcGenSettings.default_values.cave_depth},
		cave_floor_diff_node: {"min":1.0, "default": ProcGenSettings.default_values.cave_floor_difficulty},
		cave_wall_coverage_node: {"min":0.0, "max":1.0, "default": ProcGenSettings.default_values.cave_wall_coverage},
		distance_between_planets_node: {"min":0.0, "rec_min":0.1, "rec_max":10.0, "default": ProcGenSettings.default_values.distance_between_planets},
		max_planets_in_system_node: {"min":1, "rec_max":50, "default": ProcGenSettings.default_values.max_planets_in_system},
		star_system_density_node: {"min":0.0, "rec_min":0.1, "rec_max":10.0, "default": ProcGenSettings.default_values.star_system_density},
		elliptical_galaxy_min_size_node: {"min":1, "default": ProcGenSettings.default_values.min_number_of_systems_elliptical},
		elliptical_galaxy_max_size_node: {"min":1, "rec_max":50000, "default": ProcGenSettings.default_values.max_number_of_systems_elliptical},
		spiral_galaxy_min_size_node: {"min":1, "default": ProcGenSettings.default_values.min_number_of_systems_spiral},
		spiral_galaxy_max_size_node: {"min":1, "rec_max":50000, "default": ProcGenSettings.default_values.max_number_of_systems_spiral},
		dwarf_elliptical_galaxy_ratio_node: {"min":0.0, "max":1.0, "default": ProcGenSettings.default_values.dwarf_elliptical_galaxy_ratio},
		elliptical_spiral_galaxy_ratio_node: {"min":0.0, "max":1.0, "default": ProcGenSettings.default_values.elliptical_spiral_galaxy_ratio},
		galaxy_density_node: {"min":0.0, "rec_min":0.3, "rec_max":10.0, "default": ProcGenSettings.default_values.galaxy_density},
		min_number_of_galaxies_node: {"min":1, "default": ProcGenSettings.default_values.min_number_of_galaxies},
		max_number_of_galaxies_node: {"min":1, "rec_max":50000, "default": ProcGenSettings.default_values.max_number_of_galaxies},
		galaxy_group_ratio_node: {"min":0.0, "max":1.0, "default": ProcGenSettings.default_values.galaxy_group_ratio},
		cluster_density_node: {"min":0.0, "rec_min":0.1, "rec_max":10.0, "default": ProcGenSettings.default_values.cluster_density},
		number_of_clusters_node: {"min":1, "rec_max":50000, "default": ProcGenSettings.default_values.number_of_clusters},
	}
	$Seed.text = str(int(Time.get_unix_time_from_system()))
	$Seed.text_submitted.connect(check_seed_validity)
	$Seed.focus_exited.connect(check_seed_validity)
	$BasicSettingsGroup/SizeOfCOSHBox/Medium._on_Button_pressed()
	$BasicSettingsGroup/DensityOfCOSHBox/Normal._on_Button_pressed()
	for line_edit in $AdvancedSettingsGroup/ScrollContainer/Control.get_children():
		if line_edit is not LineEdit:
			continue
		var warning_icon = TextureRect.new()
		warning_icon.texture = load("res://Graphics/Icons/warning.png")
		warning_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		warning_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		warning_icon.size = Vector2(20.0, 24.0)
		warning_icon.position = Vector2(32.0, 4.0)
		warning_icon.name = "Warning"
		warning_icon.hide()
		line_edit.add_child(warning_icon)
		line_edit.text_changed.connect(check_value_validity.bind(line_edit))
		line_edit.text_submitted.connect(check_value_validity2.bind(line_edit))
		line_edit.focus_exited.connect(check_value_validity2.bind("", line_edit))
		line_edit.mouse_entered.connect(line_edit_show_tooltip.bind(line_edit))
		line_edit.mouse_exited.connect(game.hide_tooltip)
		line_edit.text = str(min_max_values[line_edit].default)
	max_planet_tile_dimensions_node.text_changed.connect(update_max_planet_tile_dimensions_label_2)
	$BasicSettingsGroup/SizeOfCOSHBox/Small.pressed.connect(set_size_of_COs.bind(0.66))
	$BasicSettingsGroup/SizeOfCOSHBox/Medium.pressed.connect(set_size_of_COs.bind(1.0))
	$BasicSettingsGroup/SizeOfCOSHBox/Large.pressed.connect(set_size_of_COs.bind(2.0))
	$BasicSettingsGroup/DensityOfCOSHBox/Sparse.pressed.connect(set_density_of_COs.bind(2.0))
	$BasicSettingsGroup/DensityOfCOSHBox/Normal.pressed.connect(set_density_of_COs.bind(1.0))
	$BasicSettingsGroup/DensityOfCOSHBox/Dense.pressed.connect(set_density_of_COs.bind(0.66))

func set_size_of_COs(size_mult:float):
	planet_tile_dimensions_node.text = str(size_mult)
	cave_tile_dimensions_node.text = str(size_mult)
	elliptical_galaxy_min_size_node.text = str(int(size_mult * ProcGenSettings.default_values.min_number_of_systems_elliptical))
	elliptical_galaxy_max_size_node.text = str(int(size_mult * ProcGenSettings.default_values.max_number_of_systems_elliptical))
	spiral_galaxy_min_size_node.text = str(int(size_mult * ProcGenSettings.default_values.min_number_of_systems_spiral))
	spiral_galaxy_max_size_node.text = str(int(size_mult * ProcGenSettings.default_values.max_number_of_systems_spiral))
	dwarf_elliptical_galaxy_ratio_node.text = str(snappedf(ProcGenSettings.default_values.dwarf_elliptical_galaxy_ratio / sqrt(size_mult), 0.01))
	min_number_of_galaxies_node.text = str(int(size_mult * ProcGenSettings.default_values.min_number_of_galaxies))
	max_number_of_galaxies_node.text = str(int(size_mult * ProcGenSettings.default_values.max_number_of_galaxies))
	galaxy_group_ratio_node.text = str(snappedf(ProcGenSettings.default_values.galaxy_group_ratio / sqrt(size_mult), 0.01))
	number_of_clusters_node.text = str(int(size_mult * ProcGenSettings.default_values.number_of_clusters))
	for line_edit in $AdvancedSettingsGroup/ScrollContainer/Control.get_children():
		if line_edit is not LineEdit:
			continue
		check_value_validity(line_edit.text, line_edit)

func set_density_of_COs(density_mult:float):
	distance_between_planets_node.text = str(density_mult)
	star_system_density_node.text = str(density_mult)
	galaxy_density_node.text = str(density_mult)
	cluster_density_node.text = str(density_mult)

func check_seed_validity():
	if not $Seed.text.is_valid_int():
		$Seed.text = str(int(Time.get_unix_time_from_system()))

# Check if entered value exceeds hard minimum/maximum
func check_value_validity(new_text:String, line_edit_node):
	if new_text.is_valid_float() or new_text.is_valid_int():
		if min_max_values[line_edit_node].has("min") and float(new_text) < min_max_values[line_edit_node].min:
			line_edit_node.text = str(min_max_values[line_edit_node].min)
		elif min_max_values[line_edit_node].has("max") and float(new_text) > min_max_values[line_edit_node].max:
			line_edit_node.text = str(min_max_values[line_edit_node].max)
	line_edit_node.get_node("Warning").visible = get_warning_text(line_edit_node) != ""

# Check if entered value is a valid number, otherwise reset it to default value
func check_value_validity2(new_text:String, line_edit_node):
	if new_text == "":
		new_text = line_edit_node.text
	if not new_text.is_valid_float() and not new_text.is_valid_int():
		line_edit_node.text = str(min_max_values[line_edit_node].default)
		check_value_validity("", line_edit_node)

func update_max_planet_tile_dimensions_label_2(new_text:String):
	$AdvancedSettingsGroup/ScrollContainer/Control/MaxPlanetTileDimensionsLabel2.text = "= " + tr("OBJECT_COUNT").format({
		"num": Helper.format_num(pow(int(new_text), 2), false, 308),
		"object":tr("TILES"),
	})

func line_edit_show_tooltip(line_edit_node):
	var tooltip = ""
	var _min_max_values = min_max_values[line_edit_node]
	
	if _min_max_values.has("min"):
		tooltip += "{min_text}: {min}\n".format({"min_text":tr("MINIMUM"), "min":_min_max_values.min})
	if _min_max_values.has("rec_min"):
		tooltip += "{rec_min_text}: {min}\n".format({"rec_min_text":tr("RECOMMENDED_MINIMUM"), "min":_min_max_values.rec_min})
	if _min_max_values.has("rec_max"):
		tooltip += "{rec_max_text}: {max}\n".format({"rec_max_text":tr("RECOMMENDED_MAXIMUM"), "max":_min_max_values.rec_max})
	if _min_max_values.has("max"):
		tooltip += "{max_text}: {max}\n".format({"max_text":tr("MAXIMUM"), "max":_min_max_values.max})
	
	tooltip += get_warning_text(line_edit_node)
	game.show_tooltip(tooltip)

func get_warning_text(line_edit_node):
	var min_value = min_max_values[line_edit_node].get("rec_min", NAN)
	var max_value = min_max_values[line_edit_node].get("rec_max", NAN)
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
	ProcGenSettings.planet_tile_dimensions = float(planet_tile_dimensions_node.text)
	ProcGenSettings.max_planet_tile_dimensions = int(max_planet_tile_dimensions_node.text)
	ProcGenSettings.lake_coverage = float(lake_coverage_node.text)
	ProcGenSettings.cave_spawn_frequency = float(cave_spawn_frequency_node.text)

	ProcGenSettings.cave_tile_dimensions = float(cave_tile_dimensions_node.text)
	ProcGenSettings.cave_depth = float(cave_depth_node.text)
	ProcGenSettings.cave_floor_difficulty = float(cave_floor_diff_node.text)
	ProcGenSettings.cave_wall_coverage = float(cave_wall_coverage_node.text)

	ProcGenSettings.distance_between_planets = float(distance_between_planets_node.text)
	ProcGenSettings.max_planets_in_system = int(max_planets_in_system_node.text)

	ProcGenSettings.star_system_density = float(star_system_density_node.text)
	ProcGenSettings.min_number_of_systems_elliptical = int(elliptical_galaxy_min_size_node.text)
	ProcGenSettings.max_number_of_systems_elliptical = int(elliptical_galaxy_max_size_node.text)
	ProcGenSettings.min_number_of_systems_spiral = int(spiral_galaxy_min_size_node.text)
	ProcGenSettings.max_number_of_systems_spiral = int(spiral_galaxy_max_size_node.text)
	ProcGenSettings.dwarf_elliptical_galaxy_ratio = float(dwarf_elliptical_galaxy_ratio_node.text)
	ProcGenSettings.elliptical_spiral_galaxy_ratio = float(elliptical_spiral_galaxy_ratio_node.text)

	ProcGenSettings.galaxy_density = float(galaxy_density_node.text)
	ProcGenSettings.min_number_of_galaxies = int(min_number_of_galaxies_node.text)
	ProcGenSettings.max_number_of_galaxies = int(max_number_of_galaxies_node.text)
	ProcGenSettings.galaxy_group_ratio = float(galaxy_group_ratio_node.text)

	ProcGenSettings.cluster_density = float(cluster_density_node.text)
	ProcGenSettings.number_of_clusters = int(number_of_clusters_node.text)
	ProcGenSettings.universe_seed = int($Seed.text)
	emit_signal("done")
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func _on_advanced_settings_pressed() -> void:
	$AdvancedSettingsGroup.show()
	$BasicSettingsGroup.hide()


func _on_basic_settings_pressed() -> void:
	$BasicSettingsGroup.show()
	$AdvancedSettingsGroup.hide()


func _on_return_to_menu_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(game.return_to_menu)
	tween.tween_callback(queue_free)
