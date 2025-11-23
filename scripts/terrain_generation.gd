@tool
extends Node2D
class_name TerrainGenerator

var terrain_noise: FastNoiseLite = FastNoiseLite.new()
var cave_noise: FastNoiseLite = FastNoiseLite.new()

var world_tiles: Array[Vector2] = []
var world_chunks: Array[Node2D] = []
var unity_gradient: Gradient
var current_script: Script = get_script()

@export_category("Generation")
@export_tool_button("Generate Terrrain") var generate_terrain_btn: Callable = start_generation
@export_tool_button("Reset Generation") var reset_generation_btn: Callable = reset_generation

@export var noise_texture: NoiseTexture2D = null
@export var chunk_size: int = 20
@export var world_size: int = 100
@export var generate_caves: bool = true
@export var height_addition: int = 25
@export var surface_value: float = 0.25
@export var height_multiplier: float = 25
@export var dirt_layer_height: int = 5
@export var ground_offset: float = 600.0
@export var tile_size: int = 128

@export_category("Noise")
@export var terrain_frequency: float = 0.04
@export var cave_frequency: float = 0.08
@export var noise_seed: float = 0.0

@export_category("Trees")
@export var tree_chance: int = 15 # 15%
@export var min_tree_height: int = 4
@export var max_tree_height: int = 6

@export_category("Tiles")
@export var grass_sprite: Sprite2D
@export var dirt_sprite: Sprite2D
@export var stone_sprite: Sprite2D
@export var log_sprite: Sprite2D
@export var leaf_sprite: Sprite2D

func _ready() -> void:
	if not Engine.is_editor_hint():
		start_generation()


func reset_generation() -> void:
	world_tiles.clear()
	world_chunks.clear()
	
	for i: Node2D in get_children():
		i.queue_free()
	
	assert(current_script != null, "There is should be a script here!")
	
	noise_texture = current_script.get_property_default_value("noise_texture")
	chunk_size = current_script.get_property_default_value("chunk_size")
	world_size = current_script.get_property_default_value("world_size")
	generate_caves = current_script.get_property_default_value("generate_caves")
	height_addition = current_script.get_property_default_value("height_addition")
	surface_value = current_script.get_property_default_value("surface_value")
	height_multiplier = current_script.get_property_default_value("height_multiplier")
	dirt_layer_height = current_script.get_property_default_value("dirt_layer_height")
	ground_offset = current_script.get_property_default_value("ground_offset")
	tile_size = current_script.get_property_default_value("tile_size")

	terrain_frequency = current_script.get_property_default_value("terrain_frequency")
	cave_frequency = current_script.get_property_default_value("cave_frequency")
	noise_seed = current_script.get_property_default_value("noise_seed")

	tree_chance = current_script.get_property_default_value("tree_chance")
	min_tree_height = current_script.get_property_default_value("min_tree_height")
	max_tree_height = current_script.get_property_default_value("max_tree_height")
	
func start_generation() -> void:
	reset_generation()
	
	noise_seed = randi_range(-10000, 10000)
	unity_gradient = Gradient.new()
	unity_gradient.set_color(0, Color.BLACK)
	unity_gradient.set_color(1, Color.WHITE)

	cave_noise.seed = 0
	cave_noise.frequency = cave_frequency
	cave_noise.offset = Vector3(noise_seed, noise_seed, 0)
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	cave_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	
	terrain_noise.seed = 0
	terrain_noise.frequency = terrain_frequency
	terrain_noise.offset = Vector3(noise_seed, noise_seed, 0)
	terrain_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	terrain_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	
	await generate_noise_texture()
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

func generate_noise_texture() -> void:
	if noise_texture == null:
		noise_texture = NoiseTexture2D.new()
	noise_texture.width = world_size
	noise_texture.height = world_size
	noise_texture.noise = cave_noise
	noise_texture.color_ramp = unity_gradient
	noise_texture.normalize = true
	await noise_texture.changed
	notify_property_list_changed()

func place_tile(tile: Sprite2D, x: int, y: int) -> void:
	var chunk_coord: int = floori(float(x) / chunk_size)
	var new_tile: Sprite2D = tile.duplicate()
	new_tile.visible = true
	new_tile.position = Vector2(x * tile_size, ground_offset - (y * tile_size))
	new_tile.name += " (%d, %d)" % [new_tile.position.x / tile_size, new_tile.position.y / tile_size]
	world_chunks[chunk_coord].add_child(new_tile)
	world_tiles.push_back(Vector2(x, y))
	if Engine.is_editor_hint():
		new_tile.owner = get_tree().edited_scene_root
	
func place_tree(x: int, y: int) -> void:
	if randi_range(0, tree_chance) == 1 and world_tiles.has(Vector2(x, y)):
		var tree_height: int = randi_range(min_tree_height, max_tree_height)
		for i in range(1, tree_height + 1):
			place_tile(log_sprite, x, y + i)
			
		place_tile(leaf_sprite, x, y + tree_height + 1)
		place_tile(leaf_sprite, x, y + tree_height + 2)
		place_tile(leaf_sprite, x, y + tree_height + 3)
		
		place_tile(leaf_sprite, x - 1, y + tree_height + 1)
		place_tile(leaf_sprite, x - 1, y + tree_height + 2)
		
		place_tile(leaf_sprite, x + 1, y + tree_height + 1)
		place_tile(leaf_sprite, x + 1, y + tree_height + 2)
			
func generate_terrain() -> void:
	var noise_image: Image = noise_texture.get_image()
	for x: int in range(world_size):
		var height: float = terrain_noise.get_noise_2d(x, 0) * height_multiplier + height_addition
		for y: int in range(height):
			var tile: Sprite2D
			if y < height - dirt_layer_height:
				tile = stone_sprite
			elif y < int(height - 1):
				tile = dirt_sprite
			else:
				tile = grass_sprite
				
			if noise_image.get_pixel(x, y).r > surface_value or not generate_caves:
				place_tile(tile, x, y)
			
			if y >= int(height - 1):
				place_tree(x, y)
