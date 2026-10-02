extends Node

# Planet
var planet_tile_dimensions = 1.0
var max_planet_tile_dimensions = 100
var lake_coverage = 0.5

# Cave
var cave_spawn_frequency = 1.0
var cave_tile_dimensions = 1.0
var cave_depth = 1.0
var cave_floor_difficulty = 1.0
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
var dwarf_elliptical_galaxy_ratio = 0.5
var elliptical_spiral_galaxy_ratio = 0.5

# Cluster
var galaxy_density = 1.0
var min_number_of_galaxies = 500
var max_number_of_galaxies = 5000
var galaxy_group_ratio = 1.0

# Universe
var cluster_density = 1.0
var number_of_clusters = 1000
