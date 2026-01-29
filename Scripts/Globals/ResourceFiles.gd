extends Node

var cave_walls_tile_set: TileSet = preload("res://Resources/CaveWallsTileSet.tres")
var planet_tile_set: TileSet = preload("res://Resources/PlanetTileSet.tres")
var soil_tile_set: TileSet = preload("res://Resources/SoilTileSet.tres")

func _init() -> void:
	var src = cave_walls_tile_set.get_source(0)
	if src.texture.get_width() == 550:
		resize_texture(src)
	src = planet_tile_set.get_source(0)
	if src.texture.get_width() == 550:
		resize_texture(src)
	src = soil_tile_set.get_source(0)
	if src.texture.get_width() == 550:
		resize_texture(src)

func resize_texture(src):
	var image: Image = src.texture.get_image()
	image.resize(image.get_width() * 4, image.get_height() * 4)
	var resized_texture = ImageTexture.create_from_image(image)
	src.texture_region_size = Vector2i.ONE * 200
	src.texture = resized_texture
