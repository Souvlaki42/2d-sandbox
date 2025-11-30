@tool
extends Node2D
class_name TerrainGenerator

var biome_noise: PerlinNoise = null
var biome_lookup: Dictionary = {}
var world_tiles: Array[Vector2i] = []
var world_chunks: Array[Node2D] = []

@export_category("Actions")
@export_tool_button("Generate Terrrain") var generate_terrain_btn: Callable = start_generation
@export_tool_button("Draw Noise Images") var draw_noise_images_btn: Callable = draw_noise_images
@export_tool_button("Clear Everything") var reset_generation_btn: Callable = clear_everything

@export_category("Terrain Settings")
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY) var noise_seed: int = 0
@export var chunk_size: int = 20
@export var world_size: int = 100
@export var height_addition: int = 50
@export var ground_offset: int = 600
@export var tile_size: int = 128

@export_category("Biome Settings")
@export var biome_map: Image = null
@export var biome_frequency: float = 0.01
@export var biome_colors: Gradient
@export var biomes: Array[Biome] = []

func _ready() -> void:
	if not Engine.is_editor_hint():
		start_generation()

func clear_everything() -> void:
	assert(not biomes.is_empty(), "Biomes should be here!")

	world_tiles.clear()
	world_chunks.clear()

	biome_map = null
	for biome in biomes:
		biome.cave_noise_image = null
		var ores: Array[Ore] = biome.tile_atlas.get_ores()
		for ore in ores:
			ore.spread_image = null

	noise_seed = 0

	notify_property_list_changed()

	for i: Node2D in get_children():
		i.queue_free()

func start_generation() -> void:
	clear_everything()

	randomize()
	if noise_seed == 0:
		noise_seed = randi_range(-10000, 10000)
		seed(noise_seed)

	for biome in biomes:
		biome_lookup[biome.tint] = biome

	draw_noise_images()
	create_chunks()
	generate_terrain()

func get_biome(x: int, y: int) -> Biome:
	return biome_lookup.get(biome_map.get_pixel(x, y), null)

func create_chunks() -> void:
	# TODO: Fix out of bounds errors
	var num_of_chunks: int = roundi(float(world_size) / chunk_size)
	world_chunks.resize(num_of_chunks)

	for i: int in range(num_of_chunks):
		var new_chunk: Node2D = Node2D.new()
		new_chunk.name = "Chunk #%d" % i
		world_chunks[i] = new_chunk
		add_child(new_chunk)
		if Engine.is_editor_hint():
			new_chunk.owner = get_tree().edited_scene_root

func draw_noise_images() -> void:
	biome_noise = PerlinNoise.new(noise_seed, biome_frequency)
	biome_map = generate_biome_image(biome_noise, world_size)

	for biome in biomes:
		biome.terrain_noise = PerlinNoise.new(noise_seed, biome.terrain_frequency)
		biome.cave_noise = PerlinNoise.new(noise_seed, biome.cave_frequency)
		biome.cave_noise_image = generate_noise_image(biome.cave_noise, world_size, biome.surface_value)

		for ore in biome.tile_atlas.get_ores():
			ore.noise = PerlinNoise.new(noise_seed, ore.frequency)
			ore.spread_image = generate_noise_image(ore.noise, world_size, ore.vein_size)

	notify_property_list_changed()

func place_tile(tile: Tile, x: int, y: int) -> void:
	if world_tiles.has(Vector2i(x, y)): return
	if x < 0 or y < 0 or x >= world_size or y >= world_size: return

	var chunk_coord: int = clamp(floori(float(x) / chunk_size), 0, world_chunks.size() - 1)
	var new_tile: Sprite2D = Sprite2D.new()
	new_tile.name = "%s (%d, %d)" % [tile.tile_name, x, y]
	new_tile.texture = tile.tile_sprites[randi_range(0, tile.tile_sprites.size() - 1)]
	new_tile.visible = true
	new_tile.position = Vector2i(x * tile_size, ground_offset - (y * tile_size))
	world_chunks[chunk_coord].add_child(new_tile)
	world_tiles.push_back(Vector2i(x, y))
	if Engine.is_editor_hint():
		new_tile.owner = get_tree().edited_scene_root

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

func generate_noise_image(noise: PerlinNoise, size: int, threshold: float) -> Image:
	var image: Image = Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)

	for x: int in range(size):
		for y: int in range(size):
			if  noise.get_unity_noise(x, y) > threshold:
				image.set_pixel(x, y, Color.WHITE)
	return image

func generate_biome_image(noise: PerlinNoise, size: int) -> Image:
	var image: Image = Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)

	for x: int in range(size):
		for y: int in range(size):
			var biome_color: Color = biome_colors.sample(noise.get_unity_noise(x, y))
			image.set_pixel(x, y, biome_color)
	return image

func generate_terrain() -> void:
	for x: int in range(world_size):
		for y: int in range(world_size):
			var current_biome: Biome = get_biome(x, y)
			var height: float = current_biome.terrain_noise.get_unity_noise(x, 0) * current_biome.height_multiplier + height_addition
			if y >= height: break
			var current_tile: Tile = current_biome.tile_atlas.stone
			if y < height - current_biome.dirt_layer_height and not current_biome.tile_atlas.get_ores().is_empty():
				if current_biome.tile_atlas.coal.spread_image.get_pixel(x, y).r > 0.5 and height - y > current_biome.tile_atlas.coal.max_spawn_height:
					current_tile = current_biome.tile_atlas.coal
				if current_biome.tile_atlas.iron.spread_image.get_pixel(x, y).r > 0.5 and height - y > current_biome.tile_atlas.iron.max_spawn_height:
					current_tile = current_biome.tile_atlas.iron
				if current_biome.tile_atlas.gold.spread_image.get_pixel(x, y).r > 0.5 and height - y > current_biome.tile_atlas.gold.max_spawn_height:
					current_tile = current_biome.tile_atlas.gold
				if current_biome.tile_atlas.diamond.spread_image.get_pixel(x, y).r > 0.5 and height - y > current_biome.tile_atlas.diamond.max_spawn_height:
					current_tile = current_biome.tile_atlas.diamond
			elif y < int(height - 1):
				current_tile = current_biome.tile_atlas.dirt
			else:
				current_tile = current_biome.tile_atlas.grass

			if current_biome.cave_noise_image.get_pixel(x, y).r > 0.5 or not current_biome.generate_caves:
				place_tile(current_tile, x, y)

			if y >= int(height - 1):
				if randi_range(0, current_biome.tree_percent_chance) == 1 and world_tiles.has(Vector2i(x, y)):
					place_tree(current_biome, x, y)
				elif current_biome.tile_atlas.addons != null and randi_range(0, current_biome.addon_percent_chance) == 1 and world_tiles.has(Vector2i(x, y)):
					place_tile(current_biome.tile_atlas.addons, x, y + 1)
