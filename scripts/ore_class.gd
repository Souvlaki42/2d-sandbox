@tool
extends Tile
class_name Ore

var noise: PerlinNoise = null

@export_range(0, 1) var rarity: float
@export_range(0, 1) var vein_size: float
@export var max_spawn_height: int
@export var spread_image: Image
