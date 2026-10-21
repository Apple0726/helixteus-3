extends Node

# Planet
var planet_tile_dimensions = 1.0
var max_planet_tile_dimensions = 100
var lake_coverage = 0.5
var cave_spawn_frequency = 1.0

# Cave
var cave_tile_dimensions = 1.0
var cave_depth = 1.0
var cave_floor_difficulty = 2.0
var cave_wall_coverage = 0.5

# Star system
var distance_between_planets = 1.0
var max_planets_in_system = 40

# Galaxy
var star_system_density = 1.0
var min_number_of_systems_elliptical = 2000
var max_number_of_systems_elliptical = 10000
var min_number_of_systems_spiral = 5000
var max_number_of_systems_spiral = 15000
var dwarf_elliptical_galaxy_ratio = 0.6
var elliptical_spiral_galaxy_ratio = 0.16

# Cluster
var galaxy_density = 1.0
var min_number_of_galaxies = 500
var max_number_of_galaxies = 5000
var galaxy_group_ratio = 0.5

# Universe
var cluster_density = 1.0
var number_of_clusters = 1000
var universe_seed = 0

var default_values = {
	"planet_tile_dimensions": planet_tile_dimensions,
	"max_planet_tile_dimensions": max_planet_tile_dimensions,
	"lake_coverage": lake_coverage,
	"cave_spawn_frequency": cave_spawn_frequency,

	"cave_tile_dimensions": cave_tile_dimensions,
	"cave_depth": cave_depth,
	"cave_floor_difficulty": cave_floor_difficulty,
	"cave_wall_coverage": cave_wall_coverage,

	"distance_between_planets": distance_between_planets,
	"max_planets_in_system": max_planets_in_system,

	"star_system_density": star_system_density,
	"min_number_of_systems_elliptical": min_number_of_systems_elliptical,
	"max_number_of_systems_elliptical": max_number_of_systems_elliptical,
	"min_number_of_systems_spiral": min_number_of_systems_spiral,
	"max_number_of_systems_spiral": max_number_of_systems_spiral,
	"dwarf_elliptical_galaxy_ratio": dwarf_elliptical_galaxy_ratio,
	"elliptical_spiral_galaxy_ratio": elliptical_spiral_galaxy_ratio,

	"galaxy_density": galaxy_density,
	"min_number_of_galaxies": min_number_of_galaxies,
	"max_number_of_galaxies": max_number_of_galaxies,
	"galaxy_group_ratio": galaxy_group_ratio,

	"cluster_density": cluster_density,
	"number_of_clusters": number_of_clusters,
	"universe_seed": universe_seed,
}
