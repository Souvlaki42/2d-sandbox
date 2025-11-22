extends Node2D
class_name TerrainGenerator

var terrain_noise: FastNoiseLite = FastNoiseLite.new()
var cave_noise: FastNoiseLite = FastNoiseLite.new()

var world_tiles: Array[Vector2] = []
var unity_gradient: Gradient
var noise_texture: NoiseTexture2D

@export_category("Generation")
@export var generate_caves: bool = true
@export var world_size: int = 100
@export var height_addition: int = 25
@export var surface_value: float = 0.25
@export var height_multiplier: float = 25
@export var dirt_layer_height: int = 5
@export var ground_offset: float = 600.0
@export var tile_size: int = 128

@export_category("Noise")
@export var terrain_frequency: float = 0.04
@export var cave_frequency: float = 0.08
@export var seed_num: float = 0

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
	seed_num = randi_range(-10000, 10000)
	
	unity_gradient = Gradient.new()
	unity_gradient.set_color(0, Color.BLACK)
	unity_gradient.set_color(1, Color.WHITE)

	cave_noise.seed = 0
	cave_noise.frequency = cave_frequency
	cave_noise.offset = Vector3(seed_num, seed_num, 0)
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	cave_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	
	terrain_noise.seed = 0
	terrain_noise.frequency = terrain_frequency
	terrain_noise.offset = Vector3(seed_num, seed_num, 0)
	terrain_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	terrain_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	
	await generate_noise_texture()
	generate_terrain()
	
func generate_noise_texture() -> void:
	if noise_texture == null:
		noise_texture = NoiseTexture2D.new()
	noise_texture.width = world_size
	noise_texture.height = world_size
	noise_texture.noise = cave_noise
	noise_texture.color_ramp = unity_gradient
	noise_texture.normalize = true
	await noise_texture.changed

func place_tile(tile: Sprite2D, x: int, y: int) -> void:
	var new_tile: Node = tile.duplicate()
	new_tile.visible = true
	new_tile.position = Vector2(x * tile_size, ground_offset - (y * tile_size))
	new_tile.name += " (%d, %d)" % [new_tile.position.x, new_tile.position.y]
	new_tile.owner = get_tree().edited_scene_root
	add_child(new_tile)
	world_tiles.push_back(Vector2(x, y))
	
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
