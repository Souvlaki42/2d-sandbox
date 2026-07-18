@icon("res://assets/icons/color/icon_map_2.png")
class_name Terrain
extends Node2D

@export_category("Terrain Settings")
@export var world_size: int = 200
@export var height_addition: int = 50
@export var tile_size: int = 128
@export var world_seed: String = ""

@export_category("Biome Settings")
@export var biome_frequency: float = 0.01
@export var biome_colors: Gradient
@export var biomes: Array[Biome] = []

@export_category("Layers")
@export var foreground: TileMapLayer
@export var middle_ground: TileMapLayer
@export var background: TileMapLayer

@export_category("Node References")
@export var player: Player
@export var debug: Debug
@export var left_wall: CollisionShape2D
@export var right_wall: CollisionShape2D
@export var tile_drop: PackedScene

var biome_noise: PerlinNoise = null
var biome_lookup: Dictionary[int, Biome] = { }
var world_tiles: Dictionary[Vector2i, WorldTile] = { }
var noise_seed: int = 0
var biome_map: NoiseTexture2D = null


class WorldTile:
	var chosen_tile: Tile
	var chosen_layer: TileMapLayer
	var is_natural: bool


	func _init(tile: Tile, layer: TileMapLayer, natural: bool) -> void:
		self.chosen_tile = tile
		self.chosen_layer = layer
		self.is_natural = natural
		

func _ready() -> void:
	randomize()
	if world_seed == "":
		noise_seed = randi()
	else:
		noise_seed = world_seed.hash()
	seed(noise_seed)

	for biome in biomes:
		biome_lookup[biome.tint.to_rgba32()] = biome

	draw_noise_images()
	generate_terrain()
	player.global_position = find_spawn_position()


func set_limits() -> void:
	player.camera.set_limit(SIDE_LEFT, 0)
	player.camera.set_limit(SIDE_RIGHT, world_size * tile_size)
	player.camera.set_limit(SIDE_TOP, 0)
	player.camera.set_limit(SIDE_BOTTOM, world_size * tile_size)

	left_wall.position.x = player.camera.limit_left
	right_wall.position.x = player.camera.limit_right


func find_spawn_position() -> Vector2:
	var x: int = world_size / 2
	for y: int in range(world_size):
		var current_tile = world_tiles.get(Vector2i(x, y))
		if current_tile and current_tile.chosen_layer == foreground:
			return foreground.to_global(foreground.map_to_local(Vector2i(x, y - 1)))
	return foreground.to_global(foreground.map_to_local(Vector2i(x, world_size / 2)))


func get_empty_tiles() -> Array[Vector2i]:
	var empty_tiles: Array[Vector2i] = []
	for x in range(world_size):
		for y in range(world_size):
			if not world_tiles.has(Vector2i(x, y)):
				empty_tiles.append(Vector2i(x, y))
	return empty_tiles


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


func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < world_size and pos.y < world_size


func generate_terrain() -> void:
	for x: int in range(world_size):
		var current_biome: Biome = get_biome(x, 0)
		var surface_y: int = int(world_size - (current_biome.terrain_noise.get_unity_noise(x, 0) * current_biome.height_multiplier + height_addition))

		for y: int in range(world_size):
			current_biome = get_biome(x, y)
			var tiles: TileAtlas = current_biome.tile_atlas

			if y < surface_y:
				continue

			var current_tile: Tile = tiles.stone

			if y == surface_y:
				current_tile = tiles.grass
			elif y < surface_y + current_biome.dirt_layer_height:
				current_tile = tiles.dirt
			elif not tiles.get_ores().is_empty():
				if tiles.coal.noise.get_unity_noise(x, y) > tiles.coal.vein_size and y - surface_y > tiles.coal.max_spawn_height:
					current_tile = tiles.coal
				if tiles.iron.noise.get_unity_noise(x, y) > tiles.iron.vein_size and y - surface_y > tiles.iron.max_spawn_height:
					current_tile = tiles.iron
					if tiles.gold.noise.get_unity_noise(x, y) > tiles.gold.vein_size and y - surface_y > tiles.gold.max_spawn_height:
						current_tile = tiles.gold
						if tiles.diamond.noise.get_unity_noise(x, y) > tiles.diamond.vein_size and y - surface_y > tiles.diamond.max_spawn_height:
							current_tile = tiles.diamond

			var cave_noise: float = current_biome.cave_noise.get_unity_noise(x, y)

			if not current_biome.generate_caves or cave_noise > current_biome.surface_value:
				place_tile(current_tile, Vector2i(x, y))

			if current_biome.generate_caves and cave_noise <= current_biome.surface_value and current_tile.wall_variant:
				place_tile(current_tile.wall_variant, Vector2i(x, y), background)

			if y == surface_y:
				if randi_range(0, current_biome.tree_percent_chance) == 1 and world_tiles.has(Vector2i(x, y)):
					place_tree(current_biome, x, y)
				elif tiles.addons and randi_range(0, current_biome.addon_percent_chance) == 1 and world_tiles.has(Vector2i(x, y)):
					place_tile(tiles.addons, Vector2i(x, y - 1))


func get_texture_from_position(pos: Vector2i, layer: TileMapLayer = foreground) -> Texture2D:
	var source_id: int = layer.get_cell_source_id(pos)
	var atlas_coords: Vector2i = layer.get_cell_atlas_coords(pos)
	var atlas_source: TileSetAtlasSource = layer.tile_set.get_source(source_id)
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = atlas_source.texture
	atlas_texture.region = atlas_source.get_tile_texture_region(atlas_coords)
	return atlas_texture


func remove_tile(pos: Vector2i) -> void:
	if not is_in_bounds(pos):
		return

	var world_tile: WorldTile = world_tiles.get(pos)

	if not world_tile:
		return

	if world_tile.chosen_tile.is_droppable:
		var new_tile_drop: TileDrop = tile_drop.instantiate()
		new_tile_drop.position = world_tile.chosen_layer.to_global(world_tile.chosen_layer.map_to_local(pos))
		new_tile_drop.sprite.texture = get_texture_from_position(pos, world_tile.chosen_layer)
		add_child(new_tile_drop)

	world_tile.chosen_layer.set_cell(pos, -1)
	world_tiles.erase(pos)

	if world_tile.chosen_tile.wall_variant and world_tile.is_natural:
		place_tile(world_tile.chosen_tile.wall_variant, pos, background)


func place_tile(tile: Tile, pos: Vector2i, layer: TileMapLayer = null, natural: bool = true) -> void:
	if not is_in_bounds(pos):
		return
	if not tile:
		return

	var chosen_layer: TileMapLayer = foreground
	if layer:
		chosen_layer = layer
	elif tile.is_background:
		chosen_layer = middle_ground

	var player_tile: Vector2i = chosen_layer.local_to_map(chosen_layer.to_local(player.global_position))
	if pos == player_tile:
		return

	var world_tile: WorldTile = world_tiles.get(pos)
	if world_tile:
		if world_tile.chosen_layer == foreground:
			return

	var coord_choice = tile.atlas_coords.pick_random()

	chosen_layer.set_cell(pos, tile.source_id, coord_choice)
	world_tiles[pos] = WorldTile.new(tile, chosen_layer, natural)


func place_tree(current_biome: Biome, x: int, y: int) -> void:
	var tree_height: int = randi_range(current_biome.min_tree_height, current_biome.max_tree_height)
	for i in range(1, tree_height + 1):
		place_tile(current_biome.tile_atlas.tree_log, Vector2i(x, y - i))

	if current_biome.tile_atlas.tree_leaves:
		place_tile(current_biome.tile_atlas.tree_leaves, Vector2i(x, y - tree_height - 1))
		place_tile(current_biome.tile_atlas.tree_leaves, Vector2i(x, y - tree_height - 2))
		place_tile(current_biome.tile_atlas.tree_leaves, Vector2i(x, y - tree_height - 3))

		place_tile(current_biome.tile_atlas.tree_leaves, Vector2i(x - 1, y - tree_height - 1))
		place_tile(current_biome.tile_atlas.tree_leaves, Vector2i(x - 1, y - tree_height - 2))

		place_tile(current_biome.tile_atlas.tree_leaves, Vector2i(x + 1, y - tree_height - 1))
		place_tile(current_biome.tile_atlas.tree_leaves, Vector2i(x + 1, y - tree_height - 2))
