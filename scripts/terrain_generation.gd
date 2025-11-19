extends Node2D
class_name TerrainGenerator

var terrain_noise: FastNoiseLite = FastNoiseLite.new()
var cave_noise: FastNoiseLite = FastNoiseLite.new()

@export_category("Generation")
@export var world_size: int = 100
@export var height_addition: int = 25
@export var terrain_frequency: float = 0.04
@export var cave_frequency: float = 0.08
@export var surface_value: float = 0.25
@export var height_multiplier: float = 25
@export var seed_num: float = 0
@export var ground_offset: float = 600.0

@export_category("Nodes")
@export var tile: Sprite2D
@export var noise_texture: NoiseTexture2D

func _ready() -> void:
	seed_num = randi_range(-10000, 10000)
	
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
	var gradient = Gradient.new()
	gradient.set_color(0, Color.BLACK)
	gradient.set_color(1, Color.WHITE)
	noise_texture = NoiseTexture2D.new()
	noise_texture.width = world_size
	noise_texture.height = world_size
	noise_texture.noise = cave_noise
	noise_texture.color_ramp = gradient
	noise_texture.normalize = true
	await noise_texture.changed
			
func generate_terrain() -> void:
	var tile_size: int = tile.texture.get_width()
	var noise_image: Image = noise_texture.get_image()
	for x: int in range(world_size):
		var height: float = terrain_noise.get_noise_2d(x, 0) * height_multiplier + height_addition
		for y: int in range(height):
			if noise_image.get_pixel(x, y).r > surface_value:
				var new_tile: Node = tile.duplicate()
				new_tile.visible = true
				new_tile.position = Vector2(x * tile_size, ground_offset - (y * tile_size))
				new_tile.name = "Tile (%d, %d)" % [new_tile.position.x, new_tile.position.y]
				add_child(new_tile)
