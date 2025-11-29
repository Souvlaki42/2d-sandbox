@tool
extends Node2D
class_name TerrainGenerator

var terrain_noise: PerlinNoise = null
var cave_noise: PerlinNoise = null

var world_tiles: Array[Vector2i] = []
var world_chunks: Array[Node2D] = []

@export_category("Actions")
@export_tool_button("Generate Terrrain") var generate_terrain_btn: Callable = start_generation
@export_tool_button("Clear Generation") var reset_generation_btn: Callable = clear_generation

@export_category("Terrain Settings")
@export var chunk_size: int = 20
@export var world_size: int = 100
@export var generate_caves: bool = true
@export var height_addition: int = 50
@export var surface_value: float = 0.25
@export var height_multiplier: float = 25
@export var dirt_layer_height: int = 5
@export var ground_offset: int = 600
@export var tile_size: int = 128

@export_category("Biome Settings")
@export var biome_map: Image = null
@export var biome_frequency: float
@export var grassland_color: Color
@export var forest_color: Color
@export var desert_color: Color
@export var freezing_color: Color

@export_category("Prop Settings")
@export var tall_grass_percent_chance: int = 2
@export var tree_percent_chance: int = 15
@export var min_tree_height: int = 4
@export var max_tree_height: int = 6

@export_category("Noise Settings")
@export var cave_noise_image: Image = null
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY) var noise_seed: int = 0

@export var terrain_frequency: float = 0.04
@export var cave_frequency: float = 0.08
@export var tile_atlas: TileAtlas
@export var ore_atlas: OreAtlas

func _ready() -> void:
	if not Engine.is_editor_hint():
		start_generation()

func clear_generation() -> void:
	world_tiles.clear()
	world_chunks.clear()

	cave_noise_image = null
	if ore_atlas != null:
		ore_atlas.coal.spread_image = null
		ore_atlas.iron.spread_image = null
		ore_atlas.gold.spread_image = null
		ore_atlas.diamond.spread_image = null
	noise_seed = 0

	notify_property_list_changed()

	for i: Node2D in get_children():
		i.queue_free()

func start_generation() -> void:
	clear_generation()

	assert(world_atlas != null, "World atlas should be here!")
	assert(tile_atlas != null, "Tile atlas should be here!")
	assert(ore_atlas != null, "Ore atlas should be here!")

	randomize()
	if noise_seed == 0:
		noise_seed = randi_range(-10000, 10000)
		seed(noise_seed)

	draw_noise_images()
	create_chunks()
	generate_terrain()



func create_chunks() -> void:
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
	cave_noise = PerlinNoise.new(noise_seed, cave_frequency)
	cave_noise_image = draw_noise_image(cave_noise, world_size, surface_value)

	terrain_noise = PerlinNoise.new(noise_seed, terrain_frequency)

	ore_atlas.coal.noise = PerlinNoise.new(noise_seed, ore_atlas.coal.rarity)
	ore_atlas.coal.spread_image = draw_noise_image(ore_atlas.coal.noise, world_size, ore_atlas.coal.vein_size)

	ore_atlas.iron.noise = PerlinNoise.new(noise_seed, ore_atlas.iron.rarity)
	ore_atlas.iron.spread_image = draw_noise_image(ore_atlas.iron.noise, world_size, ore_atlas.iron.vein_size)

	ore_atlas.gold.noise = PerlinNoise.new(noise_seed, ore_atlas.gold.rarity)
	ore_atlas.gold.spread_image = draw_noise_image(ore_atlas.gold.noise, world_size, ore_atlas.gold.vein_size)

	ore_atlas.diamond.noise = PerlinNoise.new(noise_seed, ore_atlas.diamond.rarity)
	ore_atlas.diamond.spread_image = draw_noise_image(ore_atlas.diamond.noise, world_size, ore_atlas.diamond.vein_size)

	notify_property_list_changed()

func place_tile(tile: Tile, x: int, y: int) -> void:
	if world_tiles.has(Vector2i(x, y)): return

	var chunk_coord: int = floori(float(x) / chunk_size)
	var new_tile: Sprite2D = Sprite2D.new()
	new_tile.name = "%s (%d, %d)" % [tile.tile_name, x, y]
	new_tile.texture = tile.tile_sprites[randi_range(0, tile.tile_sprites.size() - 1)]
	new_tile.visible = true
	new_tile.position = Vector2i(x * tile_size, ground_offset - (y * tile_size))
	world_chunks[chunk_coord].add_child(new_tile)
	world_tiles.push_back(Vector2i(x, y))
	if Engine.is_editor_hint():
		new_tile.owner = get_tree().edited_scene_root

func place_tree(x: int, y: int) -> void:
	var tree_height: int = randi_range(min_tree_height, max_tree_height)
	for i in range(1, tree_height + 1):
		place_tile(tile_atlas.tree_log, x, y + i)

	place_tile(tile_atlas.tree_leaves, x, y + tree_height + 1)
	place_tile(tile_atlas.tree_leaves, x, y + tree_height + 2)
	place_tile(tile_atlas.tree_leaves, x, y + tree_height + 3)

	place_tile(tile_atlas.tree_leaves, x - 1, y + tree_height + 1)
	place_tile(tile_atlas.tree_leaves, x - 1, y + tree_height + 2)

	place_tile(tile_atlas.tree_leaves, x + 1, y + tree_height + 1)
	place_tile(tile_atlas.tree_leaves, x + 1, y + tree_height + 2)

func draw_noise_image(noise: PerlinNoise, size: int, threshold: float) -> Image:
	var image: Image = Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)

	for x: int in range(size):
		for y: int in range(size):
			if  noise.get_unity_noise(x, y) > threshold:
				image.set_pixel(x, y, Color.WHITE)
	return image
func generate_terrain() -> void:
	for x: int in range(world_size):
		var height: float = terrain_noise.get_unity_noise(x, 0) * height_multiplier + height_addition
		for y: int in range(height):
			var tile: Tile = tile_atlas.stone
			if y < height - dirt_layer_height:
				if ore_atlas.coal.spread_image.get_pixel(x, y).r > 0.5 and height - y > ore_atlas.coal.max_spawn_height:
					tile = ore_atlas.coal
				if ore_atlas.iron.spread_image.get_pixel(x, y).r > 0.5 and height - y > ore_atlas.iron.max_spawn_height:
					tile = ore_atlas.iron
				if ore_atlas.gold.spread_image.get_pixel(x, y).r > 0.5 and height - y > ore_atlas.gold.max_spawn_height:
					tile = ore_atlas.gold
				if ore_atlas.diamond.spread_image.get_pixel(x, y).r > 0.5 and height - y > ore_atlas.diamond.max_spawn_height:
					tile = ore_atlas.diamond
			elif y < int(height - 1):
				tile = tile_atlas.dirt
			else:
				tile = tile_atlas.grass

			if cave_noise_image.get_pixel(x, y).r > 0.5 or not generate_caves:
				place_tile(tile, x, y)

			if y >= int(height - 1):
				if randi_range(0, tree_percent_chance) == 1 and world_tiles.has(Vector2i(x, y)):
					place_tree(x, y)
				elif randi_range(0, tall_grass_percent_chance) == 1 && world_tiles.has(Vector2i(x, y)):
					place_tile(tile_atlas.tall_grass, x, y + 1)
