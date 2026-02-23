@icon("res://assets/icons/color/icon_map_2.png")
@tool
class_name Terrain
extends Node2D

var biome_noise: PerlinNoise = null
var biome_lookup: Dictionary[int, Biome] = { }
var world_tiles: Dictionary[Vector2i, WorldTile] = { }
var noise_seed: int = 0


class WorldTile:
	var chosen_tile: Tile
	var chosen_layer: TileMapLayer


	func _init(tile: Tile, layer: TileMapLayer) -> void:
		self.chosen_tile = tile
		self.chosen_layer = layer

@export_category("Actions")
@export_tool_button("Generate Terrrain") var generate_terrain_btn: Callable = start_generation
@export_tool_button("Draw Noise Images") var draw_noise_images_btn: Callable = draw_noise_images
@export_tool_button("Clear Everything") var reset_generation_btn: Callable = clear_everything

@export_category("Terrain Settings")
@export var world_size: int = 200
@export var height_addition: int = 50
@export var ground_offset: int = 640
@export var tile_size: int = 128

@export_category("Biome Settings")
@export var biome_map: NoiseTexture2D = null
@export var biome_frequency: float = 0.01
@export var biome_colors: Gradient
@export var biomes: Array[Biome] = []

@export_category("Node References")
@export var foreground: TileMapLayer
@export var background: TileMapLayer
@export var player: Player
@export var debug: Debug
@export var left_wall: CollisionShape2D
@export var right_wall: CollisionShape2D
@export var tile_drop: PackedScene


func _ready() -> void:
	if not Engine.is_editor_hint():
		start_generation()


func clear_everything() -> void:
	assert(not biomes.is_empty(), "Biomes should be here!")

	world_tiles.clear()
	foreground.clear()
	background.clear()

	biome_map = null
	for biome in biomes:
		biome.cave_noise_texture = null
		var ores: Array[Ore] = biome.tile_atlas.get_ores()
		for ore in ores:
			ore.spread_texture = null

	noise_seed = 0

	notify_property_list_changed()


func start_generation() -> void:
	if Engine.is_editor_hint():
		clear_everything()

	if noise_seed == 0:
		randomize()
		noise_seed = randi_range(-10000, 10000)
		seed(noise_seed)

	for biome in biomes:
		biome_lookup[biome.tint.to_rgba32()] = biome

	draw_noise_images()
	generate_terrain()
	player.global_position = find_spawn_position()


func set_limits() -> void:
	player.camera.set_limit(SIDE_LEFT, 0)
	player.camera.set_limit(SIDE_RIGHT, world_size * tile_size)
	player.camera.set_limit(SIDE_BOTTOM, ground_offset + tile_size)
	player.camera.set_limit(SIDE_TOP, ground_offset - world_size * tile_size)

	left_wall.position.x = player.camera.limit_left
	right_wall.position.x = player.camera.limit_right


func find_spawn_position() -> Vector2:
	var x: int = world_size / 2
	for y: int in range(world_size - 1, -1, -1):
		var current_tile = world_tiles.get(Vector2i(x, y))
		if current_tile and not current_tile.chosen_tile.is_background:
			return get_world_position(x, y + 1)
	return get_world_position(x, world_size / 2)


func draw_noise_images() -> void:
	biome_noise = PerlinNoise.new(noise_seed, biome_frequency)
	biome_map = biome_noise.get_noise_texture(world_size, biome_colors)

	for biome in biomes:
		biome.terrain_noise = PerlinNoise.new(noise_seed, biome.terrain_frequency)
		biome.cave_noise = PerlinNoise.new(noise_seed, biome.cave_frequency)
		biome.cave_noise_texture = biome.cave_noise.get_noise_texture(world_size, biome.surface_value)

		for ore in biome.tile_atlas.get_ores():
			ore.noise = PerlinNoise.new(noise_seed, ore.frequency)
			ore.spread_texture = ore.noise.get_noise_texture(world_size, ore.vein_size)

	notify_property_list_changed()


func get_biome(x: int, y: int) -> Biome:
	return biome_lookup.get(biome_colors.sample(biome_noise.get_unity_noise(x, y)).to_rgba32(), null)


func get_world_position(grid_x: float, logic_height: float) -> Vector2:
	var origin_y_in_tiles: int = ground_offset / tile_size
	var tile_map_y: float = origin_y_in_tiles - logic_height

	var pixel_x = grid_x * tile_size + (tile_size / 2.0)
	var pixel_y = tile_map_y * tile_size + (tile_size / 2.0)

	return Vector2(pixel_x, pixel_y)


func generate_terrain() -> void:
	for x: int in range(world_size):
		for y: int in range(world_size):
			var current_biome: Biome = get_biome(x, y)
			var tiles: TileAtlas = current_biome.tile_atlas
			var height: float = current_biome.terrain_noise.get_unity_noise(x, 0) * current_biome.height_multiplier + height_addition
			if y >= height:
				break
			var current_tile: Tile = tiles.stone
			if y < height - current_biome.dirt_layer_height and not tiles.get_ores().is_empty():
				if tiles.coal.noise.get_unity_noise(x, y) > tiles.coal.vein_size and height - y > tiles.coal.max_spawn_height:
					current_tile = tiles.coal
				if tiles.iron.noise.get_unity_noise(x, y) > tiles.iron.vein_size and height - y > tiles.iron.max_spawn_height:
					current_tile = tiles.iron
					if tiles.gold.noise.get_unity_noise(x, y) > tiles.gold.vein_size and height - y > tiles.gold.max_spawn_height:
						current_tile = tiles.gold
						if tiles.diamond.noise.get_unity_noise(x, y) > tiles.diamond.vein_size and height - y > tiles.diamond.max_spawn_height:
							current_tile = tiles.diamond
			elif y < int(height - 1):
				current_tile = tiles.dirt
			else:
				current_tile = tiles.grass

			if current_biome.cave_noise.get_unity_noise(x, y) > current_biome.surface_value or not current_biome.generate_caves:
				place_tile(current_tile, x, y)

			if y > int(height - 1):
				if randi_range(0, current_biome.tree_percent_chance) == 1 and world_tiles.has(Vector2i(x, y)):
					place_tree(current_biome, x, y)
				elif tiles.addons != null and randi_range(0, current_biome.addon_percent_chance) == 1 and world_tiles.has(Vector2i(x, y)):
					place_tile(tiles.addons, x, y + 1)


func get_coordinates_from_position(mouse_pos: Vector2i, layer: TileMapLayer = foreground) -> Vector2i:
	var grid_pos: Vector2i = layer.local_to_map(layer.to_local(mouse_pos))
	return Vector2i(grid_pos.x, (ground_offset / tile_size) - grid_pos.y)


func get_texture_from_position(pos: Vector2i, layer: TileMapLayer = foreground) -> Texture2D:
	var source_id: int = layer.get_cell_source_id(pos)
	var atlas_coords: Vector2i = layer.get_cell_atlas_coords(pos)
	var atlas_source: TileSetAtlasSource = layer.tile_set.get_source(source_id)
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = atlas_source.texture
	atlas_texture.region = atlas_source.get_tile_texture_region(atlas_coords)
	return atlas_texture


func remove_tile(x: int, y: int) -> void:
	if not world_tiles.has(Vector2i(x, y)):
		return
	if x < 0 or y < 0 or x >= world_size or y >= world_size:
		return

	var world_tile: WorldTile = world_tiles.get(Vector2i(x, y))

	var tile_pos: Vector2i = Vector2i(x, (ground_offset / tile_size) - y)

	if world_tile.chosen_tile.is_droppable:
		var new_tile_drop: TileDrop = tile_drop.instantiate()
		new_tile_drop.position = get_world_position(x, y + 0.5)
		new_tile_drop.sprite.texture = get_texture_from_position(tile_pos, world_tile.chosen_layer)
		add_child(new_tile_drop)

	world_tile.chosen_layer.set_cell(tile_pos, -1)
	world_tiles.erase(Vector2i(x, y))


func place_tile(tile: Tile, x: int, y: int, layer: TileMapLayer = null) -> void:
	if x < 0 or y < 0 or x >= world_size or y >= world_size:
		return
	if not tile:
		return

	var player_tile: Vector2i = get_coordinates_from_position(player.global_position)
	if Vector2i(x, y) == player_tile:
		return

	var world_tile: WorldTile = world_tiles.get(Vector2i(x, y))
	if world_tile:
		if world_tile.chosen_layer == background:
			remove_tile(x, y)
		else:
			return

	var chosen_layer: TileMapLayer = foreground
	if layer:
		chosen_layer = layer
	elif tile.is_background:
		chosen_layer = background

	var tile_pos: Vector2i = Vector2i(x, (ground_offset / tile_size) - y)
	var coord_choice = tile.atlas_coords.pick_random()

	chosen_layer.set_cell(tile_pos, tile.source_id, coord_choice)
	world_tiles[Vector2i(x, y)] = WorldTile.new(tile, chosen_layer)


func place_tree(current_biome: Biome, x: int, y: int) -> void:
	var tree_height: int = randi_range(current_biome.min_tree_height, current_biome.max_tree_height)
	for i in range(1, tree_height + 1):
		place_tile(current_biome.tile_atlas.tree_log, x, y + i)

	if current_biome.tile_atlas.tree_leaves:
		place_tile(current_biome.tile_atlas.tree_leaves, x, y + tree_height + 1)
		place_tile(current_biome.tile_atlas.tree_leaves, x, y + tree_height + 2)
		place_tile(current_biome.tile_atlas.tree_leaves, x, y + tree_height + 3)

		place_tile(current_biome.tile_atlas.tree_leaves, x - 1, y + tree_height + 1)
		place_tile(current_biome.tile_atlas.tree_leaves, x - 1, y + tree_height + 2)

		place_tile(current_biome.tile_atlas.tree_leaves, x + 1, y + tree_height + 1)
		place_tile(current_biome.tile_atlas.tree_leaves, x + 1, y + tree_height + 2)
