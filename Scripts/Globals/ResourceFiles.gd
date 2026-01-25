extends Node

var cave_walls_tile_set: TileSet = preload("res://Resources/CaveWallsTileSet.tres")
var planet_tile_set: TileSet = preload("res://Resources/PlanetTileSet.tres")
var soil_tile_set: TileSet = preload("res://Resources/SoilTileSet.tres")

func _init() -> void:
	var src = cave_walls_tile_set.get_source(0)
	cave_walls_tile_set.tile_size = Vector2.ONE * src.texture.get_width() / 2200.0 * 200.0
	if src is TileSetAtlasSource:
		src.texture_region_size = Vector2.ONE * src.texture.get_width() / 2200.0 * 200.0
	src = planet_tile_set.get_source(0)
	planet_tile_set.tile_size = Vector2.ONE * src.texture.get_width() / 2200.0 * 200.0
	if src is TileSetAtlasSource:
		src.texture_region_size = Vector2.ONE * src.texture.get_width() / 2200.0 * 200.0
	src = soil_tile_set.get_source(0)
	soil_tile_set.tile_size = Vector2.ONE * src.texture.get_width() / 2200.0 * 200.0
	if src is TileSetAtlasSource:
		src.texture_region_size = Vector2.ONE * src.texture.get_width() / 2200.0 * 200.0
