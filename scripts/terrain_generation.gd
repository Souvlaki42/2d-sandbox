extends Node2D
class_name TerrainGenerator

var noise: FastNoiseLite = FastNoiseLite.new()

@export_category("Generation")
@export var worldSize: int = 100
@export var heightAddition: int = 25
@export var terrainFrequency: float = 0.04
@export var caveFrequency: float = 0.08
@export var surfaceValue: float = 0.25
@export var heightMultiplier: float = 25
@export var seedNum: float = 0
@export var ground_offset: float = 600.0

@export_category("Nodes")
@export var tile: Sprite2D
@export var noise_texture: ImageTexture

var noise_image: Image

func _ready() -> void:
	seedNum = randi_range(-10000, 10000)
	noise.seed = 0
	noise.frequency = 1
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	generate_noise_texture()
	generate_terrain()
	
func perlin_noise(x: float, y: float, frequency: float) -> float:
	return (noise.get_noise_2d((x + seedNum) * frequency, (y + seedNum) * frequency) + 1.0) / 2.0
	
func generate_noise_texture() -> void:
	noise_image = Image.create(worldSize, worldSize, true, Image.FORMAT_L8)
	for x: int in range(noise_image.get_width()):
		for y: int in range(noise_image.get_height()):
			var v: float = perlin_noise(x, y, caveFrequency)
			noise_image.set_pixel(x, y, Color(v, v, v))
	noise_texture = ImageTexture.create_from_image(noise_image)
			
func generate_terrain() -> void:
	var tile_size: int = tile.texture.get_width()
	for x: int in range(worldSize):
		var height: float = perlin_noise(x, 0, terrainFrequency) * heightMultiplier + heightAddition
		for y: int in range(height):
			if noise_image.get_pixel(x, y).r > surfaceValue:
				var new_tile: Node = tile.duplicate()
				new_tile.visible = true
				new_tile.position = Vector2(x * tile_size, ground_offset - (y * tile_size))
				new_tile.name = "Tile (%d, %d)" % [new_tile.position.x, new_tile.position.y]
				add_child(new_tile)
