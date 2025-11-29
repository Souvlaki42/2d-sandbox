@tool
extends FastNoiseLite
class_name PerlinNoise

func _init(noise_seed: int, noise_frequency: float) -> void:
	seed = noise_seed
	frequency = noise_frequency
	noise_type = FastNoiseLite.TYPE_PERLIN
	fractal_type = FastNoiseLite.FRACTAL_NONE

func get_unity_noise(x: int, y: int) -> float:
	return clamp((get_noise_2d(x, y) + 1.0) / 2.0, 0.0, 1.0)
