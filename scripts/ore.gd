class_name Ore
extends Tile

var noise: PerlinNoise = null
var spread_texture: NoiseTexture2D = null

@export_range(0, 1) var frequency: float
@export_range(0, 1) var vein_size: float
@export var max_spawn_height: int
