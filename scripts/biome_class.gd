@tool
class_name Biome extends Resource

var cave_noise: PerlinNoise = null
var terrain_noise: PerlinNoise = null

@export var name: StringName
@export var tint: Color
@export var tile_atlas: TileAtlas

@export_category("Terrain Settings")
@export var generate_caves: bool = true
@export var surface_value: float = 0.25
@export var height_multiplier: float = 25
@export var dirt_layer_height: int = 5

@export_category("Prop Settings")
@export var addon_percent_chance: int = 2
@export var tree_percent_chance: int = 15
@export var min_tree_height: int = 4
@export var max_tree_height: int = 6

@export_category("Noise Settings")
@export var cave_noise_texture: NoiseTexture2D = null
@export var terrain_frequency: float = 0.04
@export var cave_frequency: float = 0.08
