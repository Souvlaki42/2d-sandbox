@tool
extends Node2D
class_name TerrainGenerator

var terrain_noise: FastNoiseLite = FastNoiseLite.new()
var cave_noise: FastNoiseLite = FastNoiseLite.new()

var world_tiles: Array[Vector2] = []
var world_chunks: Array[Node2D] = []

@export_category("Terrain Settings")
@export var chunk_size: int = 20:
	set(new_value):
		chunk_size = new_value
		Globals.terrain_settings_changed.emit()
@export var world_size: int = 100:
	set(new_value):
		chunk_size = new_value
		Globals.terrain_settings_changed.emit()
@export var generate_caves: bool = true:
	set(new_value):
		generate_caves = new_value
		Globals.terrain_settings_changed.emit()
@export var height_addition: int = 25:
	set(new_value):
		height_addition = new_value
		Globals.terrain_settings_changed.emit()
@export var surface_value: float = 0.25:
	set(new_value):
		surface_value = new_value
		Globals.terrain_settings_changed.emit()
@export var height_multiplier: float = 25:
	set(new_value):
		height_multiplier = new_value
		Globals.terrain_settings_changed.emit()
@export var dirt_layer_height: int = 5:
	set(new_value):
		dirt_layer_height = new_value
		Globals.terrain_settings_changed.emit()
@export var ground_offset: float = 600.0:
	set(new_value):
		ground_offset = new_value
		Globals.terrain_settings_changed.emit()
@export var tile_size: int = 128:
	set(new_value):
		tile_size = new_value
		Globals.terrain_settings_changed.emit()

@export_category("Noise Settings")
@export var world_atlas: WorldAtlas
@export var cave_noise_texture: NoiseTexture2D = null

@export var terrain_frequency: float = 0.04:
	set(new_value):
		terrain_frequency = new_value
		Globals.noise_settings_changed.emit()
@export var cave_frequency: float = 0.08:
	set(new_value):
		cave_frequency = new_value
		Globals.noise_settings_changed.emit()
@export var noise_seed: int = 0:
	set(new_value):
		noise_seed = new_value
		Globals.noise_settings_changed.emit()

@export_category("Tree Settings")
@export var tree_percent_chance: int = 15:
	set(new_value):
		tree_percent_chance = new_value
		Globals.terrain_settings_changed.emit()
@export var min_tree_height: int = 4:
	set(new_value):
		min_tree_height = new_value
		Globals.terrain_settings_changed.emit()
@export var max_tree_height: int = 6:
	set(new_value):
		max_tree_height = new_value
		Globals.terrain_settings_changed.emit()

@export_category("Actions")
@export_tool_button("Generate Terrrain") var generate_terrain_btn: Callable = start_generation
@export_tool_button("Clear Generation") var reset_generation_btn: Callable = clear_generation

func _ready() -> void:
	Globals.terrain_settings_changed.connect(_on_terrain_settings_connect)
	Globals.noise_settings_changed.connect(_on_noise_settings_connect)
	if not Engine.is_editor_hint():
		start_generation()
		
func _on_terrain_settings_connect() -> void:
	start_generation()

func _on_noise_settings_connect() -> void:
	create_noise_textures()

func clear_generation() -> void:
	world_tiles.clear()
	world_chunks.clear()
	
	cave_noise_texture = null
	noise_seed = 0
	
	for i: Node2D in get_children():
		i.queue_free()
	
func start_generation() -> void:
	clear_generation()
	assert(world_atlas != null, "World atlas should be here!")

	if noise_seed == 0:
		noise_seed = randi_range(-10000, 10000)
		
	await create_noise_textures()
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
			
func create_noise_textures() -> void:
	cave_noise.seed = noise_seed
	cave_noise.frequency = cave_frequency
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	cave_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	
	terrain_noise.seed = noise_seed
	terrain_noise.frequency = terrain_frequency
	terrain_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	terrain_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	
	cave_noise_texture = await _generate_noise_texture(cave_noise)
	
	notify_property_list_changed()

func _generate_noise_texture(noise: Noise) -> NoiseTexture2D:
	var texture: NoiseTexture2D = NoiseTexture2D.new()
	texture.width = world_size
	texture.height = world_size
	texture.noise = noise
	texture.normalize = true
	await texture.changed
	return texture

func place_tile(tile: Tile, x: int, y: int) -> void:
	var chunk_coord: int = floori(float(x) / chunk_size)
	var new_tile: Sprite2D = Sprite2D.new()
	new_tile.name = "%s (%d, %d)" % [tile.tile_name, x, y]
	new_tile.texture = tile.tile_sprite
	new_tile.visible = true
	new_tile.position = Vector2(x * tile_size, ground_offset - (y * tile_size))
	world_chunks[chunk_coord].add_child(new_tile)
	world_tiles.push_back(Vector2(x, y))
	if Engine.is_editor_hint():
		new_tile.owner = get_tree().edited_scene_root
	
func place_tree(x: int, y: int) -> void:
	if randi_range(0, tree_percent_chance) == 1 and world_tiles.has(Vector2(x, y)):
		var tree_height: int = randi_range(min_tree_height, max_tree_height)
		for i in range(1, tree_height + 1):
			place_tile(world_atlas.tree_log, x, y + i)
			
		place_tile(world_atlas.tree_leaves, x, y + tree_height + 1)
		place_tile(world_atlas.tree_leaves, x, y + tree_height + 2)
		place_tile(world_atlas.tree_leaves, x, y + tree_height + 3)
		
		place_tile(world_atlas.tree_leaves, x - 1, y + tree_height + 1)
		place_tile(world_atlas.tree_leaves, x - 1, y + tree_height + 2)
		
		place_tile(world_atlas.tree_leaves, x + 1, y + tree_height + 1)
		place_tile(world_atlas.tree_leaves, x + 1, y + tree_height + 2)
			
func generate_terrain() -> void:
	var noise_image: Image = cave_noise_texture.get_image()
	for x: int in range(world_size):
		var height: float = terrain_noise.get_noise_2d(x, 0) * height_multiplier + height_addition
		for y: int in range(height):
			var tile: Tile
			if y < height - dirt_layer_height:
				tile = world_atlas.stone
			elif y < int(height - 1):
				tile = world_atlas.dirt
			else:
				tile = world_atlas.grass
				
			if noise_image.get_pixel(x, y).r > surface_value or not generate_caves:
				place_tile(tile, x, y)
			
			if y >= int(height - 1):
				place_tree(x, y)
